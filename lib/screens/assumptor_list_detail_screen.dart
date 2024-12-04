// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:assumemate/components/listing_item.dart';
import 'package:assumemate/format.dart';
import 'package:assumemate/provider/profile_provider.dart';
import 'package:assumemate/screens/listing/update_motor.dart';
import 'package:assumemate/screens/listing/update_car.dart';
import 'package:assumemate/screens/listing/update_restate.dart';
import 'package:assumemate/screens/chat_message_screen.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:flutter/material.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'listing/promote.dart';
import 'listing/listing_delete.dart';
import 'listing/listpayment.dart';

class AssumptorListDetailScreen extends StatefulWidget {
  final String listingId;

  const AssumptorListDetailScreen({super.key, required this.listingId});

  @override
  State<AssumptorListDetailScreen> createState() =>
      _AssumptorListDetailScreenState();
}

class _AssumptorListDetailScreenState extends State<AssumptorListDetailScreen> {
  final SecureStorage secureStorage = SecureStorage();
  late final PageController pageController;
  int pageNo = 0;
  bool isFav = false;
  ListingDetail? listingDetail; // Variable to hold the listing details
  String? assumptorId;
  String? _applicationStatus;
  String? listingStatus;
  bool _isUserValid = false;
  String? ToPay;
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
    pageController = PageController(initialPage: 0);
    fetchListingDetails(widget.listingId).then((details) {
      setState(() {
        listingDetail = details; // Assign the fetched details
      });
      isUser().then((isValidUser) {
        setState(() {
          _isUserValid = isValidUser; // Update the state variable
        });
      });
    });
  }

  Future<bool> isUser() async {
    _userId = await secureStorage.getUserId();
    // Compare assumptorId and _userId after ensuring they are of the same type
    return assumptorId.toString() ==
        _userId
            .toString(); // Assuming assumptorId is of type int, convert it to String
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
      final data = json.decode(response.body);
      setState(() {
        assumptorId = data['user_id'].toString();
        listingStatus = data['list_status'].toString();
        _applicationStatus =
            data['list_app_status'].toString(); // Add this line
        ToPay = data['has_active_listing'].toString();
      });
      print(data['user_id']);
      listingDetail = ListingDetail.fromJson(data);
      print('Listing details: $listingDetail');
      print(_applicationStatus);

      return ListingDetail.fromJson(data);
    } else {
      throw Exception('Failed to load listing details: ${response.statusCode}');
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

  Future<List<Map<String, String>>> fetchRejectedListings(
      String listingId) async {
    // Simulating network delay
    await Future.delayed(const Duration(seconds: 2));

    // Retrieve the token from secure storage
    final token = await secureStorage.getToken();

    // Prepare the API URL
    final apiUrl = Uri.parse('$baseURL/listings/rejected/$listingId/');

    // Make the API request with the token in the Authorization header
    final response = await http.get(
      apiUrl,
      headers: {
        'Authorization':
            'Bearer $token', // Include the token in the request header
      },
    );

    // Check if the response is successful
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Return the necessary information
      return [
        {
          'title':
              '${data['list_app_status']}: There are issues with your listing',
          'message': data['list_reason'] ?? 'No reason provided',
        },
      ];
    } else {
      // Handle error (optional: you can display the error message in the UI)
      throw Exception('Failed to load rejected listings');
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
    final profileProvider = Provider.of<ProfileProvider>(context);

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
                          if (listingDetail?.category == "Motorcycle" ||
                              listingDetail?.category == "Car") ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    style: const TextStyle(color: Colors.black),
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
                                    listingDetail?.formattedDownPayment != null
                                        ? formatCurrency(
                                            listingDetail!.reservation)
                                        : "Loading...",
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
                                    listingDetail?.formattedDownPayment != null
                                        ? '${listingDetail!.formattedDownPayment}'
                                        : "Loading...",
                                    style: const TextStyle(color: Colors.black),
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
                                    '${listingDetail?.formattedTotalPaymentMade ?? "N/A"}',
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
                                    listingDetail
                                                ?.formattedNumberOfMonthsPaid !=
                                            null
                                        ? '${listingDetail!.formattedNumberOfMonthsPaid}'
                                        : "Loading...",
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
                                    '${listingDetail?.formattedLoanDuration ?? "N/A"}',
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  const SizedBox(),
                                ],
                              ),
                              // Conditionally rendered rows based on the category
                              if (listingDetail?.category == "Real Estate") ...[
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
                                      style:
                                          const TextStyle(color: Colors.black),
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
                                      style:
                                          const TextStyle(color: Colors.black),
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
                                      style:
                                          const TextStyle(color: Colors.black),
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
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    const Text(
                                      'Parking Space:',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    const SizedBox(),
                                    Text(
                                      listingDetail?.parkingSpace ?? "N/A",
                                      style:
                                          const TextStyle(color: Colors.black),
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
                                      style:
                                          const TextStyle(color: Colors.black),
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
                                      style:
                                          const TextStyle(color: Colors.black),
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
                                backgroundImage: profileProvider
                                            .userProfile['user_prof_pic'] !=
                                        null
                                    ? NetworkImage(profileProvider
                                        .userProfile['user_prof_pic'])
                                    : AssetImage(
                                        'assets/images/no-profile.jpg'),
                                radius: 25,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${profileProvider.userProfile['user_prof_fname'] ?? ''} ${profileProvider.userProfile['user_prof_lname'] ?? ''}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _applicationStatus == 'REJECTED'
                              ? buildRejectListing(
                                  fetchRejectedListings(widget.listingId))
                              : const SizedBox.shrink(),
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
                    icon: const Icon(Icons.more_vert, color: Color(0xffFFFCF1)),
                    iconSize: 26,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    onSelected: (value) async {
                      if (value == 0) {
                        // Edit listing option
                        if (listingDetail != null) {
                          if (listingDetail!.category == 'Car' ||
                              listingDetail!.category == 'Motorcycle') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return listingDetail!.category == 'Car'
                                      ? CarForm(
                                          listingData: {
                                            'id': widget.listingId,
                                            'make': listingDetail!.make,
                                            'model': listingDetail!.model,
                                            'year': listingDetail!.year,
                                            'loanDuration':
                                                listingDetail!.loanDuration,
                                            'transmission':
                                                listingDetail!.transmission,
                                            'fuelType': listingDetail!.fuelType,
                                            'mileage': listingDetail!.mileage,
                                            'address': listingDetail!.address,
                                            'description':
                                                listingDetail!.description,
                                            'color': listingDetail!.color,
                                            'price':
                                                listingDetail!.price.toString(),
                                            'reservation': listingDetail!
                                                .reservation
                                                .toString(),
                                            'offer_allowed':
                                                listingDetail!.offer_allowed,
                                            'monthlyPayment': listingDetail!
                                                .monthlyPayment
                                                .toString(),
                                            'downPayment': listingDetail!
                                                .downPayment
                                                .toString(),
                                            'numberOfMonthsPaid': listingDetail!
                                                .numberOfMonthsPaid1,
                                            'images': listingDetail!.images,
                                            'documents':
                                                listingDetail!.documents,
                                            'totalpaymentmade':
                                                listingDetail!.totalPaymentMade,
                                            'preference':
                                                listingDetail!.preference,
                                          },
                                          isEditing: true,
                                        )
                                      : MotorForm(
                                          listingData: {
                                            'id': widget.listingId,
                                            'make': listingDetail!.make,
                                            'model': listingDetail!.model,
                                            'year': listingDetail!.year,
                                            'loanDuration':
                                                listingDetail!.loanDuration,
                                            'transmission':
                                                listingDetail!.transmission,
                                            'reservation': listingDetail!
                                                .reservation
                                                .toString(),
                                            'offer_allowed':
                                                listingDetail!.offer_allowed,
                                            'fuelType': listingDetail!.fuelType,
                                            'mileage': listingDetail!.mileage,
                                            'address': listingDetail!.address,
                                            'description':
                                                listingDetail!.description,
                                            'color': listingDetail!.color,
                                            'price':
                                                listingDetail!.price.toString(),
                                            'monthlyPayment': listingDetail!
                                                .monthlyPayment
                                                .toString(),
                                            'downPayment': listingDetail!
                                                .downPayment
                                                .toString(),
                                            'numberOfMonthsPaid': listingDetail!
                                                .numberOfMonthsPaid1,
                                            'images': listingDetail!.images,
                                            'documents':
                                                listingDetail!.documents,
                                            'totalpaymentmade':
                                                listingDetail!.totalPaymentMade,
                                            'preference':
                                                listingDetail!.preference,
                                          },
                                          isEditing: true,
                                        );
                                },
                              ),
                            );
                          } else if (listingDetail!.category == 'Real Estate') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return Restate(
                                    listingData: {
                                      'id': widget.listingId,
                                      'year': listingDetail!.year,
                                      'price': listingDetail!.price.toString(),
                                      'title': listingDetail!.title,
                                      'images': listingDetail!.images,
                                      'address': listingDetail!.address,
                                      'lotArea': listingDetail!.lotArea,
                                      'bedrooms': listingDetail!.bedrooms,
                                      'category': listingDetail!.category,
                                      'bathrooms': listingDetail!.bathrooms,
                                      'reservation':
                                          listingDetail!.reservation.toString(),
                                      'offer_allowed':
                                          listingDetail!.offer_allowed,
                                      'documents': listingDetail!.documents,
                                      'floorArea': listingDetail!.floorArea,
                                      'preference': listingDetail!.preference,
                                      'description': listingDetail!.description,
                                      'downPayment':
                                          listingDetail!.downPayment.toString(),
                                      'loanDuration': listingDetail!
                                          .loanDuration
                                          .toString(),
                                      'parkingSpace':
                                          listingDetail!.parkingSpace,
                                      'monthlyPayment': listingDetail!
                                          .monthlyPayment
                                          .toString(),
                                      'totalPaymentMade': listingDetail!
                                          .totalPaymentMade
                                          .toString(),
                                      'numberOfMonthsPaid':
                                          listingDetail!.numberOfMonthsPaid1,
                                    },
                                    isEditing: true,
                                  );
                                },
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Listing details are not available.')),
                          );
                        }
                      } else if (value == 1) {
                        // Archive listing logic
                        final deleteService = DeleteService();
                        await deleteService.deleteListing(
                            context, widget.listingId);
                      }
                    },
                    itemBuilder: (context) => [
                      if (_isUserValid &&
                          listingStatus == 'PENDING' &&
                          _applicationStatus == 'REJECTED')
                        const PopupMenuItem<int>(
                          value: 0, // Edit listing option
                          height: 25,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Edit listing',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              Icon(
                                Icons.mode_edit_outline_rounded,
                                color: Color(0xff4A8AF0),
                              ),
                            ],
                          ),
                        ),
                      const PopupMenuItem<int>(
                        value: 1, // Archive listing option
                        height: 25,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Archive listing',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Icon(
                              Icons.archive_outlined,
                              color: Color(0xff4A8AF0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_isUserValid &&
                      listingStatus == 'PENDING' &&
                      _applicationStatus == 'APPROVED' &&
                      ToPay == 'true')
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          // Call the PaymentService's processPayment method
                          await PaymentService().processPayment(
                            context,
                            widget.listingId,
                            50.0,
                          );
                        } catch (e) {
                          // Display error message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xffFFFCF1),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        backgroundColor: const Color(0xff4A8AF0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13),
                      ),
                      label: const Text(
                        'Pay',
                        style: TextStyle(
                          color: Color(0xffFFFCF1),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  const SizedBox(width: 20),
                  if (_isUserValid &&
                      listingStatus == 'ACTIVE' &&
                      _applicationStatus == 'APPROVED')
                    OutlinedButton.icon(
                      onPressed: () {
                        final promotionService = PromotionService();
                        promotionService.showPromotionOptions(
                            context, widget.listingId);
                      },
                      icon: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Color(0xff4A8AF0),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: const BorderSide(
                            color: Color(0xff4A8AF0), width: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 13),
                      ),
                      label: const Text(
                        'Promote now',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
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
  final String loanDuration;
  final String parkingSpace;
  final String address;
  final String make;
  final String model;
  final String transmission;
  final String mileage;
  final String fuelType;
  final String color;
  final String preference;
  final String year;

  String? lotArea;
  String? bedrooms;
  String? bathrooms;
  bool offer_allowed;
  String? floorArea;
  List<String>? documents;

  final double price;
  final double monthlyPayment;
  final double reservation;
  final int downPayment;
  final int totalPaymentMade;
  final int numberOfMonthsPaid;
  final int numberOfMonthsPaid1;

  ListingDetail(
      {required this.price,
      required this.reservation,
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
      required this.numberOfMonthsPaid1,
      required this.address,
      required this.make,
      required this.model,
      required this.color,
      required this.transmission,
      required this.mileage,
      required this.fuelType,
      required this.preference,
      required this.year,
      this.lotArea,
      this.bedrooms,
      this.bathrooms,
      this.floorArea,
      this.documents,
      required this.offer_allowed});

  factory ListingDetail.fromJson(Map<String, dynamic> json) {
    var content = json['list_content'] ?? {};

    double parsedMonthlyPayment =
        double.tryParse(content['monthlyPayment']?.toString() ?? '0') ?? 0;
    int parsedNumberOfMonthsPaid =
        int.tryParse(content['numberOfMonthsPaid']?.toString() ?? '0') ?? 0;

    print(content['loanDuration']!);

    double calculatedPrice = parsedMonthlyPayment * parsedNumberOfMonthsPaid;

    return ListingDetail(
        year: content['year']?.toString() ?? '0',

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
        images: List<String>.from(content['images'] ?? []),
        documents: List<String>.from(content['documents'] ?? []),
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
        numberOfMonthsPaid1:
            (content['numberOfMonthsPaid'] as num?)?.toInt() ?? 0,
        lotArea: content['lotArea']?.toString(),
        bedrooms: content['bedrooms']?.toString(),
        bathrooms: content['bathrooms']?.toString(),
        floorArea: content['floorArea']?.toString(),
        offer_allowed: content['offer_allowed'] ?? false,
        address: content['address']?.toString() ?? 'Unknown Location',
        //make: content['make:']?.toString() ?? 'Unknown make',
        make: content['make']?.toString() ?? 'Unknown make',
        model: content['model']?.toString() ?? 'Unknown model',
        transmission:
            content['transmission']?.toString() ?? 'Unknown transmission',
        mileage: content['mileage']?.toString() ?? 'Unknown mileage',
        fuelType: content['fuelType'].toString(),
        color: content['color']?.toString() ?? 'Unknown color',
        preference: content['preference'].toString());
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
              var content = listing['list_content'];
              var title;

              if (content['category'] == "Car" ||
                  content['category'] == "Motorcycle") {
                title =
                    '${content['model'] ?? 'Unknown model'} ${content['make'] ?? 'Unknown make'} ${content['year'] ?? 'Unknown year'}';
              } else if (content['category'] == "Real Estate") {
                title = content['title'] ?? 'No Title';
              } else {
                title = content['title'] ??
                    'No Title'; // Default case if category doesn't match
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

Widget buildRejectListing(
    Future<List<Map<String, String>>> futureRejectListing) {
  return FutureBuilder<List<Map<String, String>>>(
    future: futureRejectListing,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }

      if (snapshot.hasData && snapshot.data!.isEmpty) {
        return const Center(child: Text('No rejected listings found.'));
      }

      var rejectionData =
          snapshot.data![0]; // Getting the first item from the list

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 40,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rejectionData['title']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rejectionData['message']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
