import 'dart:convert';
import 'package:assumemate/screens/ReportDetailScreen.dart';
import 'package:assumemate/screens/user_auth/login_screen.dart';
import 'package:assumemate/storage/secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class Report {
  final int id;
  final Map<String, dynamic> reportReason;
  final String reportStatus;
  final String updatedAt;
  final Map<String, dynamic> details;

  Report({
    required this.id,
    required this.reportReason,
    required this.reportStatus,
    required this.updatedAt,
    required this.details,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    // Convert dynamic map to Map<String, dynamic>
    Map<String, dynamic> convertDynamicMap(dynamic map) {
      if (map == null) return {};
      if (map is Map<String, dynamic>) return map;
      return Map<String, dynamic>.from(map as Map);
    }

    // Handle details field
    var details = convertDynamicMap(json['details']);

    // Handle report_reason field
    var reportReason = convertDynamicMap(json['report_reason']);

    // Convert specific fields in details if needed
    if (details.containsKey('images') && details['images'] is List) {
      details['images'] = (details['images'] as List).cast<String>();
    }
    if (details.containsKey('issue_types') && details['issue_types'] is List) {
      details['issue_types'] = (details['issue_types'] as List).cast<String>();
    }

    return Report(
      id: json['report_id'] ?? 0,
      reportReason: reportReason,
      reportStatus: json['report_status'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      details: details,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'report_id': id,
      'report_reason': reportReason,
      'report_status': reportStatus,
      'updated_at': updatedAt,
      'details': details,
    };
  }
}

class ReportListScreen extends StatefulWidget {
  const ReportListScreen({Key? key}) : super(key: key);

  @override
  _ReportListScreenState createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Report>> futureReceivedReports;
  late Future<List<Report>> futureSentReports;
  final String? baseURL = dotenv.env['API_URL'];
  final secureStorage = SecureStorage();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeReports() async {
    setState(() {
      isLoading = true;
    });

    try {
      futureReceivedReports = fetchReports("received");
      futureSentReports = fetchReports("sent");
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing reports: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<List<Report>> fetchReports(String reportType) async {
    final apiUrl = Uri.parse('$baseURL/reports/$reportType/');
    String? token = await secureStorage.getToken();

    try {
      final response = await http.get(
        apiUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData =
            jsonDecode(response.body) as List<dynamic>;
        return responseData.map((json) {
          if (json is Map) {
            return Report.fromJson(Map<String, dynamic>.from(json));
          }
          throw FormatException('Invalid report format');
        }).toList();
      } else if (response.statusCode == 401) {
        // Handle unauthorized access
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        throw Exception('Unauthorized access');
      } else {
        throw Exception('Failed to fetch reports: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch reports: $e');
    }
  }

  Widget _buildStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Icon(Icons.pending, color: Colors.orange);
      case 'APPROVED':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'REJECTED':
        return const Icon(Icons.cancel, color: Colors.red);
      default:
        return const Icon(Icons.help, color: Colors.grey);
    }
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            error,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeReports,
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(List<Report> reports) {
    if (reports.isEmpty) {
      return const Center(
        child: Text("No Reports Found", style: TextStyle(fontSize: 16)),
      );
    }

    return RefreshIndicator(
      onRefresh: _initializeReports,
      child: ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: _buildStatusIcon(report.reportStatus),
              title: Text(
                "Report ID: ${report.id}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Reason: ${_formatReportReason(report.reportReason)}"),
                  Text("Status: ${report.reportStatus}"),
                  Text("Updated At: ${report.updatedAt}"),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportDetailScreen(report: report),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _formatReportReason(Map<String, dynamic> reason) {
    if (reason.isEmpty) return 'No reason provided';
    return reason.toString();
  }

  Widget _buildReportsFuture(Future<List<Report>> futureReports) {
    return FutureBuilder<List<Report>>(
      future: futureReports,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return _buildErrorView(snapshot.error.toString());
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return _buildReportsList(snapshot.data!);
        } else {
          return const Center(child: Text("No Reports Found"));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabTextStyle =
        GoogleFonts.poppins(textStyle: const TextStyle(fontSize: 13));

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          splashColor: Colors.transparent,
          icon: const Icon(Icons.arrow_back_ios),
          color: Colors.black,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Reports',
            style: TextStyle(
              fontSize: 18,
            )),
        backgroundColor: const Color(0xffFFFCF1),
        bottom: TabBar(
          controller: _tabController,
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
            Tab(child: Text('Sent', style: tabTextStyle)),
            Tab(child: Text('Received', style: tabTextStyle)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsFuture(futureSentReports),
          _buildReportsFuture(futureReceivedReports),
        ],
      ),
    );
  }
}
