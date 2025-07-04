import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:common/communication_protocol.dart';
import 'package:common/models/generic/access_level.dart';
import 'package:common/models/generic/extended_item_serializable.dart';
import 'package:common_flutter/providers/auth_provider.dart';
import 'package:enhanced_containers/database_list_provided.dart';
import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:web_socket_client/web_socket_client.dart';

class _Selector {
  final Function(Map<String, dynamic> items, {bool notify}) addOrReplaceItems;
  final Function(dynamic items, {bool notify}) removeItem;
  final Function() stopFetchingData;
  final Function() notify;

  const _Selector({
    required this.addOrReplaceItems,
    required this.removeItem,
    required this.stopFetchingData,
    required this.notify,
  });
}

/// A [BackendListProvided] that automagically saves all of its into the backend
/// implemented in $ROOT/backend,
///
/// Written by: @pariterre
abstract class BackendListProvided<T extends ExtendedItemSerializable>
    extends DatabaseListProvided<T> {
  final Uri uri;
  bool _hasProblemConnecting = false;
  bool get hasProblemConnecting => _hasProblemConnecting;
  bool _connexionRefused = false;
  bool get connexionRefused => _connexionRefused;
  bool get isConnected =>
      (_providerSelector[getField()] != null &&
          _socket != null &&
          _handshakeReceived) ||
      mockMe;
  bool get isNotConnected => !isConnected;

  /// Creates a [BackendListProvided] with the specified data path and ids path.
  BackendListProvided({required this.uri, this.mockMe = false});

  /// This method should be called after the user has logged on
  @override
  Future<void> initializeFetchingData({AuthProvider? authProvider}) async {
    if (isConnected) return;
    if (authProvider == null) {
      throw Exception('AuthProvider is required to initialize the connection');
    }
    _hasProblemConnecting = false;
    _connexionRefused = false;

    // Get the JWT token
    String? token;
    while (true) {
      token = await authProvider.getAuthenticatorIdToken();
      if (token != null) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // If the socket is already connected, it means another provider is already connected
    // Simply return now after having kept the reference to the deserializer function
    if (_socket == null && !mockMe) {
      try {
        // Send a connexion request to the server
        _socket = WebSocket(
          uri,
          headers: {HttpHeaders.contentTypeHeader: 'application/json'},
          timeout: const Duration(seconds: 5),
        );

        _socket!.connection.listen((event) {
          if (_socket == null) return;

          if (event is Connected || event is Reconnected) {
            _socket!.send(
              jsonEncode(
                CommunicationProtocol(
                  requestType: RequestType.handshake,
                  data: {'token': token},
                ).serialize(),
              ),
            );
          } else if (event is Disconnected) {
            _handshakeReceived = false;
            notifyListeners();
          }
        });
        _socket!.messages.listen((data) {
          final map = jsonDecode(data);
          final protocol = CommunicationProtocol.deserialize(map);

          if (!isConnected) {
            if (protocol.requestType == RequestType.response &&
                protocol.response == Response.connexionRefused) {
              _connexionRefused = true;
              disconnect();
              return;
            }
          }

          _incommingMessage(protocol, authProvider: authProvider);
        });

        final started = DateTime.now();
        while (!_handshakeReceived) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (_socket == null) {
            // If the socket is null, it means the connection failed
            dev.log('Connection to the server was canceled');
            return;
          }

          if (DateTime.now().isAfter(started.add(const Duration(seconds: 5)))) {
            if (!_hasProblemConnecting) {
              // Only notify once
              _hasProblemConnecting = true;
              dev.log('Handshake takes more time than expected');
              notifyListeners();
            }
          }
        }
      } catch (e) {
        dev.log(
          'Error while connecting to the server: $e',
          error: e,
          stackTrace: StackTrace.current,
        );
        disconnect();
      }
    }

    // Keep a reference to the deserializer function
    _providerSelector[getField()] = _Selector(
      addOrReplaceItems: _addOrReplaceIntoSelf,
      removeItem: _removeFromSelf,
      stopFetchingData: stopFetchingData,
      notify: notifyListeners,
    );
    _providerSelector[getField(true)] = _Selector(
      addOrReplaceItems: _addOrReplaceIntoSelf,
      removeItem: _removeFromSelf,
      stopFetchingData: stopFetchingData,
      notify: notifyListeners,
    );

    // Send a get request to the server for the list of items
    while (!_handshakeReceived) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_socket == null) return;
    }
    _getFromBackend(getField(true));
  }

  Future<void> disconnect() async {
    if (_socket != null) {
      _socket!.close();
      _socket = null;
      _socketId = null;
      _handshakeReceived = false;
    }

    for (final selectorKey in _providerSelector.keys.toList()) {
      await _providerSelector[selectorKey]?.stopFetchingData();
    }
  }

  @override
  Future<void> stopFetchingData() async {
    _providerSelector.remove(getField());
    _providerSelector.remove(getField(true));

    super.clear();
    notifyListeners();
  }

  final bool mockMe;

  bool isOfCorrectRequestFields(RequestFields field) =>
      field == getField(false) || field == getField(true);
  bool isNotOfCorrectRequestFields(RequestFields field) =>
      !isOfCorrectRequestFields(field);

  RequestFields getField([bool asList = false]);

  void _sanityChecks({required bool notify}) {
    assert(notify, 'Notify has no effect here and should not be used.');
    assert(isConnected, 'Please call \'initializeFetchingData\' at least once');
  }

  Future<CommunicationProtocol> sendMessageWithResponse({
    required CommunicationProtocol message,
  }) async {
    try {
      return await _sendMessageWithResponse(message: message);
    } on Exception {
      // Make sure to keep the list in sync with the database
      notifyListeners();
      rethrow;
    }
  }

  /// Adds an item to the Realtime Database.
  ///
  /// Note that [notify] has no effect here and should not be used.
  @override
  void add(T item, {bool notify = true}) {
    addWithConfirmation(item, notify: notify);
  }

  Future<bool> addWithConfirmation(T item, {bool notify = true}) async {
    _sanityChecks(notify: notify);

    try {
      final response = await sendMessageWithResponse(
        message: CommunicationProtocol(
          requestType: RequestType.post,
          field: getField(),
          data: item.serialize(),
        ),
      );

      if (mockMe) {
        super.add(item, notify: true);
      }
      return response.response == Response.success;
    } on Exception {
      // Make sure to keep the list in sync with the database
      notifyListeners();
      return false;
    }
  }

  ///
  /// Actually performs the add to the self list
  void _addOrReplaceIntoSelf(Map<String, dynamic> items, {bool notify = true}) {
    if (items.containsKey('id')) {
      // A single item was received
      if (contains(items['id'])) {
        super.replace(this[items['id']].copyWithData(items), notify: notify);
      } else {
        super.add(deserializeItem(items), notify: notify);
      }
    } else {
      // A map of items was received, callback the add function for each item
      for (final item in items.values) {
        _addOrReplaceIntoSelf(item, notify: false);
      }
    }
    if (notify) notifyListeners();
  }

  /// Inserts elements in a list of a logged user
  ///
  void insertInList(String pathToItem, ListSerializable<T> items) {
    try {
      for (final item in items) {
        add(item, notify: true);
      }
    } on Exception {
      // Make sure to keep the list in sync with the database
      notifyListeners();
    }
  }

  /// Replaces the current item by [item] in the Realtime Database.
  /// The item to replace is identified by its id.
  ///
  /// Note that [notify] has no effect here and should not be used.
  @override
  void replace(T item, {bool notify = true}) {
    replaceWithConfirmation(item, notify: notify);
  }

  Future<bool> replaceWithConfirmation(T item, {bool notify = true}) async {
    _sanityChecks(notify: notify);

    try {
      final response = await sendMessageWithResponse(
        message: CommunicationProtocol(
          requestType: RequestType.post,
          field: getField(),
          data: item.serialize(),
        ),
      );

      if (mockMe) {
        super.replace(item, notify: true);
      }
      return response.response == Response.success;
    } on Exception {
      // Make sure to keep the list in sync with the database
      notifyListeners();
      return false;
    }
  }

  /// You can't not use this function with [BackendListProvided] in case the ids of the provided values dont match.
  /// Use the function [replace] intead.
  @override
  operator []=(value, T item) {
    throw const ShouldNotCall(
      'You should not use this operator. Use the function replace instead.',
    );
  }

  /// Removes an item from the Realtime Database.
  ///
  /// Note that [notify] has no effect here and should not be used.
  @override
  void remove(value, {bool notify = true}) {
    removeWithConfirmation(value, notify: notify);
  }

  Future<bool> removeWithConfirmation(T item, {bool notify = true}) async {
    _sanityChecks(notify: notify);

    try {
      final response = await sendMessageWithResponse(
        message: CommunicationProtocol(
          requestType: RequestType.delete,
          field: getField(),
          data: item.serialize(),
        ),
      );

      if (mockMe) {
        super.remove(item, notify: true);
      }
      return response.response == Response.success;
    } on Exception {
      // Make sure to keep the list in sync with the database
      notifyListeners();
      return false;
    }
  }

  ///
  /// Actually performs the remove from the self list
  void _removeFromSelf(value, {bool notify = true}) {
    super.remove(value, notify: notify);
  }

  /// Removes all objects from this list and from the Realtime Database; the length of the list becomes zero.
  /// Setting [confirm] to true is required in order to call this function as a 'security' mesure.
  ///
  /// Note that [notify] has no effect here and should not be used.
  @override
  void clear({bool confirm = false, bool notify = true}) {
    _sanityChecks(notify: notify);
    if (!confirm) {
      throw const ShouldNotCall(
        'You almost cleared the entire database ! Set the parameter confirm to true if that was really your intention.',
      );
    }

    for (final item in this) {
      remove(item);
    }
  }
}

///
/// These resources are shared accross all the backend providers
/// Another way we could have done this would have been to allow for multiple
/// connections to the backend, dropping the communications which are related
/// to other providers.
WebSocket? _socket;
int? _socketId;
bool _handshakeReceived = false;
Map<RequestFields, _Selector> _providerSelector = {};
final _completers = <String, Completer<CommunicationProtocol>>{};

_Selector _getSelector(RequestFields field) {
  final selector = _providerSelector[field];
  if (selector == null) {
    throw Exception(
      'No selector found for field $field, please call initializeFetchingData()',
    );
  }
  return selector;
}

Future<void> _getFromBackend(
  RequestFields requestField, {
  String? id,
  List<String>? fields,
}) async {
  try {
    final protocol = await _sendMessageWithResponse(
      message: CommunicationProtocol(
        requestType: RequestType.get,
        field: requestField, // Id is not null for item of the list
        data: id == null ? null : {'id': id, 'fields': fields},
      ),
    );

    final selector = _getSelector(protocol.field!);
    selector.addOrReplaceItems(protocol.data!, notify: true);
  } catch (e) {
    dev.log('Error while getting data from the backend: $e');
  }
}

Future<void> _sendMessage({required CommunicationProtocol message}) async {
  final encodedMessage = jsonEncode(message.serialize());
  _socket?.send(encodedMessage);
}

Future<CommunicationProtocol> _sendMessageWithResponse({
  required CommunicationProtocol message,
}) async {
  _completers[message.id] = Completer<CommunicationProtocol>();
  _sendMessage(message: message);

  final answer = await _completers[message.id]!.future.timeout(
    const Duration(seconds: 5),
    onTimeout: () {
      _completers.remove(message.id);
      throw TimeoutException(
        'The request timed out after 5 seconds',
        Duration(seconds: 5),
      );
    },
  );
  if (answer.response == Response.failure) {
    throw Exception('Error while processing the request: ${answer.field}');
  }
  return answer;
}

Future<void> _incommingMessage(
  CommunicationProtocol protocol, {
  required AuthProvider authProvider,
}) async {
  try {
    // If we received an unsolicited message, it is probably due to previous
    // connexions that did not get closed properly. Just ignore the message
    if (protocol.socketId != null &&
        protocol.socketId != _socketId &&
        protocol.requestType != RequestType.handshake) {
      return;
    }

    // If no data are provided
    if (protocol.requestType != RequestType.handshake &&
        protocol.field == null) {
      return;
    }

    switch (protocol.requestType) {
      case RequestType.handshake:
        {
          authProvider.schoolBoardId = protocol.data!['school_board_id'] ?? '';
          authProvider.schoolId = protocol.data!['school_id'] ?? '';
          authProvider.teacherId = protocol.data!['user_id'] ?? '';
          authProvider.databaseAccessLevel = AccessLevel.fromSerialized(
            protocol.data!['access_level'],
          );

          _handshakeReceived = true;
          _socketId = protocol.socketId;
          for (final selector in _providerSelector.values) {
            selector.notify();
          }

          return;
        }
      case RequestType.response:
        {
          final completer = _completers.remove(protocol.id);
          if (completer != null && !completer.isCompleted) {
            completer.complete(protocol);
          }
          return;
        }
      case RequestType.update:
        {
          if (protocol.data == null) {
            throw Exception(
              'The data field cannot be null for the update request',
            );
          }

          final requestField = protocol.field!;
          _getFromBackend(
            requestField,
            id: protocol.data!['id'],
            fields: (protocol.data!['updated_fields'] as List?)?.cast<String>(),
          );
          return;
        }
      case RequestType.delete:
        {
          if (protocol.data == null) {
            throw Exception(
              'The data field cannot be null for the delete request',
            );
          }

          final requestField = protocol.field!;
          final selector = _getSelector(requestField);

          final deletedIds =
              (protocol.data!['deleted_ids'] as List).cast<String>();
          for (final id in deletedIds) {
            selector.removeItem(id, notify: false);
          }
          selector.notify();
          return;
        }
      case RequestType.get:
      case RequestType.post:
      case RequestType.registerUser:
      case RequestType.unregisterUser:
        throw Exception('Unsupported request type: ${protocol.requestType}');
    }
  } catch (e) {
    dev.log(e.toString(), error: e, stackTrace: StackTrace.current);
    return;
  }
}
