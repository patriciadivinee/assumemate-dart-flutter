import 'package:assumemate/components/listing_item.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/provider/follow_provider.dart';
import 'package:assumemate/screens/assumptor_listing_screen.dart';
import 'package:assumemate/screens/feed_screen.dart';
import 'package:assumemate/screens/following_screen.dart';
import 'package:assumemate/screens/transaction.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:assumemate/components/highlighted_item.dart';
import 'package:assumemate/components/offer_list.dart';
import 'package:assumemate/logo/loading_animation.dart';
import 'package:assumemate/provider/profile_provider.dart';
import 'package:assumemate/screens/account_settings_screen.dart';
import 'package:assumemate/screens/edit_profile_screen.dart';
// import 'package:assumemate/screens/offer_list_screen.dart';
import 'package:assumemate/screens/payment_screen.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? errorMsg;
  double _coins = 0;
  late ScrollController _scrollController;
  bool? _isCollapsed = false;
  List<Map<String, dynamic>> _offers = [];
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _followers = [];
  String? token;
  String? _applicationStatus;

  final SecureStorage secureStorage = SecureStorage();
  final ApiService apiService = ApiService();

  Future<void> _fetchCoins() async {
    final wallId = await secureStorage.getUserId();
    try {
      double totalCoins = await apiService.getTotalCoins(int.parse(wallId!));
      setState(() {
        _coins = totalCoins;
      });
    } catch (e) {
      print('Error fetching coins: $e');
    }
  }

  Future<void> _addCoins(int coinsToAdd) async {
    final wallId = await secureStorage.getUserId();
    try {
      await apiService.addCoinsToWallet(int.parse(wallId!), coinsToAdd);
      await _fetchCoins(); // Re-fetch the coins from the database after adding
    } catch (e) {
      // Handle error appropriately
      print('Error adding coins: $e');
    }
  }

  bool get _isSliverAppBarExpanded {
    return _scrollController.hasClients &&
        _scrollController.offset > (150 - kToolbarHeight);
  }

  Future<void> _getOffers() async {
    try {
      final response = await apiService.getAssumptorListOffer();

      if (response.containsKey('offers')) {
        setState(() {
          _offers = List<Map<String, dynamic>>.from(response['offers']);
        });
      }
    } catch (e) {
      popUp(context, 'Error: $e');
    }
  }

  Future<void> _getListings() async {
    try {
      final response = await apiService.assumptorListings();
      if (response.containsKey('listings')) {
        setState(() {
          _listings = List<Map<String, dynamic>>.from(response['listings']);
        });
        print('yawa');
        print(_listings);
      }
    } catch (e) {
      popUp(context, 'Error: $e');
    }
  }

  void _getToken() async {
    final tok = await secureStorage.getToken();
    final status = await secureStorage.getApplicationStatus();
    setState(() {
      token = tok;
      _applicationStatus = status;
    });
  }

  void _getFollower() async {
    try {
      final response = await apiService.getFollowers();

      if (response.containsKey('follower')) {
        setState(() {
          _followers = List<Map<String, dynamic>>.from(response['follower']);
        });
        print(_followers);
      }
    } catch (e) {
      popUp(context, 'An error occureed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getToken();
    _getFollower();
    _fetchCoins();
    _getOffers();
    _getListings();

    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _isCollapsed = _isSliverAppBarExpanded;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final followProvider = Provider.of<FollowProvider>(context);
    final tabTextStyle =
        GoogleFonts.poppins(textStyle: const TextStyle(fontSize: 13));

    if (profileProvider.isLoading) {
      return const LoadingAnimation();
    } else if (profileProvider.errorMessage.isNotEmpty) {
      Text(
        profileProvider.errorMessage,
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      );
    }
    if (profileProvider.userProfile.isNotEmpty) {
      return Scaffold(
          body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ));
                    },
                    icon: const FaIcon(
                      FontAwesomeIcons.solidPenToSquare,
                      size: 25,
                      color: Color(0xffFFFFFF),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AccontSettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    color: const Color(0xffFFFCF1),
                    iconSize: 30,
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF4A8AF0),
              forceElevated: true,
              pinned: true,
              floating: true,
              expandedHeight: 250,
              collapsedHeight: 60,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 15),
                background: Stack(children: [
                  Positioned.fill(
                    child: Image.network(
                      'https://pbs.twimg.com/media/GQ6Tse_aQAABFI2?format=jpg&name=large',
                      fit: BoxFit
                          .cover, // Ensure the image covers the entire area
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    left: 10,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                              profileProvider.userProfile['user_prof_pic']),
                          radius: 40,
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${profileProvider.userProfile['user_prof_fname']} ${profileProvider.userProfile['user_prof_lname']}',
                                    style: const TextStyle(
                                      color: Color(0xffFFFFFF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  _applicationStatus == 'APPROVED'
                                      ? const Icon(
                                          Icons.verified_rounded,
                                          color: Color(0xffFFFFFF),
                                          size: 18,
                                        )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                        builder: (context) => FollowScreen(
                                          title: 'Followers',
                                          follow: _followers,
                                        ),
                                      ));
                                    },
                                    child: Text(
                                      _followers.length < 2
                                          ? '0 Follower'
                                          : '${_followers.length} Followers',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xffFFFFFF),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 30, // Adjust the height as needed
                                    child: VerticalDivider(
                                      thickness: 1.5,
                                      color: Color(0xffFFFFFF),
                                      width: 20,
                                      indent: 4,
                                      endIndent: 4,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  FollowScreen(
                                                    title: 'Following',
                                                    follow: followProvider
                                                        .followingIds,
                                                  )));
                                    },
                                    child: Text(
                                      '${followProvider.followingCount} Following',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xffFFFFFF),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ]),
                collapseMode: CollapseMode.pin,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'My Wallet',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 10, right: 8, left: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    FontAwesomeIcons.coins,
                                    color: Color(0xffF2D120),
                                    size: 32,
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _coins.toString(),
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const Text('Coins',
                                          style: TextStyle(fontSize: 13))
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentScreen(
                                        addCoins: _addCoins,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                iconSize: 28,
                                color: const Color(0xFF4A8AF0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Manage',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildCard(
                            'Listings',
                            Icons.local_convenience_store_outlined,
                            const Color(0xff34a36e),
                            () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AssumptorListingScreen(),
                                  ),
                                )),
                        const SizedBox(height: 15),
                        _buildCard(
                            'Offers',
                            Icons.local_offer_outlined,
                            const Color(0xffe04946),
                            () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FeedScreen(),
                                  ),
                                )),
                        const SizedBox(height: 15),
                        _buildCard(
                            'Transactions',
                            Icons.receipt_long_outlined,
                            const Color(0xff626362),
                            () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TransactionHistoryScreen(),
                                  ),
                                )),
                      ])),
            ),
            SliverPersistentHeader(
              delegate: MySliverPersistentHeaderDelegate(
                minExtentVal: 35.0,
                maxExtentVal: 35.0,
              ),
              pinned: true,
            ),
          ];
        },
        body: Padding(
            padding: const EdgeInsets.all(10),
            child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  mainAxisExtent: MediaQuery.of(context).size.width * .50,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: _listings.length,
                itemBuilder: (context, index) {
                  print(_listings[0]);
                  final listing = _listings[index];
                  String title;

                  if (listing['list_content']['category'] == "Cars" ||
                      listing['list_content']['category'] == "Motorcycle") {
                    title =
                        '${listing['list_content']['make'] ?? 'Unknown make'} (${listing['list_content']['model'] ?? 'Unknown model'})';
                  } else if (listing['list_content']['category'] ==
                      "Real Estate") {
                    title = listing['list_content']['title'] ?? 'No Title';
                  } else {
                    title = listing['list_content']['title'] ??
                        'No Title'; // Default case if category doesn't match
                  }

                  if (listing['list_status'].toUpperCase() == 'ACTIVE') {
                    return const SizedBox.shrink();
                  }
                  return ListingItem(
                    title: title,
                    imageUrl: listing['list_content']['images'],
                    description: listing['list_content']['description'] ??
                        'No Description',
                    listingId: listing['list_id'].toString(),
                    assumptorId: listing['user_id'].toString(),
                    price: listing['list_content']['price'].toString(),
                  );
                })),
      ));
    } else {
      return const Center(child: Text('No profile data available.'));
    }
  }

  Widget _buildCard(
      String title, IconData icon, Color color, VoidCallback? callback) {
    return GestureDetector(
      onTap: callback,
      child: Container(
        padding: const EdgeInsets.only(top: 10, bottom: 10, right: 8, left: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 13))
              ],
            ),
            IconButton(
              onPressed: callback,
              icon: const Icon(Icons.chevron_right_rounded),
              iconSize: 28,
              color: const Color(0xFF4A8AF0),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class MySliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExtentVal;
  final double maxExtentVal;

  MySliverPersistentHeaderDelegate({
    required this.minExtentVal,
    required this.maxExtentVal,
  });

  @override
  double get minExtent => minExtentVal;
  @override
  double get maxExtent => maxExtentVal;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double visibleExtent =
        maxExtent - shrinkOffset.clamp(0, maxExtent - minExtent);

    return SizedBox(
      height: visibleExtent,
      child: Container(
        color: const Color(0xffFFFCF1),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Listings', style: TextStyle(fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(MySliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
