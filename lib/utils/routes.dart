import 'package:attendance_app/screen/admin_login_page.dart';
import 'package:attendance_app/screen/employee_login_page.dart';

class AppRoutes {
  static const adminLogin = '/adminLogin';
  static const employeeLogin = '/employeeLogin';

  static final routes = {
    adminLogin: (context) => const AdminLoginPage(),
    employeeLogin: (context) => const EmployeeLoginPage(),
  };
}
