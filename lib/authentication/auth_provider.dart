import 'package:attendance_app/authentication/auth.dart';
import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  final Auth _auth;

  AuthProvider(this._auth);
}
