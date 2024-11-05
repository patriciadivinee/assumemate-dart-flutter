import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:assumemate/provider/favorite_provider.dart';
import 'dart:convert';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'item_detail_screen.dart'; // Import the ItemDetailScreen

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> favorites = [];
  final SecureStorage _secureStorage = SecureStorage();
  Map<int, String> userProfiles = {}; // Cache user profiles

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  Future<void> fetchFavorites() async {
    String? token = await _secureStorage.getToken();

    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/favorites/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      try {
        print('Favorites response: ${response.body}'); // Log the response
        List<dynamic> fetchedFavorites = json.decode(response.body);
        setState(() {
          favorites = fetchedFavorites;
        });
      } catch (e) {
        print('Error decoding favorites response: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected data format')),
        );
      }
    } else {
      print('Failed to load favorites: ${response.reasonPhrase}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load favorites')),
      );
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(int userId) async {
    String? token = await _secureStorage.getToken(); // Retrieve the token

    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/view/$userId/profile/'),
      headers: {
        'Authorization':
            'Bearer $token', // Include the token in the request headers
      },
    );

    print(
        'User Profile Response: ${response.statusCode} ${response.body}'); // Log the response

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          'Failed to load user profile: ${response.reasonPhrase}'); // Include the reason
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider = Provider.of<FavoriteProvider>(context);

    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xffFFFCF1),
          leading: IconButton(
            splashColor: Colors.transparent,
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.black,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text('Favorites')),
      body: favorites.isEmpty
          ? const Center(child: Text('No favorites yet!'))
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final favorite = favorites[index];
                print(favorite); // Log the current favorite item

                // Access the list_id and list_content correctly
                final listId = favorite['list_id'];
                final listContent =
                    listId != null ? listId['list_content'] : {};
                final title = listContent['title'] ?? 'No Title';
                final price = listContent['price']?.toString() ?? 'N/A';
                final images = listContent['images'] ?? [];
                final category = listContent['category']?.toString() ?? 'N/A';
                final listingId = listId['list_id']?.toString() ?? '';
                final assumptorId = listId['user_id'];

                // Initialize user full name
                String userFullName = userProfiles[assumptorId] ?? 'Loading...';

                // Fetch the user profile based on the assumptorId if it's not already cached
                if (assumptorId != null &&
                    !userProfiles.containsKey(assumptorId)) {
                  fetchUserProfile(assumptorId).then((profile) {
                    setState(() {
                      userProfiles[assumptorId] =
                          '${profile['user_prof_fname'] ?? ''} ${profile['user_prof_lname'] ?? ''}';
                    });
                  }).catchError((error) {
                    print('Error fetching user profile: $error');
                  });
                }

                // Check for empty listingId to prevent navigation errors
                if (listingId.isEmpty) {
                  print('Listing ID is empty for favorite: $favorite');
                  return SizedBox(); // Or any placeholder widget
                }

                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    title: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Price: $price\nPosted by: $userFullName ($category)', // Display the user's full name
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    leading: images.isNotEmpty
                        ? Image.network(
                            images[0],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image_not_supported);
                            },
                          )
                        : const Icon(Icons.image_not_supported),
                    trailing: favoriteProvider.isFavorited(listingId)
                        ? const Icon(
                            Icons.favorite,
                            color: Color(0xffFF0000),
                          )
                        : const Icon(
                            Icons.favorite_outline,
                            color: Colors.black,
                          ),
                    onTap: () async {
                      final token = await SecureStorage().getToken();
                      if (token != null) {
                        try {
                          String message =
                              await favoriteProvider.toggleFavorite(listingId);

                          if (message == 'Removed from favorites') {
                            setState(() {
                              favorites.removeAt(
                                  index); // Remove the unfavorited item from list
                            });
                          }

                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(message)));
                        } catch (error) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $error')),
                          );
                        }
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
