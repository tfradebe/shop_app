import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shop_app/exceptions/http_exception.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDate;
  String _userId;
  Timer _authTimer;

  bool get isAuth {
    return token != null;
  }

  String get token {
    if (_expiryDate != null &&
        _expiryDate.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url =
        "https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyCjiHTnoaO9co0ecuWhmK9xNIxSDe6tzy0";
    try {
      final response = await http.post(
        url,
        body: jsonEncode(
          {
            "email": email.trim(),
            "password": password,
            "returnSecureToken": true,
          },
        ),
      );
      final responseData = json.decode(response.body);
      if (responseData["error"] != null) {
        throw HttpException(responseData["erroe"]["message"]);
      }
      _token = responseData["idToken"];
      _userId = responseData["localId"];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(responseData["expiresIn"]),
        ),
      );
      _authLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({
        "token": _token,
        "userId": _userId,
        "expiryDate": _expiryDate.toIso8601String(),
      });
      prefs.setString("userData", userData);
    } catch (error) {
      throw error;
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey("userData")) {
      return false;
    }
    final extractedUserData =
        jsonDecode(prefs.getString("userData")) as Map<String, Object>;
    final expiryDate = DateTime.parse(extractedUserData["expiryDate"]);

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }
    _token = extractedUserData["token"];
    _userId = extractedUserData["userId"];
    _expiryDate = expiryDate;
    notifyListeners();
    _authLogout();
    return true;
  }

  String get userId {
    return _userId;
  }

  Future<void> signup(String email, String password) async {
    return _authenticate(email, password, "signUp");
  }

  Future<void> login(String email, String password) async {
    return _authenticate(email, password, "signInWithPassword");
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _expiryDate = null;
    if (_authTimer != null) {
      _authTimer.cancel();
      _authTimer = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("userData");
  }

  void _authLogout() {
    if (_authTimer != null) {
      _authTimer.cancel();
    }
    final timeToExpiry = _expiryDate.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }
}
