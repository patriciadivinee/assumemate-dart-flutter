import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:assumemate/storage/secure_storage.dart';

class FavoriteProvider with ChangeNotifier {
  List<String> _favoriteIds = [];
  int _faveCount = 0;
  final SecureStorage secureStorage = SecureStorage();
  String _token = '';

  List<String> get favoriteIds => _favoriteIds;
  int get faveCount => _faveCount;
  String get token => _token;

  Future<void> initializeFave() async {
    _token = await secureStorage.getToken() ?? '';
    print('Token: $_token');
    // clearFavorites();r

    // print('_token');
    // print(_token);

    if (_token.isNotEmpty) {
      await fetchFavorites();
    }
  }

  // Method to fetch favorites from the server
  Future<void> fetchFavorites() async {
    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/favorites/'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> favoritesData = json.decode(response.body);

      // Extract 'list_id' from the nested 'list_id' object in FavoriteSerializer
      _favoriteIds = favoritesData
          .map((favorite) => favorite['list_id'].toString())
          .toList();
      // Notify the UI of the changes
      _faveCount = _favoriteIds.length;
    } else {
      throw Exception('Failed to load favorites');
    }
  }

  Future<String> toggleFavorite(String listingId) async {
    _token = await secureStorage.getToken() ?? '';
    if (isFavorited(listingId)) {
      final response = await http.delete(
        Uri.parse('${dotenv.env['API_URL']}/favorites/remove/'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'list_id': listingId}),
      );

      if (response.statusCode == 200) {
        _favoriteIds.remove(listingId);
        _faveCount = _favoriteIds.length;
        notifyListeners();

        return 'Removed from favorites';
      } else {
        print('Failed to remove from favorites: ${response.reasonPhrase}');
        notifyListeners();

        return 'Failed to remove from favorites';
      }
    } else {
      final url = '${dotenv.env['API_URL']}/favorites/add/';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'listing_id': listingId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _favoriteIds.add(listingId);

        _faveCount = _favoriteIds.length;
        notifyListeners();
        return 'Added to favorites';
      } else {
        notifyListeners();

        return 'Already in Favorites';
      }
    }
  }

  bool isFavorited(String listingId) {
    return _favoriteIds.contains(listingId);
  }

  void clearFavorites() {
    _favoriteIds.clear();
    _faveCount = 0;
    notifyListeners();
  }
}
