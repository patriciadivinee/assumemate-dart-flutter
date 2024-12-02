import 'package:assumemate/components/listing_item.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/provider/follow_provider.dart';
import 'package:assumemate/screens/item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:assumemate/logo/loading_animation.dart';
import 'package:assumemate/screens/account_settings_screen.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class OtherProfileScreen extends StatefulWidget {
  String userId;

  OtherProfileScreen({super.key, required this.userId});

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  String? errorMsg;
  bool? _isCollapsed = false;
  List<Map<String, dynamic>>? _listings;
  late Future<List<dynamic>> _reviews;
  Map<String, dynamic> _userProfile = {};
  double? _averageRating;
  String? token;
  int _followerCount = 0;
  late String profileError;
  bool _isLoading = false;
  bool _isActive = true;
  bool _isAssumptor = false;

  final SecureStorage secureStorage = SecureStorage();
  final ApiService apiService = ApiService();

  Future<void> _getProfile() async {
    setState(() {
      profileError = '';
      _isLoading = true;
    });

    try {
      final response =
          await apiService.viewOtherUserProfile(int.parse(widget.userId));

      if (response.containsKey('user_profile')) {
        final rawReviews = response['reviews'];

        // Process reviews
        final List<Map<String, dynamic>> processedReviews = rawReviews.isEmpty
            ? []
            : rawReviews.map<Map<String, dynamic>>((rating) {
                return {
                  'name': rating['from_user_id'] != null
                      ? '${rating['from_user_id']['user_prof_fname']} ${rating['from_user_id']['user_prof_lname']}'
                      : 'Anonymous',
                  'rating': rating['rating_value'] ?? 0,
                  'comment': rating['review_comment'] ?? 'No comment provided',
                };
              }).toList();

        setState(() {
          _userProfile = response['user_profile'];
          _followerCount = _userProfile['followers'];
          _averageRating = response['average_rating'];
          _isActive = response['isActive'];
          _reviews = Future.value(processedReviews);
          profileError = '';
        });
        print(_userProfile);
        print('_reviews');
        print(_reviews);
      }

      if (response.containsKey('listings')) {
        setState(() {
          _listings = List<Map<String, dynamic>>.from(response['listings']);
          _isAssumptor = true;
        });
      }
    } catch (e) {
      setState(() {
        profileError = 'Error occured: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Future<void> _getListings() async {
  //   try {
  //     final response =
  //         await apiService.assumptorUserListings(int.parse(widget.userId));
  //     if (response.containsKey('listings')) {
  //       setState(() {
  //         _listings = List<Map<String, dynamic>>.from(response['listings']);
  //       });
  //     }
  //   } catch (e) {
  //     popUp(context, 'Error: $e');
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _getProfile();
    // _getListings();
  }

  @override
  Widget build(BuildContext context) {
    final followProvider = Provider.of<FollowProvider>(context);
    final tabTextStyle =
        GoogleFonts.poppins(textStyle: const TextStyle(fontSize: 13));

    if (_isLoading) {
      return const LoadingAnimation();
    } else if (profileError.isNotEmpty) {
      Center(
          child: Text(
        profileError,
        style: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ));
    }

    if (!_isActive) {
      return Scaffold(
          body: SafeArea(
              child: Column(
        children: [
          Stack(
            children: [
              Container(
                color: Colors.grey,
                child: Image.network(
                  'https://pbs.twimg.com/media/GQ6Tse_aQAABFI2?format=jpg&name=large',
                  height: 250,
                  fit: BoxFit.cover, // Ensure the image covers the entire area
                ),
              ),
              Positioned(
                bottom: 15,
                left: 10,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      backgroundImage:
                          AssetImage('assets/images/no-profile.jpg'),
                      radius: 40,
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${_userProfile['user_prof_fname']} ${_userProfile['user_prof_lname']}',
                            style: const TextStyle(
                              color: Color(0xffFFFFFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '0 Follower',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xffFFFFFF),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        onPressed: Navigator.of(context).pop,
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Color(0xffFFFCF1),
                          size: 24,
                        )),
                  ],
                ),
              )
            ],
          ),
          const Expanded(
              child: Center(
            child: Text('This user has deactivated'),
          ))
        ],
      )));
    }

    return Scaffold(
        body: DefaultTabController(
      length: _isAssumptor ? 2 : 1,
      child: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xffFFFCF1),
                  size: 24,
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton<int>(
                    color: const Color(0xffFCFCFC),
                    icon: const Icon(Icons.more_vert, color: Color(0xffFFFCF1)),
                    iconSize: 26,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          height: 25,
                          child: Row(children: [
                            Expanded(
                              child: Text(
                                'Report',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Icon(
                              Icons.flag_outlined,
                              color: Color(0xffFF0000),
                            ),
                          ]))
                    ],
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
                      child: Image.asset(
                    'assets/images/cover-photo1.jpeg',
                    fit: BoxFit.fill,
                  )),
                  Positioned(
                    bottom: 15,
                    left: 10,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              NetworkImage(_userProfile['user_prof_pic']),
                          radius: 40,
                        ),
                        const SizedBox(width: 10),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${_userProfile['user_prof_fname']} ${_userProfile['user_prof_lname']}',
                                    style: const TextStyle(
                                      color: Color(0xffFFFFFF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  _userProfile['application_status'] ==
                                          'APPROVED'
                                      ? const Icon(
                                          Icons.verified_rounded,
                                          color: Color(0xffFFFFFF),
                                          size: 18,
                                        )
                                      : const SizedBox.shrink(),
                                  const SizedBox(width: 6),
                                  Text(
                                    _averageRating != null
                                        ? '⭐ ${_averageRating!.toStringAsFixed(1)}'
                                        : '⭐ N/A', // Display the average rating
                                    style: const TextStyle(
                                      color: Color(0xffFFFFFF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _followerCount < 2
                                        ? '$_followerCount Follower'
                                        : '$_followerCount Followers',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xffFFFFFF),
                                      fontSize: 13,
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
                                  OutlinedButton(
                                    onPressed: () async {
                                      final token =
                                          await SecureStorage().getToken();
                                      if (token != null) {
                                        try {
                                          String message = await followProvider
                                              .toggleFollowing(widget.userId);
                                          setState(() {
                                            if (followProvider
                                                .isFollowing(widget.userId)) {
                                              _followerCount++;
                                            } else {
                                              _followerCount--;
                                            }
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(message)));
                                        } catch (error) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text('Error: $error')),
                                          );
                                        }
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Color(0xffFFFFFF), width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: const Size(0, 0),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                    ),
                                    child: Text(
                                      followProvider.isFollowing(widget.userId)
                                          ? 'Following'
                                          : 'Follow',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xffFFFFFF),
                                        fontSize: 12,
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
            SliverPersistentHeader(
                pinned: true,
                delegate: MySliverPersistentHeaderDelegate(
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
                      if (_isAssumptor)
                        Tab(child: Text('Listings', style: tabTextStyle)),
                      Tab(child: Text('Reviews', style: tabTextStyle)),
                    ],
                  ),
                )),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _getProfile,
          color: const Color(0xff4A8AF0),
          child: Container(
            padding: const EdgeInsets.all(10),
            child: TabBarView(
              children: [
                if (_isAssumptor)
                  (_listings == null)
                      ? const Center(child: Text('No Listing Data'))
                      : GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                            mainAxisExtent:
                                MediaQuery.of(context).size.width * .50,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _listings!.length,
                          itemBuilder: (context, index) {
                            final listing = _listings![index];

                            return ListingItem(
                              listing: listing,
                            );
                          },
                        ),
                buildRatingList(_reviews)
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

Widget buildRatingList(Future<List<dynamic>> futureRatings) {
  return FutureBuilder<List<dynamic>>(
    future: futureRatings,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Failed to load ratings: ${snapshot.error}'));
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text('No ratings available'));
      } else {
        return ListView.builder(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var rating = snapshot.data![index];
            var name = rating['name'] ?? 'Anonymous';
            var stars = (rating['rating'] ?? 0)
                .toInt(); // Convert rating to integer for stars
            var comment = rating['comment'] ?? 'No comment provided';

            return Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '★' * stars, // Display stars based on rating value
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    comment,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Divider(), // Add a divider for spacing
                ],
              ),
            );
          },
        );
      }
    },
  );
}

class MySliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  MySliverPersistentHeaderDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xffFFFCF1),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(MySliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
