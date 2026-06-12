import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_daon/common/widget/DetailAppBar.dart';
import 'package:project_daon/common/widget/gradientButton.dart';
import 'package:project_daon/common/widget/textFieldWidget.dart';
import 'package:project_daon/mypage/api/mypageApi.dart';
import 'package:project_daon/mypage/model/userModel.dart';
import 'package:project_daon/onboarding/model/onboardingLocation.dart';
import 'package:project_daon/onboarding/view/onboardingLocationConfirmPage.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class ProfileEditPage extends StatefulWidget {
  final UserProfile profile;

  const ProfileEditPage({super.key, required this.profile});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nicknameController;

  String? _profileImageUrl;
  String? _newAddressName;
  bool _isReverified = false;
  bool _isSaving = false;
  bool _isReverifying = false;
  bool _isImageUploading = false;

  final MypageApi _mypageApi = MypageApi();

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(
      text: widget.profile.nickname ?? '',
    );
    _profileImageUrl = widget.profile.profileImage;
    _newAddressName = widget.profile.addressName;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  String _getImageContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        throw Exception('지원하지 않는 이미지 형식입니다.');
    }
  }

  String _getFileExtension(String path) {
    final fileName = path.split('/').last.split('\\').last;
    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      throw Exception('이미지 파일 확장자를 확인할 수 없습니다.');
    }

    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  Future<void> _handleImagePick() async {
    if (_isImageUploading) return;

    final picker = ImagePicker();
    XFile? picked;

    try {
      picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
    } catch (e) {
      _showSnackBar('이미지를 선택하는 중 오류가 발생했습니다.');
      return;
    }

    if (picked == null) return;

    late final String ext;
    late final String contentType;

    try {
      ext = _getFileExtension(picked.path);

      if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
        _showSnackBar('jpg, jpeg, png, webp 형식의 이미지만 업로드할 수 있습니다.');
        return;
      }

      contentType = _getImageContentType(ext);
    } catch (e) {
      _showSnackBar(_cleanError(e));
      return;
    }

    final file = File(picked.path);

    if (!await file.exists()) {
      _showSnackBar('선택한 이미지 파일을 찾을 수 없습니다.');
      return;
    }

    final fileSize = await file.length();

    if (fileSize > 10 * 1024 * 1024) {
      _showSnackBar('이미지 파일 크기는 10MB 이하여야 합니다.');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      _showSnackBar('Firebase 로그인 정보가 없어 이미지를 업로드할 수 없습니다.');
      return;
    }

    setState(() => _isImageUploading = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = 'users/$uid/profile/profile_$timestamp.$ext';

      if (kDebugMode) {
        debugPrint('[프로필 이미지] Firebase UID: $uid');
        debugPrint(
          '[프로필 이미지] storageBucket: ${FirebaseStorage.instance.bucket}',
        );
        debugPrint('[프로필 이미지] 업로드 경로: $storagePath');
        debugPrint('[프로필 이미지] 파일 크기: ${fileSize}bytes');
        debugPrint('[프로필 이미지] content type: $contentType');
      }

      final ref = FirebaseStorage.instance.ref().child(storagePath);

      final snapshot = await ref.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        debugPrint('[프로필 이미지] 다운로드 URL: $downloadUrl');
      }

      final savedUrl = await _mypageApi.uploadProfileImageUrl(downloadUrl);

      if (!mounted) return;

      setState(() => _profileImageUrl = savedUrl);
      _showSnackBar('프로필 이미지가 변경되었습니다.');
    } on FirebaseException catch (e) {
      if (!mounted) return;

      if (kDebugMode) {
        debugPrint('[프로필 이미지] Firebase 오류: ${e.code} ${e.message}');
      }

      switch (e.code) {
        case 'unauthorized':
          _showSnackBar(
            'Firebase Storage 업로드 권한이 없습니다. Storage Rules 또는 App Check 설정을 확인해 주세요.',
          );
          break;
        case 'unauthenticated':
          _showSnackBar('Firebase 로그인이 필요합니다. 다시 로그인해 주세요.');
          break;
        case 'object-not-found':
          _showSnackBar('Firebase Storage 경로를 찾을 수 없습니다.');
          break;
        case 'bucket-not-found':
        case 'no-default-bucket':
          _showSnackBar('Firebase Storage bucket 설정을 확인해 주세요.');
          break;
        case 'canceled':
          _showSnackBar('이미지 업로드가 취소되었습니다.');
          break;
        default:
          _showSnackBar('이미지 업로드에 실패했습니다. 다시 시도해 주세요.');
      }
    } catch (e) {
      if (!mounted) return;

      if (kDebugMode) {
        debugPrint('[프로필 이미지 업로드 실패] $e');
      }

      _showSnackBar(_cleanError(e));
    } finally {
      if (mounted) {
        setState(() => _isImageUploading = false);
      }
    }
  }

  Future<void> _handleReverify() async {
    if (_isReverifying) return;

    final result = await Navigator.push<LocationConfirmResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OnboardingLocationConfirmPage(initialQuery: _newAddressName ?? ''),
      ),
    );

    if (!mounted || result == null) return;

    setState(() => _isReverifying = true);

    try {
      final status = await _mypageApi.reverifyResidence(
        currentLatitude: result.currentLatitude,
        currentLongitude: result.currentLongitude,
        currentAddress: result.currentAddress,
      );

      if (!mounted) return;

      if (status.verified) {
        setState(() {
          _newAddressName = result.location.displayAddress;
          _isReverified = true;
        });
        _showSnackBar('거주지 재인증이 완료되었습니다.');
      } else {
        _showSnackBar(status.message ?? '거주지 재인증에 실패했습니다. 다시 시도해 주세요.');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(_cleanError(e));
    } finally {
      if (mounted) setState(() => _isReverifying = false);
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final newNickname = _nicknameController.text.trim();
    final oldNickname = widget.profile.nickname?.trim() ?? '';
    final nicknameChanged = newNickname != oldNickname;

    final oldAddress = widget.profile.addressName?.trim() ?? '';
    final newAddress = _newAddressName?.trim() ?? '';
    final addressChanged = newAddress.isNotEmpty && newAddress != oldAddress;

    final imageChanged = _profileImageUrl != widget.profile.profileImage;

    if (!nicknameChanged && !addressChanged && !imageChanged) {
      _showSnackBar('변경된 내용이 없습니다.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _mypageApi.updateUserProfile(
        nickname: nicknameChanged ? newNickname : null,
        addressName: addressChanged ? _newAddressName : null,
        profileImageUrl: imageChanged ? _profileImageUrl : null,
      );

      if (!mounted) return;

      _showSnackBar('프로필이 수정되었습니다.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) debugPrint('[프로필 수정 실패] $e');
      _showSnackBar(_cleanError(e));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Widget _buildProfileImageSection() {
    return Center(
      child: GestureDetector(
        onTap: _isImageUploading ? null : _handleImagePick,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: ColorStyles.grey2,
              child: ClipOval(
                child: _isImageUploading
                    ? const SizedBox(
                        width: 88,
                        height: 88,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorStyles.main1,
                          ),
                        ),
                      )
                    : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                    ? Image.network(
                        _profileImageUrl!,
                        width: 88,
                        height: 88,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => SvgPicture.asset(
                          'assets/mypage/myprofile.svg',
                          width: 88,
                          height: 88,
                        ),
                      )
                    : SvgPicture.asset(
                        'assets/mypage/myprofile.svg',
                        width: 88,
                        height: 88,
                      ),
              ),
            ),
            if (!_isImageUploading)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: ColorStyles.main1,
                  shape: BoxShape.circle,
                  border: Border.all(color: ColorStyles.white, width: 2),
                ),
                child: const Icon(Icons.edit, color: ColorStyles.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('거주지', style: FontStyles.med16.copyWith(color: ColorStyles.main1)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isReverified
                        ? ColorStyles.main1
                        : ColorStyles.grey2,
                  ),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  _newAddressName?.isNotEmpty == true
                      ? _newAddressName!
                      : '등록된 거주지가 없습니다',
                  style: FontStyles.med16.copyWith(
                    color: _newAddressName?.isNotEmpty == true
                        ? ColorStyles.main1
                        : ColorStyles.grey1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isReverifying
                ? const SizedBox(
                    width: 80,
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorStyles.main1,
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _handleReverify,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isReverified
                            ? ColorStyles.white
                            : ColorStyles.main1,
                        backgroundColor: _isReverified
                            ? ColorStyles.main1
                            : Colors.transparent,
                        side: const BorderSide(color: ColorStyles.main1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(
                        _isReverified ? '인증완료' : '재인증',
                        style: FontStyles.med16,
                      ),
                    ),
                  ),
          ],
        ),
        if (_isReverified) ...[
          const SizedBox(height: 6),
          Text(
            '거주지 재인증이 완료되었습니다.',
            style: FontStyles.med14.copyWith(
              fontSize: 13,
              color: ColorStyles.main1,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DetailAppBar(title: '프로필 수정'),
      backgroundColor: ColorStyles.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileImageSection(),
                    const SizedBox(height: 32),

                    Text(
                      '닉네임',
                      style: FontStyles.med16.copyWith(
                        color: ColorStyles.main1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFieldWidget(
                      hintText: '닉네임을 입력해주세요 (최대 10자)',
                      controller: _nicknameController,
                      inputFormatters: [
                        _NoNewlineFormatter(),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      keyboardType: TextInputType.text,
                      maxLines: 1,
                      minLines: 1,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),

                    const SizedBox(height: 28),
                    _buildAddressSection(),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GradientButton(
                    text: _isSaving ? '' : '저장하기',
                    onPressed: _isSaving ? null : _handleSave,
                  ),
                  if (_isSaving)
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
      ),
    );
  }
}

class _NoNewlineFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.contains('\n')) return oldValue;
    return newValue;
  }
}
