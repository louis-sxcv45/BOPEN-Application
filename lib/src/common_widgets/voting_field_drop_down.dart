import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/style_manager/color_manager.dart';
import 'package:project_pkl/src/style_manager/font_family_manager.dart';
import 'package:project_pkl/src/style_manager/values_manager.dart';

class VotingFieldDropDown extends StatelessWidget {
  const VotingFieldDropDown({super.key, required this.title, required this.hintText, required this.dropDownController});
  final String title;
  final String hintText;
  final SingleValueDropDownController dropDownController; 
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: FontFamilyManager.latoFont,
            fontWeight: FontWeightManager.bold,
            fontSize: FontSizeManager.f36,
          ),
        ),

        SizedBox(
          height: AppSize.s12,
        ),

        DropDownTextField(
          controller: dropDownController,
          enableSearch: true,
          textFieldDecoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSize.s12),
              borderSide: BorderSide(
                color: ColorManager.black,
              )
            ),
            hintText: hintText
          ),
          dropDownList: const [
            DropDownValueModel(
              name: '',
              value: ''
            )
          ],
        ),
        SizedBox(
          height: AppSize.s12,
        ),
      ],
    );
  }
}