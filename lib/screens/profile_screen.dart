import 'package:assumemate/logo/pop_up.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:assumemate/components/highlighted_item.dart';
import 'package:assumemate/components/offer_list.dart';
import 'package:assumemate/logo/loading_animation.dart';
import 'package:assumemate/provider/profile_provider.dart';
import 'package:assumemate/screens/accont_settings_screen.dart';
import 'package:assumemate/screens/edit_profile_screen.dart';
// import 'package:assumemate/screens/offer_list_screen.dart';
import 'package:assumemate/screens/payment_screen.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

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
  String? token;

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
      // Handle error appropriately
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

  void _getToken() async {
    final tok = await secureStorage.getToken();
    setState(() {
      token = tok;
    });
  }

  @override
  void initState() {
    super.initState();
    _getToken();
    _fetchCoins();
    _getOffers();

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
        body: DefaultTabController(
          length: 2,
          child: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
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
                                  builder: (context) =>
                                      const AccontSettingsScreen()),
                            );
                          },
                          icon: const Icon(Icons.settings),
                          color: const Color(0xffFFFCF1),
                          iconSize: 30,
                        )
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
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(profileProvider
                                    .userProfile['user_prof_pic']),
                                radius: 40,
                              ),
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${profileProvider.userProfile['user_prof_fname']} ${profileProvider.userProfile['user_prof_lname']}',
                                      style: const TextStyle(
                                        color: Color(0xffFFFFFF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const EditProfileScreen(),
                                            ));
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Color(0xffFFFFFF),
                                            width: 1.5),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        minimumSize: const Size(0, 0),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Edit profile',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xffFFFFFF),
                                              fontSize: 11,
                                            ),
                                          ),
                                          SizedBox(width: 2),
                                          Icon(
                                            Icons.edit_outlined,
                                            color: Color(0xffFFFFFF),
                                            size: 18,
                                          ),
                                        ],
                                      ),
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
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentScreen(
                                        addCoins: _addCoins,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                _coins.toString(),
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const Text('Coins',
                                                  style:
                                                      TextStyle(fontSize: 13))
                                            ],
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.add),
                                        iconSize: 28,
                                        color: const Color(0xFF4A8AF0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ])),
                  ),
                  SliverPersistentHeader(
                    delegate: MySliverPersistentHeaderDelegate(
                      TabBar(
                        labelColor: Colors.black,
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.bold),
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
                          Tab(child: Text('Listings', style: tabTextStyle)),
                          Tab(child: Text('Offers', style: tabTextStyle)),
                        ],
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: Padding(
                padding: EdgeInsets.zero,
                child: TabBarView(
                  children: [
                    GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                        mainAxisExtent: 190,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return const HighlightedItem();
                      },
                      itemCount: 55,
                    ),
                    RefreshIndicator(
                      onRefresh: _getOffers,
                      color: const Color(0xff4A8AF0),
                      child: ListView.builder(
                        itemCount: _offers.length,
                        itemBuilder: (context, index) {
                          final offer = _offers[index];
                          return OfferList(
                            offerId: offer['offer_id'],
                            offerAmnt: offer['offer_price'],
                            listId: offer['list_id'],
                            listImage: offer['list_image'],
                            userId: offer['user_id'],
                            userFullname: offer['user_fullname'],
                            roomId: offer['chatroom_id'],
                          );
                        },
                      ),
                    )
                  ],
                ),
              )),
        ),
      );
    } else {
      return const Center(child: Text('No profile data available.'));
    }
  }
}

class MySliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  MySliverPersistentHeaderDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new Container(
      color: const Color(0xffFFFCF1),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(MySliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
