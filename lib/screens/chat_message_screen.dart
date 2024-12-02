import 'dart:async';
import 'dart:io';

import 'package:assumemate/format.dart';
import 'package:assumemate/screens/Report_user.dart';
import 'package:assumemate/screens/payment_receipt_screen.dart';
import 'package:assumemate/screens/rating.dart';
import 'package:assumemate/screens/waiting_area/payment_confirmation_screen.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:assumemate/components/chat_message.dart';
// import 'package:assumemate/logo/loading_animation.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/provider/photos_permission.dart';
import 'package:assumemate/provider/storage_permission.dart';
import 'package:assumemate/screens/item_detail_screen.dart';
import 'package:assumemate/screens/other_profile_screen.dart';
import 'package:assumemate/service/service.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:path/path.dart' as p;

class ChatMessageScreen extends StatefulWidget {
  final String receiverId;

  const ChatMessageScreen({super.key, required this.receiverId});

  @override
  State<ChatMessageScreen> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessageScreen> {
  List<Map<String, dynamic>> _messages = [];

  final String? baseURL = dotenv.env['WEB_SOCKET_URL'];
  final SecureStorage secureStorage = SecureStorage();
  final ApiService apiService = ApiService();
  late PhotosPermission photoPermission;
  late StoragePermission storagePermission;
  // final ImagePicker _picker = ImagePicker();
  WebSocketChannel? _channel;
  WebSocketChannel? _isReadChannel;
  WebSocketChannel? _inboxChannel;
  String? _userId;
  String? _chatroomId;
  String? _userType;
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _otherIsTyping = false;
  bool _isLoading = false;
  final TextEditingController _messageController = TextEditingController();
  File? _selectedFile;
  String? _fileExtension;

  String name = '';
  String picture = '';
  bool isActive = true;

  bool _hasOffer = false;
  String? offerStatus;

  Map<String, dynamic> offerDetails = {};

  Future<void> _getUserType() async {
    _userType = await secureStorage.getUserType();
    _userId = await secureStorage.getUserId();
  }

  Future<void> _initializeIsReadWebSocket() async {
    final token = await secureStorage.getToken();

    if (_userId != null) {
      try {
        _isReadChannel = WebSocketChannel.connect(
          Uri.parse('$baseURL/ws/chat/read/$_chatroomId/?token=$token'),
        );

        _isReadChannel!.stream.listen((message) {
          final messageResponse = jsonDecode(message);
          if (messageResponse['type'] == 'chat_status') {
            if (mounted) {
              setState(() {
                for (var msg in _messages) {
                  if (msg['sender_id'] !=
                      int.parse(messageResponse['user_id'])) {
                    msg['chatmess_is_read'] = true;
                  }
                }
              });
            }
          }
        });

        _sendReadStatus();
        // _sendInboxUpdate(message, true);
      } catch (e) {
        popUp(context, 'Connection error: $e');
      }
    } else {
      popUp(context, 'User ID is null or empty');
    }
  }

  Future<void> _initializeInboxWebsocket() async {
    final token = await secureStorage.getToken();
    if (_userId != null) {
      try {
        _inboxChannel = WebSocketChannel.connect(
          Uri.parse('$baseURL/ws/inbox/?token=$token'),
        );

        _inboxChannel!.sink.add(jsonEncode({
          'type': 'inbox_read',
          'room_id': _chatroomId,
          'is_read': true,
        }));
      } catch (e) {
        popUp(context, 'Connection error: $e');
      }
    } else {
      popUp(context, 'User ID is null or empty');
    }
  }

  Future<void> _initializeWebSocket() async {
    final token = await secureStorage.getToken();
    if (_userId != null) {
      try {
        _channel = WebSocketChannel.connect(
          Uri.parse('$baseURL/ws/chat/${widget.receiverId}/?token=$token'),
        );

        _channel!.stream.listen((message) {
          final messageResponse = jsonDecode(message);
          if (messageResponse['type'] == 'chat_message') {
            setState(() {
              _isTyping = false;
              _messages.add({
                'sender_id': int.parse(messageResponse['user_id']),
                'chatmess_content': messageResponse['message'],
                'chatmess_created_at': messageResponse['timestamp'],
                'chatmess_is_read': messageResponse['is_read']
              });
              _sendReadStatus();
            });
          } else if (messageResponse['type'] == 'typing_status') {
            if (messageResponse['user_id'] != _userId) {
              setState(() {
                // _hasOffer = false;
                _otherIsTyping = messageResponse['is_typing'];
              });
            }
          } else if (messageResponse['type'] == 'offer_status') {
            offerStatus = messageResponse['offer_status'];

            if (offerStatus == 'PENDING' || offerStatus == 'ACCEPTED') {
              setState(() {
                _hasOffer = true;
                offerDetails['offerStatus'] = offerStatus;
              });
              print(_hasOffer);
            } else {
              setState(() {
                offerDetails.clear();
                _hasOffer = false;
              });
            }
            _sendReadStatus();
            setState(() {
              _messages.add({
                'sender_id': int.parse(messageResponse['user_id']),
                'chatmess_content': messageResponse['message'],
                'chatmess_created_at': messageResponse['timestamp'],
                'chatmess_is_read': messageResponse['is_read']
              });
            });
          } else if (messageResponse['type'] == 'change_offer') {
            _sendReadStatus();
            setState(() {
              offerDetails['offerPrice'] = messageResponse['offer_amount'];
              _messages.add({
                'sender_id': int.parse(messageResponse['user_id']),
                'chatmess_content': messageResponse['message'],
                'chatmess_created_at': messageResponse['timestamp'],
                'chatmess_is_read': messageResponse['is_read']
              });
            });
          }
        });
        // await _sendReadStatus();
      } catch (e) {
        popUp(context, 'Connection error: $e');
      }
    } else {
      popUp(context, 'User ID is null or empty');
    }
  }

  void _sendReadStatus() {
    _isReadChannel!.sink.add(jsonEncode({
      'type': 'chat_status',
      'user_id': _userId,
      'chat_room': _chatroomId,
      'chat_status': true
    }));
  }

  void _setTypingStatus(bool status) {
    _channel!.sink.add(jsonEncode({
      'type': 'typing',
      'user_id': _userId,
      'is_typing': status,
    }));
  }

  void _resetTypingTimer() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping) {
        _setTypingStatus(false);
      }
    });
  }

  void _handleTyping(String value) {
    if (value.isNotEmpty && !_isTyping) {
      setState(() {
        _isTyping = true;
      });

      _setTypingStatus(true);
      _resetTypingTimer();
    } else if (value.isEmpty && _isTyping) {
      setState(() {
        _isTyping = false;
      });

      _setTypingStatus(false);
    } else {
      _resetTypingTimer();
    }
  }

  void _sendInboxUpdate(Map<String, dynamic> message, bool isRead) {
    _inboxChannel!.sink.add(jsonEncode({
      'type': 'inbox_update',
      'sender_id': _userId,
      'message': message,
      'room_id': _chatroomId,
      'receiver_id': widget.receiverId,
      'is_read': isRead,
    }));
  }

  void _sendMessage() async {
    _setTypingStatus(false);
    _typingTimer?.cancel();

    if (_selectedFile != null && _channel != null) {
      final bytes = await File(_selectedFile!.path).readAsBytes();
      String base64Image = base64Encode(bytes);
      String fileNameWithoutExt =
          p.basenameWithoutExtension(_selectedFile!.path);

      final message = {
        'message':
            _messageController.text.isNotEmpty ? _messageController.text : null,
        'file': base64Image,
        'file_name': fileNameWithoutExt,
        'file_type': _fileExtension,
      };

      _channel!.sink.add(jsonEncode({
        'type': 'message',
        'user_id': _userId,
        'message': message,
        'room_id': _chatroomId
      }));

      _sendInboxUpdate(message, false);

      _messageController.clear();
      setState(() {
        _selectedFile = null; // Reset the image after sending
      });
    } else if (_messageController.text.isNotEmpty && _channel != null) {
      final message = {
        'message': _messageController.text,
        'file': null,
        'file_name': null,
        'file_type': null,
      };
      _channel!.sink.add(jsonEncode({
        'type': 'message',
        'user_id': _userId,
        'message': message,
        'room_id': _chatroomId
      }));

      _sendInboxUpdate(message, false);

      _messageController.clear();
    }
  }

  void _updateOffer(String status) async {
    print('press');

    if (status == 'CANCELLED' && offerDetails['offerStatus'] == 'ACCEPTED') {
      if (offerDetails.containsKey('order_id')) {
        final response =
            await apiService.cancelOrder(offerDetails['order_id'].toString());

        if (response.containsKey('message')) {
          popUp(context, response['message']);
        } else {
          popUp(context, response['error']);
          return;
        }
      } else {
        popUp(context, 'pop upppppppp');
        return;
      }
    }

    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'offer_update',
        'user_id': _userId,
        'offer_id': offerDetails['offerId'],
        'offer_status': status
      }));

      final updatedStatus = status.toLowerCase();

      final message = {
        'message': 'Offer $updatedStatus',
        'file': null,
        'file_name': null,
        'file_type': null,
      };

      _sendInboxUpdate(message, false);
    }
  }

  void _cancelOffer(String status) async {
    print(offerDetails);
    try {
      final response = await apiService.cancelOffer(
          offerDetails['offerId'].toString(), status);

      if (response.containsKey('message')) {
        setState(() {
          offerDetails.clear();
          _hasOffer = false;
        });
        popUp(context, response['message']);
      } else {
        popUp(context, response['error']);
      }
    } catch (e) {
      popUp(context, 'An error occured: $e');
    }
  }

  Future<void> _fetchMessages() async {
    _userId = await secureStorage.getUserId();
    final userToken = await secureStorage.getToken();
    final response = await apiService.viewConversation(
        userToken!, int.parse(widget.receiverId));

    if (response.containsKey('messages')) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(response['messages']);
        _chatroomId = response['room_id'];
      });
    } else if (response.containsKey('error')) {
      popUp(context, response['error']);
    }
  }

  Future<void> _getProfile() async {
    final response =
        await apiService.viewOtherUserProfile(int.parse(widget.receiverId));

    try {
      if (response.containsKey('user_profile')) {
        final profile = response['user_profile'];
        setState(() {
          name = '${profile['user_prof_fname']} ${profile['user_prof_lname']}';
          picture = profile['user_prof_pic'];
          isActive = response['isActive'];
        });
        print('isActive');
        print(isActive);
      } else {
        popUp(context, response['error']);
      }
    } catch (e) {
      popUp(context, '$e');
    }
  }

  Future<void> _getOffer() async {
    _userType = await secureStorage.getUserType();
    final response = (_userType == 'assumee')
        ? await apiService.getActiveOffer(int.parse(widget.receiverId))
        : await apiService.getListingOffer(int.parse(widget.receiverId));

    try {
      if (response.containsKey('offer')) {
        final offer = response['offer'];
        final list = response['listing'];
        final img = list['list_content']['images'];
        print(offer);
        setState(() {
          _hasOffer = true;
          offerDetails['offerId'] = offer['offer_id'].toString();
          offerDetails['itemImg'] = img[0];
          offerDetails['listingId'] = list['list_id'];
          offerDetails['offerPrice'] = offer['offer_price'];
          offerDetails['offerStatus'] = offer['offer_status'];
          if (offer.containsKey('order_id')) {
            final order = offer['order_id'];
            print('order');
            print(order);
            offerDetails['order_id'] = order['order_id'];
            offerDetails['order_price'] = order['order_price'];
            offerDetails['order_status'] = order['order_status'];
          }
        });
        print(_hasOffer);
      }
    } catch (e) {
      popUp(context, 'An error occured: $e');
    }
  }

  Future<void> _pickImage() async {
    final result = await photoPermission.requestPhotosPermission();

    if (result) {
      final selectedfile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpeg', 'jpg', 'png'],
      );
      if (selectedfile != null) {
        final file = File(selectedfile.files.first.path!);
        _selectedFile = file;
        _fileExtension = p.extension(selectedfile.files.first.path!);
      }
      setState(() {});
    }
  }

  Future<void> _pickDocument() async {
    final result = await storagePermission.requestStoragePermission();

    if (result) {
      final selectedfile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx', 'pdf'],
      );
      if (selectedfile != null) {
        final file = File(selectedfile.files.first.path!);
        _selectedFile = file;
        _fileExtension = p.extension(selectedfile.files.first.path!);
      }
      setState(() {});
    }
  }

  Future<void> initialization() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _getUserType();
      await _getProfile();
      await _fetchMessages();
      await _getOffer();
      await _initializeWebSocket();
      await _initializeIsReadWebSocket();
      await _initializeInboxWebsocket();
      photoPermission = Provider.of<PhotosPermission>(context, listen: false);
      await photoPermission.checkPhotoPermission();
      storagePermission =
          Provider.of<StoragePermission>(context, listen: false);
      await storagePermission.checkStoragePermission();
    } catch (e) {
      if (mounted) {
        popUp(context, 'Initialization failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    // print(baseURL);
    if (mounted) {
      initialization();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
          color: const Color(0xffD1E3FE),
          child: const Center(
            child: CircularProgressIndicator(),
          ));
    }

    return Scaffold(
      backgroundColor: const Color(0xffD1E3FE),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: const Color(0xffFFFCF1),
        leading: Center(
          child: IconButton(
            splashColor: Colors.transparent,
            icon: const Icon(Icons.arrow_back_ios),
            color: const Color(0xff4A8AF0),
            onPressed: () {
              Navigator.of(context).pop(context);
            },
          ),
        ),
        title: Transform.translate(
          offset: const Offset(-13, 0),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => OtherProfileScreen(
                      userId: widget.receiverId,
                    ),
                  ));
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: (picture != '')
                      ? NetworkImage(picture)
                      : const AssetImage('assets/images/no-profile.jpg'),
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                name,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        // actions: [
        //   PopupMenuButton<int>(
        //     color: const Color(0xffFCFCFC),
        //     icon: const Icon(Icons.more_vert, color: Color(0xff4A8AF0)),
        //     iconSize: 26,
        //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        //     itemBuilder: (context) => [
        //       const PopupMenuItem(
        //           height: 25,
        //           child: Row(children: [
        //             Expanded(
        //               child: Text(
        //                 'Report',
        //                 style: TextStyle(fontSize: 14),
        //               ),
        //             ),
        //             Icon(
        //               Icons.flag_outlined,
        //               color: Color(0xffFF0000),
        //             ),
        //           ]))
        //     ],
        //   ),
        // ],
        actions: [
          PopupMenuButton<int>(
            color: const Color(0xffFCFCFC),
            icon: const Icon(Icons.more_vert, color: Color(0xff4A8AF0)),
            iconSize: 26,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            onSelected: (value) {
              if (value == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ReportUserScreen(widget.receiverId)),
                );
              } else if (value == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RateUserPage(widget.receiverId)),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<int>(
                value: 0,
                height: 25,
                child: Row(
                  children: [
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
                  ],
                ),
              ),
              const PopupMenuItem<int>(
                value: 1,
                height: 25,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rate',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Icon(
                      Icons.star_border_rounded,
                      color: Color(0xffFFD700),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          (_hasOffer)
              ? Container(
                  height: MediaQuery.of(context).size.width * .27,
                  padding: const EdgeInsets.all(8),
                  color: const Color(0xffD9D9D9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                          onTap: () {
                            (!isActive)
                                ? popUp(context, 'Listing not found')
                                : Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => ItemDetailScreen(
                                        listingId: offerDetails['listingId'],
                                        assumptorId: widget.receiverId),
                                  ));
                          },
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                offerDetails['itemImg'] != ''
                                    ? offerDetails['itemImg']
                                    : 'https://example.com/placeholder.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          )),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Offered price: ${formatCurrency(double.parse(offerDetails['offerPrice']))}",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                    softWrap: true,
                                  ),
                                  if (offerDetails.containsKey('order_id'))
                                    Text(
                                      "Reservation: ${formatCurrency(double.parse(offerDetails['order_price']))}",
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                      softWrap: true,
                                    ),
                                ],
                              )),
                              const SizedBox(height: 10),
                              (_userType == 'assumptor')
                                  ? (offerDetails['offerStatus'] == 'PENDING')
                                      ? actionButtons(
                                          'REJECT',
                                          'ACCEPT',
                                          () => _updateOffer('REJECTED'),
                                          () => acceptOfferAndReserve(context)
                                          // _updateOffer('ACCEPTED')
                                          )
                                      : (offerDetails['offerStatus'] == 'ACCEPTED' ||
                                              offerDetails['offerStatus'] ==
                                                  'PAID')
                                          ? actionButtons(
                                              'UNRESERVED',
                                              'MARK AS SOLD',
                                              () => _updateOffer('CANCELLED'),
                                              () => Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          PaymentReceiptScreen(
                                                              orderId: offerDetails['order_id']
                                                                  .toString()))))
                                          : const SizedBox()
                                  : (offerDetails['offerStatus'] == 'PENDING')
                                      ? actionButtons(
                                          'CANCEL',
                                          'CHANGE',
                                          () => _updateOffer('CANCELLED'),
                                          () => {
                                                offerDialog(context,
                                                    offerDetails['offerId'])
                                              })
                                      : (offerDetails['offerStatus'] ==
                                              'ACCEPTED')
                                          ? actionButtons(
                                              'CANCEL',
                                              'PAY NOW',
                                              () => _updateOffer('CANCELLED'),
                                              () => Navigator.of(context)
                                                  .push(MaterialPageRoute(builder: (context) => PaymentConfirmationScreen(orderId: offerDetails['order_id'].toString()))))
                                          : (offerDetails['offerStatus'] == 'PAID')
                                              ? actionButtons('REFUND', 'MARK AS COMPLETE', () => {}, () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => PaymentReceiptScreen(orderId: offerDetails['order_id'].toString()))))
                                              : const SizedBox()
                            ]),
                      )
                    ],
                  ),
                )
              : const SizedBox(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 8, right: 8, top: 0),
              child: ListView.builder(
                reverse: true,
                itemCount: _messages.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final message = _messages[_messages.length - 1 - index];
                  return ChatMessage(
                    messages: message['chatmess_content']!,
                    timestamp: message['chatmess_created_at'],
                    isCurrentUser: message['sender_id'] == int.parse(_userId!),
                    isLastChat: index == 0,
                    isRead: message['chatmess_is_read'] ?? false,
                  );
                },
              ),
            ),
          ),
          _otherIsTyping
              ? AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                      padding:
                          const EdgeInsets.only(right: 6, left: 14, top: 10),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.width * 0.75,
                                maxWidth:
                                    MediaQuery.of(context).size.width > 220
                                        ? 220
                                        : MediaQuery.of(context).size.width,
                              ),
                              decoration: const BoxDecoration(
                                  color: Color(0xffB5D1FD),
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(2),
                                    bottomRight: Radius.circular(20),
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  )),
                              child: const Text(
                                'User is typing...',
                                style: TextStyle(fontSize: 12),
                              ),
                            )
                          ])))
              : const SizedBox.shrink(),
          (_selectedFile != null)
              ? Container(
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.only(top: 5),
                  padding: const EdgeInsets.only(right: 30, left: 30),
                  child: Stack(
                    children: [
                      (['.jpg', '.jpeg', '.png'].contains(_fileExtension))
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_selectedFile!.path),
                                fit: BoxFit.cover,
                                height: 100,
                                width: 100,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                  const Icon(Icons.insert_drive_file),
                                  const SizedBox(width: 5),
                                  Text(_selectedFile!.path
                                      .split('/')
                                      .last), // Show the file name
                                ] // Icon for the file type
                              ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () {
                            // Handle the cancel action (e.g., remove the image)
                            setState(() {
                              _selectedFile =
                                  null; // Update your state to remove the image
                              _fileExtension = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white54,
                            ),
                            child: const Icon(
                              FontAwesomeIcons.xmark,
                              color: Colors.black54,
                              size: 15, // Adjust size as needed
                            ),
                          ),
                        ),
                      ),
                    ],
                  ))
              : const SizedBox(),
          Container(
              margin: const EdgeInsets.only(top: 5, bottom: 4),
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(30)),
              child: isActive
                  ? Row(
                      children: [
                        IconButton(
                          onPressed: () => _pickDocument(),
                          icon: const Icon(Icons.attach_file),
                          color: const Color(0xff4A8AF0),
                          padding: const EdgeInsets.only(left: 8, right: 4),
                          constraints:
                              const BoxConstraints(), // override default min size of 48px
                          style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize
                                  .shrinkWrap, // the '2023' part
                              overlayColor:
                                  WidgetStateProperty.all(Colors.transparent)),
                        ),
                        IconButton(
                          onPressed: () => _pickImage(),
                          icon: const Icon(Icons.photo_outlined),
                          color: const Color(0xff4A8AF0),
                          padding: const EdgeInsets.only(left: 4, right: 8),
                          constraints:
                              const BoxConstraints(), // override default min size of 48px
                          style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize
                                  .shrinkWrap, // the '2023' part
                              overlayColor:
                                  WidgetStateProperty.all(Colors.transparent)),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _messageController,
                            onChanged: _handleTyping,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                                hintStyle: const TextStyle(fontSize: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                  borderSide: BorderSide.none,
                                ),
                                hintText: 'Write a message...',
                                filled: true,
                                fillColor: const Color(0xffFCFCFC),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 12.0)),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send),
                          color: const Color(0xff4A8AF0),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          constraints:
                              const BoxConstraints(), // override default min size of 48px
                          style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize
                                  .shrinkWrap, // the '2023' part
                              overlayColor:
                                  WidgetStateProperty.all(Colors.transparent)),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text('Cannot reply to this conversation')],
                    ))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _isReadChannel?.sink.close();
    _inboxChannel?.sink.close();
    _messageController.dispose();
    super.dispose();
  }

  Widget actionButtons(
      String label1, String label2, Function action1, Function action2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: () {
            print('press1');
            final status = label1 == 'CANCEL' ? 'CANCELLED' : 'REJECTED';
            !isActive && (label1 == 'CANCEL' || label1 == 'REJECT')
                ? _cancelOffer(status)
                : action1();
          },
          style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              side: const BorderSide(
                color: Color(0xff683131),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              minimumSize: Size(40, 30)),
          child: Text(
            label1,
            style: const TextStyle(
              color: Color(0xff683131),
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 7),
        isActive
            ? ElevatedButton(
                onPressed: () => action2(),
                style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    backgroundColor: const Color(0xff4A8AF0),
                    foregroundColor: Colors.white,
                    minimumSize: Size(40, 30)),
                child: Text(
                  label2,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              )
            : const SizedBox.shrink()
      ],
    );
  }

  Future<void> offerDialog(BuildContext context, String offerId) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController offerController = TextEditingController();

    void changeOffer() {
      final amount = offerController.text;

      if (amount.isNotEmpty && _channel != null) {
        _channel!.sink.add(jsonEncode({
          'type': 'change_offer_amount',
          'user_id': _userId,
          'offer_id': offerId,
          'offer_amount': amount.replaceAll(',', '')
        }));

        final message = {
          'message':
              'Change offer: ${formatCurrency(double.parse(amount.replaceAll(',', '')))}',
          'file': null,
          'file_name': null,
          'file_type': null,
        };

        _sendInboxUpdate(message, false);

        offerController.clear();
      }
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding:
              const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
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
                  changeOffer();
                  Navigator.of(context).pop();
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

  Future<void> acceptOfferAndReserve(BuildContext context) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController reserveController = TextEditingController();

    void acceptReserve() async {
      final amntTxt = reserveController.text;
      final amount = amntTxt.replaceAll(',', '');

      try {
        final response =
            await apiService.createOrder(offerDetails['offerId'], amount);

        if (response.containsKey('message')) {
          print('response SA ORDER');
          print(response);
          print(response['order']);
          print(response['order']['order_id']);
          setState(() {
            offerDetails['order_id'] = response['order']['order_id'];
            offerDetails['order_price'] = response['order']['order_price'];
          });
          popUp(context, response['message']);
        } else {
          popUp(context, response['error']);
          return;
        }
      } catch (e) {
        popUp(context, 'Error accepting offer');
      }

      if (_channel != null) {
        _channel!.sink.add(jsonEncode({
          'type': 'offer_update',
          'user_id': _userId,
          'offer_id': offerDetails['offerId'],
          'offer_status': 'ACCEPTED'
        }));

        final updatedStatus = 'accepted';

        final message = {
          'message': 'Offer $updatedStatus',
          'file': null,
          'file_name': null,
          'file_type': null,
        };

        _sendInboxUpdate(message, false);
      }
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding:
              const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 17),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          title: const Center(
            child: Text(
              'Enter reservation amount',
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
                  controller: reserveController,
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
                  acceptReserve();
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4A8AF0),
              ),
              child: const Text(
                'Accept and Reserve',
                style: TextStyle(color: Color(0xffFFFCF1)),
              ),
            ),
          ],
        );
      },
    );
  }
}
