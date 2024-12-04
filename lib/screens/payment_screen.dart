import 'package:flutter/material.dart';
import 'package:assumemate/service/paypal_topup.dart';

class PaymentScreen extends StatelessWidget {
  final Function(int) addCoins; // Function to add coins

  PaymentScreen({Key? key, required this.addCoins}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final amounts = [50, 100, 150, 200, 250, 500];
    final coins = [50, 110, 170, 230, 280, 600];

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
                      onPressed: () async {
                        double selectedAmount = amounts[index].toDouble();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PayPalPaymentScreen(amount: selectedAmount),
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
