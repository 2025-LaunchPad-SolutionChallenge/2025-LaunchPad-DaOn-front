import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_daon/checklist/widget/checkItemWidget.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class ChecklistItemDropdown extends StatefulWidget {
  final List<ChecklistItemModel> items;
  final int? selectedId;
  final ValueChanged<int> onChanged;

  const ChecklistItemDropdown({
    super.key,
    required this.items,
    this.selectedId,
    required this.onChanged,
  });

  @override
  State<ChecklistItemDropdown> createState() => _ChecklistItemDropdownState();
}

class _ChecklistItemDropdownState extends State<ChecklistItemDropdown> {
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId ??
        (widget.items.isNotEmpty ? widget.items.first.checklistItemId : null);
    if (_selectedId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onChanged(_selectedId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border.all(color: ColorStyles.main1),
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Text(
          '체크리스트 항목이 없습니다',
          style: FontStyles.med14.copyWith(color: ColorStyles.grey1),
        ),
      );
    }

    final validId = widget.items.any((e) => e.checklistItemId == _selectedId)
        ? _selectedId
        : widget.items.first.checklistItemId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 2.0, bottom: 4.0),
      decoration: BoxDecoration(
        border: Border.all(color: ColorStyles.main1, width: 1.0),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: validId,
          isExpanded: true,
          style: FontStyles.med14.copyWith(color: ColorStyles.main1),
          icon: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: SvgPicture.asset('assets/home/arrowGreen.svg'),
          ),
          isDense: true,
          dropdownColor: Colors.white,
          onChanged: (int? newId) {
            if (newId == null) return;
            setState(() => _selectedId = newId);
            widget.onChanged(newId);
          },
          items: widget.items.map((item) {
            return DropdownMenuItem<int>(
              value: item.checklistItemId,
              child: Text(
                item.title,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: FontStyles.med14.copyWith(color: ColorStyles.main1),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
