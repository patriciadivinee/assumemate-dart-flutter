import 'package:assumemate/format.dart';
import 'package:assumemate/screens/assumptor_list_detail_screen.dart';
import 'package:assumemate/screens/item_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HighlightedItemBanner extends StatefulWidget {
  final Map<String, dynamic> promotedListing;
  const HighlightedItemBanner({super.key, required this.promotedListing});

  @override
  State<HighlightedItemBanner> createState() => _HighlightedItemBannerState();
}

class _HighlightedItemBannerState extends State<HighlightedItemBanner> {
  final SecureStorage secureStorage = SecureStorage();
  String? _currUserId;

  Future<void> _getUserId() async {
    _currUserId = await secureStorage.getUserId();
  }

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  @override
  Widget build(BuildContext context) {
    print('widget.promotedListing');
    print(widget.promotedListing);
    final list = widget.promotedListing['list_id'];
    final listContent = list['list_content'];
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => (list['user_id'].toString() == _currUserId)
                ? AssumptorListDetailScreen(listingId: _currUserId!)
                : ItemDetailScreen(
                    listingId: list['list_id'],
                    assumptorId: list['user_id'].toString(),
                  ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(left: 3, top: 6, right: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: const Color(0xff4A8AF0), // Background color for the card
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listContent['title'],
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          ' \u20B1',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatCurrency(
                              double.parse(listContent['price'].toString()),
                              symbol: ''),
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 15,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            listContent['address'],
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                            softWrap: true,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                  child: AspectRatio(
                aspectRatio: 16 / 14,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: listContent['images'][0],
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
                              style:
                                  TextStyle(fontSize: 10, color: Colors.white),
                            )
                          ],
                        )),
                    fit: BoxFit.cover,
                  ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
