import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter/material.dart';
import 'package:project_pkl/src/style_manager/color_manager.dart';
import 'package:project_pkl/src/style_manager/font_family_manager.dart';
import 'package:project_pkl/src/style_manager/values_manager.dart';

class VotingFieldDropDown extends StatelessWidget {
  const VotingFieldDropDown({
    super.key,
    required this.title,
    required this.hintText,
    required this.dropDownController,
    required this.dropDownList,
    required this.onChanged,
  });

  final String title;
  final String hintText;
  final SingleValueDropDownController dropDownController;
  final List<DropDownValueModel> dropDownList; // Menambahkan parameter untuk dropdown list
  final ValueChanged<String> onChanged; // Callback saat item dipilih

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
        const SizedBox(
          height: AppSize.s12,
        ),
        Container(
          width: 300,
          margin: const EdgeInsets.only(left: AppSize.s12),
          child: DropDownTextField(
            controller: dropDownController,
            enableSearch: true,
            textFieldDecoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSize.s12),
                borderSide: BorderSide(
                  color: ColorManager.black,
                ),
              ),
              hintText: hintText,
            ),
            dropDownList: dropDownList, // Menggunakan data dari parameter
            onChanged: (value) {
              onChanged(value!.value); // Menjalankan callback saat item dipilih
            },
          ),
        ),
        const SizedBox(
          height: AppSize.s12,
        ),
      ],
    );
  }
}
