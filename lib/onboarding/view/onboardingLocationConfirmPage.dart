import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:project_daon/common/widget/gradientButton.dart';
import 'package:project_daon/common/widget/greenBackButton.dart';
import 'package:project_daon/core/config/apiKeys.dart';
import 'package:project_daon/onboarding/api/kakaoLocalApi.dart';
import 'package:project_daon/onboarding/model/onboardingLocation.dart';
import 'package:project_daon/ui/colorStyles.dart';

class OnboardingLocationConfirmPage extends StatefulWidget {
  final String initialQuery;

  const OnboardingLocationConfirmPage({super.key, required this.initialQuery});

  @override
  State<OnboardingLocationConfirmPage> createState() =>
      _OnboardingLocationConfirmPageState();
}

class _OnboardingLocationConfirmPageState
    extends State<OnboardingLocationConfirmPage> {
  final KakaoLocalApi _kakaoLocalApi = KakaoLocalApi(
    restApiKey: AppKeys.kakaoRestApiKey,
  );

  late final TextEditingController _searchController;

  NaverMapController? _mapController;
  OnboardingLocation? _selectedLocation;

  bool _isLoading = false;
  bool _isVerifying = false;
  String? _message;

  static const NLatLng _defaultTarget = NLatLng(37.5666102, 126.9783881);

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(text: widget.initialQuery.trim());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery.trim().isEmpty) {
        _useCurrentLocation();
      } else {
        _searchByText();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchByText() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      await _useCurrentLocation();
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final result = await _kakaoLocalApi.search(query);

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _message = '검색 결과를 찾지 못했어요. 도로명 주소나 지번 주소로 다시 입력해주세요.';
        });
        return;
      }

      await _applySelectedLocation(result);
    } catch (e, stackTrace) {
      debugPrint('주소 검색 실패');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _message = _getSearchErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final position = await _determinePosition();

      final result = await _kakaoLocalApi.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _message = '현재 위치의 주소를 확인하지 못했어요. 주소를 직접 검색해주세요.';
        });
        return;
      }

      await _applySelectedLocation(result);
    } catch (e, stackTrace) {
      debugPrint('현재 위치 주소 변환 실패');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _message = _getSearchErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('위치 서비스가 꺼져 있어요. 기기 설정에서 위치 서비스를 켜주세요.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('현재 위치를 확인하려면 위치 권한이 필요해요.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부되어 있어요. 앱 설정에서 위치 권한을 허용해주세요.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _applySelectedLocation(OnboardingLocation location) async {
    if (!mounted) return;

    setState(() {
      _selectedLocation = location;
      _message = null;
      _searchController.text = location.displayAddress;
    });

    await _renderMapOverlays(location);
  }

  Future<void> _renderMapOverlays(OnboardingLocation location) async {
    final controller = _mapController;
    final latitude = location.latitude;
    final longitude = location.longitude;

    if (controller == null || latitude == null || longitude == null) return;

    final target = NLatLng(latitude, longitude);

    await controller.clearOverlays();

    final circle = NCircleOverlay(
      id: 'selected_area_circle',
      center: target,
      radius: 10000, // 10km 반경
      color: const Color(0x1A62C99C), // 투명도 낮춤(10%): 넓은 반경에서 지도가 가려지지 않도록
      outlineColor: const Color(0x9962C99C),
      outlineWidth: 2,
    );

    final marker = NMarker(
      id: 'selected_location_marker',
      position: target,
      caption: NOverlayCaption(
        text: location.dong.isEmpty ? '선택 위치' : location.dong,
      ),
    );

    await controller.addOverlay(circle);
    await controller.addOverlay(marker);

    // zoom 11: 10km 원이 지도 면적의 약 1/4을 차지하도록 축소
    await controller.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: target, zoom: 11),
    );
  }

  Future<void> _confirmLocation() async {
    if (_isVerifying) return;

    final location = _selectedLocation;
    if (location == null) return;

    if (location.latitude == null || location.longitude == null) {
      setState(() {
        _message = '선택한 장소의 좌표를 확인할 수 없어요. 다른 장소를 다시 검색해주세요.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _message = null;
    });

    try {
      final position = await _determinePosition();

      String currentAddress = '';
      try {
        final addressResult = await _kakaoLocalApi.reverseGeocode(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        currentAddress = addressResult?.displayAddress ?? '';
      } catch (_) {}

      if (!mounted) return;

      Navigator.pop(
        context,
        LocationConfirmResult(
          location: location,
          currentLatitude: position.latitude,
          currentLongitude: position.longitude,
          currentAddress: currentAddress,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = e is DioException
            ? _getSearchErrorMessage(e)
            : e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  String _getSearchErrorMessage(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final responseData = error.response?.data;

      debugPrint('========== Kakao Local API Error ==========');
      debugPrint('type: ${error.type}');
      debugPrint('statusCode: $statusCode');
      debugPrint('responseData: $responseData');
      debugPrint('message: ${error.message}');
      debugPrint('==========================================');

      if (statusCode == 401) {
        return '카카오 REST API Key가 없거나 잘못됐어요. REST API Key를 사용 중인지, --dart-define이 적용됐는지 확인해주세요.';
      }

      if (statusCode == 403) {
        return '카카오 API 접근이 거부됐어요. 카카오 개발자 콘솔의 앱 설정이나 API 사용 권한을 확인해주세요.';
      }

      if (statusCode == 429) {
        return '카카오 API 호출량이 초과됐어요. 잠시 후 다시 시도해주세요.';
      }

      if (statusCode == 400) {
        return '주소 검색 요청 형식이 잘못됐어요. 입력한 주소를 다시 확인해주세요.';
      }

      if (error.type == DioExceptionType.connectionError) {
        return '네트워크 연결에 실패했어요. 에뮬레이터 인터넷 연결과 AndroidManifest.xml의 INTERNET 권한을 확인해주세요.';
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return '카카오 주소 검색 서버 응답이 지연되고 있어요. 잠시 후 다시 시도해주세요.';
      }
    }

    debugPrint('Unknown address search error: $error');
    return '주소 검색 중 문제가 발생했어요. 잠시 후 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final mapHeight = MediaQuery.of(context).size.height * 0.58;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: mapHeight,
              child: Stack(
                children: [
                  NaverMap(
                    options: const NaverMapViewOptions(
                      initialCameraPosition: NCameraPosition(
                        target: _defaultTarget,
                        zoom: 14,
                      ),
                    ),
                    onMapReady: (controller) async {
                      _mapController = controller;

                      final location = _selectedLocation;
                      if (location != null) {
                        await _renderMapOverlays(location);
                      }
                    },
                  ),

                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _searchByText(),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '예) 연희동 132, 도산대로 33',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GreenBackButton(
                          text: '검색',
                          width: 70,
                          height: 48,
                          onPressed: _searchByText,
                        ),
                      ],
                    ),
                  ),

                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      elevation: 3,
                      child: IconButton(
                        icon: const Icon(Icons.my_location),
                        color: ColorStyles.main1,
                        onPressed: _useCurrentLocation,
                      ),
                    ),
                  ),

                  if (_isLoading)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x33000000),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedLocation == null
                          ? '주소를 검색하거나 현재 위치를 확인해주세요.'
                          : '현재 위치가 ‘${_selectedLocation!.dong}’으로 확인돼요',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedLocation == null
                          ? '검색 후 지도에서 위치를 확인하면 거주지 인증을 완료할 수 있어요.'
                          : _selectedLocation!.displayAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),

                    if (_message != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _message!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ],

                    const Spacer(),

                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              GradientButton(
                                text: _isVerifying ? '' : '거주지 인증하기',
                                onPressed:
                                    _selectedLocation == null || _isVerifying
                                    ? null
                                    : _confirmLocation,
                              ),

                              if (_isVerifying)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ColorStyles.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
