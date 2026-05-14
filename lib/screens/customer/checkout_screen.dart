import 'package:flutter/material.dart';
import 'package:microlab/services/razorpay_service.dart';
import 'package:microlab/theme/app_theme.dart';
import 'customer_dashboard_screen.dart';
import 'customer_home_screen.dart';
import 'my_bookings_screen.dart';
import 'booking_widgets.dart';
import 'package:microlab/models.dart';



// ─── Checkout Screen ──────────────────────────────────────────────────────────

class CheckoutScreen extends StatefulWidget {
  final MemberModel member;
  final List<TestModel> cart;
  final String mode;
  final String? address;
  final String? pincode;
  final String? city;
  final BranchModel? branch;
  final bool isVip;

  const CheckoutScreen({
    super.key,
    required this.member,
    required this.cart,
    required this.mode,
    this.address,
    this.pincode,
    this.city,
    this.branch,
    this.isVip = false,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // ── Config ────────────────────────────────────────────────
  static const double _serviceChargeFlat = 99.0;

  // ── Date ─────────────────────────────────────────────────
  DateTime? _selectedDate;

  // ── Available slots only (no unavailable shown) ───────────
  // TODO: replace with GET /api/slots?date=_selectedDate
  final List<TimeSlot> _availableSlots = const [
    TimeSlot(id: '1', label: '10:00 AM', time: '10:00'),
    TimeSlot(id: '2', label: '12:00 PM', time: '12:00'),
    TimeSlot(id: '3', label: '1:00 PM',  time: '13:00'),
    TimeSlot(id: '4', label: '4:00 PM',  time: '16:00'),
    TimeSlot(id: '5', label: '5:00 PM',  time: '17:00'),
  ];
  TimeSlot? _selectedSlot;

  // ── Document upload state ─────────────────────────────────
  bool _docUploaded = false;
  bool _docVerified = false; // set by technician via API; mock as false

  // ── Payment ───────────────────────────────────────────────
  // 'service_charge' always available; 'full' only if !docRequired OR docVerified
  String _paymentType = 'service_charge';
  bool _isProcessing = false;

  // ── VIP: selected technician ─────────────────────────────
  TechnicianModel? _selectedTechnician;

  // ── VIP: mock available technicians (replace with GET /api/technicians?date=&slot=) ──
  final List<TechnicianModel> _availableTechnicians = const [
    TechnicianModel(id: 't1', name: 'Dr. Arjun Sharma', mobile: '9876500001', rating: 4.9, totalReviews: 142, experience: '6 years', specializations: ['Phlebotomy', 'Diabetes', 'General'], available: true),
    TechnicianModel(id: 't2', name: 'Priya Nair', mobile: '9876500002', rating: 4.7, totalReviews: 98, experience: '4 years', specializations: ['General', 'Thyroid', 'Paediatric'], available: true),
    TechnicianModel(id: 't3', name: 'Karthik Rajan', mobile: '9876500003', rating: 4.8, totalReviews: 115, experience: '5 years', specializations: ['Heart', 'Kidney', 'General'], available: true),
    TechnicianModel(id: 't4', name: 'Meena Devi', mobile: '9876500004', rating: 4.6, totalReviews: 76, experience: '3 years', specializations: ['Vitamins', 'Wellness', 'General'], available: false),
  ];

  // ── Computed ──────────────────────────────────────────────
  double get _testsTotal => widget.cart.fold(0, (s, t) => s + t.finalPrice);
  double get _serviceCharge => _serviceChargeFlat;
  double get _grandTotal => _testsTotal + _serviceCharge;

  // Any test in cart requiring a document
  bool get _anyDocRequired => widget.cart.any((t) => t.docRequired);

  // Full payment enabled only when no doc required OR doc verified by tech
  bool get _fullPaymentEnabled => !_anyDocRequired || _docVerified;

  double get _payableNow =>
      _paymentType == 'service_charge' ? _serviceCharge : _grandTotal;

  double get _payableLater =>
      _paymentType == 'service_charge' ? _testsTotal : 0;

  bool get _canProceed => _selectedDate != null && _selectedSlot != null && (!widget.isVip || _selectedTechnician != null);

  // ── Date picker (future only) ─────────────────────────────
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    clearRazorpay();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? tomorrow,
      firstDate: tomorrow,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'SELECT APPOINTMENT DATE',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.brandGreen,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
        _selectedTechnician = null; // reset so VIP must re-pick per date
      });
    }
  }

  // ── Mock prescription upload ──────────────────────────────
  Future<void> _uploadDoc() async {
    // TODO: image_picker → multipart POST /api/upload/prescription
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _docUploaded = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.upload_file_outlined, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text('Prescription uploaded. Awaiting technician verification.')),
          ]),
          backgroundColor: AppColors.brandGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // ── Open Razorpay checkout ───────────────────────────────
  void _proceedToPayment() {
    if (!_canProceed) return;
    setState(() => _isProcessing = true);

    // TODO: fetch order_id from your backend first
    // POST /api/payment/create-order { amount: _payableNow, currency: 'INR' }
    // then use response['order_id'] below

    final options = {
      'key': 'rzp_test_SonqjjPurqlLci', // replace with your Razorpay key
      'amount': (_payableNow * 100).toInt(), // paise
      'name': 'MicroLab',
      'description': widget.cart.map((t) => t.name).join(', '),
      'prefill': {
        'contact': widget.member.mobile,
        'email': widget.member.email ?? '',
        'name': widget.member.name,
      },
      'notes': {
        'booking_mode': widget.mode,
        'customer_name': widget.member.name,
        'tests': widget.cart.map((t) => t.name).join(', '),
      },
      'theme': {
        'color': '#0A5C4A',
      },
      'retry': {
        'enabled': true,
        'max_count': 2,
      },
    };

    openRazorpay(
      options: options,
      onSuccess: (paymentId) => _confirmBooking(paymentId),
      onError: (message) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            message == 'Payment cancelled'
                ? 'Payment cancelled'
                : 'Payment failed: $message'),
          backgroundColor: message == 'Payment cancelled'
              ? AppColors.textSecondary
              : Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      },
    );
  }

  // ── Confirm booking after Razorpay success ───────────
  Future<void> _confirmBooking(String razorpayPaymentId) async {
    setState(() => _isProcessing = true);

    // TODO: POST /api/bookings { ...bookingData, razorpay_payment_id: razorpayPaymentId }
    await Future.delayed(const Duration(milliseconds: 1200));

    final booking = BookingModel(
      id: 'BK${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      member: widget.member,
      tests: widget.cart,
      mode: widget.mode,
      address: widget.address,
      pincode: widget.pincode,
      city: widget.city,
      branch: widget.branch,
      date: _selectedDate!,
      timeSlot: _selectedSlot?.label ?? '',
      paymentType: _paymentType,
      serviceCharge: _serviceCharge,
      testsTotal: _testsTotal,
      grandTotal: _grandTotal,
      paidAmount: _payableNow,
      status: 'Technician Allocated',
      createdAt: DateTime.now(),
      docRequired: _anyDocRequired,
      docVerified: _docVerified,
      isVip: widget.isVip,
      selectedTechnician: _selectedTechnician,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(booking: booking),
        ),
      );
    }
  }

  String _formatDate(DateTime d) {
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.brandGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Checkout',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [

          // ── Order Summary ─────────────────────────────────
          _SectionCard(
            title: 'Order Summary',
            icon: Icons.receipt_long_outlined,
            child: Column(
              children: [
                ...widget.cart.map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: t.type == 'package'
                              ? AppColors.brandGreen
                              : const Color(0xFF1565C0),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                            if (t.docRequired)
                              const Text('Prescription required',
                                  style: TextStyle(fontSize: 11, color: Color(0xFFE65100))),
                          ],
                        ),
                      ),
                      Text('₹${t.finalPrice.toInt()}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Collection Info ───────────────────────────────
          _SectionCard(
            title: widget.mode,
            icon: widget.mode == 'Home Collection' ? Icons.home_outlined : Icons.local_hospital_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.mode == 'Home Collection') ...[
                  if (widget.address != null && widget.address!.isNotEmpty)
                    _InfoLine(Icons.home_outlined, widget.address!),
                  Row(children: [
                    if (widget.pincode != null)
                      Expanded(child: _InfoLine(Icons.pin_outlined, widget.pincode!)),
                    if (widget.pincode != null && widget.city != null)
                      const SizedBox(width: 12),
                    if (widget.city != null)
                      Expanded(child: _InfoLine(Icons.location_city_outlined, widget.city!)),
                  ]),
                ],
                if (widget.mode == 'Lab Test' && widget.branch != null) ...[
                  if (widget.branch != null) _InfoLine(Icons.local_hospital_outlined, widget.branch!.name),
                  if (widget.branch != null) _InfoLine(Icons.location_on_outlined, widget.branch!.address),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Date Selection ────────────────────────────────
          _SectionCard(
            title: 'Appointment Date',
            icon: Icons.calendar_today_outlined,
            required: true,
            child: GestureDetector(
              onTap: _pickDate,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedDate != null ? AppColors.brandGreenSurface : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDate != null ? AppColors.brandGreen : AppColors.divider,
                    width: _selectedDate != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_outlined,
                        size: 20,
                        color: _selectedDate != null ? AppColors.brandGreen : AppColors.textHint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate != null ? _formatDate(_selectedDate!) : 'Select appointment date',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: _selectedDate != null ? FontWeight.w500 : FontWeight.w400,
                            color: _selectedDate != null ? AppColors.textPrimary : AppColors.textHint),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: _selectedDate != null ? AppColors.brandGreen : AppColors.textHint),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── Time Slot (available only) ────────────────────
          _SectionCard(
            title: 'Time Slot',
            icon: Icons.schedule_outlined,
            required: true,
            child: _selectedDate == null
                ? const Text('Please select a date first',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint, fontStyle: FontStyle.italic))
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _availableSlots.map((slot) {
                      final isSelected = _selectedSlot?.id == slot.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSlot = slot),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.brandGreen : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.brandGreen : AppColors.divider,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(slot.label,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.textPrimary)),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 14),

          // ── Document Upload (if any test requires it) ─────
          if (_anyDocRequired)
            _SectionCard(
              title: 'Prescription / Document',
              icon: Icons.description_outlined,
              required: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.4)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFE65100)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'One or more tests require a doctor\'s prescription. Upload it here. Full payment will be available after the technician verifies your document.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF795548), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (!_docUploaded)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _uploadDoc,
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: const Text('Upload Prescription'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brandGreen,
                          side: const BorderSide(color: AppColors.brandGreen, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                  if (_docUploaded && !_docVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreenSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.brandGreenLight),
                      ),
                      child: const Row(children: [
                        Icon(Icons.check_circle_outline, size: 16, color: AppColors.brandGreen),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Prescription uploaded',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandGreen)),
                              Text('Awaiting technician verification',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ]),
                    ),

                  if (_docVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreenSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.brandGreen),
                      ),
                      child: const Row(children: [
                        Icon(Icons.verified_outlined, size: 16, color: AppColors.brandGreen),
                        SizedBox(width: 8),
                        Expanded(child: Text('Document verified by technician',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandGreen))),
                      ]),
                    ),
                ],
              ),
            ),

          if (_anyDocRequired) const SizedBox(height: 14),

          // ── Payment Options ───────────────────────────────
          _SectionCard(
            title: 'Payment Option',
            icon: Icons.payment_outlined,
            required: true,
            child: Column(
              children: [
                // Option 1: Service charge only (always available)
                _PaymentOptionTile(
                  selected: _paymentType == 'service_charge',
                  title: 'Pay Service Charge Now',
                  subtitle: 'Pay ₹${_serviceCharge.toInt()} now to confirm booking · Remaining ₹${_testsTotal.toInt()} collected at home',
                  amount: '₹${_serviceCharge.toInt()} now',
                  badge: 'RECOMMENDED',
                  badgeColor: AppColors.brandGreen,
                  enabled: true,
                  onTap: () => setState(() => _paymentType = 'service_charge'),
                ),
                const SizedBox(height: 10),

                // Option 2: Full amount (locked if doc required & not verified)
                _PaymentOptionTile(
                  selected: _paymentType == 'full',
                  title: 'Pay Full Amount Now',
                  subtitle: _fullPaymentEnabled
                      ? 'Pay complete ₹${_grandTotal.toInt()} (tests + service charge) · Nothing due later'
                      : 'Available after technician verifies your prescription',
                  amount: '₹${_grandTotal.toInt()} now',
                  badge: _fullPaymentEnabled ? 'SAVE TIME' : 'LOCKED',
                  badgeColor: _fullPaymentEnabled ? const Color(0xFF1565C0) : AppColors.textHint,
                  enabled: _fullPaymentEnabled,
                  onTap: _fullPaymentEnabled ? () => setState(() => _paymentType = 'full') : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── VIP: Technician Selection ─────────────────────
          if (widget.isVip) ...[
            _SectionCard(
              title: 'Choose Technician',
              icon: Icons.medical_services_outlined,
              required: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedDate == null || _selectedSlot == null)
                    const Text(
                      'Please select a date and time slot first to see available technicians.',
                      style: TextStyle(fontSize: 12, color: AppColors.textHint, fontStyle: FontStyle.italic),
                    )
                  else ...[
                    Text(
                      'Available for ${_selectedSlot!.label} on ${_formatDate(_selectedDate!)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    // TODO: replace with GET /api/technicians?date=_selectedDate&slot=_selectedSlot.time
                    ..._availableTechnicians
                        .where((t) => t.available)
                        .map((t) => _TechnicianTile(
                      technician: t,
                      selected: _selectedTechnician?.id == t.id,
                      onTap: t.available
                          ? () => setState(() => _selectedTechnician = t)
                          : null,
                    )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Billing Summary ───────────────────────────────
          _SectionCard(
            title: 'Billing Summary',
            icon: Icons.calculate_outlined,
            child: Column(
              children: [
                _BillRow('Tests Total', '₹${_testsTotal.toInt()}'),
                _BillRow('Service Charge', '+ ₹${_serviceCharge.toInt()}', sub: true),
                const Divider(height: 20),
                _BillRow('Grand Total', '₹${_grandTotal.toInt()}', bold: true),
                const SizedBox(height: 8),
                _BillRow('Pay Now', '₹${_payableNow.toInt()}', bold: true, green: true),
                if (_paymentType == 'service_charge')
                  _BillRow('Pay at Collection', '₹${_payableLater.toInt()}', sub: true),
              ],
            ),
          ),
        ],
      ),

      // ── Bottom Pay Button ─────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_canProceed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _selectedDate == null
                      ? 'Please select a date'
                      : _selectedSlot == null
                          ? 'Please select a time slot'
                          : widget.isVip && _selectedTechnician == null
                              ? 'Please choose your preferred technician'
                              : '',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFD32F2F)),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _canProceed && !_isProcessing ? _proceedToPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  disabledBackgroundColor: AppColors.brandGreen.withOpacity(0.35),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isProcessing
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Text('Pay ₹${_payableNow.toInt()} via Razorpay',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



// ─── Technician Tile ──────────────────────────────────────────────────────────

class _TechnicianTile extends StatelessWidget {
  final TechnicianModel technician;
  final bool selected;
  final VoidCallback? onTap;

  const _TechnicianTile({
    required this.technician,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandGreenSurface : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.brandGreen : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.brandGreen
                    : AppColors.brandGreenSurface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  technician.name.isNotEmpty
                      ? technician.name.split(' ').map((w) => w[0]).take(2).join()
                      : '?',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.brandGreen),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(technician.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.brandGreen
                              : AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        size: 12, color: Color(0xFFFFB300)),
                    const SizedBox(width: 3),
                    Text('${technician.rating}  ·  ${technician.experience}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                  const SizedBox(height: 3),
                  Text(technician.specializations.join(', '),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textHint),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.brandGreen : AppColors.divider,
                  width: selected ? 5 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Payment Option Tile ──────────────────────────────────────────────────────

class _PaymentOptionTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final String amount;
  final String badge;
  final Color badgeColor;
  final bool enabled;
  final VoidCallback? onTap;

  const _PaymentOptionTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.badge,
    required this.badgeColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: !enabled
              ? const Color(0xFFF5F5F5)
              : selected
                  ? badgeColor.withOpacity(0.05)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: !enabled
                ? AppColors.divider
                : selected
                    ? badgeColor
                    : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20, height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: !enabled ? AppColors.divider : selected ? badgeColor : AppColors.divider,
                  width: selected ? 5 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: !enabled
                                  ? AppColors.textHint
                                  : selected
                                      ? badgeColor
                                      : AppColors.textPrimary)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(badge,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                                color: badgeColor, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12,
                          color: !enabled ? AppColors.textHint : AppColors.textSecondary,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Text(amount,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                          color: !enabled ? AppColors.textHint : badgeColor)),
                ],
              ),
            ),
            if (!enabled)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textHint),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Booking Confirmation ─────────────────────────────────────────────────────

class BookingConfirmationScreen extends StatelessWidget {
  final BookingModel booking;
  const BookingConfirmationScreen({super.key, required this.booking});

  String _formatDate(DateTime d) {
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: [
                  // Success banner
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.brandGreenSurface, shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle_outline_rounded,
                              size: 40, color: AppColors.brandGreen),
                        ),
                        const SizedBox(height: 16),
                        const Text('Booking Confirmed!',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 6),
                        Text(booking.id,
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 16),
                        BookingStatusBadge(status: booking.status),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    title: 'Booking Details',
                    icon: Icons.info_outline_rounded,
                    child: Column(
                      children: [
                        _ConfirmRow(Icons.person_outline, 'Customer', booking.member.name),
                        _ConfirmRow(Icons.event_outlined, 'Date', _formatDate(booking.date)),
                        _ConfirmRow(Icons.schedule_outlined, 'Time Slot', booking.timeSlot),
                        _ConfirmRow(
                          booking.mode == 'Home Collection' ? Icons.home_outlined : Icons.local_hospital_outlined,
                          'Mode', booking.mode,
                        ),
                        if (booking.isVip && booking.selectedTechnician != null)
                          _ConfirmRow(Icons.medical_services_outlined,
                              'Technician', booking.selectedTechnician!.name),
                        if (booking.mode == 'Home Collection' && booking.city != null)
                          _ConfirmRow(Icons.location_on_outlined, 'Location',
                              '${booking.city}${booking.pincode != null ? ', ${booking.pincode}' : ''}'),
                        if (booking.mode == 'Lab Test' && booking.branch != null)
                          if (booking.branch != null) _ConfirmRow(Icons.local_hospital_outlined, 'Branch', booking.branch!.name),
                        if (booking.selectedTechnician != null)
                          _ConfirmRow(Icons.medical_services_outlined, 'Technician',
                              '${booking.selectedTechnician!.name}  ★ ${booking.selectedTechnician!.rating}'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    title: 'Tests Booked',
                    icon: Icons.science_outlined,
                    child: Column(
                      children: booking.tests.map((t) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6,
                              decoration: BoxDecoration(
                                color: t.type == 'package' ? AppColors.brandGreen : const Color(0xFF1565C0),
                                shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(t.name,
                                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary))),
                            Text('₹${t.finalPrice.toInt()}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    title: 'Payment',
                    icon: Icons.payment_outlined,
                    child: Column(
                      children: [
                        _ConfirmRow(Icons.receipt_outlined, 'Tests Total', '₹${booking.testsTotal.toInt()}'),
                        _ConfirmRow(Icons.add_circle_outline, 'Service Charge', '+ ₹${booking.serviceCharge.toInt()}'),
                        _ConfirmRow(Icons.calculate_outlined, 'Grand Total', '₹${booking.grandTotal.toInt()}'),
                        const Divider(height: 16),
                        _ConfirmRow(Icons.check_circle_outline, 'Paid Now',
                            '₹${booking.paidAmount.toInt()}', valueColor: AppColors.brandGreen),
                        if (booking.paymentType == 'service_charge')
                          _ConfirmRow(Icons.schedule_outlined, 'Due at Collection',
                              '₹${(booking.grandTotal - booking.paidAmount).toInt()}',
                              valueColor: const Color(0xFFE65100)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreenSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.brandGreenLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("What's next?",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandGreen)),
                        SizedBox(height: 10),
                        _NextStep('1', 'A technician has been allocated to your booking'),
                        _NextStep('2', 'You will receive a call 1 hour before the appointment'),
                        _NextStep('3', 'Keep your samples ready as per test requirements'),
                        _NextStep('4', 'Reports will be shared within the promised time'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brandGreen,
                        side: const BorderSide(color: AppColors.brandGreen, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back to Home', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => MyBookingsScreen(initialBooking: booking)));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('My Bookings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool required;
  const _SectionCard({required this.title, required this.icon, required this.child, this.required = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: AppColors.brandGreen),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              if (required)
                const Text(' *', style: TextStyle(color: Color(0xFFD32F2F), fontSize: 14)),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.textHint),
            const SizedBox(width: 6),
            Flexible(child: Text(text, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          ],
        ),
      );
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool green;
  final bool sub;
  const _BillRow(this.label, this.value, {this.bold = false, this.green = false, this.sub = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(
                fontSize: sub ? 12 : 13,
                color: sub ? AppColors.textSecondary : AppColors.textPrimary)),
            Text(value, style: TextStyle(
                fontSize: sub ? 12 : 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: green ? AppColors.brandGreen : AppColors.textPrimary)),
          ],
        ),
      );
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _ConfirmRow(this.icon, this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: AppColors.brandGreen),
            const SizedBox(width: 10),
            SizedBox(width: 110,
              child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            Expanded(
              child: Text(value, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary)),
            ),
          ],
        ),
      );
}

class _NextStep extends StatelessWidget {
  final String number;
  final String text;
  const _NextStep(this.number, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(color: AppColors.brandGreen, shape: BoxShape.circle),
              child: Center(child: Text(number,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.brandGreen, height: 1.4))),
          ],
        ),
      );
}
