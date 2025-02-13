import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_pkl/src/style_manager/color_manager.dart';
import 'package:project_pkl/src/style_manager/font_family_manager.dart';
import 'package:project_pkl/src/style_manager/values_manager.dart';

class VotingTextField extends StatelessWidget {
  const VotingTextField({super.key, required this.title, required this.hintText, required this.votingFieldController});
  final String title;
  final String hintText;
  final TextEditingController votingFieldController;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textAlign: TextAlign.start,
          style: TextStyle(
            fontFamily: FontFamilyManager.latoFont,
            fontSize: FontSizeManager.f16,
            fontWeight: FontWeight.bold
          ),
        ),

        const SizedBox(
          height: AppSize.s12,
        ),

        TextField(
          controller: votingFieldController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSize.s12),
              borderSide: BorderSide(
                color: ColorManager.black
              )
            )
          ),
          style: TextStyle(
            fontSize: FontSizeManager.f12,
          ),
        ),

        const SizedBox(
          height: AppSize.s12,
        ),
      ],
    );
  }
}