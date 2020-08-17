import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shop_app/models/cart_item.dart';
import 'package:shop_app/models/order_item.dart';
import 'package:http/http.dart' as http;

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  final String authToken;
  final String userId;

  Orders(
    this.authToken,
    this._orders,
    this.userId,
  );

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    final url =
        'https://tfradebe-my-shop.firebaseio.com/orders/$userId.json?auth=$authToken';
    final response = await http.get(url);
    final List<OrderItem> loadedOrders = [];
    final extractedData = jsonDecode(response.body) as Map<String, dynamic>;
    if (extractedData == null) {
      return;
    }
    extractedData.forEach((orderId, orderData) {
      loadedOrders.add(OrderItem(
        id: orderId,
        dateTime: DateTime.parse(orderData["dateTime"]),
        amount: orderData["amount"],
        products: (orderData["products"] as List<dynamic>)
            .map(
              (item) => CartItem(
                id: item['id'],
                title: item['title'],
                quantity: item['quantity'],
                price: item['price'],
              ),
            )
            .toList(),
      ));
    });
    _orders = loadedOrders;
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url =
        'https://tfradebe-my-shop.firebaseio.com/orders/$userId.json?auth=$authToken';
    final dateTime = DateTime.now();
    final response = await http.post(
      url,
      body: jsonEncode({
        "amount": total,
        "dateTime": dateTime.toIso8601String(),
        'products': [
          cartProducts
              .map(
                (cp) => {
                  'id': cp.id,
                  'title': cp.title,
                  'quantity': cp.quantity,
                  'price': cp.price,
                },
              )
              .toList(),
        ]
      }),
    );
    _orders.insert(
      0,
      OrderItem(
        id: jsonDecode(response.body)["name"],
        amount: total,
        dateTime: dateTime,
        products: cartProducts,
      ),
    );
    notifyListeners();
  }
}
