import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatCurrency(double value, {String? symbol = '\u20B1'}) {
  final formatcur = NumberFormat.currency(
    locale: 'en_PH',
    decimalDigits: 2,
    symbol: symbol,
  );
  return formatcur.format(value);
}

OutlineInputBorder borderStyle = OutlineInputBorder(
  borderRadius: BorderRadius.circular(30.0),
  borderSide: const BorderSide(color: Colors.black),
);

String timeFormat(String dateMade) {
  DateTime dateTime = DateTime.parse(dateMade).toLocal();
  String date = DateFormat('MMM dd, yyyy').format(dateTime);
  String time = DateFormat('hh:mm a').format(dateTime);

  return '$date  $time';
}
