import 'dart:async';

import 'package:flutter/material.dart';

void popUp(BuildContext context, String content,
    {TextAlign align = TextAlign.start}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      Timer? _timer;

      _timer = Timer(const Duration(seconds: 3), () {
        Navigator.of(context).pop();
      });

      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Adjust the radius here
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        contentPadding: const EdgeInsets.only(left: 18, right: 18, top: 12),
        content: Text(content, textAlign: align),
        actions: [
          Center(
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                child: const Text(
                  'Close Now',
                  style: TextStyle(
                      color: Color(0xff4A8AF0), fontWeight: FontWeight.w400),
                ),
                onPressed: () {
                  if (_timer != null) {
                    _timer.cancel();
                  }
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      );
    },
  );
}
