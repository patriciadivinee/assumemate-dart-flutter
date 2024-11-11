import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PayPalPaymentScreen extends StatefulWidget {
  final double amount;

  const PayPalPaymentScreen({Key? key, required this.amount}) : super(key: key);

  @override
  _PayPalPaymentScreenState createState() => _PayPalPaymentScreenState();
}

class _PayPalPaymentScreenState extends State<PayPalPaymentScreen> {
  late WebViewController _controller;
  final SecureStorage secureStorage = SecureStorage();
  final ApiService apiService = ApiService();
  String? _orderId;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          if (request.url.contains('payment-success')) {
            _capturePayment();
            return NavigationDecision.prevent;
          }
          if (request.url.contains('payment-cancelled')) {
            _handlePaymentCancelled();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ));

    _initiatePayment(widget.amount);
  }

  Future<void> _addCoins(int coinsToAdd) async {
    final wallId = await secureStorage.getUserId();
    try {
      await apiService.addCoinsToWallet(int.parse(wallId!), coinsToAdd);
      // Re-fetch the coins after adding
    } catch (e) {
      print('Error adding coins: $e');
    }
  }

  Future<void> _initiatePayment(double amount) async {
    final String? baseUrl = dotenv.env['API_URL'];
    final token =
        await secureStorage.getToken(); // Fetch token from secure storage
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create-paypal-order/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Send the token in the Authorization header
        },
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _orderId = responseData['id']; // Store the order ID
        String approvalUrl = responseData['approval_url'];
        await _controller.loadRequest(Uri.parse(approvalUrl));
      } else {
        throw 'Failed to create PayPal order';
      }
    } catch (error) {
      print('Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize payment')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _capturePayment() async {
    final token =
        await secureStorage.getToken(); // Fetch token from secure storage
    final String? baseUrl = dotenv.env['API_URL'];
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/capture-paypal-order/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Send the token in the Authorization header
        },
        body: json.encode({'orderID': _orderId, 'amount': widget.amount}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Capture Response: $data');
        await _addCoins(widget.amount.toInt());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment successful!')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        throw 'Payment capture failed';
      }
    } catch (error) {
      print('Capture Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed')),
        );
        Navigator.of(context).pop(false);
      }
    }
  }

  void _handlePaymentCancelled() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cancelled')),
      );
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PayPal Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _handlePaymentCancelled();
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
