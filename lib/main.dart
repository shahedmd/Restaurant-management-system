import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'Kitchen Admin/kitchenadmin.dart';
import 'Users/auth.dart';
import 'Users/login.dart';
import 'controller/liverorderscontroller.dart';
import 'firebase_options.dart';
import 'homepage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INIT FIREBASE FIRST
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Get.put(LiveOrdersController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AuthController(), permanent: true);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        double heightFinal = 1040.0;
        double widthFinal = 1440.0;

        if (screenWidth > 1600) {
          heightFinal = 1050.0;
          widthFinal = 1680.0;
        } else if (screenWidth > 1800) {
          heightFinal = 1280.0;
          widthFinal = 1980.0;
        } else if (screenWidth < 650) {
          heightFinal = 932.0;
          widthFinal = 430.0;
        }

        return ScreenUtilInit(
          designSize: Size(widthFinal, heightFinal),
          minTextAdapt: false,
          splitScreenMode: true,
          builder: (_, __) {
            return GetMaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                iconTheme: IconThemeData(color: Colors.white),
              ),
              initialRoute: '/',
              getPages: [
                GetPage(name: '/', page: () => LoginPage()),
                GetPage(name: '/admin', page: () => AdminHomepage()),
                GetPage(name: '/staff', page: () => StaffHomePage()),
              ],
            );
          },
        );
      },
    );
  }
}
