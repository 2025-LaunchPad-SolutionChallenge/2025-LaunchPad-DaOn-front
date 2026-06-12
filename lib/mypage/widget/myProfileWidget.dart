import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class MyProfileWidget extends StatelessWidget {
  final String name;
  final int? stageId;
  final String? stageName;
  final String? disasterTypeName;
  final String? profileImageUrl;
  final bool residenceVerified;

  const MyProfileWidget({
    super.key,
    required this.name,
    this.stageName,
    this.stageId,
    this.disasterTypeName,
    this.profileImageUrl,
    this.residenceVerified = false,
  });

  String _buildInfoLine() {
    final parts = <String>[];
    if (stageId != null) {
      parts.add('Lv. ${stageId!.toString().trim()}');
    }
    if (stageName != null && stageName!.trim().isNotEmpty) {
      parts.add(stageName!.trim());
    }
    if (disasterTypeName != null && disasterTypeName!.trim().isNotEmpty) {
      parts.add('${disasterTypeName!.trim()} 피해');
    }
    return parts.join('   /   ');
  }

  Widget _buildProfileImage() {
    final url = profileImageUrl;
    if (url != null && url.isNotEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ColorStyles.white.withAlpha(100),
          border: Border.all(color: ColorStyles.white.withAlpha(100), width: 4),
        ),
        child: ClipOval(
          child: Image.network(
            url,
            width: 86,
            height: 86,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                SvgPicture.asset('assets/mypage/myprofile.svg'),
          ),
        ),
      );
    }
    return SvgPicture.asset('assets/mypage/myprofile.svg');
  }

  @override
  Widget build(BuildContext context) {
    final infoLine = _buildInfoLine();

    return Container(
      width: double.infinity,
      height: 225.0,
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProfileImage(),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: FontStyles.semi20.copyWith(color: ColorStyles.white),
              ),
              if (residenceVerified) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: ColorStyles.white, size: 13),
                      SizedBox(width: 3),
                      Text(
                        '거주 인증',
                        style: FontStyles.med11.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorStyles.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (infoLine.isNotEmpty) ...[
            const SizedBox(height: 4.0),
            Text(
              infoLine,
              style: FontStyles.med15.copyWith(
                color: ColorStyles.white.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }
}
