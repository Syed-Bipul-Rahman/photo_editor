import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LoggerHelper {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  static bool _isProduction = false;

  static void setEnvironment(bool isProduction) {
    _isProduction = isProduction;
  }

  static void debug( message) {
    if (!_isProduction) {
      _logger.d(message);
    }
  }

  static void info( message) {
    if (!_isProduction) {
      _logger.i(message);
    }
  }

  static void warn( message) {
    _logger.w(message);
  }

  static void error( message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // Write logs to a file (optional)
  static Future<void> writeToFile(String message) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/app_logs.txt');
      final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final logMessage = '$now - $message\n';
      await file.writeAsString(logMessage, mode: FileMode.append);
    } catch (e) {
      _logger.e('Failed to write log to file', error: e);
    }
  }
}
