import 'package:dio/dio.dart';
import 'package:project_daon/onboarding/model/onboardingLocation.dart';

class KakaoLocalApi {
  KakaoLocalApi({required String restApiKey})
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'https://dapi.kakao.com',
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: {'Authorization': 'KakaoAK $restApiKey'},
        ),
      );

  final Dio _dio;

  Future<OnboardingLocation?> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return null;

    final addressResult = await _searchByAddress(trimmedQuery);
    if (addressResult != null) return addressResult;

    return _searchByKeyword(trimmedQuery);
  }

  Future<OnboardingLocation?> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final addressResponse = await _dio.get<Map<String, dynamic>>(
      '/v2/local/geo/coord2address.json',
      queryParameters: {'x': longitude, 'y': latitude, 'input_coord': 'WGS84'},
    );

    final documents = _documents(addressResponse.data);
    final addressDoc = documents.isNotEmpty
        ? _asMap(documents.first) ?? <String, dynamic>{}
        : <String, dynamic>{};

    final region = await _fetchRegionCode(
      latitude: latitude,
      longitude: longitude,
    );

    if (addressDoc.isEmpty && region == null) {
      return null;
    }

    return _buildLocation(
      latitude: latitude,
      longitude: longitude,
      addressMap: _asMap(addressDoc['address']),
      roadAddressMap: _asMap(addressDoc['road_address']),
      regionMap: region,
    );
  }

  Future<OnboardingLocation?> _searchByAddress(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v2/local/search/address.json',
      queryParameters: {'query': query, 'size': 1},
    );

    final documents = _documents(response.data);
    if (documents.isEmpty) return null;

    final doc = _asMap(documents.first);
    if (doc == null) return null;

    final longitude = _toDouble(doc['x']);
    final latitude = _toDouble(doc['y']);

    if (latitude == null || longitude == null) return null;

    final region = await _fetchRegionCode(
      latitude: latitude,
      longitude: longitude,
    );

    return _buildLocation(
      latitude: latitude,
      longitude: longitude,
      addressMap: _asMap(doc['address']),
      roadAddressMap: _asMap(doc['road_address']),
      regionMap: region,
      fallbackAddress: _text(doc['address_name']),
    );
  }

  Future<OnboardingLocation?> _searchByKeyword(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v2/local/search/keyword.json',
      queryParameters: {'query': query, 'size': 1},
    );

    final documents = _documents(response.data);
    if (documents.isEmpty) return null;

    final doc = _asMap(documents.first);
    if (doc == null) return null;

    final longitude = _toDouble(doc['x']);
    final latitude = _toDouble(doc['y']);

    if (latitude == null || longitude == null) return null;

    final region = await _fetchRegionCode(
      latitude: latitude,
      longitude: longitude,
    );

    final roadAddress = _text(doc['road_address_name']);
    final jibunAddress = _text(doc['address_name']);

    return _buildLocation(
      latitude: latitude,
      longitude: longitude,
      roadAddressText: roadAddress,
      jibunAddressText: jibunAddress,
      regionMap: region,
      fallbackAddress: roadAddress.isNotEmpty ? roadAddress : jibunAddress,
      placeName: _text(doc['place_name']),
    );
  }

  Future<Map<String, dynamic>?> _fetchRegionCode({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v2/local/geo/coord2regioncode.json',
      queryParameters: {'x': longitude, 'y': latitude},
    );

    final documents = _documents(response.data);
    if (documents.isEmpty) return null;

    Map<String, dynamic>? fallback;

    for (final raw in documents) {
      final map = _asMap(raw);
      if (map == null) continue;

      fallback ??= map;

      // 행정동 우선 사용
      if (map['region_type'] == 'H') {
        return map;
      }
    }

    return fallback;
  }

  OnboardingLocation _buildLocation({
    required double latitude,
    required double longitude,
    Map<String, dynamic>? addressMap,
    Map<String, dynamic>? roadAddressMap,
    Map<String, dynamic>? regionMap,
    String fallbackAddress = '',
    String roadAddressText = '',
    String jibunAddressText = '',
    String? placeName,
  }) {
    final roadAddress = _firstNonEmpty([
      roadAddressText,
      _read(roadAddressMap, 'address_name'),
    ]);

    final jibunAddress = _firstNonEmpty([
      jibunAddressText,
      _read(addressMap, 'address_name'),
    ]);

    final address = _firstNonEmpty([
      roadAddress,
      jibunAddress,
      fallbackAddress,
      _read(regionMap, 'address_name'),
    ]);

    final sido = _firstNonEmpty([
      _read(regionMap, 'region_1depth_name'),
      _read(addressMap, 'region_1depth_name'),
      _read(roadAddressMap, 'region_1depth_name'),
    ]);

    final sigungu = _firstNonEmpty([
      _read(regionMap, 'region_2depth_name'),
      _read(addressMap, 'region_2depth_name'),
      _read(roadAddressMap, 'region_2depth_name'),
    ]);

    final dong = _firstNonEmpty([
      _read(regionMap, 'region_3depth_name'),
      _read(addressMap, 'region_3depth_h_name'),
      _read(addressMap, 'region_3depth_name'),
      _read(roadAddressMap, 'region_3depth_name'),
    ]);

    final legalDong = _firstNonEmpty([
      _read(addressMap, 'region_3depth_name'),
      _read(roadAddressMap, 'region_3depth_name'),
    ]);

    return OnboardingLocation(
      address: address,
      roadAddress: roadAddress,
      jibunAddress: jibunAddress,
      sido: sido,
      sigungu: sigungu,
      dong: dong,
      legalDong: legalDong.isEmpty ? null : legalDong,
      administrativeCode: _read(regionMap, 'code').isEmpty
          ? null
          : _read(regionMap, 'code'),
      latitude: latitude,
      longitude: longitude,
      placeName: placeName?.isEmpty == true ? null : placeName,
      isVerified: true,
    );
  }

  List<dynamic> _documents(Map<String, dynamic>? data) {
    final documents = data?['documents'];
    if (documents is List) return documents;
    return const [];
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  String _read(Map<String, dynamic>? map, String key) {
    return _text(map?[key]);
  }

  String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  double? _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '');
  }
}
