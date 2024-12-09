import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/provider/storage_permission.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:assumemate/screens/photo_screen.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

class ChatMessage extends StatefulWidget {
  final Map<String, dynamic> messages;
  final bool isCurrentUser;
  final String timestamp;
  final bool isLastChat;
  final bool isRead;

  const ChatMessage({
    super.key,
    required this.messages,
    required this.isCurrentUser,
    required this.timestamp,
    required this.isLastChat,
    required this.isRead,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  bool _timeShown = false;
  final SecureStorage secureStorage = SecureStorage();
  late StoragePermission storagePermission;
  int size = 0;

  double _progress = 0.0;
  bool _isDownloading = false;
  bool _isDownloadComplete = false;

  String extractFileName(String url) {
    return Uri.parse(url).pathSegments.last;
  }

  Future<void> downloadFile(String url, String filename) async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    final result = await storagePermission.requestStoragePermission();

    const types = {
      ".pdf": "application/pdf",
      ".doc": "application/msword",
      ".docx":
          "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    };

    if (result) {
      try {
        Directory? directory = Directory('/storage/emulated/0/Download');
        final savePath = '${directory.path}/$filename';

        final extension = p.extension(savePath);

        final response = await Dio().download(url, savePath,
            onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
            });
          }
        });

        if (response.statusCode == 200) {
          setState(() {
            _isDownloadComplete = true;
          });
          popUp(context, 'File saved', align: TextAlign.center);
          Future.delayed(const Duration(milliseconds: 200), () async {
            await OpenFile.open(savePath, type: types[extension]);
          });

          Future.delayed(const Duration(seconds: 2), () {
            setState(() {
              _isDownloadComplete = false;
            });
          });
        } else {
          popUp(context, 'Download failed', align: TextAlign.center);
        }
      } catch (e) {
        popUp(context, 'Download failed: $e');
      } finally {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> getFileSize(String url) async {
    try {
      final response =
          await Dio().head(url); // Send a HEAD request to get headers
      if (response.headers['content-length'] != null &&
          response.headers['content-length']!.isNotEmpty) {
        setState(() {
          size = int.parse(response
              .headers['content-length']!.first); // Update state with file size
        }); // Get the first element of the list
      }
    } catch (e) {
      print('Error fetching file size: $e');
    } // Return 0 if there's an error
  }

  Widget _showPhoto() {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PhotoScreen(
                      imageUrl: widget.messages['file'],
                    )));
      },
      child: CachedNetworkImage(
        memCacheHeight: 250,
        imageUrl: widget.messages['file'],
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 300),
        imageBuilder: (context, imageProvider) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image: imageProvider,
              width: MediaQuery.of(context).size.width > 250
                  ? 250
                  : MediaQuery.of(context).size.width,
              // fit: ,
            ),
          );
        },
        placeholder: (context, url) => ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 250,
            height: 150,
            color: const Color(0xffD1D1CF),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xff4A8AF0),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 250,
          width: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Icon(Icons.error, color: Colors.red),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    storagePermission = Provider.of<StoragePermission>(context, listen: false);
    storagePermission.checkStoragePermission();
    if (widget.messages['file_type'] == 'document') {
      getFileSize(widget.messages['file']);
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime dateTime = DateTime.parse(widget.timestamp).toLocal();
    String date = DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);

    return Container(
      padding: const EdgeInsets.all(5),
      child: Row(
        mainAxisAlignment: widget.isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              if (!widget.isLastChat || !widget.isCurrentUser) {
                setState(() {
                  _timeShown = !_timeShown;
                });
              }
            },
            splashColor: Colors.transparent, // No splash effect
            highlightColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: widget.isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (widget.messages['text'] != null &&
                    widget.messages['file'] != null)
                  // Text and Image together in the same container
                  Container(
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width > 250
                          ? 250
                          : MediaQuery.of(context).size.width,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffB5D1FD),
                      borderRadius: BorderRadius.only(
                        bottomLeft: widget.isCurrentUser
                            ? const Radius.circular(20)
                            : const Radius.circular(1),
                        bottomRight: widget.isCurrentUser
                            ? const Radius.circular(1)
                            : const Radius.circular(20),
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.messages['text'],
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _showPhoto()
                      ],
                    ),
                  )
                else if (widget.messages['text'] != null &&
                    widget.messages['text'].isNotEmpty)
                  // Only text message
                  Container(
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width > 250
                          ? 250
                          : MediaQuery.of(context).size.width,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffB5D1FD),
                      borderRadius: BorderRadius.only(
                        bottomLeft: widget.isCurrentUser
                            ? const Radius.circular(20)
                            : const Radius.circular(2),
                        bottomRight: widget.isCurrentUser
                            ? const Radius.circular(2)
                            : const Radius.circular(20),
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      widget.messages['text'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                else if (widget.messages['file'] != null &&
                    widget.messages['file_type'] == 'image')
                  // Only image
                  _showPhoto()
                else if (widget.messages['file'] != null &&
                    widget.messages['file_type'] == 'document')
                  Container(
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width > 250
                          ? 250
                          : MediaQuery.of(context).size.width,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffB5D1FD),
                      borderRadius: BorderRadius.only(
                        bottomLeft: widget.isCurrentUser
                            ? const Radius.circular(20)
                            : const Radius.circular(2),
                        bottomRight: widget.isCurrentUser
                            ? const Radius.circular(2)
                            : const Radius.circular(20),
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircularPercentIndicator(
                          radius: 20.0,
                          lineWidth: 1.5,
                          percent: _progress,
                          center: _isDownloading
                              ? Text(
                                  "${(_progress * 100).toStringAsFixed(0)}%",
                                  style: const TextStyle(fontSize: 11),
                                )
                              : CircleAvatar(
                                  backgroundColor: Colors.white24,
                                  child: (_isDownloadComplete)
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.black87,
                                          size: 20,
                                        )
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.file_open,
                                            color: Colors.black87,
                                          ),
                                          iconSize: 20.0,
                                          onPressed: () => (
                                                downloadFile(
                                                    widget.messages['file'],
                                                    extractFileName(widget
                                                        .messages['file'])),
                                              ))),
                          progressColor: _isDownloading
                              ? const Color(0xff4A8AF0)
                              : const Color(0xffB5D1FD),
                          backgroundColor: const Color(0xffB5D1FD),
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                extractFileName(widget.messages['file']),
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                '${(size / 1024).toStringAsFixed(2)} KB',
                                style: const TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_timeShown)
                  Row(children: [
                    Text(
                      date,
                      style:
                          TextStyle(fontSize: 9, color: Colors.grey.shade400),
                    ),
                    if (widget.isRead) ...[
                      const SizedBox(width: 3),
                      Text(
                        'Read',
                        style:
                            TextStyle(fontSize: 9, color: Colors.grey.shade400),
                      ),
                    ],
                  ]),
                if (widget.isCurrentUser && widget.isLastChat)
                  Row(
                    children: [
                      if (widget.isRead) ...[
                        const SizedBox(width: 3),
                        Text(
                          'Read',
                          style: TextStyle(
                              fontSize: 9, color: Colors.grey.shade400),
                        ),
                      ]
                    ],
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
