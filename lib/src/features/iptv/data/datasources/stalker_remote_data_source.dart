import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show HttpClient;
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:dio/io.dart' show IOHttpClientAdapter;
import 'package:movi/src/core/network/network_executor.dart';
import 'package:movi/src/features/iptv/domain/value_objects/stalker_endpoint.dart';
import 'package:movi/src/features/iptv/data/dtos/stalker_auth_dto.dart';
import 'package:movi/src/features/iptv/data/dtos/stalker_category_dto.dart';

class StalkerRemoteDataSource {
  StalkerRemoteDataSource(this._executor);

  final NetworkExecutor _executor;

  void _debugLog(String message) {
    assert(() {
      developer.log(message, name: 'StalkerRemoteDataSource');
      return true;
    }());
  }

  // Headers MAG box pour imiter un vrai boîtier
  // Correspond exactement au script Python qui fonctionne
  static const Map<String, String> _magBoxHeaders = {
    'User-Agent':
        'Mozilla/5.0 (QtEmbedded; U; Linux; C) AppleWebKit/533.3 (KHTML, like Gecko) MAG200 stbapp ver: 4 rev: 2721 Mobile Safari/533.3',
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept-Encoding': 'gzip, deflate',
    'X-Requested-With': 'XMLHttpRequest',
    'Connection': 'keep-alive',
  };

  // Génère un UUID pour le token initial du handshake
  String _generateInitialToken() {
    final random = Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // Génère un serial number aléatoire
  String _generateSerialNumber() {
    final random = Random();
    final bytes = List<int>.generate(6, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
  }

  // Génère un device ID aléatoire
  String _generateDeviceId() {
    final random = Random();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
  }

  // Génère un device ID2 aléatoire (pour get_profile)
  String _generateDeviceId2() {
    final random = Random();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
  }

  // Génère une signature aléatoire (pour get_profile)
  String _generateSignature() {
    final random = Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
  }

  // Construit l'URL Referer
  String _buildRefererUrl(StalkerEndpoint endpoint) {
    final port = endpoint.uri.hasPort ? ':${endpoint.uri.port}' : '';
    return '${endpoint.uri.scheme}://${endpoint.uri.host}$port/stalker_portal/c/';
  }

  // Construit l'URL du portal avec les paramètres
  Uri _buildPortalUrl(
    StalkerEndpoint endpoint,
    Map<String, String> params,
  ) {
    // Ajoute toujours JsHttpRequest=1-json si pas déjà présent
    if (!params.containsKey('JsHttpRequest')) {
      params['JsHttpRequest'] = '1-json';
    }

    return endpoint.buildUri(params);
  }

  // Effectue une requête avec les headers MAG box et cookies
  Future<Map<String, dynamic>> _makeRequest(
    StalkerEndpoint endpoint,
    Map<String, String> params, {
    String? token,
    String? macAddress,
  }) {
    // Ajoute le token si fourni
    if (token != null && !params.containsKey('token')) {
      params['token'] = token;
    }

    final uri = _buildPortalUrl(endpoint, params);
    final mac = macAddress ?? '';

    return _executor.run<dynamic, Map<String, dynamic>>(
      request: (client, cancelToken) {
        // Configure les headers MAG box
        // Désactive la vérification SSL pour Stalker Portal (beaucoup de serveurs utilisent
        // des certificats auto-signés ou HTTP au lieu de HTTPS)
        final options = Options(
          headers: {
            ..._magBoxHeaders,
            'Referer': _buildRefererUrl(endpoint),
            if (mac.isNotEmpty) 'Cookie': 'mac=$mac; stb_lang=en; timezone=Europe/Paris',
          },
          // Accepte les codes 200-499 comme le script Python (gère les erreurs dans le mapper)
          validateStatus: (status) => status != null && status >= 200 && status < 500,
          // Utilise ResponseType.json pour que Dio parse automatiquement le JSON
          responseType: ResponseType.json,
        );

        // Configure le client pour désactiver la vérification SSL si HTTPS
        if (uri.scheme == 'https') {
          final adapter = client.httpClientAdapter;
          if (adapter is IOHttpClientAdapter) {
            adapter.createHttpClient = () {
              final httpClient = HttpClient();
              httpClient.badCertificateCallback = (cert, host, port) => true;
              return httpClient;
            };
          }
        }

        return client.getUri<dynamic>(
          uri,
          options: options,
          cancelToken: cancelToken,
        );
      },
      mapper: (response) {
        // Gère les réponses null ou vides
        if (response.data == null) {
          return <String, dynamic>{};
        }

        final data = response.data;
        
        // Si c'est un Map, extraire l'objet "js" si présent (comme le script Python)
        if (data is Map<String, dynamic>) {
          // Stalker retourne souvent les données dans un objet "js"
          if (data.containsKey('js')) {
            final jsData = data['js'];
            if (jsData is Map<String, dynamic>) {
              return jsData;
            }
            if (jsData is String) {
              final trimmed = jsData.trim();
              if (trimmed.isNotEmpty) {
                return <String, dynamic>{'cmd': trimmed};
              }
            }
            if (jsData is List) {
              return <String, dynamic>{'data': jsData};
            }
          }
          return data;
        }

        if (data is String) {
          final trimmed = data.trim();
          if (trimmed.isEmpty) return <String, dynamic>{};
          try {
            final decoded = jsonDecode(trimmed);
            if (decoded is Map<String, dynamic>) {
              if (decoded.containsKey('js')) {
                final jsData = decoded['js'];
                if (jsData is Map<String, dynamic>) {
                  return jsData;
                }
                if (jsData is String) {
                  final jsTrimmed = jsData.trim();
                  if (jsTrimmed.isNotEmpty) {
                    return <String, dynamic>{'cmd': jsTrimmed};
                  }
                }
                if (jsData is List) {
                  return <String, dynamic>{'data': jsData};
                }
              }
              return decoded;
            }
            if (decoded is List) {
              return <String, dynamic>{'data': decoded};
            }
            if (decoded is String) {
              final decodedTrimmed = decoded.trim();
              if (decodedTrimmed.isNotEmpty) {
                return <String, dynamic>{'cmd': decodedTrimmed};
              }
            }
          } catch (_) {
            // fallback to raw cmd
          }
          return <String, dynamic>{'cmd': trimmed};
        }

        // Si ce n'est pas un Map, retourner un map vide
        return <String, dynamic>{};
      },
    );
  }

  /// Handshake initial pour obtenir le token
  Future<StalkerAuthDto> handshake({
    required StalkerEndpoint endpoint,
    required String macAddress,
    String? serialNumber,
    String? deviceId,
  }) {
    final initialToken = _generateInitialToken();
    final sn = serialNumber ?? _generateSerialNumber();
    final did = deviceId ?? _generateDeviceId();

    final params = {
      'type': 'stb',
      'action': 'handshake',
      'token': initialToken,
      'JsHttpRequest': '1-json',
      'sn': sn,
      'device_id': did,
    };

    return _executor.run<dynamic, StalkerAuthDto>(
      request: (client, cancelToken) {
        final uri = _buildPortalUrl(endpoint, params);
        
        // LOGS DE DÉBOGAGE
        _debugLog('\n🤝 [STALKER HANDSHAKE DEBUG]');
        _debugLog('   URL: $uri');
        _debugLog('   MAC: $macAddress');
        _debugLog('   Serial: $sn');
        _debugLog('   Device ID: $did');
        _debugLog('   Initial Token: $initialToken');
        _debugLog('   Scheme: ${uri.scheme}');
        
        final options = Options(
          headers: {
            ..._magBoxHeaders,
            'Referer': _buildRefererUrl(endpoint),
            'Cookie': 'mac=$macAddress; stb_lang=en; timezone=Europe/Paris',
          },
          // Accepte les codes 200-499 comme le script Python (gère les erreurs dans le mapper)
          validateStatus: (status) => status != null && status >= 200 && status < 500,
          // Utilise ResponseType.plain pour voir la réponse brute (pas de parsing auto)
          responseType: ResponseType.plain,
        );
        
        _debugLog('   Headers:');
        options.headers?.forEach((key, value) {
          _debugLog('     $key: $value');
        });

        // Configure le client pour désactiver la vérification SSL si HTTPS
        if (uri.scheme == 'https') {
          final adapter = client.httpClientAdapter;
          if (adapter is IOHttpClientAdapter) {
            adapter.createHttpClient = () {
              final httpClient = HttpClient();
              httpClient.badCertificateCallback = (cert, host, port) => true;
              return httpClient;
            };
          }
          _debugLog('   ⚠️  SSL verification disabled for HTTPS');
        }

        return client.getUri<dynamic>(
          uri,
          options: options,
          cancelToken: cancelToken,
        ).then((response) {
          // LOG DE LA RÉPONSE BRUTE
          _debugLog('   Status: ${response.statusCode}');
          _debugLog('   Data type: ${response.data.runtimeType}');
          _debugLog('   Raw response body: "${response.data}"');
          _debugLog('   Response length: ${response.data?.toString().length ?? 0} chars');
          
          // Parse manuellement le JSON depuis la string
          if (response.data == null || (response.data as String).trim().isEmpty) {
            _debugLog('   ⚠️  Response is null or empty');
            return Response<Map<String, dynamic>>(
              data: <String, dynamic>{},
              statusCode: response.statusCode,
              statusMessage: response.statusMessage,
              headers: response.headers,
              requestOptions: response.requestOptions,
              extra: response.extra,
              isRedirect: response.isRedirect,
              redirects: response.redirects,
            ) as Response<dynamic>;
          }
          
          // Parse le JSON manuellement
          try {
            final rawString = response.data as String;
            
            // Si le serveur renvoie "null" (la chaîne), c'est une erreur d'auth
            if (rawString.trim().toLowerCase() == 'null') {
              _debugLog(
                '   ⚠️  Server returned literal "null" string - MAC not authorized',
              );
              return Response<Map<String, dynamic>>(
                data: <String, dynamic>{},
                statusCode: response.statusCode,
                statusMessage: response.statusMessage,
                headers: response.headers,
                requestOptions: response.requestOptions,
                extra: response.extra,
                isRedirect: response.isRedirect,
                redirects: response.redirects,
              ) as Response<dynamic>;
            }
            
            final decoded = jsonDecode(rawString);
            
            // Si c'est null (JSON null, pas la string "null")
            if (decoded == null) {
              _debugLog('   ⚠️  JSON decoded to null');
              return Response<Map<String, dynamic>>(
                data: <String, dynamic>{},
                statusCode: response.statusCode,
                statusMessage: response.statusMessage,
                headers: response.headers,
                requestOptions: response.requestOptions,
                extra: response.extra,
                isRedirect: response.isRedirect,
                redirects: response.redirects,
              ) as Response<dynamic>;
            }
            
            // Doit être un Map
            if (decoded is! Map<String, dynamic>) {
              _debugLog('   ❌ JSON is not a Map: ${decoded.runtimeType}');
              return Response<Map<String, dynamic>>(
                data: <String, dynamic>{},
                statusCode: response.statusCode,
                statusMessage: response.statusMessage,
                headers: response.headers,
                requestOptions: response.requestOptions,
                extra: response.extra,
                isRedirect: response.isRedirect,
                redirects: response.redirects,
              ) as Response<dynamic>;
            }
            
            // decoded is Map<String, dynamic> est garanti par le check ci-dessus
            final jsonData = decoded;
            _debugLog('   ✅ JSON parsed successfully: ${jsonData.keys.toList()}');
            return Response<Map<String, dynamic>>(
              data: jsonData,
              statusCode: response.statusCode,
              statusMessage: response.statusMessage,
              headers: response.headers,
              requestOptions: response.requestOptions,
              extra: response.extra,
              isRedirect: response.isRedirect,
              redirects: response.redirects,
            ) as Response<dynamic>;
          } catch (e) {
            _debugLog('   ❌ JSON parse error: $e');
            return Response<Map<String, dynamic>>(
              data: <String, dynamic>{},
              statusCode: response.statusCode,
              statusMessage: response.statusMessage,
              headers: response.headers,
              requestOptions: response.requestOptions,
              extra: response.extra,
              isRedirect: response.isRedirect,
              redirects: response.redirects,
            ) as Response<dynamic>;
          }
        });
      },
      mapper: (response) {
        // Gère les réponses null gracieusement (comme le script Python)
        // Si data est un Map vide {}, c'est qu'on a transformé null
        final rawData = response.data;
        
        _debugLog('   [MAPPER] rawData type: ${rawData.runtimeType}');
        _debugLog('   [MAPPER] rawData: $rawData');
        
        if (rawData == null || 
            (rawData is Map<String, dynamic> && rawData.isEmpty)) {
          // Réponse null = erreur d'authentification
          _debugLog('   ❌ Null or empty response - auth failed');
          return StalkerAuthDto(
            token: '',
            isAuthorized: false,
            message: 'Le serveur a retourné "null" - Causes possibles:\n'
                '• MAC address non reconnue (vérifiez: 00:54:10:FE:53:A1)\n'
                '• Abonnement expiré ou inactif\n'
                '• MAC déjà utilisée dans une autre session\n'
                '• Serveur ne supporte pas cette version de l\'API',
          );
        }

        // Vérifie le status code pour les erreurs HTTP
        if (response.statusCode != null && response.statusCode! >= 400) {
          _debugLog('   ❌ HTTP error: ${response.statusCode}');
          return StalkerAuthDto(
            token: '',
            isAuthorized: false,
            message: 'Erreur HTTP ${response.statusCode} lors du handshake',
          );
        }

        // Extraire l'objet "js" si présent (comme le script Python)
        final data = (rawData is Map<String, dynamic> && rawData.containsKey('js'))
            ? rawData['js'] as Map<String, dynamic>
            : (rawData is Map<String, dynamic> ? rawData : <String, dynamic>{});
        
        _debugLog('   [MAPPER] Extracted data: $data');
        
        final result = StalkerAuthDto.fromHandshakeJson(data);
        _debugLog('   ✅ Token obtained: ${result.token}');
        _debugLog('   isAuthorized: ${result.isAuthorized}');
        
        return result;
      },
    );
  }

  /// Récupère le profil utilisateur
  Future<StalkerAuthDto> getProfile({
    required StalkerEndpoint endpoint,
    required String token,
    required String macAddress,
    String? serialNumber,
    String? deviceId,
  }) {
    final sn = serialNumber ?? _generateSerialNumber();
    final did = deviceId ?? _generateDeviceId();
    final did2 = _generateDeviceId2();
    final signature = _generateSignature();

    final params = {
      'type': 'stb',
      'action': 'get_profile',
      'hd': '1',
      'ver': 'ImageDescription: 0.2.18-r14-pub-250; ImageDate: Fri Jan 15 15:20:44 EET 2016; PORTAL version: 5.6.0; API Version: JS API version: 328; STB API version: 134; Player Engine version: 0x566',
      'num_banks': '2',
      'sn': sn,
      'stb_type': 'MAG250',
      'client_type': 'STB',
      'image_version': '218',
      'video_out': 'hdmi',
      'device_id': did,
      'device_id2': did2,
      'signature': signature,
      'auth_second_step': '1',
      'hw_version': '1.7-BD-00',
      'not_valid_token': '0',
      'metrics': jsonEncode({
        'mac': macAddress,
        'sn': sn,
        'model': 'MAG250',
        'type': 'STB',
        'uid': '',
        'random': '',
      }),
    };

    return _executor.run<dynamic, StalkerAuthDto>(
      request: (client, cancelToken) {
        final uri = _buildPortalUrl(endpoint, {...params, 'token': token});
        
        // LOGS DE DÉBOGAGE
        _debugLog('\n👤 [STALKER GET_PROFILE DEBUG]');
        _debugLog(
          '   URL: ${uri.toString().substring(0, uri.toString().length > 200 ? 200 : uri.toString().length)}...',
        );
        _debugLog('   MAC: $macAddress');
        _debugLog('   Token: $token');
        _debugLog('   Serial: $sn');
        _debugLog('   Device ID: $did');
        _debugLog('   Device ID2: $did2');
        _debugLog('   Signature: $signature');
        
        final options = Options(
          headers: {
            ..._magBoxHeaders,
            'Referer': _buildRefererUrl(endpoint),
            'Cookie': 'mac=$macAddress; stb_lang=en; timezone=Europe/Paris',
          },
          // Accepte les codes 200-499 comme le script Python (gère les erreurs dans le mapper)
          validateStatus: (status) => status != null && status >= 200 && status < 500,
          // Utilise ResponseType.json pour que Dio parse automatiquement le JSON
          responseType: ResponseType.json,
        );

        // Configure le client pour désactiver la vérification SSL si HTTPS
        if (uri.scheme == 'https') {
          final adapter = client.httpClientAdapter;
          if (adapter is IOHttpClientAdapter) {
            adapter.createHttpClient = () {
              final httpClient = HttpClient();
              httpClient.badCertificateCallback = (cert, host, port) => true;
              return httpClient;
            };
          }
          _debugLog('   ⚠️  SSL verification disabled for HTTPS');
        }

        return client.getUri<dynamic>(
          uri,
          options: options,
          cancelToken: cancelToken,
        ).then((response) {
          // LOG DE LA RÉPONSE
          _debugLog('   Status: ${response.statusCode}');
          _debugLog('   Data type: ${response.data.runtimeType}');
          final dataStr = response.data.toString();
          _debugLog(
            '   Data preview: ${dataStr.substring(0, dataStr.length > 300 ? 300 : dataStr.length)}...',
          );
          
          // Transforme les réponses null en {} pour éviter EmptyResponseFailure
          // Le serveur peut retourner "null" (JSON null) qui est parsé comme null Dart
          if (response.data == null) {
            _debugLog('   ⚠️  Response data is null, transforming to empty map');
            return Response<Map<String, dynamic>>(
              data: <String, dynamic>{},
              statusCode: response.statusCode,
              statusMessage: response.statusMessage,
              headers: response.headers,
              requestOptions: response.requestOptions,
              extra: response.extra,
              isRedirect: response.isRedirect,
              redirects: response.redirects,
            ) as Response<dynamic>;
          }
          return response;
        });
      },
      mapper: (response) {
        // Gère les réponses null gracieusement (comme le script Python)
        // Si data est un Map vide {}, c'est qu'on a transformé null
        final rawData = response.data;
        
        _debugLog('   [MAPPER] rawData type: ${rawData.runtimeType}');
        
        if (rawData == null || 
            (rawData is Map<String, dynamic> && rawData.isEmpty)) {
          // Réponse null = erreur d'authentification
          _debugLog('   ❌ Null or empty response');
          return StalkerAuthDto(
            token: '',
            isAuthorized: false,
            message: 'Le serveur a retourné null - vérifiez que le token est valide et que l\'abonnement est actif',
          );
        }

        // Vérifie le status code pour les erreurs HTTP
        if (response.statusCode != null && response.statusCode! >= 400) {
          _debugLog('   ❌ HTTP error: ${response.statusCode}');
          return StalkerAuthDto(
            token: '',
            isAuthorized: false,
            message: 'Erreur HTTP ${response.statusCode} lors de la récupération du profil',
          );
        }

        // Extraire l'objet "js" si présent (comme le script Python)
        final data = (rawData is Map<String, dynamic> && rawData.containsKey('js'))
            ? rawData['js'] as Map<String, dynamic>
            : (rawData is Map<String, dynamic> ? rawData : <String, dynamic>{});
        
        _debugLog('   [MAPPER] Extracted data has keys: ${data.keys.toList()}');
        
        final result = StalkerAuthDto.fromProfileJson(data);
        _debugLog('   ✅ Profile received, authorized: ${result.isAuthorized}');
        
        return result;
      },
    );
  }

  /// Récupère les catégories VOD
  Future<List<StalkerCategoryDto>> getVodCategories({
    required StalkerEndpoint endpoint,
    required String token,
    String? macAddress,
  }) {
    final params = {
      'type': 'vod',
      'action': 'get_categories',
    };

    return _executor.run<dynamic, List<StalkerCategoryDto>>(
      request: (client, cancelToken) {
        final uri = _buildPortalUrl(endpoint, {...params, 'token': token});
        final headers = <String, String>{
          ..._magBoxHeaders,
          'Referer': _buildRefererUrl(endpoint),
        };
        final mac = macAddress ?? '';
        if (mac.isNotEmpty) {
          headers['Cookie'] = 'mac=$mac; stb_lang=en; timezone=Europe/Paris';
        }
        final options = Options(
          headers: headers,
          // Accepte les codes 200-499 comme le script Python (gère les erreurs dans le mapper)
          validateStatus: (status) => status != null && status >= 200 && status < 500,
          // Utilise ResponseType.json pour que Dio parse automatiquement le JSON
          responseType: ResponseType.json,
        );

        // Configure le client pour désactiver la vérification SSL si HTTPS
        if (uri.scheme == 'https') {
          final adapter = client.httpClientAdapter;
          if (adapter is IOHttpClientAdapter) {
            adapter.createHttpClient = () {
              final httpClient = HttpClient();
              httpClient.badCertificateCallback = (cert, host, port) => true;
              return httpClient;
            };
          }
        }

        return client.getUri<dynamic>(
          uri,
          options: options,
          cancelToken: cancelToken,
        );
      },
      mapper: (response) {
        final data = response.data;
        List<dynamic> list;
        
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic>) {
          // Peut être dans un objet "js" ou directement dans "data"
          list = data['js'] is List
              ? data['js'] as List<dynamic>
              : (data['data'] is List ? data['data'] as List<dynamic> : []);
        } else {
          list = [];
        }

        return list
            .whereType<Map<String, dynamic>>()
            .map((json) => StalkerCategoryDto.fromJson(json))
            .toList(growable: false);
      },
    );
  }

  /// Récupère les catégories de séries
  Future<List<StalkerCategoryDto>> getSeriesCategories({
    required StalkerEndpoint endpoint,
    required String token,
    String? macAddress,
  }) {
    final params = {
      'type': 'series',
      'action': 'get_categories',
    };

    return _executor.run<dynamic, List<StalkerCategoryDto>>(
      request: (client, cancelToken) {
        final uri = _buildPortalUrl(endpoint, {...params, 'token': token});
        final headers = <String, String>{
          ..._magBoxHeaders,
          'Referer': _buildRefererUrl(endpoint),
        };
        final mac = macAddress ?? '';
        if (mac.isNotEmpty) {
          headers['Cookie'] = 'mac=$mac; stb_lang=en; timezone=Europe/Paris';
        }
        final options = Options(
          headers: headers,
          // Accepte les codes 200-499 comme le script Python (gère les erreurs dans le mapper)
          validateStatus: (status) => status != null && status >= 200 && status < 500,
          // Utilise ResponseType.json pour que Dio parse automatiquement le JSON
          responseType: ResponseType.json,
        );

        // Configure le client pour désactiver la vérification SSL si HTTPS
        if (uri.scheme == 'https') {
          final adapter = client.httpClientAdapter;
          if (adapter is IOHttpClientAdapter) {
            adapter.createHttpClient = () {
              final httpClient = HttpClient();
              httpClient.badCertificateCallback = (cert, host, port) => true;
              return httpClient;
            };
          }
        }

        return client.getUri<dynamic>(
          uri,
          options: options,
          cancelToken: cancelToken,
        );
      },
      mapper: (response) {
        final data = response.data;
        List<dynamic> list;
        
        if (data is List) {
          list = data;
        } else if (data is Map<String, dynamic>) {
          // Peut être dans un objet "js" ou directement dans "data"
          list = data['js'] is List
              ? data['js'] as List<dynamic>
              : (data['data'] is List ? data['data'] as List<dynamic> : []);
        } else {
          list = [];
        }

        return list
            .whereType<Map<String, dynamic>>()
            .map((json) => StalkerCategoryDto.fromJson(json))
            .toList(growable: false);
      },
    );
  }

  /// Récupère le contenu VOD (utilise get_ordered_list comme validé par le script Python)
  Future<Map<String, dynamic>> getVodContent({
    required StalkerEndpoint endpoint,
    required String token,
    String? categoryId,
    int page = 1,
    int perPage = 20,
    String? macAddress,
  }) {
    final params = {
      'type': 'vod',
      'action': 'get_ordered_list',
      'p': page.toString(),
      'per_page': perPage.toString(),
      'sortby': 'added',
      'fav': '0',
      'is_fav': '0',
      'hd': '1',
    };

    if (categoryId != null) {
      params['genre'] = categoryId;
      params['category'] = categoryId;
    }

    return _makeRequest(endpoint, params, token: token, macAddress: macAddress);
  }

  /// Récupère le contenu de séries (utilise get_ordered_list)
  Future<Map<String, dynamic>> getSeriesContent({
    required StalkerEndpoint endpoint,
    required String token,
    String? categoryId,
    int page = 1,
    int perPage = 20,
    String? macAddress,
  }) {
    final params = {
      'type': 'series',
      'action': 'get_ordered_list', // 🔧 FIX: get_content ne retourne rien, get_ordered_list fonctionne
      'p': page.toString(),
      'per_page': perPage.toString(),
      'sortby': 'added',
      'fav': '0',
      'is_fav': '0',
      'hd': '1',
    };

    if (categoryId != null) {
      params['genre'] = categoryId;
      params['category'] = categoryId;
    }

    return _makeRequest(endpoint, params, token: token, macAddress: macAddress);
  }

  Future<Map<String, dynamic>> createVodStreamLink({
    required StalkerEndpoint endpoint,
    required String token,
    required String contentId,
    String? macAddress,
  }) {
    final params = {
      'type': 'vod',
      'action': 'create_link',
      'id': contentId,
    };

    return _makeRequest(endpoint, params, token: token, macAddress: macAddress);
  }

  Future<Map<String, dynamic>> getVodStreamLink({
    required StalkerEndpoint endpoint,
    required String token,
    required String contentId,
    String? macAddress,
  }) {
    final params = {
      'type': 'vod',
      'action': 'get_url',
      'id': contentId,
    };

    return _makeRequest(endpoint, params, token: token, macAddress: macAddress);
  }

  Future<Map<String, dynamic>> createSeriesStreamLink({
    required StalkerEndpoint endpoint,
    required String token,
    required String seriesId,
    int? seasonNumber,
    int? episodeNumber,
    String? macAddress,
  }) {
    final params = {
      'type': 'series',
      'action': 'create_link',
      'id': seriesId,
      'series_id': seriesId,
    };
    if (seasonNumber != null) {
      params['season'] = seasonNumber.toString();
    }
    if (episodeNumber != null) {
      params['episode'] = episodeNumber.toString();
    }

    return _makeRequest(endpoint, params, token: token, macAddress: macAddress);
  }

  Future<Map<String, dynamic>> getSeriesStreamLink({
    required StalkerEndpoint endpoint,
    required String token,
    required String seriesId,
    int? seasonNumber,
    int? episodeNumber,
    String? macAddress,
  }) {
    final params = {
      'type': 'series',
      'action': 'get_url',
      'id': seriesId,
      'series_id': seriesId,
    };
    if (seasonNumber != null) {
      params['season'] = seasonNumber.toString();
    }
    if (episodeNumber != null) {
      params['episode'] = episodeNumber.toString();
    }

    return _makeRequest(endpoint, params, token: token, macAddress: macAddress);
  }
}

/// Classe helper pour les requêtes Stalker
class StalkerAccountRequest {
  StalkerAccountRequest({
    required this.endpoint,
    required this.token,
    required this.macAddress,
  });

  final StalkerEndpoint endpoint;
  final String token;
  final String macAddress;
}

