import 'package:flutter/material.dart';
import 'package:project_daon/checklist/api/checklist_api.dart';
import 'package:project_daon/checklist/view/checklistAiAddPage.dart';
import 'package:project_daon/checklist/widget/addBottomPopup.dart';
import 'package:project_daon/checklist/widget/aiChecklistFloatingButton.dart';
import 'package:project_daon/checklist/widget/checkItemWidget.dart';
import 'package:project_daon/checklist/widget/itemBottomPopup.dart';
import 'package:project_daon/checklist/widget/checkNullWidget.dart';
import 'package:project_daon/checklist/widget/checkProgress.dart';
import 'package:project_daon/checklist/widget/checklistWeekWidget.dart';
import 'package:project_daon/checklist/widget/pictureButton.dart';
import 'package:project_daon/common/widget/tapBarWidget.dart';
import 'package:project_daon/home/api/homeApi.dart';
import 'package:project_daon/ui/colorStyles.dart';
import 'package:project_daon/ui/fontStyles.dart';

class ChecklistPage extends StatefulWidget {
  const ChecklistPage({super.key});

  @override
  State<ChecklistPage> createState() => _ChecklistPageState();
}

class _ChecklistPageState extends State<ChecklistPage> {
  final _homeApi = HomeApi();
  final _checklistApi = ChecklistApi();

  DateTime _currentSelectedDate = DateTime.now();
  int _selectedIndex = 0;

  List<ChecklistItemModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  double _completionRate = 0.0;
  int? _userDisasterId;

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    if (mounted)
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    try {
      if (_userDisasterId == null) {
        final summary = await _homeApi.getHomeSummary();
        _userDisasterId = summary.userDisasterId;
      }
      final items = await _checklistApi.getChecklistItems(
        _userDisasterId!,
        _currentSelectedDate,
      );
      if (mounted) {
        final checked = items.where((i) => i.isChecked).length;
        setState(() {
          _items = items;
          _completionRate = items.isEmpty
              ? 0.0
              : (checked / items.length) * 100;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '체크리스트를 불러오는 데 실패했습니다.';
        });
      }
    }
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => const ItemBottomPopupWidget(),
    );
  }

  void _showBottomSheet22() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => const AddBottomPopupWidget(),
    );
  }

  Future<void> _navigateToNewPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChecklistAiAddPage(selectedDate: _currentSelectedDate),
      ),
    );
    if (result == true) {
      _loadChecklist();
    }
  }

  void _showItemOptionsBottomSheet(ChecklistItemModel selectedItem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => const ItemBottomPopupWidget(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: ColorStyles.main2,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            title,
            style: FontStyles.med16.copyWith(color: ColorStyles.black1),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGrid(List<String> imageUrls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            imageUrls[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allImages = <String>[];
    for (final item in _items) {
      allImages.addAll(item.imageUrls);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedIndex == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: AiChecklistFloatingButton(
                onPressed: () {
                  _navigateToNewPage();
                },
              ),
            )
          : null,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChecklistProgessBar(currentCheck: _completionRate),
              ChecklistWeekWidget(
                selectedDate: _currentSelectedDate,
                onDateSelected: (newDate) {
                  setState(() => _currentSelectedDate = newDate);
                  _loadChecklist();
                },
              ),
              const SizedBox(height: 20.0),

              TabBarWidget(
                selectedIndex: _selectedIndex,
                onTabChanged: (index) {
                  setState(() => _selectedIndex = index);
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 33.0,
                      child: Text(
                        '${_currentSelectedDate.month}.${_currentSelectedDate.day}',
                        style: FontStyles.med20,
                      ),
                    ),
                    if (_selectedIndex == 1)
                      PictureButton(
                        text: '등록하기',
                        onPressed: () {},
                        width: 100.0,
                        height: 33.0,
                      ),
                    if (_selectedIndex == 0)
                      PictureButton(
                        text: '생성하기',
                        onPressed: () {},
                        width: 100.0,
                        height: 33.0,
                      ),
                  ],
                ),
              ),

              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _buildChecklistTab(),

                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0),
                              color: ColorStyles.secon5,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Memo', style: FontStyles.semi16),
                                const SizedBox(height: 12.0),
                                Text(
                                  '텍스트 정리하기',
                                  style: FontStyles.med14.copyWith(
                                    color: ColorStyles.black2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28.0),

                          if (allImages.isNotEmpty) ...[
                            _buildSectionTitle('All'),
                            const SizedBox(height: 12.0),
                            _buildImageGrid(allImages),
                            const SizedBox(height: 32.0),
                          ],

                          for (final item in _items.where(
                            (i) => i.imageUrls.isNotEmpty,
                          ))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle(item.title),
                                const SizedBox(height: 12.0),
                                _buildImageGrid(item.imageUrls),
                                const SizedBox(height: 32.0),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: FontStyles.med14.copyWith(color: ColorStyles.black2),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: CheckNullWidget());
    }
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return ChecklistItemWidget(
          item: _items[index],
          onCheckChanged: (bool newValue) {
            setState(() => _items[index].isChecked = newValue);
          },
          onOptionsTap: _showItemOptionsBottomSheet,
        );
      },
    );
  }
}
