import 'package:flutter/material.dart';
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

  // ── Show payment method sheet, then confirm ──────────────
  void _proceedToPayment() {
    if (!_canProceed) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentMethodSheet(
        amount: _payableNow,
        onPaid: (method) {
          Navigator.pop(context); // close sheet
          _confirmBooking(method);
        },
      ),
    );
  }

  // ── Confirm booking after payment method chosen ────────
  Future<void> _confirmBooking(String paymentMethod) async {
    setState(() => _isProcessing = true);

    // TODO: POST /api/bookings { ...bookingData, payment_method: paymentMethod }
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
                    : Text('Pay ₹${_payableNow.toInt()} · Choose Payment',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Payment Method Sheet ─────────────────────────────────────────────────────

class _PaymentMethodSheet extends StatefulWidget {
  final double amount;
  final void Function(String method) onPaid;

  const _PaymentMethodSheet({required this.amount, required this.onPaid});

  @override
  State<_PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<_PaymentMethodSheet> {
  String? _selected; // selected payment method id
  String? _selectedUpi; // selected UPI app
  bool _isProcessing = false;

  final List<_PayMethod> _methods = const [
    _PayMethod(id: 'upi', label: 'UPI', subtitle: 'Pay via UPI apps', icon: Icons.account_balance_wallet_outlined, color: Color(0xFF6A1B9A)),
    _PayMethod(id: 'card', label: 'Credit / Debit Card', subtitle: 'Visa, Mastercard, RuPay', icon: Icons.credit_card_outlined, color: Color(0xFF1565C0)),
    _PayMethod(id: 'netbanking', label: 'Net Banking', subtitle: 'All major banks', icon: Icons.account_balance_outlined, color: Color(0xFF00695C)),
    _PayMethod(id: 'wallet', label: 'Wallet', subtitle: 'Paytm, PhonePe, Amazon Pay', icon: Icons.account_balance_wallet_outlined, color: Color(0xFFE65100)),
  ];

  final List<_UpiApp> _upiApps = const [
    _UpiApp(id: 'gpay',    label: 'Google Pay',  color: Color(0xFF1A73E8)),
    _UpiApp(id: 'phonepe', label: 'PhonePe',     color: Color(0xFF5F259F)),
    _UpiApp(id: 'paytm',   label: 'Paytm',       color: Color(0xFF00BAF2)),
    _UpiApp(id: 'bhim',    label: 'BHIM',        color: Color(0xFF004C97)),
    _UpiApp(id: 'other',   label: 'Other UPI',   color: Color(0xFF43A047)),
  ];

  // UPI ID fields
  final _upiCtrl = TextEditingController();
  bool _showUpiId = false;

  // Card fields
  final _cardNumCtrl   = TextEditingController();
  final _cardNameCtrl  = TextEditingController();
  final _cardExpiryCtrl = TextEditingController();
  final _cardCvvCtrl   = TextEditingController();

  @override
  void dispose() {
    _upiCtrl.dispose();
    _cardNumCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_selected == null) return;
    setState(() => _isProcessing = true);
    // TODO: integrate real payment gateway (Razorpay / Stripe)
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) {
      setState(() => _isProcessing = false);
      widget.onPaid(_selected!);
    }
  }

  bool get _readyToPay {
    if (_selected == null) return false;
    if (_selected == 'upi') {
      if (_showUpiId) return _upiCtrl.text.trim().contains('@');
      return _selectedUpi != null;
    }
    if (_selected == 'card') {
      return _cardNumCtrl.text.replaceAll(' ', '').length == 16 &&
             _cardNameCtrl.text.trim().isNotEmpty &&
             _cardExpiryCtrl.text.length == 5 &&
             _cardCvvCtrl.text.length == 3;
    }
    return true; // netbanking, wallet — just need selection
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      child: Column(
        children: [
          // Handle + header
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Choose Payment Method',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('Amount to pay: ₹${widget.amount.toInt()}',
                          style: const TextStyle(fontSize: 13, color: AppColors.brandGreen, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreenSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('₹${widget.amount.toInt()}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.brandGreen)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Method tiles ────────────────────────────
                  ..._methods.map((m) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MethodTile(
                        method: m,
                        selected: _selected == m.id,
                        onTap: () => setState(() {
                          _selected = m.id;
                          _selectedUpi = null;
                          _showUpiId = false;
                        }),
                      ),

                      // UPI expanded section
                      if (_selected == 'upi' && m.id == 'upi') ...[
                        const SizedBox(height: 10),
                        Container(
                          margin: const EdgeInsets.only(left: 8, right: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // UPI app chips
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _upiApps.map((app) {
                                  final sel = _selectedUpi == app.id;
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedUpi = app.id;
                                      _showUpiId = app.id == 'other';
                                    }),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 160),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: sel ? app.color.withOpacity(0.1) : AppColors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: sel ? app.color : AppColors.divider,
                                          width: sel ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8, height: 8,
                                            decoration: BoxDecoration(color: app.color, shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 7),
                                          Text(app.label,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                                  color: sel ? app.color : AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              // UPI ID field (for Other)
                              if (_showUpiId) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _upiCtrl,
                                  onChanged: (_) => setState(() {}),
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Enter UPI ID (e.g. name@upi)',
                                    hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                                    prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18, color: AppColors.textHint),
                                    filled: true, fillColor: AppColors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],

                      // Card expanded section
                      if (_selected == 'card' && m.id == 'card') ...[
                        const SizedBox(height: 10),
                        Container(
                          margin: const EdgeInsets.only(left: 8, right: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Column(
                            children: [
                              // Card number
                              _CardField(
                                controller: _cardNumCtrl,
                                hint: 'Card number',
                                icon: Icons.credit_card_outlined,
                                keyboardType: TextInputType.number,
                                maxLength: 19,
                                onChanged: (v) {
                                  // Auto-space every 4 digits
                                  final digits = v.replaceAll(' ', '');
                                  final spaced = digits.replaceAllMapped(
                                    RegExp(r'.{4}'),
                                    (m) => '${m.group(0)} ',
                                  ).trimRight();
                                  if (spaced != v) {
                                    _cardNumCtrl.value = TextEditingValue(
                                      text: spaced,
                                      selection: TextSelection.collapsed(offset: spaced.length),
                                    );
                                  }
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 10),
                              // Cardholder name
                              _CardField(
                                controller: _cardNameCtrl,
                                hint: 'Cardholder name',
                                icon: Icons.person_outline,
                                keyboardType: TextInputType.name,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                  child: _CardField(
                                    controller: _cardExpiryCtrl,
                                    hint: 'MM/YY',
                                    icon: Icons.calendar_month_outlined,
                                    keyboardType: TextInputType.number,
                                    maxLength: 5,
                                    onChanged: (v) {
                                      if (v.length == 2 && !v.contains('/')) {
                                        _cardExpiryCtrl.value = TextEditingValue(
                                          text: '$v/',
                                          selection: const TextSelection.collapsed(offset: 3),
                                        );
                                      }
                                      setState(() {});
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _CardField(
                                    controller: _cardCvvCtrl,
                                    hint: 'CVV',
                                    icon: Icons.lock_outline,
                                    keyboardType: TextInputType.number,
                                    maxLength: 3,
                                    obscureText: true,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 10),
                    ],
                  )),

                  // Secure payment note
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.textHint),
                      SizedBox(width: 4),
                      Text('100% secure & encrypted payment',
                          style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Pay button
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _readyToPay && !_isProcessing ? _pay : null,
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
                    : Text(
                        _selected == null ? 'Select a payment method' : 'Pay ₹${widget.amount.toInt()}',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting data classes ──────────────────────────────────────────────────

class _PayMethod {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _PayMethod({required this.id, required this.label, required this.subtitle, required this.icon, required this.color});
}

class _UpiApp {
  final String id;
  final String label;
  final Color color;
  const _UpiApp({required this.id, required this.label, required this.color});
}

class _MethodTile extends StatelessWidget {
  final _PayMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTile({required this.method, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? method.color.withOpacity(0.05) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? method.color : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: method.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(method.icon, size: 20, color: method.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected ? method.color : AppColors.textPrimary)),
                  Text(method.subtitle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? method.color : AppColors.divider,
                  width: selected ? 5 : 1.5,
                ),
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int? maxLength;
  final bool obscureText;
  final ValueChanged<String> onChanged;

  const _CardField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    required this.onChanged,
    this.maxLength,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        obscureText: obscureText,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
          prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
          counterText: '',
          filled: true, fillColor: AppColors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.divider)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        ),
      );
}


// ─── Technician Tile (VIP only) ───────────────────────────────────────────────

class _TechnicianTile extends StatelessWidget {
  final TechnicianModel technician;
  final bool selected;
  final VoidCallback? onTap;
  const _TechnicianTile({required this.technician, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: disabled
              ? AppColors.background
              : selected
                  ? AppColors.brandGreenSurface
                  : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabled
                ? AppColors.divider
                : selected
                    ? AppColors.brandGreen
                    : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar with initials
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: disabled
                    ? AppColors.divider
                    : selected
                        ? AppColors.brandGreen
                        : AppColors.brandGreenSurface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  technician.name.split(' ').map((p) => p[0]).take(2).join(),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(technician.name,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: disabled ? AppColors.textHint : AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (disabled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Unavailable',
                              style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB300)),
                      const SizedBox(width: 3),
                      Text('${technician.rating}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text(' (${technician.totalReviews})',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 10),
                      const Icon(Icons.work_outline, size: 12, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(technician.experience,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4, runSpacing: 4,
                    children: technician.specializations.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: disabled ? AppColors.background : AppColors.brandGreenSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(s,
                          style: TextStyle(
                              fontSize: 10,
                              color: disabled ? AppColors.textHint : AppColors.brandGreen)),
                    )).toList(),
                  ),
                ],
              ),
            ),

            // Radio
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18, height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: disabled ? AppColors.divider : selected ? AppColors.brandGreen : AppColors.divider,
                  width: selected ? 5 : 1.5,
                ),
                color: AppColors.white,
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
