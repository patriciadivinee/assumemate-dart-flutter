import 'package:assumemate/logo/pop_up.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PayPalListingScreen extends StatefulWidget {
  final double amount;
  final int? orderId;
  final String transType;

  const PayPalListingScreen(
      {super.key, required this.amount, this.orderId, required this.transType});

  @override
  State<PayPalListingScreen> createState() => _PayPalListingScreenState();
}

class _PayPalListingScreenState extends State<PayPalListingScreen> {
  late WebViewController _controller;
  final SecureStorage secureStorage = SecureStorage();
  final ApiService apiService = ApiService();
  String? _paypalOrderId;
  final String? baseUrl = dotenv.env['API_URL'];

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          print('request.url');
          print(request.url);
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

  Future<void> _initiatePayment(double amount) async {
    final token =
        await secureStorage.getToken(); // Fetch token from secure storage
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create/paypal/order/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Send the token in the Authorization header
        },
        body: json.encode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _paypalOrderId = responseData['paypal_order_id']; // Store the order ID
        String approvalUrl = responseData['approval_url'];

        print('approvalUrl');
        print(approvalUrl);

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
    final token = await secureStorage.getToken();
    print('starting');

    final Map<String, dynamic> data = {
      'trans_type': widget.transType,
      'paypal_order_id': _paypalOrderId
    };

    print('data patata');
    print(widget.orderId);

    if (widget.orderId != null && widget.orderId!.toString().isNotEmpty) {
      data['order_id'] = widget.orderId!;
    }

    print('data batuta');
    print(data);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/capture/paypal/order/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer $token', // Send the token in the Authorization header
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Capture Response: $data');

        if (mounted) {
          Navigator.of(context).pop(true);
          popUp(context, 'Payment successful!');

          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('Payment successful!')),
          // );
          // Navigator.of(context).pop(true);
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
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            _handlePaymentCancelled();
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
