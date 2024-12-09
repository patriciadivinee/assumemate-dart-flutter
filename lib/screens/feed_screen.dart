import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/screens/search_screen.dart';
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
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

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
  String? _appStatus;
  final ValueNotifier<bool> _isSpeedDialOpen = ValueNotifier(false);
  List<dynamic> _promotedListings = [];

  Future<void> _getUserType() async {
    String? userType = await secureStorage.getUserType();
    setState(() {
      _userType = userType;
    });
  }

  Future<void> _getappStatus() async {
    String? appStats = await secureStorage.getApplicationStatus();
    setState(() {
      _appStatus = appStats;
    });
  }

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: 0, viewportFraction: 0.95);
    _getUserType();
    _getappStatus();
    _fetchPromotedListings();
    _startAutoScroll();
    checkAndFetchListings();
    // Fetch listings for each category
    houseAndLotListings = fetchListingsByCategory('Real Estate');
    carListings = fetchListingsByCategory('Car');
    motorcycleListings = fetchListingsByCategory('Motorcycle');
  }

  final String? baseURL = dotenv.env['API_URL'];

  Future<void> checkAndFetchListings() async {
    final token = await secureStorage.getToken();
    final now = DateTime.now();

    try {
      // Fetch all active listings
      final apiUrl = Uri.parse('$baseURL/listings/');
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final listings = jsonDecode(utf8.decode(response.bodyBytes));

        if (listings is List) {
          for (var listing in listings) {
            final listId = listing['list_id'];
            final listStatus = listing['list_status'];
            final listDuration = DateTime.parse(
                listing['list_duration'] ?? now.toIso8601String());
            final promotion = listing['promotion'];

            bool isPromoted = promotion != null &&
                DateTime.parse(promotion['prom_end']).isAfter(now);

            // You only need to check and display the data here
            // Archiving will happen on the server side during periodic checks
            print(
                'Listing ID: $listId, Status: $listStatus, Duration: $listDuration, Is Promoted: $isPromoted');
          }
        } else {
          print('Unexpected response format: $listings');
        }
      } else {
        print(
            'Error fetching listings: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error checking listings: $e');
    }
  }

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
        final data = jsonDecode(utf8.decode(response.bodyBytes));

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

              return ListingItem(
                listing: listing,
              );
            },
          );
        }
      },
    );
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
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to fetch promoted listings')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching listings: $e')),
        );
      }
    }
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _promotedListings.isNotEmpty) {
        pageNo = (pageNo + 1) % _promotedListings.length;
        pageController.animateToPage(
          pageNo,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  void onClickFAB() {
    if (_appStatus != 'APPROVED') {
      popUp(context, 'You need to be verified to create a listing.');
    } else {
      _isSpeedDialOpen.value = true;
    }
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
        backgroundColor: const Color(0xffFFFCF1),
        appBar: AppBar(
          surfaceTintColor: Colors.transparent,
          backgroundColor: const Color(0xffFFFCF1),
          title: Row(children: [
            Image.asset(
              'assets/images/15-removebg-preview.png',
              height: 50,
              fit: BoxFit.contain,
            ),
            const Spacer(),
            IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
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
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: const Color(0xffFFFCF1),
                forceElevated: true,
                pinned: false,
                floating: true,
                expandedHeight: MediaQuery.of(context).size.height / 3.5,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: const Color(0xffFFFCF1),
                    child: Column(
                      children: [
                        Container(
                          margin:
                              const EdgeInsets.only(top: 2, bottom: 2, left: 8),
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const HighlightedItemScreen()),
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
                          height: MediaQuery.of(context).size.height / 3.5 - 75,
                          child: PageView.builder(
                            controller: pageController,
                            onPageChanged: (index) {
                              setState(() {
                                pageNo = index;
                              });
                            },
                            itemBuilder: (_, index) {
                              final listing = _promotedListings[index];

                              print('listing yawa');
                              print(listing);

                              return HighlightedItemBanner(
                                promotedListing: listing,
                              );
                            },
                            itemCount: _promotedListings.length,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _promotedListings.length,
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
                      ],
                    ),
                  ),
                  collapseMode: CollapseMode.none,
                ),
              ),
              SliverPersistentHeader(
                  pinned: true,
                  delegate: TabBarHeader(
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
                        Tab(child: Text('House & Lot', style: tabTextStyle)),
                        Tab(child: Text('Cars', style: tabTextStyle)),
                        Tab(child: Text('Motorcycles', style: tabTextStyle)),
                      ],
                    ),
                  )),
            ];
          },
          body: Container(
            padding: const EdgeInsets.all(10),
            child: TabBarView(
              children: [
                buildListingGrid(houseAndLotListings),
                buildListingGrid(carListings),
                buildListingGrid(motorcycleListings),
              ],
            ),
          ),
        ),
        floatingActionButton: (_userType == 'assumptor')
            ? SpeedDial(
                icon: Icons.add,
                openCloseDial: _isSpeedDialOpen,
                activeIcon: Icons.close,
                backgroundColor: const Color(0xff4A8AF0),
                foregroundColor: Colors.white,
                spaceBetweenChildren: 4,
                overlayColor: Colors.white,
                curve: Curves.bounceIn,
                children: [
                    SpeedDialChild(
                      shape: const CircleBorder(),
                      child: const Icon(Icons.motorcycle, color: Colors.white),
                      label: 'Motorcycle',
                      labelStyle: const TextStyle(fontWeight: FontWeight.w400),
                      backgroundColor: const Color(0xff4A8AF0),
                      elevation: 3,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                AddListing(category: 'Motorcycle'),
                          ),
                        );
                      },
                    ),
                    SpeedDialChild(
                      shape: const CircleBorder(),
                      child:
                          const Icon(Icons.directions_car, color: Colors.white),
                      label: 'Car',
                      labelStyle: const TextStyle(fontWeight: FontWeight.w400),
                      backgroundColor: const Color(0xff4A8AF0),
                      elevation: 3,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddListing(category: 'Car'),
                          ),
                        );
                      },
                    ),
                    SpeedDialChild(
                      shape: const CircleBorder(),
                      child:
                          const Icon(Icons.house_outlined, color: Colors.white),
                      label: 'Real Estate',
                      labelStyle: const TextStyle(fontWeight: FontWeight.w400),
                      backgroundColor: const Color(0xff4A8AF0),
                      elevation: 3,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                AddListing(category: 'Real Estate'),
                          ),
                        );
                      },
                    ),
                  ])
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

class TabBarHeader extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  TabBarHeader(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xffFFFCF1), // Adjust the background color as needed
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
