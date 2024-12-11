// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:assumemate/components/listing_item.dart';
import 'package:assumemate/format.dart';
import 'package:assumemate/provider/usertype_provider.dart';
import 'package:assumemate/screens/chat_message_screen.dart';
import 'package:assumemate/screens/other_profile_screen.dart';
import 'package:assumemate/screens/profile_screen.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/provider/favorite_provider.dart';
import 'package:flutter/material.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ItemDetailScreen extends StatefulWidget {
  final String listingId;
  final String assumptorId;

  const ItemDetailScreen(
      {super.key, required this.listingId, required this.assumptorId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final SecureStorage secureStorage = SecureStorage();
  late final PageController pageController;
  int pageNo = 0;
  bool isFav = false;
  ListingDetail? listingDetail; // Variable to hold the listing details
  String? assumptorId;
  String? _applicationStatus;
  String? _userId;

  Map<String, dynamic>? userProfile;
  final ApiService apiService = ApiService();
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>(); // Create a form key
  // final TextEditingController offerController = TextEditingController();

  final String? baseURL = dotenv.env['API_URL'];

  @override
  void initState() {
    super.initState();

    _getUserType();
    fetchUserProfile();
    pageController = PageController(initialPage: 0);
    fetchListingDetails(widget.listingId).then((details) {
      setState(() {
        listingDetail = details; // Assign the fetched details
      });
    });
  }

  Future<void> _getUserType() async {
    _applicationStatus = await secureStorage.getApplicationStatus();
    _userId = await secureStorage.getUserId();
  }

  Future<ListingDetail> fetchListingDetails(String listingId) async {
    if (listingId.isEmpty) {
      throw Exception('Listing ID cannot be empty');
    }
    final token = await secureStorage.getToken();
    final apiUrl = Uri.parse('$baseURL/listings/details/$listingId/');
    final response = await http.get(
      apiUrl,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      // Ensure correct decoding
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      final listingDetails = ListingDetail.fromJson(data);

      return listingDetails;
    } else {
      throw Exception('Failed to load listing details: ${response.statusCode}');
    }
  }

  Future<void> fetchUserProfile() async {
    final SecureStorage secureStorage = SecureStorage();
    String? token = await secureStorage.getToken(); // Retrieve the token

    try {
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['API_URL']}/view/${widget.assumptorId}/profile/'),
        headers: {
          'Authorization':
              'Bearer $token', // Include the token in the request headers
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          userProfile = json
              .decode(response.body)['user_profile']; // Access 'user_profile'
        });
      } else {
        throw Exception(
            'Failed to load user profile: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error getting user profile: $error');
    }
  }

  Future<List<dynamic>> fetchRandomListings() async {
    final token = await secureStorage.getToken();
    if (token == null) throw Exception('Token is null');

    try {
      final apiUrl = Uri.parse('$baseURL/random/listings/');
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('Fetched Data: $data'); // Debugging output
        if (data is List) {
          return data
              .where((item) => item != null)
              .toList(); // Filter null items
        } else {
          throw Exception('Failed to parse listings');
        }
      } else {
        throw Exception('Failed to load listings');
      }
    } catch (e) {
      print('Error: $e'); // Debugging output
      throw Exception('Failed to load listings');
    }
  }

  void _openFullScreenImage(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => FullScreenImageViewer(
        images: listingDetail?.images ?? [], // Pass your images list
        initialIndex: initialIndex, // Pass the tapped image index
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);
    final userType = Provider.of<UserProvider>(context).userType;

    // Show a loading indicator if listingDetail is still null
    if (listingDetail == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        body: SafeArea(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 280,
                    child: PageView.builder(
                      controller: pageController,
                      onPageChanged: (index) {
                        setState(() {
                          pageNo = index;
                        });
                      },
                      itemCount: listingDetail?.images.length ?? 0,
                      itemBuilder: (_, index) {
                        return GestureDetector(
                          onTap: () {
                            // When image is tapped, open the full-screen image viewer
                            _openFullScreenImage(context, index);
                          },
                          child: Container(
                            color: Colors.grey,
                            child: Image.network(
                              listingDetail?.images[index] ?? '',
                              width: double.infinity,
                              fit: BoxFit.cover,
                              height: 280,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                      child: Text('Image not available')),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Details section
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // GestureDetector(
                            //   onTap: () {
                            //     Navigator.push(
                            //       context,
                            //       MaterialPageRoute(
                            //         builder: (context) =>
                            //             _userId == widget.assumptorId
                            //                 ? ProfileScreen()
                            //                 : OtherProfileScreen(
                            //                     userId: widget.assumptorId,
                            //                   ),
                            //       ),
                            //     );
                            //   },
                            //   child: Text(
                            //     userProfile != null
                            //         ? '${userProfile?['user_prof_fname'] ?? ''} ${userProfile?['user_prof_lname'] ?? ''}'
                            //         : "Loading...",
                            //     style: const TextStyle(
                            //       color: Colors.black,
                            //       fontSize: 20,
                            //       fontWeight: FontWeight.bold,
                            //     ),
                            //   ),
                            // ),
                            if (listingDetail?.category == "Motorcycle" ||
                                listingDetail?.category == "Car") ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${listingDetail?.make ?? "Loading..."} (${listingDetail?.model ?? "Unknown model"}) - ${listingDetail?.transmission ?? "Unknown transmission"}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    listingDetail?.category == "Car"
                                        ? Icons.directions_car
                                        : Icons.motorcycle,
                                    size: 24,
                                    color: listingDetail?.color != null
                                        ? listingDetail!.extractColor() ??
                                            Colors.black
                                        : Colors.black,
                                  ),
                                ],
                              ),
                            ],
                            if (listingDetail?.category == "Real Estate") ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${listingDetail?.title ?? "N/A"}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 17,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.house,
                                    size: 24,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Aligns the icon and text at the top
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 15,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  // Allows text to wrap within available space
                                  child: Text(
                                    listingDetail?.address ?? 'Loading...',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w200,
                                      fontSize: 10,
                                    ),
                                    softWrap:
                                        true, // Enables wrapping of text to the next line
                                    overflow: TextOverflow
                                        .clip, // Prevents text from being cut off
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Text(
                              'Details (${listingDetail?.category ?? "Loading..."}):',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),

                            // Title Section
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(3), // Label column
                                1: FlexColumnWidth(1), // Space column
                                2: FlexColumnWidth(3), // Value column
                                3: FlexColumnWidth(1), // Space column
                              },
                              children: [
                                TableRow(
                                  children: [
                                    const Text(
                                      'Price:',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                    Text(
                                      listingDetail?.price != null
                                          ? '${listingDetail!.formattedPrice}'
                                          : "Loading...",
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                  ],
                                ),

                                TableRow(
                                  children: [
                                    const Text(
                                      'Reservation Amount:',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                    Text(
                                      listingDetail?.formattedDownPayment !=
                                              null
                                          ? formatCurrency(
                                              listingDetail!.reservation)
                                          : "Loading...",
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                  ],
                                ),

                                // Label: Down Payment
                                TableRow(
                                  children: [
                                    const Text(
                                      'Down Payment:',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                    Text(
                                      listingDetail?.formattedDownPayment !=
                                              null
                                          ? '${listingDetail!.formattedDownPayment}'
                                          : "Loading...",
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                  ],
                                ),
                                // Common fields for both Motorcycles and Cars
                                TableRow(
                                  children: [
                                    const Text(
                                      'Monthly Payment:',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                    Text(
                                      listingDetail?.formattedMonthlyPayment !=
                                              null
                                          ? '${listingDetail!.formattedMonthlyPayment}'
                                          : "Loading...",
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const Text(
                                      'Total Payment Made:',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                    Text(
                                      '${listingDetail?.formattedTotalPaymentMade ?? "N/A"}',
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const Text(
                                      'No. of Months Paid:',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                    Text(
                                      listingDetail
                                                  ?.formattedNumberOfMonthsPaid !=
                                              null
                                          ? '${listingDetail!.formattedNumberOfMonthsPaid}'
                                          : "Loading...",
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                  ],
                                ),
                                // Label: Loan Duration
                                TableRow(
                                  children: [
                                    const Text(
                                      'Loan Duration:',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                    Text(
                                      '${listingDetail?.formattedLoanDuration ?? "N/A"}',
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                  ],
                                ),
                                // Conditionally rendered rows based on the category
                                if (listingDetail?.category ==
                                    "Real Estate") ...[
                                  //Lot Area
                                  TableRow(
                                    children: [
                                      const Text(
                                        'Lot Area:',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      const SizedBox(),
                                      Text(
                                        '${listingDetail?.lotArea ?? "N/A"} sq. ft.',
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                      const SizedBox(),
                                    ],
                                  ),
                                  // Label: Floor Area
                                  TableRow(
                                    children: [
                                      const Text(
                                        'Floor Area:',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      const SizedBox(),
                                      Text(
                                        '${listingDetail?.floorArea ?? "N/A"} sq. ft.',
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                      const SizedBox(),
                                    ],
                                  ),
                                  // Label: Bedrooms
                                  TableRow(
                                    children: [
                                      const Text(
                                        'Bedrooms:',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      const SizedBox(),
                                      Text(
                                        listingDetail?.bedrooms ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                      const SizedBox(),
                                    ],
                                  ),
                                  // Label: Bathrooms
                                  TableRow(
                                    children: [
                                      const Text(
                                        'Bathrooms:',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      const SizedBox(),
                                      Text(
                                        listingDetail?.bathrooms ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                      const SizedBox(),
                                    ],
                                  ),
                                ] else if (listingDetail?.category ==
                                        "Motorcycle" ||
                                    listingDetail?.category == "Car") ...[
                                  TableRow(
                                    children: [
                                      const Text(
                                        'Mileage:',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      const SizedBox(),
                                      Text(
                                        listingDetail?.mileage ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                      const SizedBox(),
                                    ],
                                  ),

                                  TableRow(
                                    children: [
                                      const Text(
                                        'Fuel Type:',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      const SizedBox(),
                                      Text(
                                        listingDetail?.fuelType ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                      const SizedBox(),
                                    ],
                                  ),
                                  // Label: Parking Space
                                  TableRow(
                                    children: [
                                      const Text(
                                        'Parking Space:',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      const SizedBox(),
                                      Text(
                                        listingDetail?.parkingSpace ?? "N/A",
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                      const SizedBox(),
                                    ],
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 30),
                            SingleChildScrollView(
                              child: Text(
                                'Description: ${listingDetail?.description ?? "Loading..."}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: null, // Allows unlimited lines
                                overflow:
                                    TextOverflow.visible, // Prevents truncation
                              ),
                            ),

                            const SizedBox(height: 20),

                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage:
                                      userProfile?['user_prof_pic'] != null
                                          ? NetworkImage(
                                              userProfile?['user_prof_pic'])
                                          : AssetImage(
                                              'assets/images/no-profile.jpg'),
                                  radius: 25,
                                  backgroundColor:
                                      Colors.grey[300], // Fallback color
                                  child: userProfile?['user_prof_pic'] == null
                                      ? Icon(Icons.person,
                                          size: 25, color: Colors.white)
                                      : null, // Fallback icon if no image is provided
                                ),
                                const SizedBox(
                                    width:
                                        10), // Adds spacing between the avatar and the text
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            _userId == widget.assumptorId
                                                ? ProfileScreen()
                                                : OtherProfileScreen(
                                                    userId: widget.assumptorId,
                                                  ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    userProfile != null
                                        ? '${userProfile?['user_prof_fname'] ?? ''} ${userProfile?['user_prof_lname'] ?? ''}'
                                        : "Loading...",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            // Styling the section title text
                            const Text(
                              'More Listings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors
                                    .black87, // Slightly muted color for readability
                                letterSpacing:
                                    0.5, // Adds spacing for a cleaner look
                                shadows: [
                                  Shadow(
                                    // Adds a subtle shadow for depth
                                    blurRadius: 2.0,
                                    color: Colors.grey,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            buildSuggestionsList(fetchRandomListings()),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Page indicators
              Positioned(
                top: 260,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    listingDetail?.images.length ?? 0,
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
              ),
              // Top action bar
              Positioned(
                top: 10,
                right: 10,
                left: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Color(0xffFFFCF1),
                        size: 24,
                      ),
                    ),
                    PopupMenuButton<int>(
                      color: const Color(0xffFCFCFC),
                      icon:
                          const Icon(Icons.more_vert, color: Color(0xff4A8AF0)),
                      iconSize: 26,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
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
              ),
              // Favorite icon
              Positioned(
                right: 20,
                top: 260,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0xffFFFCF1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () async {
                      final token = await SecureStorage()
                          .getToken(); // Retrieve the user's token
                      if (token != null) {
                        await favoriteProvider.toggleFavorite(
                            widget.listingId); // Pass the token and listingId
                      }
                    },
                    icon: favoriteProvider.isFavorited(widget.listingId)
                        ? const Icon(
                            Icons.favorite,
                            color: Color(0xffFF0000),
                          )
                        : const Icon(
                            Icons.favorite_outline,
                            color: Colors.black,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: (userType == 'assumee' &&
                listingDetail?.status == 'ACTIVE')
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 18),
                    decoration: const BoxDecoration(
                        color: Color(0xffFFFCF1),
                        border: Border(
                            top: BorderSide(color: Colors.black45),
                            left: BorderSide(color: Colors.black45))),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ChatMessageScreen(
                            receiverId: widget.assumptorId,
                          ),
                        ));
                      },
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.messenger_outline),
                          Text(
                            'Inquire',
                            style: TextStyle(fontSize: 12),
                          )
                        ],
                      ),
                    ),
                  ),
                  if (listingDetail?.offerAllowed == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 5, horizontal: 20),
                      decoration: const BoxDecoration(
                        color: Color(0xffFFFCF1),
                        border: Border(
                            top: BorderSide(color: Colors.black45),
                            left: BorderSide(color: Colors.black45)),
                      ),
                      child: InkWell(
                        splashColor: Colors.black45,
                        onTap: () {
                          if (_applicationStatus == 'PENDING') {
                            popUp(context,
                                'You need to be verified to make an offer');
                          } else {
                            offerDialog(context, widget.listingId);
                          }
                        },
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_offer_outlined),
                            Text('Make offer', style: TextStyle(fontSize: 12))
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      decoration: const BoxDecoration(
                          color: Color(0xff4A8AF0),
                          border: Border(
                            top: BorderSide(color: Color(0xff4A8AF0)),
                          )),
                      child: InkWell(
                        splashColor: Colors.black12,
                        onTap: () {
                          if (_applicationStatus == 'PENDING') {
                            popUp(context,
                                'You need to be verified to buy this list');
                          } else {
                            showBuyConfirmation(
                              context,
                              _userId!,
                              widget.listingId,
                              listingDetail!.reservation,
                            );
                          }
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet_rounded,
                                color: Color(0xffFFFCF1)),
                            Text('${formatCurrency(listingDetail!.price)} Buy',
                                style: TextStyle(
                                    color: Color(0xffFFFCF1), fontSize: 12))
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              )
            : const SizedBox.shrink());
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  FullScreenImageViewer({required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(0),
      child: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Close the full-screen image viewer when the image is tapped
              Navigator.of(context).pop();
            },
            child: InteractiveViewer(
              child: Image.network(
                images[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

class ListingDetail {
  final String status;
  final String title;
  final bool offerAllowed;
  final List<String> images;
  final String category;
  final String description;
  final String loanDuration;
  final String parkingSpace;
  final String address;
  final String make;
  final String model;
  final String transmission;
  final String mileage;
  final String fuelType;
  final String color;

  String? lotArea;
  String? bedrooms;
  String? bathrooms;
  String? floorArea;
  List<String>? documents;

  final double price;
  final double monthlyPayment;
  final double reservation;
  final int downPayment;
  final int totalPaymentMade;
  final int numberOfMonthsPaid;

  ListingDetail({
    required this.status,
    required this.price,
    required this.reservation,
    required this.title,
    required this.offerAllowed,
    required this.images,
    required this.category,
    required this.description,
    required this.downPayment,
    required this.loanDuration,
    required this.parkingSpace,
    required this.monthlyPayment,
    required this.totalPaymentMade,
    required this.numberOfMonthsPaid,
    required this.address,
    required this.make,
    required this.model,
    required this.color,
    required this.transmission,
    required this.mileage,
    required this.fuelType,
    this.lotArea,
    this.bedrooms,
    this.bathrooms,
    this.floorArea,
    this.documents,
  });

  factory ListingDetail.fromJson(Map<String, dynamic> json) {
    var content = json['list_content'] ?? {};

    double parsedMonthlyPayment =
        double.tryParse(content['monthlyPayment']?.toString() ?? '0') ?? 0;
    int parsedNumberOfMonthsPaid =
        int.tryParse(content['numberOfMonthsPaid']?.toString() ?? '0') ?? 0;

    return ListingDetail(
      status: json['list_status'],
      // price: calculatedPrice > 0
      //     ? calculatedPrice
      //     : double.tryParse(content['price']?.toString() ?? '0') ?? 0,
      price: (content['price'] is String)
          ? double.tryParse(content['price']) ?? 0
          : (content['price'] is int)
              ? (content['price'] as int).toDouble()
              : (content['price'] as double?) ?? 0,
      reservation:
          double.tryParse(content['reservation']?.toString() ?? '0') ?? 0,
      title: content['title']?.toString() ?? 'Untitled',
      offerAllowed: content['offer_allowed'] ?? false,
      images: List<String>.from(content['images'] ?? []),
      category: content['category']?.toString() ?? 'Uncategorized',
      description:
          content['description']?.toString() ?? 'No description available',
      downPayment: (content['downPayment'] is String)
          ? int.tryParse(content['downPayment']) ?? 0
          : (content['downPayment'] as num?)?.toInt() ?? 0,
      loanDuration: content['loanDuration']?.toString() ?? '0 months',
      parkingSpace: content['parkingSpace']?.toString() ?? '0',
      monthlyPayment: parsedMonthlyPayment,
      totalPaymentMade: (content['totalPaymentMade'] as num?)?.toInt() ?? 0,
      numberOfMonthsPaid: parsedNumberOfMonthsPaid,
      lotArea: content['lotArea']?.toString(),
      bedrooms: content['bedrooms']?.toString(),
      bathrooms: content['bathrooms']?.toString(),
      floorArea: content['floorArea']?.toString(),
      address: content['address']?.toString() ?? 'Unknown Location',
      //make: content['make:']?.toString() ?? 'Unknown make',
      make: content['make']?.toString() ?? 'Unknown make',
      model: content['model']?.toString() ?? 'Unknown model',
      transmission:
          content['transmission']?.toString() ?? 'Unknown transmission',
      mileage: content['mileage']?.toString() ?? 'Unknown mileage',
      fuelType: content['fuelType'].toString(),
      color: content['color']?.toString() ?? 'Unknown color',
    );
  }

  static String convertMonthsToYears(int months) {
    int years = months ~/ 12;
    int remainingMonths = months % 12;

    String yearPart = years > 0 ? "$years year${years > 1 ? 's' : ''}" : "";
    String monthPart = remainingMonths > 0
        ? "$remainingMonths month${remainingMonths > 1 ? 's' : ''}"
        : "";

    // Combine the parts with a comma if both parts are present
    if (yearPart.isNotEmpty && monthPart.isNotEmpty) {
      return "$yearPart, $monthPart";
    } else {
      return yearPart + monthPart; // Return whichever part is not empty
    }
  }

  String get formattedPrice => formatCurrency(price);
  String get formattedMonthlyPayment => formatCurrency(monthlyPayment);
  String get formattedTotalPaymentMade =>
      formatCurrency(totalPaymentMade.toDouble());
  String get formattedDownPayment => formatCurrency(downPayment.toDouble());
  String get formattedNumberOfMonthsPaid =>
      convertMonthsToYears(numberOfMonthsPaid);
  String get formattedLoanDuration =>
      convertMonthsToYears(int.parse(loanDuration));

  Color? extractColor() {
    // ignore: unnecessary_null_comparison
    if (color == null) return null;
    final regex = RegExp(r'Color\(0xff([0-9a-fA-F]+)\)');
    final match = regex.firstMatch(color);
    if (match != null) {
      final hexString = match.group(1);
      if (hexString != null) {
        return Color(int.parse('0xff$hexString'));
      }
    }
    return null;
  }
}

Future<void> showBuyConfirmation(
    BuildContext context, String id, String listId, double reservation) async {
  final ApiService apiService = ApiService();

  Future<void> buyNow() async {
    try {
      final response = await apiService.createOrder(
          id, null, listId, reservation.toString());

      print(response);

      if (response.containsKey('message')) {
        Navigator.of(context).pop();
        popUp(context, 'Order sent');
      } else {
        popUp(context, response['error']);
        return;
      }
    } catch (e) {
      popUp(context, 'Error accepting offer');
    }
  }

  return showDialog(
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
                'Accept and reserve offer?',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 8),
              Text(
                'Do you wish to accept offer with reservation amount of ${formatCurrency(reservation)}?',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
                  onPressed: () => buyNow(),
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
      });
}

Future<void> offerDialog(BuildContext context, String listId) async {
  final ApiService apiService = ApiService();
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>(); // Create a form key
  final TextEditingController offerController = TextEditingController();

  Future<void> makeOffer() async {
    final amount = offerController.text;
    try {
      final response = await apiService.makeOffer(
          listId, double.parse(amount.replaceAll(',', '')));

      print(response);

      if (response.containsKey('user_id')) {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ChatMessageScreen(
                  receiverId: response['user_id'].toString(),
                )));
        // return ChatMessageScreen(receiverId: response['user_id'], chatroomId: response['room_id']);
        // popUp(context, 'Offer sent!', align: TextAlign.center);
      } else {
        popUp(context, response['error']);
      }
    } catch (e) {
      popUp(context, 'Error occured: $e');
    }
  }

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        titlePadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 17),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        title: const Center(
          child: Text(
            'Enter offer amount',
            style: TextStyle(color: Color(0xff4A8AF0), fontSize: 20),
          ),
        ),
        content: Form(
          key: formKey, // Assign the form key
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                cursorColor: const Color(0xff4A8AF0),
                controller: offerController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(0),
                  hintText: '\u20B10.00',
                  hoverColor: Color(0xff4A8AF0),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xff4A8AF0),
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyTextInputFormatter.currency(
                      locale: 'en_PH', decimalDigits: 2, symbol: '')
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  // Optional: Add custom validation logic for the amount (e.g., must be positive number)
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context)
                  .pop(); // Close the dialog when 'Cancel' is pressed
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xff4A8AF0)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                // Perform action if the form is valid
                makeOffer();
                Navigator.of(context).pop(); // Close the dialog
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff4A8AF0),
            ),
            child: const Text(
              'Offer',
              style: TextStyle(color: Color(0xffFFFCF1)),
            ),
          ),
        ],
      );
    },
  );
}

Widget buildSuggestionsList(Future<List<dynamic>> futureListings) {
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
        return Container(
          height: 1000, // Set a fixed height that fits your layout
          child: GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Number of items per row
              crossAxisSpacing: 5, // Spacing between columns
              mainAxisSpacing: 5, // Spacing between rows
              mainAxisExtent: MediaQuery.of(context).size.width * .50,
            ),
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling
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
          ),
        );
      }
    },
  );
}
