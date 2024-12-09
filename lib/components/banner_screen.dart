import 'package:flutter/material.dart';

class BannerScreen extends StatefulWidget {
  const BannerScreen({super.key});

  @override
  State<BannerScreen> createState() => _BannerScreenState();
}

class _BannerScreenState extends State<BannerScreen> {
  late final PageController pageController;
  int pageNo = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height / 3.5 - 75,
          child: PageView.builder(
            controller: pageController,
            onPageChanged: (index) {
              setState(() {
                pageNo = index; // Update pageNo on page change
              });
            },
            itemBuilder: (_, index) {
              // return const HighlightedItemBanner();
            },
            itemCount: 5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => Container(
              margin: const EdgeInsets.all(2),
              child: Icon(
                Icons.circle,
                size: 8,
                color: pageNo == index
                    ? const Color(0xff4A8AF0)
                    : Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}
