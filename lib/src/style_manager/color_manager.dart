import 'package:flutter/material.dart';

class ColorManager {
  static Color blue = HexColor.fromHex('#66C4FF');
  static Color yellow = HexColor.fromHex('#FFC067');
  static Color black = HexColor.fromHex('#000000');
  static Color white = HexColor.fromHex('#FFFFFF');
}

extension HexColor on Color {
  static Color fromHex(String hexColorString) {
   hexColorString =  hexColorString.replaceAll('#', '');
   if (hexColorString.length == 6){
    hexColorString = 'FF$hexColorString';
   }

   return Color(int.parse(hexColorString, radix: 16));
  }
}