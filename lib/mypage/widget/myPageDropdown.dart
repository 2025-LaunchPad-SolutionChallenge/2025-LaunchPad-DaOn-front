import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class MyPageDropdown extends StatelessWidget {
  /// value: userDisasterId (int). label: 화면에 표시될 텍스트.
  final List<int> ids;
  final List<String> labels;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final String? color;

  const MyPageDropdown({
    super.key,
    required this.ids,
    required this.labels,
    required this.selectedId,
    required this.onChanged,
    this.color,
  });

  Color _borderColor() =>
      color == 'main1' ? ColorStyles.main1 : ColorStyles.main2;

  String _arrowAsset() => color == 'main1'
      ? 'assets/home/arrowGreen.svg'
      : 'assets/home/arrow.svg';

  @override
  Widget build(BuildContext context) {
    // selectedId가 ids 목록에 없으면 null로 fallback (assertion 방지)
    final safeValue = (selectedId != null && ids.contains(selectedId))
        ? selectedId
        : null;

    return Container(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 2.0,
        bottom: 4.0,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: _borderColor(), width: 1.0),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: safeValue,
          style: FontStyles.med14.copyWith(color: _borderColor()),
          icon: Row(
            children: [
              const SizedBox(width: 10.0),
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: SvgPicture.asset(_arrowAsset()),
              ),
            ],
          ),
          iconSize: 24,
          isDense: true,
          dropdownColor: ColorStyles.white,
          onChanged: onChanged,
          items: List.generate(ids.length, (i) {
            return DropdownMenuItem<int>(
              value: ids[i],
              child: Text(labels[i]),
            );
          }),
        ),
      ),
    );
  }
}
