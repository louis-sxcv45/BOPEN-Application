import 'package:flutter/material.dart';
import 'package:project_pkl/src/style_manager/color_manager.dart';
import 'package:project_pkl/src/style_manager/values_manager.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 137,
        alignment: Alignment.center,
        height: 49,
        decoration: BoxDecoration(
          color: ColorManager.yellow,
          borderRadius: BorderRadius.circular(AppSize.s8)
        ),
        child: Text(
          title,
          style: TextStyle(
            color: ColorManager.white,
          ),
        ),
      ),
    );
  }
}