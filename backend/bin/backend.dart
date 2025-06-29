import 'dart:io';

import 'package:backend/repositories/admins_repository.dart';
import 'package:backend/repositories/enterprises_repository.dart';
import 'package:backend/repositories/internships_repository.dart';
import 'package:backend/repositories/school_boards_repository.dart';
import 'package:backend/repositories/students_repository.dart';
import 'package:backend/repositories/teachers_repository.dart';
import 'package:backend/server/connexions.dart';
import 'package:backend/server/database_manager.dart';
import 'package:backend/server/http_request_handler.dart';
import 'package:backend/utils/network_rate_limiter.dart';
import 'package:firebase_admin/firebase_admin.dart';
import 'package:firebase_admin/src/auth/credential.dart';
import 'package:logging/logging.dart';
import 'package:mysql1/mysql1.dart';

final _logger = Logger('BackendServer');

enum DatabaseBackend { mysql, mock }

void main() async {
  // Set up logging
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Connect to the authentication service
  Credentials.firebaseAdminCredentialPath;
  FirebaseAdmin.instance.initializeApp(
    AppOptions(
      credential:
          ServiceAccountCredential('backendFirebaseServiceAccountKey.json'),
    ),
  );
  // Get the Firebase API key from the environment variable
  final firebaseApiKey = Platform.environment['FIREBASE_WEB_API_KEY'];
  if (firebaseApiKey == null || firebaseApiKey.isEmpty) {
    _logger.severe('FIREBASE_WEB_API_KEY environment variable is not set.');
    exit(1);
  }

  // Set up the database backend
  final databaseBackend = DatabaseBackend.mysql;

  // Create an HTTP server listening on localhost:3456
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3456);
  _logger.info('Server running on http://localhost:3456');

  _logger.info('Using database backend: ${databaseBackend.name}');
  final connection = switch (databaseBackend) {
    DatabaseBackend.mock => null,
    DatabaseBackend.mysql => await MySqlConnection.connect(ConnectionSettings(
        host: 'localhost',
        port: 3306,
        user: 'devuser',
        password: 'devpassword',
        db: 'dev_db',
      ))
  };
  await Future.delayed(
      Duration(milliseconds: 100)); // Give a bit of time just in case
  final connexions = Connexions(
      firebaseApiKey: firebaseApiKey,
      database: DatabaseManager(
        connection: connection!,
        schoolBoardsDatabase: switch (databaseBackend) {
          DatabaseBackend.mysql =>
            MySqlSchoolBoardsRepository(connection: connection),
          DatabaseBackend.mock => SchoolBoardsRepositoryMock()
        },
        adminsDatabase: switch (databaseBackend) {
          DatabaseBackend.mysql =>
            MySqlAdminsRepository(connection: connection),
          DatabaseBackend.mock => AdminsRepositoryMock()
        },
        teachersDatabase: switch (databaseBackend) {
          DatabaseBackend.mysql =>
            MySqlTeachersRepository(connection: connection),
          DatabaseBackend.mock => TeachersRepositoryMock()
        },
        studentsDatabase: switch (databaseBackend) {
          DatabaseBackend.mysql =>
            MySqlStudentsRepository(connection: connection),
          DatabaseBackend.mock => StudentsRepositoryMock()
        },
        enterprisesDatabase: switch (databaseBackend) {
          DatabaseBackend.mysql =>
            MySqlEnterprisesRepository(connection: connection),
          DatabaseBackend.mock => EnterprisesRepositoryMock()
        },
        internshipsDatabase: switch (databaseBackend) {
          DatabaseBackend.mysql =>
            MySqlInternshipsRepository(connection: connection),
          DatabaseBackend.mock => InternshipsRepositoryMock()
        },
      ));

  _logger.info('Waiting for requests...');
  final requestHandler = HttpRequestHandler(connexions: connexions);
  final rateLimiter =
      NetworkRateLimiter(maxRequests: 50, duration: Duration(minutes: 1));
  await for (HttpRequest request in server) {
    requestHandler.answer(request, rateLimiter: rateLimiter);
  }

  if (databaseBackend == DatabaseBackend.mysql) {
    await connection.close();
  }
}
