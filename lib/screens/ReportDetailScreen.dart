import 'package:flutter/material.dart';
import 'package:assumemate/screens/report_list.dart';

class ReportDetailScreen extends StatelessWidget {
  final Report report;
  const ReportDetailScreen({Key? key, required this.report}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeline = _buildTimeline();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Details'),
        elevation: 0, // Modern flat design
      ),
      body: Theme(
        // Apply a custom theme for this screen
        data: Theme.of(context).copyWith(
          dividerTheme: const DividerThemeData(
            space: 30, // Increased space between timeline items
            thickness: 2,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report Header Section
                    _buildReportHeader(),

                    // Timeline Section
                    const SizedBox(height: 24),
                    _buildTimelineSection(timeline),

                    // Details Section
                    const SizedBox(height: 24),
                    _buildDetailsSection(),

                    // Images Section
                    if (report.details['images']?.isNotEmpty ?? false)
                      _buildImagesSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Report ID: ${report.id}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(report.reportStatus),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Updated: ${report.updatedAt}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toUpperCase()) {
      case 'APPROVED':
        chipColor = Colors.green;
        break;
      case 'REJECTED':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.orange;
    }

    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildTimelineSection(List<Map<String, dynamic>> timeline) {
    return Container(
        width: double.infinity,
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Timeline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...timeline.asMap().entries.map((entry) {
                  final index = entry.key;
                  final point = entry.value;
                  final isLast = index == timeline.length - 1;

                  return TimelineItem(
                    point: point,
                    isLast: isLast,
                  );
                }),
              ],
            ),
          ),
        ));
  }

  Widget _buildDetailsSection() {
    return Container(
        width: double.infinity,
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Report Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailRow('Description',
                    report.details['describe'] ?? 'No description provided'),
                _buildDetailRow(
                  'Issue Types',
                  report.details['issue_types'] != null
                      ? (report.details['issue_types'] as List).join(', ')
                      : 'No issue types provided',
                ),
                _buildDetailRow(
                    'Reporter ID', report.details['reporter_id'].toString()),
                _buildDetailRow('Reported User ID',
                    report.details['reported_user_id'].toString()),
              ],
            ),
          ),
        ));
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evidence Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: report.details['images'].length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      report.details['images'][index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.error_outline,
                              size: 48, color: Colors.red),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _buildTimeline() {
    final status = report.reportStatus.toUpperCase();
    final isApproved = status == 'APPROVED';
    final isRejected = status == 'REJECTED';

    if (status == 'PENDING') {
      return [
        {
          'status': 'Subject for Reviewing',
          'statusDescription': 'The report is under review',
          'statusCode': 'PENDING',
          'isActive': true,
        }
      ];
    }

    final timeline = [
      {
        'status': 'Reviewing - Done',
        'statusDescription': 'The review process is complete.',
        'statusCode': 'REVIEW_DONE',
        'isActive': false,
      }
    ];

    if (isApproved) {
      timeline.addAll([
        {
          'status': 'Report is Approved',
          'statusDescription': 'The report is approved.',
          'statusCode': 'APPROVED',
          'isActive': false,
        },
        {
          'status': 'Notify the user about the misconduct',
          'statusDescription':
              'The reported user is notified about the misconduct.',
          'statusCode': 'NOTIFY_USER',
          'isActive': true,
        },
      ]);
    } else if (isRejected) {
      timeline.add({
        'status': 'Report is Rejected',
        'statusDescription': 'The report is rejected.',
        'statusCode': 'REJECTED',
        'isActive': true,
      });
    }

    if (report.details['ban_user'] == true) {
      timeline.add({
        'status': 'User Banned',
        'statusDescription': 'The reported user has been banned.',
        'statusCode': 'BANNED',
        'isActive': false,
      });
    } else if (report.details['warning_issued'] == true) {
      timeline.add({
        'status': 'Warning Issued',
        'statusDescription': 'The reported user has been issued a warning.',
        'statusCode': 'WARNING',
        'isActive': false,
      });
    }

    return timeline;
  }
}

class TimelineItem extends StatelessWidget {
  final Map<String, dynamic> point;
  final bool isLast;

  const TimelineItem({
    Key? key,
    required this.point,
    required this.isLast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: point['isActive'] ? Colors.blue : Colors.grey,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: point['isActive']
                        ? Colors.blue
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point['status'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: point['isActive']
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: point['isActive'] ? Colors.blue : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    point['statusDescription'],
                    style: TextStyle(
                      fontSize: 14,
                      color: point['isActive'] ? Colors.blue : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
