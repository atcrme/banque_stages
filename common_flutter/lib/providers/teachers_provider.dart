import 'package:common/communication_protocol.dart';
import 'package:common/models/persons/teacher.dart';
import 'package:common_flutter/providers/auth_provider.dart';
import 'package:common_flutter/providers/backend_list_provided.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TeachersProvider extends BackendListProvided<Teacher> {
  TeachersProvider({required super.uri, super.mockMe});

  static TeachersProvider of(BuildContext context, {listen = false}) =>
      Provider.of<TeachersProvider>(context, listen: listen);

  @override
  RequestFields getField([bool asList = false]) =>
      asList ? RequestFields.teachers : RequestFields.teacher;

  @override
  Teacher deserializeItem(data) {
    return Teacher.fromSerialized(data);
  }

  Teacher? get myTeacher =>
      _authProvider!.teacherId == null || !hasId(_authProvider!.teacherId!)
          ? null
          : this[_authProvider!.teacherId];

  AuthProvider? _authProvider;
  void initializeAuth(AuthProvider auth) {
    _authProvider = auth;
    initializeFetchingData(authProvider: auth);
    auth.addListener(() => initializeFetchingData(authProvider: auth));
  }
}
