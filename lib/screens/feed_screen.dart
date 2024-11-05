import 'package:assumemate/provider/profile_provider.dart';
import 'package:assumemate/screens/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:assumemate/components/highlighted_item_banner.dart';
import 'package:assumemate/components/listing_item.dart';
import 'package:assumemate/provider/favorite_provider.dart';
import 'package:assumemate/screens/favorites_screen.dart';
import 'package:assumemate/screens/highlighted_item_screen.dart';
import 'package:assumemate/screens/listing/add_car_listing.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:provider/provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final SecureStorage secureStorage = SecureStorage();

  late final PageController pageController;
  int pageNo = 0;
  late Future<List<dynamic>> houseAndLotListings;
  late Future<List<dynamic>> carListings;
  late Future<List<dynamic>> motorcycleListings;
  String? _userType;

  Future<void> _getUserType() async {
    String? userType = await secureStorage.getUserType();
    setState(() {
      _userType = userType;
    });
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 0, viewportFraction: 0.95);
    _getUserType();

    // Fetch listings for each category
    houseAndLotListings = fetchListingsByCategory('Real Estate');
    carListings = fetchListingsByCategory('Car');
    motorcycleListings = fetchListingsByCategory('Motorcycle');
  }

  final String? baseURL = dotenv.env['API_URL'];

  Future<List<dynamic>> fetchListingsByCategory(String category) async {
    final token = await secureStorage.getToken();
    try {
      final apiUrl = Uri.parse('$baseURL/listings/$category/');
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        // Ensure proper UTF-8 decoding
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        // Assuming the response is a list of listings
        if (data is List) {
          return data; // Return the list of listings
        } else {
          print('Unexpected response format: $data');
          throw Exception('Failed to parse listings');
        }
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load listings');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to load listings');
    }
  }

  // Refactored method to build listing grid
  Widget buildListingGrid(Future<List<dynamic>> futureListings) {
    return FutureBuilder<List<dynamic>>(
      future: futureListings,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Failed to load listings'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No listings available'));
        } else {
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              mainAxisExtent: MediaQuery.of(context).size.width * .50,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var listing = snapshot.data![index];
              if (listing == null) {
                return const Center(child: Text('No Listing Data'));
              }
              var content = listing['list_content'];
              var title;

              // Check the category and set the title accordingly
              if (content['category'] == "Cars" ||
                  content['category'] == "Motorcycle") {
                title =
                    '${content['make'] ?? 'Unknown make'} (${content['model'] ?? 'Unknown model'})';
              } else if (content['category'] == "House and Lot") {
                title = content['title'] ?? 'No Title';
              } else {
                title = content['title'] ??
                    'No Title'; // Default case if category doesn't match
              }

              return ListingItem(
                title: title,
                imageUrl: content['images'],
                description: content['description'] ?? 'No Description',
                listingId: listing['list_id'].toString(),
                assumptorId: listing['user_id'].toString(),
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);

    int favoriteCount = favoriteProvider.favoriteIds.length;
    final tabTextStyle =
        GoogleFonts.poppins(textStyle: const TextStyle(fontSize: 13));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xffFFFCF1),
          title: Row(children: [
            Image.asset(
              'assets/images/15-removebg-preview.png',
              height: 50,
              fit: BoxFit.contain,
            ),
            const Spacer(),
            IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search,
                    size: 40, color: Color(0xff4A8AF0))),
            Stack(
              children: [
                IconButton(
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FavoritesScreen()),
                    );
                  },
                  icon: const Icon(
                    Icons.favorite_outline_sharp,
                    color: Color(0xff4A8AF0),
                  ),
                  iconSize: 40,
                ),
                (favoriteProvider.faveCount != 0)
                    ? Positioned(
                        right: 0,
                        top: 5,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: const Color(0xffFF0000),
                          ),
                          child: Center(
                            child: Text(
                              // Changed to non-constant Text
                              favoriteCount > 0 ? favoriteCount.toString() : '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink()
              ],
            )
          ]),
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2, bottom: 2, left: 8),
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const HighlightedItemScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2,
                  ),
                ),
                child: const Text(
                  'Highlighted Items',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: pageController,
                onPageChanged: (index) {
                  setState(() {
                    pageNo = index; // Update pageNo on page change
                  });
                },
                itemBuilder: (_, index) {
                  return AnimatedBuilder(
                    animation: pageController,
                    builder: (context, child) {
                      return child!;
                    },
                    child: const HighlightedItemBanner(),
                  );
                },
                itemCount: 5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Container(
                  margin: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.circle,
                    size: 8,
                    color: pageNo == index
                        ? const Color(0xff4A8AF0)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            TabBar(
              labelColor: Colors.black,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: UnderlineTabIndicator(
                borderSide: const BorderSide(
                  width: 4,
                  color: Color(0xff4A8AF0),
                ),
                insets: const EdgeInsets.symmetric(
                  horizontal: (30 - 4) / 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              tabs: [
                Tab(
                    child: Text(
                  'House & Lot',
                  style: tabTextStyle,
                )),
                Tab(
                    child: Text(
                  'Cars',
                  style: tabTextStyle,
                )),
                Tab(
                    child: Text(
                  'Motorcycles',
                  style: tabTextStyle,
                )),
              ],
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
                child: TabBarView(
                  children: [
                    // Real Estate Listings
                    buildListingGrid(houseAndLotListings),
                    // Car Listings
                    buildListingGrid(carListings),
                    // Motorcycle Listings
                    buildListingGrid(motorcycleListings),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _userType == 'assumptor'
            ? FloatingActionButton(
                onPressed: () async {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddListing(),
                  ));
                },
                heroTag: null,
                backgroundColor: const Color(0xff4A8AF0),
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add,
                  size: 30,
                  color: Color(0xffFFFCF1),
                ),
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
