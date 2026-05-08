import 'package:flutter/material.dart';
import '../../ui/colorStyles.dart';
import '../../ui/fontStyles.dart';

class SelectableButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onPressed;
  final double? width;
  final double height;

  const SelectableButton({
    Key? key,
    required this.text,
    required this.isSelected,
    required this.onPressed,
    this.width,
    this.height = 57.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? ColorStyles.main1 : Colors.white,
          foregroundColor: isSelected ? Colors.white : ColorStyles.main1,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.0),
            side: BorderSide(color: ColorStyles.main1, width: 1.0),
          ),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Text(text, style: FontStyles.med16),
      ),
    );
  }
}
