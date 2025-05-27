import 'package:attendance_app/screen/login_page.dart';

class AppRoutes {
  static const adminLogin = '/adminLogin';

  static final routes = {
    adminLogin: (context) => const LoginPage(),
  };
}
