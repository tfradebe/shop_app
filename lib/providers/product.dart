import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shop_app/exceptions/http_exception.dart';

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;
  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.price,
    @required this.imageUrl,
    this.isFavorite = false,
  });

  Future<void> toggleFavoriteStatus(String authToken, String userId) async {
    final oldStatus = isFavorite;
    isFavorite = !isFavorite;
    notifyListeners();
    final url =
        'https://tfradebe-my-shop.firebaseio.com/userFavorites/$userId.json?auth=$authToken';
    try {
      // http throw exceptions for >=400 status code only on GET and POST. Not on DELETE. PATCH, PUT.
      final response = await http.patch(
        url,
        body: jsonEncode({
          id: isFavorite,
        }),
      );
      if (response.statusCode >= 400) {
        throw HttpException(
            "Exception with status code ${response.statusCode} calling ${response.request.method} on URL/ID $url ");
      }
    } catch (error) {
      isFavorite = oldStatus;
      notifyListeners();
    }
  }
}
