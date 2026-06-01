import 'package:axlpl_delivery/utils/assets.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          scale: 1.0,
          image: AssetImage(
            splashIMG,
          ),
        ),
      ),
      // child: Padding(
      //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.end,
      //     children: [
      //       Text(
      //         'See how truly integrated logistics delivers',
      //         style: TextStyle(fontSize: 28, color: themes.whiteColor),
      //       ),
      //       // Text(
      //       //     'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
      //       //     style: TextStyle(fontSize: 14, color: themes.grayColor))
      //     ],
      //   ),
      // ),
    ));
  }
}
