import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:movi/src/core/notifications/local_notification_gateway.dart';

const AndroidNotificationChannel _seriesNotificationChannel =
    AndroidNotificationChannel(
      'series_new_episodes',
      'Nouveaux épisodes',
      description: 'Alertes quand une série suivie reçoit un nouvel épisode.',
      importance: Importance.high,
    );

@pragma('vm:entry-point')
void moviNotificationTapBackground(NotificationResponse response) {
  FlutterLocalNotificationGateway().handleNotificationResponse(response);
}

class FlutterLocalNotificationGateway implements LocalNotificationGateway {
  factory FlutterLocalNotificationGateway() => _instance;

  FlutterLocalNotificationGateway._internal();

  static final FlutterLocalNotificationGateway _instance =
      FlutterLocalNotificationGateway._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<SeriesNotificationNavigationIntent> _intents =
      StreamController<SeriesNotificationNavigationIntent>.broadcast();
  final Dio _dio = Dio();

  bool _initialized = false;

  @override
  Stream<SeriesNotificationNavigationIntent> get navigationIntents =>
      _intents.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: moviNotificationTapBackground,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_seriesNotificationChannel);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchResponse != null) {
      handleNotificationResponse(launchResponse);
    }

    _initialized = true;
  }

  void handleNotificationResponse(NotificationResponse response) {
    final intent = SeriesNotificationNavigationIntent.fromPayload(
      response.payload,
    );
    if (intent == null) return;
    _intents.add(intent);
  }

  @override
  Future<bool> requestSeriesNotificationsPermissionIfNeeded() async {
    await initialize();
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }

    final alreadyEnabled = await areSeriesNotificationsEnabled();
    if (alreadyEnabled) return true;

    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    }

    final darwinPlugin =
        _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await darwinPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  @override
  Future<bool> areSeriesNotificationsEnabled() async {
    await initialize();
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false;
    }

    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }

    final darwinPlugin =
        _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final granted = await darwinPlugin?.checkPermissions();
    return granted?.isEnabled ?? false;
  }

  @override
  Future<void> showNewEpisodeNotification(
    NewEpisodeNotificationRequest request,
  ) async {
    await initialize();
    if (!await areSeriesNotificationsEnabled()) {
      return;
    }

    final attachmentPath = await _downloadAttachmentIfPossible(
      request.posterUri,
    );

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _seriesNotificationChannel.id,
        _seriesNotificationChannel.name,
        channelDescription: _seriesNotificationChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.recommendation,
        styleInformation: attachmentPath != null
            ? BigPictureStyleInformation(
                FilePathAndroidBitmap(attachmentPath),
                largeIcon: FilePathAndroidBitmap(attachmentPath),
                contentTitle: request.title,
                summaryText: request.body,
              )
            : BigTextStyleInformation(request.body),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: request.seriesTitle,
        attachments: attachmentPath != null
            ? <DarwinNotificationAttachment>[
                DarwinNotificationAttachment(attachmentPath),
              ]
            : null,
      ),
    );

    await _plugin.show(
      request.notificationId,
      request.title,
      request.body,
      notificationDetails,
      payload: request.toPayload(),
    );
  }

  Future<String?> _downloadAttachmentIfPossible(Uri? uri) async {
    if (uri == null) return null;
    if (!uri.hasScheme || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return null;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final digest = md5.convert(uri.toString().codeUnits).toString();
      final extension = _safeExtensionFromUri(uri);
      final filePath = p.join(
        tempDir.path,
        'movi_series_notification_$digest$extension',
      );
      final file = File(filePath);
      if (await file.exists()) {
        return file.path;
      }

      final response = await _dio.get<List<int>>(
        uri.toString(),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (error, stackTrace) {
      debugPrint(
        '[SeriesNotifications] attachment download failed: $error\n$stackTrace',
      );
      return null;
    }
  }

  String _safeExtensionFromUri(Uri uri) {
    final last = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    final extension = p.extension(last).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
      case '.png':
        return extension;
      default:
        return '.jpg';
    }
  }
}
