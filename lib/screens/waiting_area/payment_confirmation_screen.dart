import 'package:assumemate/format.dart';
import 'package:assumemate/service/paypal_listing.dart';
import 'package:assumemate/service/service.dart';
import 'package:flutter/material.dart';

class PaymentConfirmationScreen extends StatefulWidget {
  final String orderId;

  const PaymentConfirmationScreen({super.key, required this.orderId});

  @override
  State<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  ApiService apiService = ApiService();
  Map<String, dynamic> orderDetails = {};
  String? title;
  String? address;
  double? price;
  String? firstImage;
  // Map<String, dynamic> listDetails = {};
  Map<String, dynamic> listerDetails = {};
  bool _isLoading = false;

  void _getOrderDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiService.viewOrder(widget.orderId);

      // print(response);

      if (response.containsKey('order')) {
        setState(() {
          final order = response['order'];
          final listing = response['list'];
          final lister = response['lister'];
          orderDetails['order_id'] = order['order_id'];
          orderDetails['amount'] = order['order_price'];
          address = listing['list_content']['address'];
          price = listing['list_content']['price'];
          firstImage = listing['list_content']['images'][0];
          listerDetails = lister;

          if (listing['list_content']['category'] != 'Real Estate') {
            title =
                '${listing['list_content']['make']} ${listing['list_content']['model']} ${listing['list_content']['year']}';
          } else {
            title = listing['list_content']['description'];
          }
        });
        print(orderDetails);
        print(address);
        print(price);
        print(firstImage);
        //   print(listDetails);
        //   print(listDetails['list_content']);
        //   print(listDetails['list_content']['price']);
      }
    } catch (e) {
      print('An error occured: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getOrderDetails();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
          color: const Color(0xffD1E3FE),
          child: const Center(
            child: CircularProgressIndicator(),
          ));
    }

    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xff4A8AF0),
          leading: IconButton(
            splashColor: Colors.transparent,
            icon: const Icon(
              Icons.arrow_back_ios,
            ),
            color: const Color(0xffFFFEF7),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            "Review & Confirm Payment",
            style: TextStyle(
              fontSize: 18,
              color: Color(0xffFFFEF7),
              fontWeight: FontWeight.bold,
            ),
          )),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You\'re about to pay for:'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.network(
                    firstImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const Text(
              'Villag echuchu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 18,
                  color: Colors.black,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatCurrency(price!),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                children: [
                  const Text(
                    'Total amount to pay:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    formatCurrency(double.parse(orderDetails['amount'])),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 18),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PayPalListingScreen(
                    amount: double.parse(orderDetails['amount']),
                    orderId: int.parse(widget.orderId),
                    transType: 'Payment Purchase',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A8AF0),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            child: const Text(
              'Confirm & Pay',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )),
    );
  }
}
