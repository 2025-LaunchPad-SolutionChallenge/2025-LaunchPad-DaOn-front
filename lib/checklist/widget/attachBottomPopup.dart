import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_daon/checklist/api/checklist_api.dart';
import 'package:project_daon/checklist/widget/checkItemWidget.dart';
import 'package:project_daon/checklist/widget/checklistItemDropdown.dart';
import 'package:project_daon/common/widget/gradientButton.dart';
import 'package:project_daon/common/widget/lineTextField.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class AttachBottomPopupWidget extends StatefulWidget {
  final List<ChecklistItemModel> items;
  final int userDisasterId;
  final VoidCallback onSuccess;

  const AttachBottomPopupWidget({
    super.key,
    required this.items,
    required this.userDisasterId,
    required this.onSuccess,
  });

  @override
  State<AttachBottomPopupWidget> createState() =>
      _AttachBottomPopupWidgetState();
}

class _AttachBottomPopupWidgetState extends State<AttachBottomPopupWidget> {
  final TextEditingController _titleController = TextEditingController();
  int? _selectedChecklistItemId;
  XFile? _selectedFile;
  String? _fileType;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedChecklistItemId =
        widget.items.isNotEmpty ? widget.items.first.checklistItemId : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.length();
    if (bytes > 10 * 1024 * 1024) {
      setState(() => _errorMessage = '10MB를 초과하는 파일은 첨부할 수 없습니다.');
      return;
    }
    setState(() {
      _selectedFile = file;
      _fileType = 'IMAGE';
      _errorMessage = null;
      if (_titleController.text.isEmpty) {
        _titleController.text = file.name;
      }
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    if (picked.size > 10 * 1024 * 1024) {
      setState(() => _errorMessage = '10MB를 초과하는 파일은 첨부할 수 없습니다.');
      return;
    }
    final path = picked.path;
    if (path == null) {
      setState(() => _errorMessage = '파일 경로를 읽을 수 없습니다.');
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[파일 선택] name=${picked.name} size=${picked.size} path=$path',
      );
    }
    setState(() {
      _selectedFile = XFile(path);
      _fileType = 'FILE';
      _errorMessage = null;
      if (_titleController.text.isEmpty) {
        _titleController.text = picked.name;
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedChecklistItemId == null) {
      setState(() => _errorMessage = '체크리스트 항목을 선택해주세요.');
      return;
    }
    if (_selectedFile == null) {
      setState(() => _errorMessage = '파일을 선택해주세요.');
      return;
    }

    final ioFile = File(_selectedFile!.path);
    final fileName = _selectedFile!.name;
    final title = _titleController.text.trim();
    final originalFileName = title.isNotEmpty ? title : fileName;
    final mimeType = _selectedFile!.mimeType ?? _inferMimeType(fileName) ?? '';

    if (kDebugMode) {
      debugPrint(
        '[첨부 업로드 호출] userDisasterId=${widget.userDisasterId} '
        'checklistItemId=$_selectedChecklistItemId '
        'attachmentType=$_fileType '
        'file=$originalFileName',
      );
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      await ChecklistApi().uploadAndAddFileAttachment(
        userDisasterId: widget.userDisasterId,
        checklistItemId: _selectedChecklistItemId!,
        file: ioFile,
        originalFileName: originalFileName,
        mimeType: mimeType,
        attachmentType: _fileType!,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSuccess();
    } catch (e) {
      if (kDebugMode) debugPrint('[파일 업로드] 오류: $e');
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String? _inferMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
    return map[ext];
  }

  ButtonStyle get _buttonStyle => ElevatedButton.styleFrom(
    backgroundColor: ColorStyles.white,
    foregroundColor: ColorStyles.black2,
    overlayColor: ColorStyles.main1,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(7),
      side: const BorderSide(color: ColorStyles.main1, width: 1.0),
    ),
    padding: EdgeInsets.zero,
  );

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
            ChecklistItemDropdown(
              items: widget.items,
              selectedId: _selectedChecklistItemId,
              onChanged: (id) =>
                  setState(() => _selectedChecklistItemId = id),
            ),
            const SizedBox(height: 16.0),
            Text(
              '사진 / 파일 추가하기',
              style: FontStyles.semi20.copyWith(color: ColorStyles.black1),
            ),
            const SizedBox(height: 4.0),
            LineTextField(
              hintText: '제목을 입력해주세요! (선택)',
              maxLength: 50,
              controller: _titleController,
            ),
            const SizedBox(height: 12.0),
            if (_selectedFile == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 112.0,
                        child: ElevatedButton(
                          style: _buttonStyle,
                          onPressed: _pickImage,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                'assets/checklist/camera_alt.svg',
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                '사진',
                                style: FontStyles.med12.copyWith(
                                  color: ColorStyles.black2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: SizedBox(
                        height: 112.0,
                        child: ElevatedButton(
                          style: _buttonStyle,
                          onPressed: _pickFile,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset('assets/checklist/memo.svg'),
                              const SizedBox(height: 8.0),
                              Text(
                                '파일',
                                style: FontStyles.med12.copyWith(
                                  color: ColorStyles.black2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: ColorStyles.main1),
                  borderRadius: BorderRadius.circular(7.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      _fileType == 'IMAGE'
                          ? Icons.image_outlined
                          : Icons.insert_drive_file_outlined,
                      color: ColorStyles.main1,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFile!.name,
                        overflow: TextOverflow.ellipsis,
                        style: FontStyles.med14.copyWith(
                          color: ColorStyles.main1,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedFile = null;
                        _fileType = null;
                      }),
                      child: const Icon(
                        Icons.close,
                        color: ColorStyles.grey1,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8.0),
            ],
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _errorMessage!,
                  style: FontStyles.med12.copyWith(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16.0),
            GradientButton(
              text: _isUploading ? '업로드 중...' : '추가하기',
              onPressed: _isUploading ? null : _submit,
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }
}
