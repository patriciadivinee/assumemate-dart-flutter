import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:assumemate/logo/welcome.dart';
import 'package:assumemate/main.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    final profAPI = Uri.parse('$baseURL/create-profile/');

    String validIDBase64 = await imageToBase64(validID);
    String picBase64 = await imageToBase64(picture);

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
    };

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
        String token = responseData['access'] ?? '';
        String refreshToken = responseData['refresh'] ?? '';
        await secureStorage.storeToken(token);
        await secureStorage.storeRefreshToken(refreshToken);

        final user = responseData['user'];

        if (user['is_assumptor'] == true) {
          await secureStorage.storeUserType('assumptor');
        } else if (user['is_assumee'] == true) {
          await secureStorage.storeUserType('assumee');
        }

        final Map<String, dynamic> userProfile = {
          'user_id': user['id'],
          'user_prof_fname': fname,
          'user_prof_lname': lname,
          'user_prof_gender': gender,
          'user_prof_dob': formatDate(dob),
          'user_prof_mobile': mobnum,
          'user_prof_address': address,
          'user_prof_valid_id': validIDBase64,
          'user_prof_pic': picBase64,
        };

        try {
          final profile = await http.post(
            profAPI,
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode(userProfile),
          );
          if (profile.statusCode == 201) {
            final profileDetail = jsonDecode(profile.body);
            await secureStorage.storeApplicationStatus('PENDING');
            return {'profile': profileDetail, 'credential': responseData};
          } else {
            var responseBody = jsonDecode(profile.body);
            return {
              'error': 'Profile creation failed.  ${responseBody['error']}'
            };
          }
        } catch (e) {
          return {'error': 'Profile creation exception: ${e.toString()}'};
        }
      } else {
        var responseBody = jsonDecode(response.body);
        return {
          'error': 'User registration failed. ${responseBody['email'][0]}'
        };
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
        return {
          'access_token': responseData['access'],
          'is_approved': responseData['user']['is_approved']
        };
      } else {
        if (responseData.containsKey('error')) {
          return (responseData);
        }
        return {'error': 'Incorrect email or password'};
      }
    } catch (e) {
      return {'error': e.toString()};
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

  Future<String> makeOffer(String listId, double price) async {
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
        return 'success';
      } else {
        final error = jsonDecode(response.body);
        return error['error'];
      }
    } catch (e) {
      return 'An error occured: $e';
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

  Future<Map<String, dynamic>> viewConversation(
      String token, int chatroomId) async {
    final apiUrl = Uri.parse('$baseURL/view-convo/$chatroomId/');

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

    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
    );
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
    await _googleSignIn.disconnect();
  }
}
