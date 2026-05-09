import 'package:flutter/material.dart';
import 'selectableButton.dart';

class ButtonGroupManager extends StatefulWidget {
  final List<String> options;
  final bool isMultipleSelection;
  final Function(List<String>) onChanged;

  final bool isGrid;

  const ButtonGroupManager({
    Key? key,
    required this.options,
    this.isMultipleSelection = false,
    this.isGrid = false,
    required this.onChanged,
  }) : super(key: key);

  @override
  _ButtonGroupManagerState createState() => _ButtonGroupManagerState();
}

class _ButtonGroupManagerState extends State<ButtonGroupManager> {
  List<String> _selectedValues = [];

  void _handlePress(String value) {
    setState(() {
      if (widget.isMultipleSelection) {
        // [복수 선택] 이미 선택된 값이면 제거, 아니면 추가
        if (_selectedValues.contains(value)) {
          _selectedValues.remove(value);
        } else {
          _selectedValues.add(value);
        }
      } else {
        // [단수 선택] 이미 선택된 값이면 선택 해제, 아니면 해당 값만 유지
        if (_selectedValues.contains(value)) {
          _selectedValues.clear();
        } else {
          _selectedValues = [value];
        }
      }
    });
    // 부모 위젯으로 현재 선택된 리스트 전달
    widget.onChanged(_selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGrid) {
      List<Widget> gridRows = [];

      for (int i = 0; i < widget.options.length; i += 2) {
        gridRows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: SelectableButton(
                    text: widget.options[i],
                    isSelected: _selectedValues.contains(widget.options[i]),
                    onPressed: () => _handlePress(widget.options[i]),
                  ),
                ),

                const SizedBox(width: 10.0),
                if (i + 1 < widget.options.length)
                  Expanded(
                    child: SelectableButton(
                      text: widget.options[i + 1],
                      isSelected: _selectedValues.contains(
                        widget.options[i + 1],
                      ),
                      onPressed: () => _handlePress(widget.options[i + 1]),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
        );
      }
      return Column(children: gridRows);
    }

    return Column(
      children: widget.options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: SelectableButton(
            text: option,
            isSelected: _selectedValues.contains(option),
            onPressed: () => _handlePress(option),
          ),
        );
      }).toList(),
    );
  }
}
