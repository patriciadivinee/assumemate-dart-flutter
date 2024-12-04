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
  const HighlightedItemBanner({super.key});

  @override
  State<HighlightedItemBanner> createState() => _HighlightedItemBannerState();
}

class _HighlightedItemBannerState extends State<HighlightedItemBanner> {
  List<dynamic> _promotedListings = [];
  bool _isLoading = true;
  late PageController _pageController;
  int _currentPage = 0;
  final SecureStorage secureStorage = SecureStorage();
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchPromotedListings();
    _pageController = PageController(initialPage: 0);
    _startAutoScroll();
    _getUserType();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _promotedListings.isNotEmpty) {
        _currentPage = (_currentPage + 1) % _promotedListings.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  Future<void> _fetchPromotedListings() async {
    final SecureStorage _secureStorage = SecureStorage();
    String? token = await _secureStorage.getToken();

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/promote/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _promotedListings =
              data.take(5).toList(); // Ensure a max of 5 listings
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch promoted listings')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching listings: $e')),
      );
    }
  }

  Future<void> _getUserType() async {
    _userId = await secureStorage.getUserId();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_promotedListings.isEmpty) {
      return const Center(
        child: Text(
          'No promoted listings available.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _promotedListings.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          final listing = _promotedListings[index];
          final listId = listing['list_id'] ?? {};
          final user_id = listing['user_id'] ?? {};
          final listContent = listId['list_content'] ?? {};
          final images = listContent['images'] ?? [];
          final title = listContent['title'] ?? 'Unknown Title';
          final price = listContent['price']?.toString() ?? 'N/A';
          final location = listContent['address'] ?? 'Unknown Location';

          return GestureDetector(
            onTap: () {
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => (_userId == user_id)
              //         ? AssumptorListDetailScreen(listingId: user_id)
              //         : ItemDetailScreen(
              //             listingId: user_id,
              //             assumptorId: user_id,
              //           ),
              //   ),
              // );
            },
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: const Color(0xff4A8AF0),
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Text(
                                '₱',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatCurrency(double.tryParse(price) ?? 0),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                  softWrap: true,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: images.isNotEmpty ? images[0] : '',
                        placeholder: (context, url) => Container(
                          color: Colors.black38,
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error,
                          color: Colors.white,
                        ),
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
