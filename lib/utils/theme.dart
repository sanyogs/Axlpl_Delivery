import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// App text styles — use getters so [.sp] runs after [ScreenUtilInit].
class Themes {
  final whiteColor = Colors.white;
  final lightWhite = Color.fromRGBO(246, 248, 249, 1);
  final blackColor = Colors.black;
  final blueColor = Colors.blue;
  final blueGray = Color.fromRGBO(230, 237, 255, 1);
  final lightCream = Color.fromRGBO(255, 238, 230, 1);
  final shineBlue = Color.fromRGBO(2, 20, 179, 1);
  final redColor = Colors.red;
  final orangeColor = Colors.deepOrangeAccent;
  final greenColor = Colors.green;
  final grayColor = Colors.grey;
  final lightGrayColor = Color.fromRGBO(235, 237, 237, 1);
  final darkCyanBlue = Color.fromRGBO(0, 67, 110, 1);

  TextStyle get fontSize18_600 =>
      GoogleFonts.workSans(fontSize: 18.sp, fontWeight: FontWeight.w600);

  TextStyle get fontSize16_400 =>
      GoogleFonts.workSans(fontSize: 16.sp, fontWeight: FontWeight.w400);

  TextStyle get fontSize14_400 =>
      GoogleFonts.workSans(fontSize: 14.sp, fontWeight: FontWeight.w400);

  TextStyle get fontSize14_500 =>
      GoogleFonts.workSans(fontSize: 14.sp, fontWeight: FontWeight.w500);

  TextStyle get fontReboto16_600 => GoogleFonts.workSans(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
      );
}
