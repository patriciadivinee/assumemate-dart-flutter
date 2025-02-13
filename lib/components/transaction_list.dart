import 'package:assumemate/format.dart';
import 'package:assumemate/provider/usertype_provider.dart';
import 'package:assumemate/screens/payment_receipt_screen.dart';
import 'package:assumemate/screens/rating_list.dart';
import 'package:assumemate/screens/waiting_area/payment_confirmation_screen.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TransactionList extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const TransactionList({super.key, required this.transaction});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

@override
class _TransactionListState extends State<TransactionList> {
  final SecureStorage secureStorage = SecureStorage();
  Map<String, dynamic>? trans;
  @override
  void initState() {
    trans = widget.transaction;
    print(trans);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final userType = Provider.of<UserProvider>(context, listen: false).userType;
    final listing = trans!['listing'];
    final content = trans!['listing']['list_content'];

    //changes ni joselito
    final user_id = listing['user_id'].toString(); // Make sure it's a string
    final list_id = listing['list_id'].toString();

    String? title;
    if (content['category'] == 'Real Estate') {
      title = content['title'];
    } else {
      title = '${content['make']} ${content['model']} ${content['year']}';
    }
    String address = listing['list_content']['address'];
    print('Listing ID}, Value: ${listing['list_id']}');
    print('USER for rate ID, Value: ${user_id}');

    return InkWell(
        onTap: () {
          trans!['order_status'] == 'PENDING' && userType == 'assumee'
              ? Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentConfirmationScreen(
                      orderId: trans!['order_id'].toString(),
                    ),
                  ))
              : Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentReceiptScreen(
                      orderId: trans!['order_id'].toString(),
                    ),
                  ));
        },
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .15 + 42,
          child: Card(
            color: Colors.white,
            // margin: const EdgeInsets.only(left: 3, top: 6, right: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            child: Padding(
              padding: EdgeInsets.all(7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: CachedNetworkImage(
                        imageUrl: listing['list_content']['images'][0],
                        placeholder: (context, url) => Container(
                          color: Colors.black38,
                        ),
                        errorWidget: (context, url, error) => Container(
                            color: Colors.white60,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.warning_rounded,
                                  color: Colors.white,
                                ),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.white),
                                )
                              ],
                            )),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10), // Space between image and text
                  Expanded(
                      child: Padding(
                    padding: EdgeInsets.all(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Order No. ${trans!['order_id']}', // Replace with dynamic title
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 20),
                            trans!['order_status'] == 'COMPLETED'
                                ? statusDesign('COMPLETED', Color(0xff4A8AF0),
                                    Colors.white)
                                : trans!['order_status'] == 'PAID'
                                    ? statusDesign(
                                        'PAID', Color(0xffF2D120), Colors.white)
                                    : trans!['order_status'] == 'PENDING'
                                        ? statusDesign('WAITING FOR PAYMENT',
                                            Color(0xff34a36e), Colors.white)
                                        : trans!['order_status'] ==
                                                'FOR CONFIRMATION'
                                            ? statusDesign('FOR CONFIRMATION',
                                                Color(0xff959696), Colors.white)
                                            : trans!['order_status'] ==
                                                    'CANCELLED'
                                                ? statusDesign(
                                                    'CANCELLED',
                                                    Color(0xffD42020),
                                                    Colors.white)
                                                : const SizedBox.shrink()
                          ],
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                            child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title!,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on,
                                    size: 12, color: Colors.grey),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                    softWrap: true,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              ],
                            )
                          ],
                        )),
                        Row(
                          children: [
                            const Text(
                              'Reservation price:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(), // Spacer pushes the price text to the left
                            Text(
                              formatCurrency(
                                  double.parse(trans!['order_price'])),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        //changes ni joselito
                        const SizedBox(
                            height:
                                5), // Add spacing between price and rate button

                        if (userType == 'assumee' &&
                            trans!['order_status'] == 'COMPLETED')
                          Align(
                              alignment: Alignment
                                  .centerRight, // Align the button to the right
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  side: const BorderSide(
                                      color: Color(0xff4A8AF0), width: 1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        8), // Rounded button
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => RateListPage(
                                              user_id: user_id,
                                              list_id: list_id,
                                              images: content['images'],
                                            )),
                                  );
                                  print(
                                      'Rate button clicked for user: ${listing['user_id']}');
                                  print(
                                      'Rate button clicked for users item: ${listing['list_id']}');
                                },
                                icon: const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Rate  ',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w300,
                                    fontSize: 12,
                                  ),
                                ),
                              )),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ));
  }

  Widget statusDesign(
      final String status, final Color backgroundColor, final Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
