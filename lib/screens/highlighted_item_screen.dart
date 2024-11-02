import 'package:flutter/material.dart';
import 'package:assumemate/components/highlighted_item.dart';

class HighlightedItemScreen extends StatefulWidget {
  const HighlightedItemScreen({super.key});

  @override
  State<HighlightedItemScreen> createState() => _HighlightedItemScreenState();
}

class _HighlightedItemScreenState extends State<HighlightedItemScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Highlights',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )),
        backgroundColor: const Color(0xffFFFCF1),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 5),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            mainAxisExtent: 190,
          ),
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            return const HighlightedItem();
          },
          itemCount: 5,
        ),
      ),
    );
  }
}
