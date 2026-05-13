import 'package:flutter/material.dart';
import 'package:microlab/theme/app_theme.dart';
import 'package:microlab/models.dart';
import 'my_bookings_screen.dart';

class ReportsScreen extends StatelessWidget {
  // In production: pass bookings list or fetch from API
  // For now we reuse the same mock data from MyBookingsScreen
  const ReportsScreen({super.key});

  static List<BookingModel> _mockReports() {
    final member = MemberModel(
      id: 's1', name: 'Ravi Kumar', mobile: '9876543210',
      gender: 'Male', location: 'Chennai',
      address: '12, Gandhi Street, T Nagar, Chennai - 600017',
      relation: 'Self', dob: DateTime(1985, 6, 15),
    );
    return [
      BookingModel(
        id: 'BK00122001', member: member,
        tests: [
          TestModel.fromJson({'id': '4', 'name': 'Lipid Profile', 'type': 'single', 'category': 'Heart', 'description': 'Cholesterol, HDL, LDL', 'offer': 'no', 'original_price': '500', 'final_price': '500', 'doc_req': 'no', 'report_sts': '24 hrs'}),
        ],
        mode: 'Home Collection', city: 'Chennai', pincode: '600017',
        address: '12, Gandhi Street, T Nagar',
        date: DateTime.now().subtract(const Duration(days: 7)),
        timeSlot: '4:00 PM', paymentType: 'full',
        serviceCharge: 99, testsTotal: 500, grandTotal: 599, paidAmount: 599,
        status: 'Completed', createdAt: DateTime.now().subtract(const Duration(days: 8)),
        docRequired: false, docVerified: false,
        reportUrl: 'https://example.com/reports/BK00122001.pdf',
        reportReadyDate: DateTime.now().subtract(const Duration(days: 6)),
      ),
      BookingModel(
        id: 'BK00120055', member: member,
        tests: [
          TestModel.fromJson({'id': '1', 'name': 'HbA1c', 'type': 'single', 'category': 'Diabetes', 'description': '3-month average blood sugar', 'offer': 'no', 'original_price': '600', 'final_price': '540', 'doc_req': 'no', 'report_sts': '48 hrs'}),
          TestModel.fromJson({'id': '3', 'name': 'Thyroid Profile', 'type': 'single', 'category': 'Thyroid', 'description': 'T3, T4, TSH', 'offer': 'no', 'original_price': '900', 'final_price': '765', 'doc_req': 'no', 'report_sts': '24 hrs'}),
        ],
        mode: 'Home Collection', city: 'Chennai', pincode: '600017',
        address: '12, Gandhi Street, T Nagar',
        date: DateTime.now().subtract(const Duration(days: 20)),
        timeSlot: '10:00 AM', paymentType: 'full',
        serviceCharge: 99, testsTotal: 1305, grandTotal: 1404, paidAmount: 1404,
        status: 'Completed', createdAt: DateTime.now().subtract(const Duration(days: 21)),
        docRequired: false, docVerified: false,
        reportUrl: 'https://example.com/reports/BK00120055.pdf',
        reportReadyDate: DateTime.now().subtract(const Duration(days: 18)),
      ),
      BookingModel(
        id: 'BK00119800', member: member,
        tests: [
          TestModel.fromJson({'id': '8', 'name': 'Kidney Function Test', 'type': 'single', 'category': 'Kidney', 'description': 'Creatinine, urea, eGFR', 'offer': 'no', 'original_price': '450', 'final_price': '450', 'doc_req': 'no', 'report_sts': '24 hrs'}),
        ],
        mode: 'Lab Test', city: 'Chennai',
        address: null, pincode: null,
        date: DateTime.now().subtract(const Duration(days: 35)),
        timeSlot: '1:00 PM', paymentType: 'full',
        serviceCharge: 99, testsTotal: 450, grandTotal: 549, paidAmount: 549,
        status: 'Completed', createdAt: DateTime.now().subtract(const Duration(days: 36)),
        docRequired: false, docVerified: false,
        reportUrl: null, // Report being processed — no download yet
        reportReadyDate: null,
      ),
    ];
  }

  String _formatDate(DateTime d) {
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year}';
  }

  void _download(BuildContext context, BookingModel booking) {
    // TODO: url_launcher → launch(booking.reportUrl!)
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.download_outlined, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text('Downloading ${booking.id} report…')),
      ]),
      backgroundColor: AppColors.brandGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final reports = _mockReports();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.brandGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reports & Results',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: reports.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.brandGreenLight),
                  const SizedBox(height: 16),
                  const Text('No reports yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Reports for completed tests appear here.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: reports.length,
              itemBuilder: (_, i) {
                final b = reports[i];
                final hasReport = b.reportUrl != null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Column(
                      children: [
                        // Header strip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          color: hasReport
                              ? AppColors.brandGreenSurface
                              : const Color(0xFFFFF8E1),
                          child: Row(
                            children: [
                              Icon(
                                hasReport ? Icons.check_circle_outline : Icons.hourglass_top_rounded,
                                size: 14,
                                color: hasReport ? AppColors.brandGreen : const Color(0xFFE65100),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                hasReport ? 'Report Ready' : 'Processing',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: hasReport ? AppColors.brandGreen : const Color(0xFFE65100)),
                              ),
                              const Spacer(),
                              Text(b.id,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Customer + date
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(b.member.name,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary)),
                                  ),
                                  Text(_formatDate(b.date),
                                      style: const TextStyle(
                                          fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Tests list
                              Wrap(
                                spacing: 6, runSpacing: 4,
                                children: b.tests.map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: t.type == 'package'
                                        ? AppColors.brandGreenSurface
                                        : const Color(0xFFEEF4FB),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(t.name,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: t.type == 'package'
                                              ? AppColors.brandGreen
                                              : const Color(0xFF1565C0))),
                                )).toList(),
                              ),

                              const SizedBox(height: 10),

                              // Report ready date
                              if (b.reportReadyDate != null)
                                Row(children: [
                                  const Icon(Icons.event_available_outlined,
                                      size: 12, color: AppColors.textHint),
                                  const SizedBox(width: 4),
                                  Text('Available since ${_formatDate(b.reportReadyDate!)}',
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.textSecondary)),
                                ]),

                              if (!hasReport)
                                Row(children: [
                                  const Icon(Icons.schedule_outlined,
                                      size: 12, color: AppColors.textHint),
                                  const SizedBox(width: 4),
                                  Text('Report ready within ${b.tests.map((t) => t.reportStatus).toSet().join(' / ')}',
                                      style: const TextStyle(
                                          fontSize: 11, color: AppColors.textSecondary)),
                                ]),

                              const SizedBox(height: 12),

                              // Download / Processing button
                              SizedBox(
                                width: double.infinity,
                                child: hasReport
                                    ? ElevatedButton.icon(
                                        onPressed: () => _download(context, b),
                                        icon: const Icon(Icons.download_outlined, size: 18),
                                        label: const Text('Download Report'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.brandGreen,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(vertical: 11),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10)),
                                        ),
                                      )
                                    : OutlinedButton.icon(
                                        onPressed: null,
                                        icon: const Icon(Icons.hourglass_empty_outlined, size: 16),
                                        label: const Text('Report being processed'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.textHint,
                                          side: const BorderSide(color: AppColors.divider),
                                          padding: const EdgeInsets.symmetric(vertical: 11),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
