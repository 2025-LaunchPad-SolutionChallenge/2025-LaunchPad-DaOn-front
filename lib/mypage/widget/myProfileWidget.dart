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
    return parts.join('  /  ');
  }

  Widget _buildProfileImage() {
    final url = profileImageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              SvgPicture.asset('assets/mypage/myprofile.svg'),
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
      height: 210.0,
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildProfileImage(),
          const SizedBox(height: 16.0),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.white, size: 13),
                      SizedBox(width: 3),
                      Text(
                        '거주 인증',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
              style: FontStyles.med14.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }
}
