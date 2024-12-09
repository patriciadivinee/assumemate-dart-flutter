import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:assumemate/storage/secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

final String? baseURL = dotenv.env['API_URL'];

String formatDate(DateTime date) {
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  return formatter.format(date);
}

Future<String> imageToBase64(File imageFile) async {
  List<int> imageBytes = await imageFile.readAsBytes();
  return base64Encode(imageBytes);
}

class ApiService {
  final SecureStorage secureStorage = SecureStorage();

  Future<Map<String, dynamic>> emailVerification(String email) async {
    final apiUrl = Uri.parse('$baseURL/email-verification/');

    final Map<String, dynamic> userEmail = {
      'user_verification_email': email,
    };

    try {
      final response = await http.post(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(userEmail),
      );

      if (response.statusCode == 200) {
        return {'success': 'success'};
      } else if (response.statusCode == 400) {
        final responseBody = jsonDecode(response.body);
        return {'error': responseBody[0]};
      } else if (response.statusCode == 503) {
        return {'error': 'Server unavailable. Please try again later.'};
      } else {
        return {
          'error':
              'Failed to send verification email. Status code: ${response.statusCode}'
        };
      }
    } catch (e) {
      if (e.toString().contains('Connection refused')) {
        return {
          'error':
              'Unable to connect to the server. Please check your connection.'
        };
      } else {
        return {'error': 'Error sending email verification: $e'};
      }
    }
  }

  Future<Map<String, dynamic>> registerUser(
      String email,
      String? password,
      String? googleId,
      String role,
      String fname,
      String lname,
      String gender,
      DateTime dob,
      String mobnum,
      String address,
      File validID,
      File picture) async {
    final regAPI = Uri.parse('$baseURL/user-register/');

    String validIDBase64 = await imageToBase64(validID);
    String picBase64 = await imageToBase64(picture);

    print(validIDBase64);
    print(picBase64);

    bool isAssumee = false;
    bool isAssumptor = false;

    if (role == 'assumee') {
      isAssumee = true;
    } else if (role == 'assumptor') {
      isAssumptor = true;
    }

    final Map<String, dynamic> userReg = {
      'email': email,
      'is_assumee': isAssumee,
      'is_assumptor': isAssumptor,
      'profile': {
        'user_prof_fname': fname,
        'user_prof_lname': lname,
        'user_prof_gender': gender,
        'user_prof_dob': formatDate(dob),
        'user_prof_mobile': mobnum,
        'user_prof_address': address,
        'user_prof_valid_id': validIDBase64,
        'user_prof_valid_pic': picBase64,
      }
    };

    // print()

    if (password != null && password.isNotEmpty) {
      userReg['password'] = password;
    }

    if (googleId != null && googleId.isNotEmpty) {
      userReg['google_id'] = googleId;
    }

    try {
      final response = await http.post(
        regAPI,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(userReg),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print(responseData);

        final user = responseData['user'];
        String userId = user['id'].toString();
        await secureStorage.storeUserId(userId);

        if (user['is_assumptor'] == true) {
          await secureStorage.storeUserType('assumptor');
        } else if (user['is_assumee'] == true) {
          await secureStorage.storeUserType('assumee');
        }

        String token = responseData['access'] ?? '';
        String refreshToken = responseData['refresh'] ?? '';
        await secureStorage.storeToken(token);
        await secureStorage.storeRefreshToken(refreshToken);
        await secureStorage.storeApplicationStatus('PENDING');

        return {'profile': responseData['user'], 'credential': responseData};
      } else {
        var responseBody = jsonDecode(response.body);
        print(responseBody);
        if (responseBody.containsKey('profile')) {
          return {
            'error':
                'User registration failed. ${responseBody['profile']['error'][0]}'
          };
        }

        return {'error': 'User registration failed. ${responseBody['error']}'};
      }
    } catch (e) {
      if (e.toString().contains('Connection refused')) {
        return {
          'error':
              'Unable to connect to the server. Please check your connection.'
        };
      } else {
        return {'error': 'Registration exception: ${e.toString()}}'};
      }
    }
  }

  Future<Map<String, dynamic>> loginUser(
      String? token, String? email, String? password) async {
    final apiUrl = Uri.parse('$baseURL/login/');

    final Map<String, dynamic> loginData = {};

    if (email != null && email.isNotEmpty) {
      loginData['email'] = email;
    }

    if (password != null && password.isNotEmpty) {
      loginData['password'] = password;
    }

    if (token != null && token.isNotEmpty) {
      loginData['token'] = token;
    }

    try {
      final response = await http.post(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(loginData),
      );

      final responseData = jsonDecode(response.body);

      print(responseData);

      if (response.statusCode == 200) {
        String token = responseData['access'] ?? '';
        String refreshToken = responseData['refresh'] ?? '';
        await secureStorage.storeToken(token);
        await secureStorage.storeRefreshToken(refreshToken);

        if (responseData.containsKey('user')) {
          final appStatus = responseData['user']['is_approved'];
          await secureStorage.storeApplicationStatus(appStatus);
          final userId = responseData['user']['user_id'].toString();
          await secureStorage.storeUserId(userId);
        }

        if (responseData.containsKey('user_role')) {
          final userRole = responseData['user_role'];
          if (userRole['is_assumptor'] == true) {
            await secureStorage.storeUserType('assumptor');
          } else if (userRole['is_assumee'] == true) {
            await secureStorage.storeUserType('assumee');
          }
        }
        // Save FCM token after login
        final prefs = await SharedPreferences.getInstance();
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          // Send FCM token to the backend for saving
          final notifStatus =
              await FirebaseMessaging.instance.getNotificationSettings();

          final isGranted =
              notifStatus.authorizationStatus == AuthorizationStatus.authorized;

          if (isGranted) {
            await saveFcmToken(fcmToken);
            prefs.setBool('push_notifications', true);
          }
        }
        return {
          'access_token': responseData['access'],
          'is_approved': responseData['user']['is_approved']
        };
      } else {
        if (responseData.containsKey('error')) {
          return (responseData);
        }
        print('responseData');
        print(responseData);
        return {'error': 'Incorrect email or password'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<void> removeFcmToken(String fcmToken) async {
    final userId = await secureStorage.getUserId(); // Assuming user ID is saved

    // Check if userId and fcmToken are available
    if (userId == null || userId.isEmpty) {
      print("Error: User ID not found in storage.");
      return;
    }

    if (fcmToken.isEmpty) {
      print("Error: FCM Token is empty.");
      return;
    }

    final apiUrl = Uri.parse('$baseURL/remove_fcm_token/');

    final Map<String, dynamic> fcmData = {
      'user_id': userId,
      'fcm_token': fcmToken,
    };

    try {
      print("Removing FCM token from backend: $fcmData");

      final response = await http.post(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(fcmData),
      );

      if (response.statusCode == 200) {
        print("FCM Token removed successfully!");
      } else {
        print(
            "Failed to remove FCM Token. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error removing FCM Token: $e");
    }
  }

  Future<void> saveFcmToken(String fcmToken) async {
    final userId = await secureStorage.getUserId(); // Assuming user ID is saved

    // Check if userId and fcmToken are available
    if (userId == null || userId.isEmpty) {
      print("Error: User ID not found in storage.");
      return;
    }
    if (fcmToken.isEmpty) {
      print("Error: FCM Token is empty.");
      return;
    }

    final apiUrl = Uri.parse('$baseURL/save_fcm_token/');

    final Map<String, dynamic> fcmData = {
      'user_id': userId,
      'fcm_token': fcmToken,
    };

    try {
      print("Sending FCM token to backend: $fcmData");

      final response = await http.post(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(fcmData),
      );

      if (response.statusCode == 200) {
        print("FCM Token saved successfully!");
      } else {
        print("Failed to save FCM Token. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error saving FCM Token: $e");
    }
  }

  Future<void> refreshAccessToken(String refreshToken) async {
    final apiUrl = Uri.parse('$baseURL/token/refresh/');

    final Map<String, dynamic> refreshData = {
      'refresh': refreshToken,
    };

    try {
      final response = await http.post(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(refreshData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String newAccessToken = responseData['access'];
        String newRefreshToken = responseData['refresh'];

        await secureStorage.storeToken(newAccessToken);
        await secureStorage.storeRefreshToken(newRefreshToken);
      } else {
        throw Exception('Failed to refresh token');
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }
  }

  Future<Map<String, dynamic>> viewInfoApplication() async {
    final apiUrl = Uri.parse('$baseURL/view/user/application/');
    final token = await secureStorage.getToken();

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> updateApplicationDetails(
      Map<String, dynamic> profileData) async {
    final apiUrl = Uri.parse('$baseURL/update/user/application/');
    final token = await secureStorage.getToken();

    try {
      final response = await http.put(
        apiUrl,
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        await secureStorage.storeApplicationStatus(decoded['status']);
        return {
          'success': 'Profile update successfully',
          'status': decoded['status']
        };
      } else {
        return {'error': 'Failed to update profile'};
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> viewProfile(String token) async {
    final apiUrl = Uri.parse('$baseURL/view-profile/');

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return responseData;
      } else if (response.statusCode == 401) {
        String? refreshToken = await secureStorage.getRefreshToken();

        if (refreshToken != null) {
          await refreshAccessToken(refreshToken);

          String? accessToken = await secureStorage.getToken();

          if (accessToken != null) {
            final retryResponse = await http.get(
              apiUrl,
              headers: {
                "Content-Type": "application/json",
                "Authorization": "Bearer $accessToken",
              },
            );
            if (retryResponse.statusCode == 200) {
              final retryResponseData = jsonDecode(retryResponse.body);
              return retryResponseData;
            } else {
              return {
                'error': 'Unable to refresh access token. Session expired.'
              };
            }
          } else {
            return {
              'error': 'Unable to obtain a new access token. Session expired.'
            };
          }
        } else {
          return {'error': 'Refresh token not found. Session expired.'};
        }
      } else {
        final responseData = jsonDecode(response.body);
        return {'error': responseData['error']};
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profileData) async {
    final apiUrl = Uri.parse('$baseURL/update-profile/');
    final token = await secureStorage.getToken();

    try {
      final response = await http.put(
        apiUrl,
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(profileData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'Failed to update profile'};
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfilePicture(File picture) async {
    final apiUrl = Uri.parse('$baseURL/update-profile/picture/');
    final token = await secureStorage.getToken();

    String picBase64 = await imageToBase64(picture);

    final Map<String, dynamic> userProfilePic = {'user_prof_pic': picBase64};

    try {
      final response = await http.put(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(userProfilePic),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorMessage =
            jsonDecode(response.body)['error'] ?? 'Failed to update profile';
        return {'error': errorMessage};
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> viewOtherUserProfile(int userId) async {
    final apiUrl = Uri.parse('$baseURL/view/$userId/profile/');
    final token = await secureStorage.getToken();

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return res;
      } else {
        return res['error'];
      }
    } catch (e) {
      return {'error': 'An error ocuured: $e'};
    }
  }

  Future<void> updateCarListing(String token, String listingId,
      Map<String, dynamic> updatedContent) async {
    final response = await http.put(
      // Use PUT here
      Uri.parse(
          '$baseURL/update_listing/$listingId/'), // Include listing ID in the URL
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(updatedContent),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update listing: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> cancelOffer(
      String offerId, String status) async {
    final apiUrl = Uri.parse('$baseURL/cancel/offer/');
    final token = await secureStorage.getToken();

    final Map<String, dynamic> offer = {'offer_id': offerId, 'status': status};

    try {
      final response = await http.put(
        apiUrl,
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(offer),
      );

      final decodedRes = jsonDecode(response.body);
      return decodedRes;
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> offerAcceptReject(
      String offerId, String status) async {
    final apiUrl = Uri.parse('$baseURL/offer/update/accept-reject/');
    final token = await secureStorage.getToken();

    final Map<String, dynamic> offer = {'offer_id': offerId, 'status': status};

    try {
      final response = await http.put(
        apiUrl,
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(offer),
      );

      final decodedRes = jsonDecode(response.body);
      return decodedRes;
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<String> changePassword(
      String token, String currPassword, String newPassword) async {
    final apiUrl = Uri.parse('$baseURL/change-password/');

    final Map<String, dynamic> updatePassword = {
      'curr_password': currPassword,
      'new_password': newPassword,
    };

    try {
      final response = await http.put(
        apiUrl,
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(updatePassword),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String token = responseData['access'] ?? '';
        String refreshToken = responseData['refresh'] ?? '';
        await secureStorage.storeToken(token);
        await secureStorage.storeRefreshToken(refreshToken);

        return responseData['message'];
      } else {
        final responseData = jsonDecode(response.body);
        return responseData['error'];
      }
    } catch (e) {
      return 'An error occured: $e';
    }
  }

  Future<Map<String, dynamic>> requestResetPassword(String email) async {
    final apiUrl = Uri.parse('$baseURL/find-password/');

    final Map<String, dynamic> data = {
      'email': email,
    };

    try {
      final response = await http.post(apiUrl,
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(data));

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decodedResponse;
      } else {
        return decodedResponse;
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> makeOffer(String listId, double price) async {
    final apiUrl = Uri.parse('$baseURL/make/offer/');
    final token = await secureStorage.getToken();

    final Map<String, dynamic> data = {
      'listing_id': listId,
      'offer_price': price
    };

    try {
      final response = await http.post(apiUrl,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(data));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        final error = jsonDecode(response.body);
        return error;
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<String> updateOffer(String listId, double price) async {
    final apiUrl = Uri.parse('$baseURL/update/offer/');
    final token = await secureStorage.getToken();

    final Map<String, dynamic> data = {
      'listing_id': listId,
      'offer_price': price
    };

    try {
      final response = await http.post(apiUrl,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(data));

      if (response.statusCode == 200) {
        return 'success';
      } else {
        final error = jsonDecode(response.body);
        return error['error'];
      }
    } catch (e) {
      return 'An error occured: $e';
    }
  }

  Future<Map<String, dynamic>> getAssumptorListOffer() async {
    final token = await secureStorage.getToken();
    final apiUrl = Uri.parse('$baseURL/assumptor/list/offers/');

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final offers = jsonDecode(utf8.decode(response.bodyBytes));
        return offers;
      } else {
        final error = jsonDecode(response.body);
        return error;
      }
    } catch (e) {
      return {'error': 'An error occufred $e'};
    }
  }

  Future<Map<String, dynamic>> viewConversation(
      String token, int receiverId) async {
    final apiUrl = Uri.parse('$baseURL/view-convo/$receiverId/');

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final responseData = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return responseData;
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> viewInbox(String token) async {
    final apiUrl = Uri.parse('$baseURL/view/user/inbox/');

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else if (response.statusCode == 401) {
        return {'error': 'Unauthorized access.'};
      } else {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> getActiveOffer(int receiverId) async {
    final apiUrl = Uri.parse('$baseURL/get/active/offer/$receiverId/');
    final token = await secureStorage.getToken();

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> getListingOffer(int receiverId) async {
    final apiUrl = Uri.parse('$baseURL/get/$receiverId/listing/offer/');
    final token = await secureStorage.getToken();

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> listingSold(String orderId) async {
    final apiUrl = Uri.parse('$baseURL/mark/sold/$orderId/');
    final token = await secureStorage.getToken();

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {};
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> requestPayout(
      String orderId, String paypalEmail) async {
    final apiUrl = Uri.parse('$baseURL/request/payout/');
    final token = await secureStorage.getToken();

    final Map<String, dynamic> requestPayload = {
      'order_id': orderId,
      'payout_paypal_email': paypalEmail
    };

    try {
      final response = await http.post(apiUrl,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(requestPayload));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> getRequestPayout(String orderId) async {
    final apiUrl = Uri.parse('$baseURL/get/request/payout/$orderId');
    final token = await secureStorage.getToken();

    try {
      final response = await http.get(apiUrl, headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      });

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<void> addCoinsToWallet(int wallId, int coinsToAdd) async {
    final token = await secureStorage.getToken();
    final response = await http.patch(
      Uri.parse(
          '$baseURL/wallet/$wallId/add-coins/'), // API endpoint to add coins
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
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
    final token = await secureStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseURL/wallet/total-coins/'),
      headers: {
        'Content-Type': 'application/json',
        "Authorization": "Bearer $token",
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

  Future<void> sessionExpired() async {
    await secureStorage.clearTokens();
  }

  Future<Map<String, dynamic>> checkUserEmail(String token) async {
    final apiUrl = Uri.parse('$baseURL/check/user/email/');

    final Map<String, dynamic> credentials = {
      'token': token,
    };

    try {
      final response = await http.post(apiUrl,
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonEncode(credentials));

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decodedResponse;
      } else {
        return decodedResponse;
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> assumptorListings() async {
    final apiUrl = Uri.parse('$baseURL/assumptor/all/listings/');
    final token = await secureStorage.getToken();
    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final decodedResponse = jsonDecode(response.body);
      print(decodedResponse);

      if (response.statusCode == 200) {
        print(decodedResponse);
        return decodedResponse;
      } else {
        return decodedResponse;
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> assumptorUserListings(int userId) async {
    final apiUrl = Uri.parse('$baseURL/assumptor/$userId/all/listings/');
    final token = await secureStorage.getToken();
    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final decodedResponse = jsonDecode(response.body);
      // print(decodedResponse);

      if (response.statusCode == 200) {
        // print(decodedResponse);
        return decodedResponse;
      } else {
        return decodedResponse;
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> deactivate() async {
    final apiUrl = Uri.parse('$baseURL/deactivate/');
    final token = await secureStorage.getToken();

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decodedResponse;
      } else {
        return decodedResponse;
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> getFollowers() async {
    final apiUrl = Uri.parse('$baseURL/follower/list/');
    final token = await secureStorage.getToken();
    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final decodedResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return decodedResponse;
      } else {
        return decodedResponse;
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<Map<String, dynamic>> createOrder(
      String userId, String? offerId, String listId, String amount) async {
    final apiUrl = Uri.parse('$baseURL/create/order/');
    final token = await secureStorage.getToken();

    final Map<String, dynamic> data = {
      'user_id': userId,
      'list_id': listId,
      'amount': amount
    };

    if (offerId != null && offerId.isNotEmpty) {
      data['offer_id'] = offerId;
    }

    try {
      final response = await http.post(apiUrl,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(data));

      return jsonDecode(response.body);
    } catch (e) {
      return ({'error': 'An error occured: $e'});
    }
  }

  Future<Map<String, dynamic>> confirmBuyOrder(String orderId) async {
    final apiUrl = Uri.parse('$baseURL/confirm/buy-now/order/');
    final token = await secureStorage.getToken();

    final Map<String, dynamic> data = {'order_id': orderId};

    try {
      final response = await http.put(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(data),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return ({'error': 'An error occured: $e'});
    }
  }

  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    final apiUrl = Uri.parse('$baseURL/cancel/order/$orderId');
    final token = await secureStorage.getToken();

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return ({'error': 'An error occured: $e'});
    }
  }

  Future<Map<String, dynamic>> viewOrder(String orderId) async {
    final apiUrl = Uri.parse('$baseURL/view/order/$orderId');
    final token = await secureStorage.getToken();

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return ({'error': 'An error occured: $e'});
    }
  }

  Future<Map<String, dynamic>> viewPaidOrder(String transId) async {
    final apiUrl = Uri.parse('$baseURL/view/transaction/$transId/details/');
    final token = await secureStorage.getToken();

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return ({'error': 'An error occured: $e'});
    }
  }

  Future<Map<String, dynamic>> completeOrder(String orderId) async {
    final apiUrl = Uri.parse('$baseURL/complete/transaction/$orderId/');
    final token = await secureStorage.getToken();

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded;
      } else {
        return decoded;
      }
    } catch (e) {
      return {'error': 'An error occured: $e'};
    }
  }

  Future<String?> initiatePayment() async {
    try {
      final response = await http.post(
        Uri.parse('$baseURL/create-paypal-order/'), // Your Django API endpoint
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['approval_url']; // Return the approval URL
      } else {
        throw 'Failed to create PayPal order';
      }
    } catch (error) {
      print('Error: $error');
      throw 'Payment initiation failed: $error';
    }
  }

  Future<void> deductCoins(
      String listingId, int userId, double amount, String token) async {
    final response = await http.patch(
      Uri.parse('$baseURL/wallet/$userId/deduct-coins/'),
      headers: {
        'Content-Type': 'application/json', // Fixed Content-Type header
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'amount': amount, 'list_id': listingId}),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to deduct coins: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> fetchListingStatus(String listingId, String token) async {
    final response = await http.get(
      Uri.parse('$baseURL/listingstats/$listingId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data[
          'list_status']; // Ensure 'list_status' exists in your response
    } else {
      throw Exception(
          'Failed to fetch listing status: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updateListingStatus(
      String listingId, String token, double amount) async {
    // final url = '$baseURL/listing/$listingId/update-status/'; // Update the URL to match your backend

    final response = await http.patch(
      Uri.parse('$baseURL/listing/$listingId/update-status/'),
      headers: {
        'Content-Type': 'application/json', // Fixed Content-Type header
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'amount': amount, 'list_id': listingId}),
    );

    // Check the response status code
    if (response.statusCode == 200) {
      print('Listing status updated successfully');
    } else {
      throw Exception(
          'Failed to update listing status: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> promoteListing(
      String listingId, String token, double amount, int duration) async {
    final response = await http.post(
      Uri.parse('$baseURL/promote_listing/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(
          {'list_id': listingId, 'amount': amount, 'duration': duration}),
    );

    if (response.statusCode != 201) {
      throw Exception(
          'Failed to promote listing: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> deleteListing(String listingId, String token) async {
    final response = await http.patch(
      Uri.parse('$baseURL/listing/$listingId/delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to delete listing: ${response.statusCode} - ${response.body}');
    }
  }
}

class GoogleSignInApi {
  static final _clientIdWeb = dotenv.env['CLIENT_ID'];

  static final _googleSignIn = GoogleSignIn(
    clientId: _clientIdWeb,
    scopes: ['email'],
  );

  static Future<GoogleSignInAccount?> login() async {
    try {
      return await _googleSignIn.signIn();
    } catch (error) {
      print('Error signing in with Google: $error');
      return null;
    }
  }

  static Future<void> logout() async {
    await _googleSignIn.signOut();
  }

  static Future<void> logoutDisconnect() async {
    await _googleSignIn.signOut();
    await _googleSignIn.disconnect();
  }
}
