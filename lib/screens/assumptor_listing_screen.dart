import 'package:assumemate/logo/pop_up.dart';
import 'package:assumemate/service/service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AssumptorListingScreen extends StatefulWidget {
  const AssumptorListingScreen({super.key});

  @override
  State<AssumptorListingScreen> createState() => _AssumptorListingScreenState();
}

class _AssumptorListingScreenState extends State<AssumptorListingScreen> {
  List<Map<String, dynamic>> _listings = [];
  final ApiService apiService = ApiService();

  Future<void> _getListings() async {
    try {
      final response = await apiService.assumptorListings();
      if (response.containsKey('listings')) {
        setState(() {
          _listings = List<Map<String, dynamic>>.from(response['listings']);
        });
        print('yawa');
        print(_listings);
      }
    } catch (e) {
      popUp(context, 'Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _getListings();
  }

  @override
  Widget build(BuildContext context) {
    final tabTextStyle =
        GoogleFonts.poppins(textStyle: const TextStyle(fontSize: 13));

    return DefaultTabController(
        length: 3,
        child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                splashColor: Colors.transparent,
                icon: const Icon(
                  Icons.arrow_back_ios,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: const Text('Listings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              backgroundColor: const Color(0xffFFFCF1),
              bottom: TabBar(
                labelColor: Colors.black,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: UnderlineTabIndicator(
                  borderSide: const BorderSide(
                    width: 4,
                    color: Color(0xff4A8AF0),
                  ),
                  insets: const EdgeInsets.symmetric(
                    horizontal: (30 - 4) / 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                tabs: [
                  Tab(
                      child: Text(
                    'Active',
                    style: tabTextStyle,
                  )),
                  Tab(
                      child: Text(
                    'Pending',
                    style: tabTextStyle,
                  )),
                  Tab(
                      child: Text(
                    'Archive',
                    style: tabTextStyle,
                  )),
                ],
              ),
            ),
            body: const TabBarView(
              children: [
                Icon(Icons.directions_car),
                Icon(Icons.directions_transit),
                Icon(Icons.directions_bike),
              ],
            )));
  }
}
