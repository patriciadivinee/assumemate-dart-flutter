import 'dart:convert'; // for JSON decoding
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:assumemate/provider/favorite_provider.dart';
import 'package:assumemate/screens/item_detail_screen.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For accessing environment variables

class ListingItem extends StatefulWidget {
  final String title;
  final List<dynamic> imageUrl;
  final String description;
  final String listingId;
  final String
      assumptorId; // Assuming assumptorId is the user ID for profile fetching

  const ListingItem({
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.listingId,
    required this.assumptorId,
    super.key,
  });

  @override
  State<ListingItem> createState() => _ListingItemState();
}

class _ListingItemState extends State<ListingItem> {
  Map<String, dynamic>? userProfile; // Store user profile data
  bool isLoading = true; // For loading state
  bool isError = false; // For error state

  // Method to fetch user profile
  Future<void> fetchUserProfile(String assumptorId) async {
    final SecureStorage secureStorage = SecureStorage();
    String? token = await secureStorage.getToken(); // Retrieve the token

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/view/$assumptorId/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final profile = json.decode(response.body);
        setState(() {
          userProfile = profile['user_profile'];
          isLoading = false;
        });
        print(userProfile!['user_prof_pic']);
      } else {
        throw Exception(
            'Failed to load user profile: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error fetching user profile: $error');
      setState(() {
        isError = true;
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserProfile(widget
        .assumptorId); // Fetch the user profile when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider =
        Provider.of<FavoriteProvider>(context, listen: false);

    return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(
                listingId: widget.listingId,
                assumptorId: widget.assumptorId,
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
              // Listing image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrl.isNotEmpty
                      ? widget.imageUrl[0]
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
                  height: MediaQuery.of(context).size.width * 0.32,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.cover,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(5),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: isLoading
                          ? null // Display nothing while loading
                          : isError
                              ? const NetworkImage(
                                  'https://pbs.twimg.com/media/GV_AI3pawAA-fU3?format=jpg&name=4096x4096') // Error state placeholder
                              : NetworkImage(
                                  userProfile?['user_prof_pic'] ??
                                      'https://pbs.twimg.com/media/GV_AI3pawAA-fU3?format=jpg&name=4096x4096', // User's profile image
                                ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.description,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Consumer<FavoriteProvider>(
                      builder: (context, favoriteProvider, child) {
                        final isFavorited =
                            favoriteProvider.isFavorited(widget.listingId);

                        return GestureDetector(
                          onTap: () async {
                            final token = await SecureStorage().getToken();
                            if (token != null) {
                              try {
                                String message = await favoriteProvider
                                    .toggleFavorite(widget.listingId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)));
                              } catch (error) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $error')),
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
              ),
            ],
          ),
        ));
  }
}
