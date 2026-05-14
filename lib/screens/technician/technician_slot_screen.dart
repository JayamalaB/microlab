import 'package:flutter/material.dart';
import 'package:microlab/theme/app_theme.dart';

class TechnicianSlotScreen extends StatefulWidget {
  final String mobile;
  const TechnicianSlotScreen({super.key, required this.mobile});

  @override
  State<TechnicianSlotScreen> createState() => _TechnicianSlotScreenState();
}

class _TechnicianSlotScreenState extends State<TechnicianSlotScreen> {
  late final List<DateTime> _days;
  late final Map<int, Set<String>> _selectedSlots;
  bool _isSaving = false;

  final List<String> _allSlots = [
    '6:00 AM', '7:00 AM', '8:00 AM', '9:00 AM',
    '10:00 AM', '11:00 AM', '12:00 PM',
    '1:00 PM', '2:00 PM', '3:00 PM',
    '4:00 PM', '5:00 PM', '6:00 PM', '7:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _days = [
      DateTime(now.year, now.month, now.day + 1),
      DateTime(now.year, now.month, now.day + 2),
    ];
    // Pre-populate with saved slots — replace with GET /api/technician/slots
    _selectedSlots = {
      0: {'9:00 AM', '10:00 AM', '1:00 PM', '4:00 PM'},
      1: {'10:00 AM', '11:00 AM', '3:00 PM', '5:00 PM'},
    };
  }

  String _formatDate(DateTime d) {
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]}';
  }

  void _toggleSlot(int dayIdx, String slot) {
    setState(() {
      final set = _selectedSlots[dayIdx]!;
      set.contains(slot) ? set.remove(slot) : set.add(slot);
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    // TODO: PUT /api/technician/slots
    // body: { slots: [{ date, times: [...] }, { date, times: [...] }] }
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Expanded(
          child: Text('Availability saved — customers can now book your slots')),
      backgroundColor: AppColors.brandGreen,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final total = _selectedSlots.values.fold<int>(0, (s, v) => s + v.length);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.brandGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Availability',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$total slots',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.brandGreenSurface,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: AppColors.brandGreen),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Select the time slots you are available for the next 2 days. Only these slots will be shown to customers when booking.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.brandGreen, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _days.length,
              itemBuilder: (_, dayIdx) {
                final day = _days[dayIdx];
                final selected = _selectedSlots[dayIdx]!;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day header
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                        decoration: BoxDecoration(
                          color: AppColors.brandGreenSurface,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14, color: AppColors.brandGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_formatDate(day),
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.brandGreen)),
                          ),
                          // Count badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: selected.isNotEmpty
                                  ? AppColors.brandGreen
                                  : AppColors.divider,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${selected.length} / ${_allSlots.length}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected.isNotEmpty
                                      ? Colors.white
                                      : AppColors.textHint),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Select all / Clear actions
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                size: 18, color: AppColors.textSecondary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onSelected: (v) {
                              setState(() {
                                if (v == 'all') {
                                  _selectedSlots[dayIdx] = Set.from(_allSlots);
                                } else {
                                  _selectedSlots[dayIdx] = {};
                                }
                              });
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'all',
                                height: 40,
                                child: Row(children: [
                                  Icon(Icons.select_all_rounded,
                                      size: 16, color: AppColors.brandGreen),
                                  SizedBox(width: 8),
                                  Text('Select all', style: TextStyle(fontSize: 13)),
                                ]),
                              ),
                              const PopupMenuItem(
                                value: 'clear',
                                height: 40,
                                child: Row(children: [
                                  Icon(Icons.clear_all_rounded,
                                      size: 16, color: AppColors.textSecondary),
                                  SizedBox(width: 8),
                                  Text('Clear all', style: TextStyle(fontSize: 13)),
                                ]),
                              ),
                            ],
                          ),
                        ]),
                      ),

                      // Slot grid
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allSlots.map((slot) {
                            final isSel = selected.contains(slot);
                            return GestureDetector(
                              onTap: () => _toggleSlot(dayIdx, slot),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? AppColors.brandGreen
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel
                                        ? AppColors.brandGreen
                                        : AppColors.divider,
                                    width: isSel ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  if (isSel) ...[
                                    const Icon(Icons.check_rounded,
                                        size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(slot,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSel
                                              ? Colors.white
                                              : AppColors.textSecondary)),
                                ]),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              disabledBackgroundColor: AppColors.brandGreen.withOpacity(0.4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : const Text('Save Availability',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}
