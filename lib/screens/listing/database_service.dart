import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class DatabaseService {
  final String? baseURL = dotenv.env['API_URL'];


  Future<void> addCoinsToWallet(int wallId, int coinsToAdd) async {
    final response = await http.patch(
      Uri.parse('$baseURL/wallet/$wallId/add-coins/'), // API endpoint to add coins
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'coins_to_add': coinsToAdd, // Coins to add
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add coins to wallet');
    }
  }

  Future<double> getTotalCoins(int wallId) async {
    final response = await http.get(
      Uri.parse('$baseURL/wallet/$wallId/total-coins/'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final String walletAmountString =
          data['wall_amnt']; // Assuming this is a string

      // Convert to int and handle errors
      final double walletAmount = double.tryParse(walletAmountString) ?? 0;

      return walletAmount;
    } else {
      throw Exception('Failed to fetch total coins');
    }
  }
}
