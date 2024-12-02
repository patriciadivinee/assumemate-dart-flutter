import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/service/payout_request.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:assumemate/format.dart';
import 'package:assumemate/service/service.dart';
import 'package:flutter/material.dart';

class PaymentReceiptScreen extends StatefulWidget {
  final String orderId;

  const PaymentReceiptScreen({super.key, required this.orderId});

  @override
  State<PaymentReceiptScreen> createState() => _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState extends State<PaymentReceiptScreen> {
  ApiService apiService = ApiService();
  final SecureStorage secureStorage = SecureStorage();
  Map<String, dynamic> transDetails = {};
  Map<String, dynamic> orderDetails = {};
  String? title;
  String? address;
  double? price;
  String? firstImage;
  String? _userType;
  Map<String, dynamic> listDetails = {};
  // Map<String, dynamic> listerDetails = {};
  bool _isLoading = false;

  Future<void> _getUserType() async {
    _userType = await secureStorage.getUserType();
  }

  void _markSold() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiService.listingSold(widget.orderId);
      if (response.containsKey('message')) {
        setState(() {
          listDetails['list_status'] = response['message'];
        });
        print(response['message']);
        print(listDetails['list_status']);
        popUp(context, 'Marked sold!');
      } else {
        popUp(context, response['error']);
      }
    } catch (e) {
      popUp(context, 'An error occured: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _markComplete() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await apiService.completeOrder(widget.orderId);
      if (response.containsKey('message')) {
        setState(() {
          orderDetails['order_status'] = response['message'];
        });
        popUp(context, 'Completed');
      } else {
        popUp(context, response['error']);
      }
    } catch (e) {
      popUp(context, 'An error occured: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _cancelRefund() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await apiService.completeOrder(widget.orderId);
      if (response.containsKey('message')) {
        setState(() {
          orderDetails['order_status'] = response['message'];
        });
        popUp(context, 'Completed');
      } else {
        popUp(context, response['error']);
      }
    } catch (e) {
      popUp(context, 'An error occured: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _getTransDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiService.viewPaidOrder(widget.orderId);

      print('response');
      print(response['transaction']);
      print(response['listing']);
      print(response['order']);

      if (response.containsKey('order')) {
        setState(() {
          final listing = response['listing'];
          orderDetails = response['order'];
          listDetails = listing;

          address = listing['list_content']['address'];
          price = double.tryParse(listing['list_content']['price'].toString());
          firstImage = listing['list_content']['images'][0];
          // listerDetails = lister;

          if (listing['list_content']['category'] != 'Real Estate') {
            title =
                '${listing['list_content']['make']} ${listing['list_content']['model']} ${listing['list_content']['year']}';
          } else {
            title = listing['list_content']['title'];
          }
        });
        print(transDetails);
        print(address);
        print(price);
        print(firstImage);
        //   print(listDetails);
        //   print(listDetails['list_content']);
        //   p
        // print(listDetails['list_content']['price']);
      }
      if (response.containsKey('transaction')) {
        setState(() {
          final trans = response['transaction'];
          transDetails = trans;
        });
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
    _getTransDetails();
    _getUserType();
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
            "Reservation Payment Details",
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(
                  title!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
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
                Row(
                  children: [
                    const Text(
                      'Listing price:',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      formatCurrency(price!),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                if (orderDetails.containsKey('offer_price'))
                  Row(
                    children: [
                      const Text(
                        'Offered price:',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        formatCurrency(double.parse(
                            orderDetails['offer_price'].toString())),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    const Text(
                      'Reservation amount:',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      formatCurrency(
                          double.parse(orderDetails['order_price'].toString())),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (transDetails.isNotEmpty)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Reservation amount paid:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Text(
                                formatCurrency(double.parse(
                                    transDetails['transaction_amount']
                                        .toString())),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                const SizedBox(height: 50),
                Row(
                  children: [
                    const Text(
                      'Order ID:',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      '${orderDetails['order_id']}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Reservation Date:',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      timeFormat(orderDetails['order_created_at']),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      'Payment Date:',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Text(
                      (transDetails.isNotEmpty)
                          ? timeFormat(transDetails['transaction_date'])
                          : 'Not yet paid',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                if (orderDetails['order_status'] == 'COMPLETED')
                  Row(
                    children: [
                      const Text(
                        'Completed Date:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        timeFormat(orderDetails['order_updated_at']),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
              ],
            )),
            if (_userType == 'assumptor') ...[
              listDetails['list_status'] == 'SOLD'
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 18),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PayoutRequest(orderId: widget.orderId),
                              ));
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(const Color(0xff4A8AF0)),
                          minimumSize: WidgetStateProperty.all(
                              const Size(double.infinity, 45)),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Request payout',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ))
                  : orderDetails['order_status'] == 'COMPLETED'
                      ? ElevatedButton(
                          onPressed: () => {
                            print('yawaa na'),
                            showConfirmation(
                                context,
                                'Mark as sold?',
                                'You cannot make changes after confirmation',
                                () => _markSold())
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                                orderDetails['order_status'] != 'COMPLETED'
                                    ? Colors.grey.shade400
                                    : const Color(0xff4A8AF0)),
                            minimumSize: WidgetStateProperty.all(
                                const Size(double.infinity, 45)),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Mark as Sold',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        )
                      : const SizedBox.shrink()
            ],
            if (_userType == 'assumee') ...[
              (transDetails.isNotEmpty) &&
                      orderDetails['order_status'] != 'COMPLETED'
                  ? Row(
                      // mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                            child: OutlinedButton(
                          onPressed: () {
                            print('press yawaAAA');
                            print(transDetails);
                            showConfirmation(
                                context,
                                'Cancel and request refund?',
                                'You cannot change this once confirmed.',
                                () => _markComplete());
                          },
                          style: ButtonStyle(
                            // backgroundColor: WidgetStateProperty.all(
                            //     const Color(0xff4A8AF0)),
                            side: WidgetStateProperty.all(BorderSide(
                              color: Color(0xff4A8AF0),
                              width: 1,
                            )),
                            minimumSize: WidgetStateProperty.all(
                                const Size(double.infinity, 45)),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Request Refund',
                            style: TextStyle(
                                color: Color(0xff4A8AF0),
                                fontWeight: FontWeight.bold),
                          ),
                        )),
                        const SizedBox(width: 5),
                        Flexible(
                            child: ElevatedButton(
                          onPressed: () {
                            print('press yawaAAA');
                            showConfirmation(
                                context,
                                'Confirm complete?',
                                'You cannot change this once confirmed.',
                                () => _markComplete());
                          },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                                const Color(0xff4A8AF0)),
                            minimumSize: WidgetStateProperty.all(
                                const Size(double.infinity, 45)),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                          ),
                          child: const Text(
                            'Mark as Complete',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ))
                      ],
                    )
                  : const SizedBox.shrink()
            ],
            // _userType == 'assumptor'
            //     ? listDetails['list_status'] == 'SOLD'
            //         ? Padding(
            //             padding: const EdgeInsets.symmetric(
            //                 vertical: 5, horizontal: 18),
            //             child: ElevatedButton(
            //               onPressed: () {
            //                 Navigator.push(
            //                     context,
            //                     MaterialPageRoute(
            //                       builder: (context) =>
            //                           PayoutRequest(orderId: widget.orderId),
            //                     ));
            //               },
            //               style: ButtonStyle(
            //                 backgroundColor: WidgetStateProperty.all(
            //                     const Color(0xff4A8AF0)),
            //                 minimumSize: WidgetStateProperty.all(
            //                     const Size(double.infinity, 45)),
            //                 shape: WidgetStateProperty.all(
            //                   RoundedRectangleBorder(
            //                     borderRadius: BorderRadius.circular(30.0),
            //                   ),
            //                 ),
            //               ),
            //               child: const Text(
            //                 'Request payout',
            //                 style: TextStyle(
            //                     color: Colors.white,
            //                     fontWeight: FontWeight.bold),
            //               ),
            //             ))
            //         : Padding(
            //             padding: const EdgeInsets.symmetric(
            //                 vertical: 5, horizontal: 18),
            //             child: _userType == 'assumee'
            //                 ? orderDetails['order_status'] != 'COMPLETED'
            //                     ? ElevatedButton(
            //                         onPressed: () {
            //                           print('press yawaAAA');
            //                           showConfirmation(
            //                               context,
            //                               'Confirm complete?',
            //                               'You cannot change this once confirmed.',
            //                               () => _markComplete());
            //                         },
            //                         style: ButtonStyle(
            //                           backgroundColor: WidgetStateProperty.all(
            //                               const Color(0xff4A8AF0)),
            //                           minimumSize: WidgetStateProperty.all(
            //                               const Size(double.infinity, 45)),
            //                           shape: WidgetStateProperty.all(
            //                             RoundedRectangleBorder(
            //                               borderRadius:
            //                                   BorderRadius.circular(30.0),
            //                             ),
            //                           ),
            //                         ),
            //                         child: const Text(
            //                           'Mark as Complete',
            //                           style: TextStyle(
            //                               color: Colors.white,
            //                               fontWeight: FontWeight.bold),
            //                         ),
            //                       )
            //                     : const SizedBox.shrink()
            //                 : orderDetails['order_status'] == 'COMPLETED'
            //                     ? ElevatedButton(
            //                         onPressed: () => {
            //                           print('yawaa na'),
            //                           showConfirmation(
            //                               context,
            //                               'Mark as sold?',
            //                               'You cannot make changes after confirmation',
            //                               () => _markSold())
            //                         },
            //                         style: ButtonStyle(
            //                           backgroundColor: WidgetStateProperty.all(
            //                               orderDetails['order_status'] !=
            //                                       'COMPLETED'
            //                                   ? Colors.grey.shade400
            //                                   : const Color(0xff4A8AF0)),
            //                           minimumSize: WidgetStateProperty.all(
            //                               const Size(double.infinity, 45)),
            //                           shape: WidgetStateProperty.all(
            //                             RoundedRectangleBorder(
            //                               borderRadius:
            //                                   BorderRadius.circular(30.0),
            //                             ),
            //                           ),
            //                         ),
            //                         child: const Text(
            //                           'Mark as Sold',
            //                           style: TextStyle(
            //                               color: Colors.white,
            //                               fontWeight: FontWeight.bold),
            //                         ),
            //                       )
            //                     : const SizedBox.shrink())
            //     : const SizedBox.shrink()
          ],
        ),
      ),
    );
  }

  void showConfirmation(
      BuildContext context, String title, String? desc, Function confirm) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          contentPadding: const EdgeInsets.only(left: 18, right: 18, top: 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 8),
              if (desc != null)
                Text(
                  desc,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.start,
                )
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                        color: Color(0xff4A8AF0), fontWeight: FontWeight.w400),
                  ),
                ),
                TextButton(
                  onPressed: () => {Navigator.of(context).pop(), confirm()},
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                        color: Color(0xff4A8AF0), fontWeight: FontWeight.w400),
                  ),
                ),
              ],
            )
          ],
        );
      },
    );
  }
}
