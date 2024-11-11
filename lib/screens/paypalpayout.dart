import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaypalPayoutService {
     // Replace with your actual backend URL

  // Send money to user
  static Future<Map<String, dynamic>> sendMoney({
    required String recipientEmail,
    required double amount,
    
    required String token,
  }) async {
    try {
      final String? baseUrl = dotenv.env['API_URL'];
      final response = await http.post(
        Uri.parse('$baseUrl/simple-transfer/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'recipient_email': recipientEmail,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send money: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending money: $e');
    }
  }

  // Check payout status
  static Future<Map<String, dynamic>> checkPayoutStatus({
    required String payoutBatchId,
    required String token,
  }) async {
    try {
      final String? baseUrl = dotenv.env['API_URL'];
      final response = await http.get(
        Uri.parse('$baseUrl/complete-simple-transfer/?payout_batch_id=$payoutBatchId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error checking payout status: $e');
    }
  }
}

class PayoutButton extends StatefulWidget {
  final String recipientEmail;
  final double amount;
  final String token;

  const PayoutButton({
    Key? key,
    required this.recipientEmail,
    required this.amount,
    required this.token,
  }) : super(key: key);

  @override
  State<PayoutButton> createState() => _PayoutButtonState();
}

class _PayoutButtonState extends State<PayoutButton> {
  bool _isLoading = false;

  Future<void> _handlePayout() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Initiate payout
      final result = await PaypalPayoutService.sendMoney(
        recipientEmail: widget.recipientEmail,
        amount: widget.amount,
        token: widget.token,
      );

      // Check status (optional - you might want to implement this differently)
      final String payoutBatchId = result['payout_batch_id'];
      await PaypalPayoutService.checkPayoutStatus(
        payoutBatchId: payoutBatchId,
        token: widget.token,
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout initiated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handlePayout,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Payout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}