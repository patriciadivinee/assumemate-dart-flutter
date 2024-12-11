import 'package:assumemate/format.dart';
import 'package:assumemate/screens/assumptor_list_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:assumemate/provider/favorite_provider.dart';
import 'package:assumemate/screens/item_detail_screen.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:provider/provider.dart';

class ListingItem extends StatefulWidget {
  final dynamic listing;

  const ListingItem({
    required this.listing,
    super.key,
  });

  @override
  State<ListingItem> createState() => _ListingItemState();
}

class _ListingItemState extends State<ListingItem> {
  final SecureStorage secureStorage = SecureStorage();
  Map<String, dynamic>? userProfile; // Store user profile data
  bool isLoading = true; // For loading state
  String? _userId;

  Future<void> _getUserId() async {
    _userId = await secureStorage.getUserId();
  }

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  @override
  Widget build(BuildContext context) {
    var content = widget.listing['list_content'];
    var listId = widget.listing['list_id'];
    var userId = widget.listing['user_id'].toString();
    var price = content['price'].toString();
    final images = content['images'];

    print('widget.listing');
    print(widget.listing);

    String title;

    if (content['category'] == 'Real Estate') {
      title = content['title'] ?? 'No title';
      // title = 'No title';
    } else {
      title =
          '${content['make']} ${content['model']} (${content['year']}) - ${content['transmission']}';
    }

    return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => (_userId == userId)
                  ? AssumptorListDetailScreen(listingId: listId)
                  : ItemDetailScreen(
                      listingId: listId,
                      assumptorId: userId,
                    ),
            ),
          );
        },
        child: Card(
          color: Colors.white,
          margin: const EdgeInsets.all(1),
          elevation: 2, // Adds elevation (shadow effect) similar to boxShadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: images != null
                          ? images[0]
                          : 'https://example.com/placeholder.png',
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade300,
                      ),
                      errorWidget: (context, url, error) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.warning_rounded,
                            color: Colors.black38,
                          )),
                      height: MediaQuery.of(context).size.width * 0.29,
                      width: MediaQuery.of(context).size.width,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (widget.listing['is_promoted'] ?? false)
                    Positioned(
                        left: 10,
                        top: 10,
                        child: Icon(
                          Icons.star_rounded,
                          size: 25,
                          color: Color(0xfffcba03),
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(
                                  0.8), // White shadow with slight transparency
                              offset: Offset(0, 0), // Centered shadow
                              blurRadius:
                                  15.0, // High blur for a glowing effect
                            ),
                          ],
                        )),
                  if (widget.listing['list_status'] == 'SOLD' ||
                      widget.listing['list_status'] == 'RESERVED')
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        child: Center(
                          child: Text(
                            widget.listing['list_status'],
                            style: const TextStyle(
                              color: Colors.white,
                              letterSpacing: 1.5,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  color: Colors.black54,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.red,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              content['address'],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          )
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            formatCurrency(double.parse(price)),
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff4A8AF0)),
                          ),
                          const Spacer(),
                          Consumer<FavoriteProvider>(
                            builder: (context, favoriteProvider, child) {
                              final isFavorited =
                                  favoriteProvider.isFavorited(listId);

                              print(isFavorited);

                              return GestureDetector(
                                onTap: () async {
                                  final token =
                                      await SecureStorage().getToken();
                                  if (token != null) {
                                    try {
                                      String message = await favoriteProvider
                                          .toggleFavorite(listId);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text(message)),
                                      );
                                    } catch (error) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('Error: $error')),
                                      );
                                    }
                                  }
                                },
                                child: Icon(
                                  isFavorited
                                      ? Icons.favorite
                                      : Icons.favorite_outline,
                                  color: isFavorited
                                      ? const Color(0xffFF0000)
                                      : Colors.black,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ));
  }

  @override
  void dispose() {
    super.dispose();
  }
}
