import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:gal/gal.dart';
import 'package:assumemate/logo/pop_up.dart';
import 'package:uuid/uuid.dart';

class PhotoScreen extends StatefulWidget {
  final String imageUrl;

  const PhotoScreen({super.key, required this.imageUrl});

  @override
  State<PhotoScreen> createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  bool _isShown = false;

  var uuid = const Uuid();

  void _setFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _savePhoto() async {
    try {
      final imagePath =
          '${Directory.systemTemp.path}/ASSUMEMATE_${uuid.v4()}.jpg';
      final response = await Dio().download(widget.imageUrl, imagePath);

      if (response.statusCode == 200) {
        await Gal.putImage(imagePath);
        popUp(context, 'Image saved successfully', align: TextAlign.center);
      } else {
        popUp(context, 'Error saving image', align: TextAlign.center);
      }
    } catch (e) {
      print('Error: $e');
      popUp(context, 'Failed to save image', align: TextAlign.center);
    }
  }

  @override
  void initState() {
    super.initState();
    _setFullScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      backgroundColor: Colors.black,
      body: GestureDetector(
          onTap: () {
            setState(() {
              _isShown = !_isShown;
            });
          },
          child: Stack(children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Text(
                      'Image not available',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            (_isShown)
                ? Positioned(
                    top: 10,
                    left: 10,
                    right: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xffFFFCF1),
                            size: 26,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        IconButton(
                          onPressed: _savePhoto,
                          icon: const Icon(
                            Icons.file_download_outlined,
                            color: Color(0xffFFFCF1),
                            size: 26,
                          ),
                        )
                      ],
                    ))
                : const SizedBox.shrink()
          ])),
    );
  }

  @override
  void dispose() {
    _exitFullScreen();
    super.dispose();
  }
}
