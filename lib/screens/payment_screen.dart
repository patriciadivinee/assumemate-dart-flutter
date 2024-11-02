import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentScreen extends StatelessWidget {
  final Function(int) addCoins; // Function to add coins

  PaymentScreen({Key? key, required this.addCoins}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final amounts = [20, 50, 100, 150, 200, 300, 500, 1000, 2000, 3000, 4000];
    final coins = [20, 50, 100, 150, 200, 300, 500, 1000, 2000, 3000, 4000];

    final String? clientId = dotenv.env['PAYPAL_CLIENT_ID'];
    final String? secretKey = dotenv.env['PAYPAL_SECRET_KEY'];

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back when the back button is pressed
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            width: MediaQuery.of(context).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Get More Coins',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Click higlighted blue amount with Peso sign to buy',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 16),
                ...List.generate(coins.length, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                PaypalCheckoutView(
                              sandboxMode: true,
                              clientId: clientId,
                              secretKey: secretKey,
                              transactions: [
                                {
                                  "amount": {
                                    "total": amounts[index].toString(),
                                    "currency": "PHP",
                                    "details": {
                                      "subtotal": amounts[index].toString(),
                                      "shipping": '0',
                                      "shipping_discount": 0,
                                    },
                                  },
                                  "description": "Payment for coins.",
                                  "item_list": {
                                    "items": [
                                      {
                                        "name": "Coin Purchase",
                                        "quantity": 1,
                                        "price": amounts[index].toString(),
                                        "currency": "PHP"
                                      }
                                    ],
                                  },
                                  "application_context": {
                                    "user_action": "PAY_NOW",
                                  },
                                }
                              ],
                              note: "Thank you for your purchase.",
                              onSuccess: (Map params) async {
                                log("Payment Success: $params");
                                addCoins(coins[
                                    index]); // Add coins based on the button pressed

                                // Show dialog with a message and an "Ok" button
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Payment Completed'),
                                      content: Text(
                                          'You have received ${coins[index]} coins.'),
                                      actions: [
                                        TextButton(
                                          child: Text('Ok'),
                                          onPressed: () {
                                            Navigator.pop(
                                                context); // Close the dialog
                                            Navigator.pop(
                                                context); // Pop the PayPal screen
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              onError: (error) {
                                log("Payment Error: $error");
                                Navigator.pop(context);
                              },
                              onCancel: (params) {
                                log("Payment Cancelled: $params");
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.monetization_on,
                                  color: Colors.yellow, size: 28),
                              SizedBox(width: 8),
                              Text(
                                '${coins[index]} Coins',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 6, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Php ${amounts[index]}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
