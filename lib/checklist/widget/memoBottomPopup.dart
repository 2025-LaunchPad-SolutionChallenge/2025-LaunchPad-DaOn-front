import 'package:flutter/material.dart';
import 'package:project_daon/checklist/model/attachment_model.dart';
import 'package:project_daon/checklist/widget/checkItemWidget.dart';
import 'package:project_daon/checklist/widget/checklistItemDropdown.dart';
import 'package:project_daon/common/widget/gradientButton.dart';
import 'package:project_daon/common/widget/lineTextField.dart';
import 'package:project_daon/common/widget/textFieldWidget.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class MemoAttachBottomPopupWidget extends StatefulWidget {
  final List<ChecklistItemModel> items;
  final bool isEditMode;
  final int? initialChecklistItemId;
  final String? initialTitle;
  final String? initialBody;
  final void Function(int checklistItemId, String content) onSubmit;

  const MemoAttachBottomPopupWidget({
    super.key,
    this.items = const [],
    this.isEditMode = false,
    this.initialChecklistItemId,
    this.initialTitle,
    this.initialBody,
    required this.onSubmit,
  });

  @override
  State<MemoAttachBottomPopupWidget> createState() =>
      _MemoAttachBottomPopupWidgetState();
}

class _MemoAttachBottomPopupWidgetState
    extends State<MemoAttachBottomPopupWidget> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  int? _selectedChecklistItemId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _bodyController = TextEditingController(text: widget.initialBody ?? '');
    _selectedChecklistItemId = widget.initialChecklistItemId ??
        (widget.items.isNotEmpty ? widget.items.first.checklistItemId : null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final id = widget.isEditMode
        ? widget.initialChecklistItemId
        : _selectedChecklistItemId;
    if (id == null) return;

    final content = buildMemoContent(title, _bodyController.text);
    widget.onSubmit(id, content);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: ShapeDecoration(
                  color: const Color(0x33525252),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            if (!widget.isEditMode && widget.items.isNotEmpty) ...[
              ChecklistItemDropdown(
                items: widget.items,
                selectedId: _selectedChecklistItemId,
                onChanged: (id) =>
                    setState(() => _selectedChecklistItemId = id),
              ),
              const SizedBox(height: 16.0),
            ],
            Text(
              widget.isEditMode ? '메모 수정하기' : '메모 등록하기',
              style: FontStyles.semi20.copyWith(color: ColorStyles.black1),
            ),
            const SizedBox(height: 4.0),
            LineTextField(
              hintText: '제목을 입력해주세요!',
              maxLength: 20,
              controller: _titleController,
            ),
            const SizedBox(height: 12.0),
            TextFieldWidget(
              hintText: '내용을 입력해주세요.',
              controller: _bodyController,
              keyboardType: TextInputType.multiline,
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 24.0),
            GradientButton(
              text: widget.isEditMode ? '수정하기' : '추가하기',
              onPressed: _submit,
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
