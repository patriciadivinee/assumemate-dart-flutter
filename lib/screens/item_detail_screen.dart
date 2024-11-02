// ignore_for_file: deprecated_member_use

import 'dart:async';
// import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/provider/favorite_provider.dart';
import 'package:flutter/material.dart';
// import 'package:assumemate/screens/chat_message_screen.dart';
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
  String? _userType;
  String? _applicationStatus;

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
    fetchUserProfile(widget.assumptorId);
    pageController = PageController(initialPage: 0);
    fetchListingDetails(widget.listingId).then((details) {
      setState(() {
        listingDetail = details; // Assign the fetched details
      });
    });
  }

  Future<void> _getUserType() async {
    _userType = await secureStorage.getUserType();
    _applicationStatus = await secureStorage.getApplicationStatus();
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

      setState(() {
        assumptorId = data['user_id'].toString();
      });

      print(data['user_id']);
      print(data['list_id']);

      final listingDetails = ListingDetail.fromJson(data);
      print('Listing details: $listingDetails');

      return listingDetails;
    } else {
      throw Exception('Failed to load listing details: ${response.statusCode}');
    }
  }

  Future<void> fetchUserProfile(String assumptorId) async {
    final SecureStorage secureStorage = SecureStorage();
    String? token = await secureStorage.getToken(); // Retrieve the token

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/view/$assumptorId/profile/'),
        headers: {
          'Authorization':
              'Bearer $token', // Include the token in the request headers
        },
      );

      // print(
      //     'User Profile Response: ${response.statusCode} ${response.body}'); // Log the response

      if (response.statusCode == 200) {
        setState(() {
          userProfile = json.decode(response.body);
        });
      } else {
        throw Exception(
            'Failed to load user profile: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error getting user profile: $error');
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
                  Container(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Navigate to the new screen
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
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 15,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              listingDetail?.address ?? 'Loading...',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (listingDetail?.category == "Motorcycles" ||
                            listingDetail?.category == "Cars") ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Title: ${listingDetail?.make ?? "Loading..."} (${listingDetail?.model ?? "Unknown model"})',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Icon(
                                listingDetail?.category == "Cars"
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
                        if (listingDetail?.category == "House and Lot") ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Title: ${listingDetail?.title ?? "N/A"}',
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
                                      ? '${listingDetail!.price}'
                                      : "Loading...",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                const SizedBox(),
                              ],
                            ),
                            // Conditionally rendered rows based on the category
                            if (listingDetail?.category == "House and Lot") ...[
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
                                    style: const TextStyle(color: Colors.black),
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
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  const SizedBox(),
                                ],
                              ),
                              // Label: Lot Area
                              TableRow(
                                children: [
                                  const Text(
                                    'Lot Area:',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  const SizedBox(),
                                  Text(
                                    '${listingDetail?.lotArea ?? "N/A"} sq. ft.',
                                    style: const TextStyle(color: Colors.black),
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
                                    style: const TextStyle(color: Colors.black),
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
                                    listingDetail?.downPayment ?? "N/A",
                                    style: const TextStyle(color: Colors.black),
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
                                    '${listingDetail?.loanDuration ?? "N/A"} months',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  const SizedBox(),
                                ],
                              ),
                            ] else if (listingDetail?.category ==
                                    "Motorcycles" ||
                                listingDetail?.category == "Cars") ...[
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
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  const SizedBox(),
                                ],
                              ),
                            ],
                            // Common fields for both Motorcycles and Cars
                            TableRow(
                              children: [
                                const Text(
                                  'Monthly Payment:',
                                  style: TextStyle(color: Colors.black),
                                ),
                                const SizedBox(),
                                Text(
                                  listingDetail?.monthlyPayment != null
                                      ? '${listingDetail!.monthlyPayment}'
                                      : "Loading...",
                                  style: const TextStyle(color: Colors.black),
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
                                  '${listingDetail?.totalPaymentMade ?? "N/A"}',
                                  style: const TextStyle(color: Colors.black),
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
                                  listingDetail?.numberOfMonthsPaid != null
                                      ? '${listingDetail!.numberOfMonthsPaid}'
                                      : "Loading...",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                const SizedBox(),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                        Text(
                          'Description: ${listingDetail?.description ?? "Loading..."}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
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
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xffFFFCF1),
                        size: 30,
                      ),
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
        bottomNavigationBar: (_userType == 'assumee')
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                    decoration: const BoxDecoration(
                        color: Color(0xffFFFCF1),
                        border: Border(
                            top: BorderSide(color: Colors.black45),
                            left: BorderSide(color: Colors.black45))),
                    child: InkWell(
                      onTap: () {},
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.messenger_outline),
                          SizedBox(height: 2),
                          Text(
                            'Inquire',
                            style: TextStyle(fontSize: 14),
                          )
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
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
                          SizedBox(height: 2),
                          Text('Make offer', style: TextStyle(fontSize: 14))
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
                          } else {}
                        },
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet_rounded,
                                color: Color(0xffFFFCF1)),
                            SizedBox(height: 2),
                            Text('₱ 1,000,000 Buy',
                                style: TextStyle(
                                    color: Color(0xffFFFCF1), fontSize: 14))
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
  final String title;
  final List<String> images;
  final String category;
  final String description;
  final String downPayment;
  final String loanDuration;
  final String parkingSpace;
  final String address;
  final String make;
  final String model;
  final String color;

  // Optional fields for specific categories
  String? lotArea;
  String? bedrooms;
  String? bathrooms;
  String? floorArea;
  List<String>? documents;

  // Numerical fields
  final double price;
  final double monthlyPayment;
  final int totalPaymentMade;
  final int numberOfMonthsPaid;

  ListingDetail({
    required this.price,
    required this.title,
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
    this.lotArea,
    this.bedrooms,
    this.bathrooms,
    this.floorArea,
    this.documents,
  });

  factory ListingDetail.fromJson(Map<String, dynamic> json) {
    var content = json['list_content'] ?? {};

    // Parse price and monthly payment
    double parsedMonthlyPayment =
        double.tryParse(content['monthlyPayment']?.toString() ?? '0') ?? 0;
    int parsedNumberOfMonthsPaid =
        int.tryParse(content['numberOfMonthsPaid']?.toString() ?? '0') ?? 0;

    // Calculate price based on monthlyPayment * numberOfMonthsPaid
    double calculatedPrice = parsedMonthlyPayment * parsedNumberOfMonthsPaid;

    return ListingDetail(
      price: calculatedPrice > 0
          ? calculatedPrice
          : double.tryParse(content['price']?.toString() ?? '0') ?? 0,
      title: content['title']?.toString() ?? 'Untitled',
      images: List<String>.from(content['images'] ?? []),
      category: content['category']?.toString() ?? 'Uncategorized',
      description:
          content['description']?.toString() ?? 'No description available',
      downPayment: content['downPayment']?.toString() ?? '0',
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
      make: content['make']?.toString() ?? 'Unknown make',
      model: content['model']?.toString() ?? 'Unknown model',
      color: content['color']?.toString() ?? 'Unknown color',
    );
  }

  Color? extractColor() {
    // if (color == null) return null;
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

Future<void> offerDialog(BuildContext context, String listId) async {
  final ApiService apiService = ApiService();
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>(); // Create a form key
  final TextEditingController offerController = TextEditingController();

  Future<void> makeOffer() async {
    // final token = await secureStorage.getToken();
    final response =
        await apiService.makeOffer(listId, double.parse(offerController.text));

    if (response == 'success') {
      // return ChatMessageScreen(receiverId: '2', name: name, picture: picture);
      popUp(context, 'Offer sent!', align: TextAlign.center);
    } else {
      popUp(context, response);
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
                  hintText: 'Amount',
                  hoverColor: Color(0xff4A8AF0),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Color(0xff4A8AF0),
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly, // Allow only digits
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
