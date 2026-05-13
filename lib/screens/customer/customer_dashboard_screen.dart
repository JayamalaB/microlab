import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:microlab/theme/app_theme.dart';
import 'customer_home_screen.dart';
import 'checkout_screen.dart';
import 'my_bookings_screen.dart';
import 'package:microlab/models.dart';
import 'reports_screen.dart';
import 'offers_screen.dart';



// ─── Screen ───────────────────────────────────────────────────────────────────

class CustomerDashboardScreen extends StatefulWidget {
  final MemberModel member;
  final List<TestModel> initialCartTests;
  final bool isVip;
  const CustomerDashboardScreen({
    super.key,
    required this.member,
    this.initialCartTests = const [],
    this.isVip = false,
  });

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ── Collection mode ───────────────────────────────────────
  String _mode = 'Home Collection'; // or 'Lab Test'
  final List<String> _modes = ['Home Collection', 'Lab Test'];

  // ── Location fields ───────────────────────────────────────
  String? _pincode;
  String? _city;
  BranchModel? _selectedBranch;
  bool _loadingBranches = false;

  // ── Cart ──────────────────────────────────────────────────
  final List<TestModel> _cart = [];
  bool get _isLabTest => _mode == 'Lab Test';

  // ── Tests/Packages ────────────────────────────────────────
  bool _loadingTests = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showOffersOnly = false;

  // Mock branches — replace with GET /api/branches
  List<BranchModel> _branches = [];

  // Mock tests — replace with GET /api/tests
  List<TestModel> _allTests = [];
  List<TestModel> get _filteredTests {
    var list = _allTests;
    if (_showOffersOnly) {
      list = list.where((t) => t.hasOffer).toList();
    }
    if (_selectedCategory != 'All') {
      list = list.where((t) => t.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((t) =>
        t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        t.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    return list;
  }

  List<String> get _categories {
    final cats = {'All', ..._allTests.map((t) => t.category)};
    return cats.toList();
  }

  @override
  void initState() {
    super.initState();
    _loadMockData();
    // Pre-add tests from offers/other screens
    if (widget.initialCartTests.isNotEmpty) {
      _cart.addAll(widget.initialCartTests);
    }
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  void _loadMockData() {
    setState(() => _loadingTests = true);

    // Mock API response — replace with:
    // GET /api/tests → List<TestModel>
    // GET /api/branches → List<BranchModel>
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _branches = [
          BranchModel(id: '1', name: 'Anna Nagar Branch', address: '14, 3rd Ave, Anna Nagar, Chennai'),
          BranchModel(id: '2', name: 'T Nagar Branch', address: '8, Pondy Bazaar, T Nagar, Chennai'),
          BranchModel(id: '3', name: 'Velachery Branch', address: '22, 100 Feet Rd, Velachery, Chennai'),
          BranchModel(id: '4', name: 'Tambaram Branch', address: '5, GST Road, Tambaram, Chennai'),
        ];

        _allTests = [
          TestModel.fromJson({
            'id': '1', 'name': 'HbA1c', 'type': 'single', 'category': 'Diabetes',
            'description': '3-month average blood sugar control indicator',
            'offer': 'yes', 'original_price': '600', 'offer_pct': '10',
            'final_price': '540', 'doc_req': 'no',
            'start_date': '28-04-2026', 'end_date': '30-04-2026', 'report_sts': '48 hrs',
          }),
          TestModel.fromJson({
            'id': '2', 'name': 'Complete Blood Count (CBC)', 'type': 'single', 'category': 'General',
            'description': 'Full blood panel including RBC, WBC and platelets',
            'offer': 'no', 'original_price': '350', 'final_price': '350',
            'doc_req': 'no', 'report_sts': '24 hrs',
          }),
          TestModel.fromJson({
            'id': '3', 'name': 'Thyroid Profile (T3, T4, TSH)', 'type': 'single', 'category': 'Thyroid',
            'description': 'Complete thyroid function evaluation',
            'offer': 'yes', 'original_price': '900', 'offer_pct': '15',
            'final_price': '765', 'doc_req': 'no',
            'start_date': '01-05-2026', 'end_date': '31-05-2026', 'report_sts': '24 hrs',
          }),
          TestModel.fromJson({
            'id': '4', 'name': 'Lipid Profile', 'type': 'single', 'category': 'Heart',
            'description': 'Cholesterol, HDL, LDL and triglycerides',
            'offer': 'no', 'original_price': '500', 'final_price': '500',
            'doc_req': 'no', 'report_sts': '24 hrs',
          }),
          TestModel.fromJson({
            'id': '5', 'name': 'Diabetes Care Package', 'type': 'package', 'category': 'Diabetes',
            'description': 'HbA1c + Fasting glucose + Insulin + Lipid Profile',
            'offer': 'yes', 'original_price': '1800', 'offer_pct': '20',
            'final_price': '1440', 'doc_req': 'no',
            'start_date': '01-05-2026', 'end_date': '31-05-2026', 'report_sts': '48 hrs',
          }),
          TestModel.fromJson({
            'id': '6', 'name': 'Full Body Checkup', 'type': 'package', 'category': 'General',
            'description': '60+ parameters — CBC, liver, kidney, thyroid, vitamins & more',
            'offer': 'yes', 'original_price': '3500', 'offer_pct': '25',
            'final_price': '2625', 'doc_req': 'yes',
            'start_date': '01-05-2026', 'end_date': '31-05-2026', 'report_sts': '72 hrs',
          }),
          TestModel.fromJson({
            'id': '7', 'name': 'Vitamin Panel (B12, D3, Folate)', 'type': 'single', 'category': 'Vitamins',
            'description': 'Essential vitamins for energy and immunity',
            'offer': 'no', 'original_price': '1200', 'final_price': '1200',
            'doc_req': 'no', 'report_sts': '48 hrs',
          }),
          TestModel.fromJson({
            'id': '8', 'name': 'Kidney Function Test (KFT)', 'type': 'single', 'category': 'Kidney',
            'description': 'Creatinine, urea, uric acid and eGFR',
            'offer': 'no', 'original_price': '450', 'final_price': '450',
            'doc_req': 'no', 'report_sts': '24 hrs',
          }),
        ];
        _loadingTests = false;
      });
    });
  }

  void _toggleCart(TestModel test) {
    setState(() {
      final exists = _cart.any((t) => t.id == test.id);
      if (exists) {
        _cart.removeWhere((t) => t.id == test.id);
      } else {
        _cart.add(test);
      }
    });
  }

  bool _inCart(TestModel test) => _cart.any((t) => t.id == test.id);

  void _uploadPrescription() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrescriptionUploadSheet(member: widget.member),
    );
  }

  void _showLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSheet(
        mode: _mode,
        modes: _modes,
        branches: _branches,
        selectedBranch: _selectedBranch,
        pincode: _pincode,
        city: _city,
        onModeChanged: (m) => setState(() {
          _mode = m;
          if (m == 'Home Collection') _selectedBranch = null;
          if (m == 'Lab Test') { _pincode = null; _city = null; }
        }),
        onBranchChanged: (b) => setState(() => _selectedBranch = b),
        onPincodeChanged: (p) => setState(() => _pincode = p),
        onCityChanged: (c) => setState(() => _city = c),
      ),
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CartSheet(
        cart: _cart,
        onRemove: (t) => setState(() => _cart.removeWhere((x) => x.id == t.id)),
        onCheckout: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CheckoutScreen(
                member: widget.member,
                cart: List.from(_cart),
                mode: _mode,
                address: _pincode,
                pincode: _pincode,
                city: _city,
                branch: _selectedBranch,
                isVip: widget.isVip,
              ),
            ),
          ).then((_) => setState(() => _cart.clear()));
        },
      ),
    );
  }

  void _showAllTests() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AllTestsSheet(
        tests: _allTests,
        cart: _cart,
        onToggleCart: _toggleCart,
        inCart: _inCart,
      ),
    );
  }

  void _showTestDetail(TestModel test) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TestDetailSheet(
        test: test,
        inCart: _inCart(test),
        onToggleCart: () => _toggleCart(test),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F6F8),
      drawer: _AppDrawer(member: widget.member, isVip: widget.isVip),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // ── App Bar ──────────────────────────────────────
          SliverAppBar(
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.brandGreen,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            title: _HeaderTitle(member: widget.member, isVip: widget.isVip),
            actions: [
              // Cart
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.white, size: 24),
                    onPressed: _cart.isEmpty ? null : _showCart,
                  ),
                  if (_cart.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${_cart.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                color: AppColors.brandGreen,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _LocationBar(
                  mode: _mode,
                  selectedBranch: _selectedBranch,
                  pincode: _pincode,
                  city: _city,
                  onTap: _showLocationSheet,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Search + Upload ───────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'Search tests & packages…',
                              hintStyle: TextStyle(
                                  fontSize: 14, color: AppColors.textHint),
                              prefixIcon: Icon(Icons.search_rounded,
                                  size: 20, color: AppColors.textHint),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Upload prescription
                      GestureDetector(
                        onTap: _uploadPrescription,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: const Icon(Icons.upload_file_outlined,
                              size: 22, color: AppColors.brandGreen),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Filters: Offers toggle + Category chips ───
                SizedBox(
                  height: 34,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Special Offers chip (always first)
                      GestureDetector(
                        onTap: () => setState(() => _showOffersOnly = !_showOffersOnly),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _showOffersOnly ? const Color(0xFFE65100) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _showOffersOnly ? const Color(0xFFE65100) : AppColors.divider,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_offer_rounded,
                                  size: 12,
                                  color: _showOffersOnly ? Colors.white : const Color(0xFFE65100)),
                              const SizedBox(width: 5),
                              Text('Special Offers',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _showOffersOnly ? Colors.white : const Color(0xFFE65100))),
                            ],
                          ),
                        ),
                      ),
                      // Category chips
                      ..._categories.map((cat) {
                        final selected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.brandGreen : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? AppColors.brandGreen : AppColors.divider,
                              ),
                            ),
                            child: Text(cat,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: selected ? Colors.white : AppColors.textSecondary)),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Tests/Packages header ─────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? '${_filteredTests.length} result${_filteredTests.length == 1 ? "" : "s"}'
                        : _selectedCategory == 'All'
                            ? 'Tests & Packages'
                            : _selectedCategory,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Test cards ────────────────────────────
                if (_loadingTests)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.brandGreen),
                    ),
                  )
                else if (_filteredTests.isEmpty)
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                    child: Center(
                      child: Text('No tests found',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _TestCard(
                      test: _filteredTests[i],
                      inCart: _inCart(_filteredTests[i]),
                      onAdd: () => _toggleCart(_filteredTests[i]),
                      onTap: () => _showTestDetail(_filteredTests[i]),
                    ),
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // Proceed to book FAB (visible only when cart has items)
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCart,
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.shopping_cart_outlined, size: 20),
              label: Text(
                '${_cart.length} item${_cart.length > 1 ? 's' : ''} · Proceed',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            )
          : null,
    );
  }
}

// ─── Header title ─────────────────────────────────────────────────────────────

class _HeaderTitle extends StatelessWidget {
  final MemberModel member;
  final bool isVip;
  const _HeaderTitle({required this.member, required this.isVip});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                member.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isVip) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 10, color: Colors.white),
                    SizedBox(width: 3),
                    Text('VIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (member.relation != null)
          Text(
            member.relation!,
            style: TextStyle(
                color: Colors.white.withOpacity(0.75), fontSize: 11),
          ),
      ],
    );
  }
}

// ─── Location bar ─────────────────────────────────────────────────────────────

class _LocationBar extends StatelessWidget {
  final String mode;
  final BranchModel? selectedBranch;
  final String? pincode;
  final String? city;
  final VoidCallback onTap;
  const _LocationBar({
    required this.mode,
    required this.selectedBranch,
    required this.pincode,
    required this.city,
    required this.onTap,
  });

  String get _locationLabel {
    if (mode == 'Lab Test') {
      return selectedBranch?.name ?? 'Select branch';
    }
    if (city != null && city!.isNotEmpty) return city!;
    if (pincode != null && pincode!.isNotEmpty) return pincode!;
    return 'Set location';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(
              mode == 'Lab Test'
                  ? Icons.local_hospital_outlined
                  : Icons.home_outlined,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(mode,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _locationLabel,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─── Location Sheet ───────────────────────────────────────────────────────────

class _LocationSheet extends StatefulWidget {
  final String mode;
  final List<String> modes;
  final List<BranchModel> branches;
  final BranchModel? selectedBranch;
  final String? pincode;
  final String? city;
  final ValueChanged<String> onModeChanged;
  final ValueChanged<BranchModel?> onBranchChanged;
  final ValueChanged<String?> onPincodeChanged;
  final ValueChanged<String?> onCityChanged;

  const _LocationSheet({
    required this.mode,
    required this.modes,
    required this.branches,
    required this.selectedBranch,
    required this.pincode,
    required this.city,
    required this.onModeChanged,
    required this.onBranchChanged,
    required this.onPincodeChanged,
    required this.onCityChanged,
  });

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  late String _mode;
  BranchModel? _branch;
  final _pincodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _locationError = false;
  bool _branchError = false;

  // Branches filtered by pincode/city search
  List<BranchModel> _filteredBranches = [];
  bool _searchingBranches = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _branch = widget.selectedBranch;
    _pincodeCtrl.text = widget.pincode ?? '';
    _cityCtrl.text = widget.city ?? '';
    _addressCtrl.text = '';
    _filteredBranches = widget.branches;

    // For Lab Test mode, react to pincode/city changes to filter branches
    _pincodeCtrl.addListener(_filterBranches);
    _cityCtrl.addListener(_filterBranches);
  }

  void _filterBranches() {
    if (_mode != 'Lab Test') return;
    final query = (_pincodeCtrl.text + _cityCtrl.text).trim().toLowerCase();
    setState(() {
      _branch = null; // reset selection when filter changes
      if (query.isEmpty) {
        _filteredBranches = widget.branches;
      } else {
        _filteredBranches = widget.branches.where((b) =>
          b.name.toLowerCase().contains(query) ||
          b.address.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  void _apply() {
    // Validate
    if (_mode == 'Home Collection') {
      final address = _addressCtrl.text.trim();
      final pincode = _pincodeCtrl.text.trim();
      final city = _cityCtrl.text.trim();
      if (address.isEmpty || (pincode.isEmpty && city.isEmpty)) {
        setState(() => _locationError = true);
        return;
      }
    }
    if (_mode == 'Lab Test' && _branch == null) {
      setState(() => _branchError = true);
      return;
    }

    widget.onModeChanged(_mode);
    if (_mode == 'Lab Test') {
      widget.onBranchChanged(_branch);
      widget.onPincodeChanged(_pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim());
      widget.onCityChanged(_cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim());
    } else {
      widget.onPincodeChanged(_pincodeCtrl.text.trim().isEmpty ? null : _pincodeCtrl.text.trim());
      widget.onCityChanged(_cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim());
      widget.onBranchChanged(null);
    }
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _pincodeCtrl.removeListener(_filterBranches);
    _cityCtrl.removeListener(_filterBranches);
    _pincodeCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            const Text('Collection Mode',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 14),

            // Mode selector
            Row(
              children: widget.modes.map((m) {
                final sel = _mode == m;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: m == widget.modes.first ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _mode = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.brandGreen : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel ? AppColors.brandGreen : AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              m == 'Home Collection'
                                  ? Icons.home_outlined
                                  : Icons.local_hospital_outlined,
                              size: 22,
                              color: sel ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(m,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: sel ? Colors.white : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            if (_mode == 'Home Collection') ...[
              RichText(
                text: const TextSpan(
                  text: 'Collection Address',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  children: [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFD32F2F)))],
                ),
              ),
              const SizedBox(height: 8),

              // Use current location button
              GestureDetector(
                onTap: () {
                  // TODO: geolocator → reverse geocode → fill address
                  // For now fill a mock location
                  setState(() {
                    _addressCtrl.text = 'Current Location, Chennai';
                    _pincodeCtrl.text = '600001';
                    _cityCtrl.text = 'Chennai';
                    _locationError = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreenSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.brandGreenLight),
                  ),
                  child: const Row(children: [
                    Icon(Icons.my_location_rounded, size: 18, color: AppColors.brandGreen),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Use current location',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brandGreen)),
                          Text('Auto-detect your location',
                              style: TextStyle(fontSize: 11, color: AppColors.brandGreen)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.brandGreen),
                  ]),
                ),
              ),

              const SizedBox(height: 10),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('or enter manually', style: TextStyle(fontSize: 11, color: AppColors.textHint))),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 10),

              // Full address
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 14),
                onChanged: (_) => setState(() => _locationError = false),
                decoration: InputDecoration(
                  hintText: 'House no, Street, Area',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Icon(Icons.home_outlined, size: 18, color: AppColors.textHint),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                ),
              ),
              const SizedBox(height: 10),

              // Pincode + City side by side
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _pincodeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 14),
                    onChanged: (_) => setState(() => _locationError = false),
                    decoration: InputDecoration(
                      hintText: 'Pincode',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      counterText: '',
                      prefixIcon: const Icon(Icons.pin_outlined, size: 18, color: AppColors.textHint),
                      filled: true, fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cityCtrl,
                    style: const TextStyle(fontSize: 14),
                    onChanged: (_) => setState(() => _locationError = false),
                    decoration: InputDecoration(
                      hintText: 'City',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      prefixIcon: const Icon(Icons.location_city_outlined, size: 18, color: AppColors.textHint),
                      filled: true, fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5)),
                    ),
                  ),
                ),
              ]),

              if (_locationError) ...[
                const SizedBox(height: 6),
                const Row(children: [
                  Icon(Icons.error_outline, size: 13, color: Color(0xFFD32F2F)),
                  SizedBox(width: 4),
                  Expanded(child: Text('Address with pincode/city is required', style: TextStyle(fontSize: 12, color: Color(0xFFD32F2F)))),
                ]),
              ],
            ],

            if (_mode == 'Lab Test') ...[
              // Pincode/City to filter branches
              RichText(
                text: const TextSpan(
                  text: 'Pincode or City',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  children: [TextSpan(text: '  (to find nearby branches)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w400))],
                ),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _pincodeCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Pincode',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      counterText: '',
                      prefixIcon: const Icon(Icons.pin_outlined, size: 18, color: AppColors.textHint),
                      filled: true, fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cityCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'City',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      prefixIcon: const Icon(Icons.location_city_outlined, size: 18, color: AppColors.textHint),
                      filled: true, fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              RichText(
                text: const TextSpan(
                  text: 'Select Branch',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  children: [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFD32F2F)))],
                ),
              ),
              const SizedBox(height: 8),
              if (_filteredBranches.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Row(children: [
                    Icon(Icons.search_off_rounded, size: 16, color: AppColors.textHint),
                    SizedBox(width: 8),
                    Text('No branches found for this location', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ]),
                )
              else
                DropdownButtonFormField<BranchModel>(
                  value: _filteredBranches.contains(_branch) ? _branch : null,
                  hint: const Text('Choose a branch', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.local_hospital_outlined, size: 18, color: AppColors.textHint),
                    filled: true, fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _branchError ? const Color(0xFFD32F2F) : AppColors.divider)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _branchError ? const Color(0xFFD32F2F) : AppColors.divider)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brandGreen, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  dropdownColor: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  isExpanded: true,
                  items: _filteredBranches.map((b) => DropdownMenuItem(
                    value: b,
                    child: Text(b.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                  onChanged: (b) => setState(() { _branch = b; _branchError = false; }),
                ),
              if (_branchError) ...[
                const SizedBox(height: 6),
                const Row(children: [
                  Icon(Icons.error_outline, size: 13, color: Color(0xFFD32F2F)),
                  SizedBox(width: 4),
                  Text('Please select a branch', style: TextStyle(fontSize: 12, color: Color(0xFFD32F2F))),
                ]),
              ],
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Apply',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Test Card ────────────────────────────────────────────────────────────────

class _TestCard extends StatelessWidget {
  final TestModel test;
  final bool inCart;
  final VoidCallback onAdd;
  final VoidCallback onTap;
  const _TestCard({
    required this.test,
    required this.inCart,
    required this.onAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: inCart ? AppColors.brandGreen : AppColors.divider,
              width: inCart ? 1.5 : 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Type badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: test.type == 'package'
                                          ? const Color(0xFFE8F5F1)
                                          : const Color(0xFFEEF4FB),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      test.type == 'package'
                                          ? 'Package'
                                          : 'Test',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: test.type == 'package'
                                              ? AppColors.brandGreen
                                              : const Color(0xFF1565C0)),
                                    ),
                                  ),
                                  if (test.hasOffer) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${(test.offerPercent ?? 0).toInt()}% OFF',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFE65100)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(test.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 3),
                              Text(test.description,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.4),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${test.finalPrice.toInt()}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            if (test.hasOffer)
                              Text('₹${test.originalPrice.toInt()}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textHint,
                                      decoration:
                                          TextDecoration.lineThrough)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Meta row
                    Row(
                      children: [
                        _MetaChip(
                            icon: Icons.schedule_outlined,
                            label: test.reportStatus),
                        const SizedBox(width: 8),
                        _MetaChip(
                            icon: Icons.category_outlined,
                            label: test.category),
                        if (test.docRequired) ...[
                          const SizedBox(width: 8),
                          _MetaChip(
                              icon: Icons.description_outlined,
                              label: 'Rx needed',
                              color: const Color(0xFFE65100)),
                        ],
                      ],
                    ),
                    // Offer validity
                    if (test.hasOffer && test.endDate != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.local_offer_outlined,
                              size: 11, color: Color(0xFFE65100)),
                          const SizedBox(width: 4),
                          Text('Offer valid till ${test.endDate}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFFE65100))),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Add to cart strip
              Material(
                color: inCart
                    ? AppColors.brandGreenSurface
                    : const Color(0xFFF4F6F8),
                child: InkWell(
                  onTap: onAdd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          inCart
                              ? Icons.check_circle_outline
                              : Icons.add_circle_outline,
                          size: 15,
                          color: inCart
                              ? AppColors.brandGreen
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          inCart ? 'Added to cart' : 'Add to cart',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: inCart
                                  ? AppColors.brandGreen
                                  : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MetaChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: c),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: c)),
      ],
    );
  }
}

// ─── Test Detail Sheet ────────────────────────────────────────────────────────

class _TestDetailSheet extends StatelessWidget {
  final TestModel test;
  final bool inCart;
  final VoidCallback onToggleCart;
  const _TestDetailSheet({
    required this.test,
    required this.inCart,
    required this.onToggleCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: test.type == 'package'
                              ? AppColors.brandGreenSurface
                              : const Color(0xFFEEF4FB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          test.type == 'package' ? 'Package' : 'Test',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: test.type == 'package'
                                  ? AppColors.brandGreen
                                  : const Color(0xFF1565C0)),
                        ),
                      ),
                      if (test.hasOffer) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${(test.offerPercent ?? 0).toInt()}% OFF',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE65100)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(test.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(test.description,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5)),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _InfoRow('Category', test.category),
                  _InfoRow('Report Status', test.reportStatus),
                  _InfoRow('Prescription',
                      test.docRequired ? 'Required' : 'Not required',
                      highlight: test.docRequired),
                  if (test.docRequired) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFCC02).withOpacity(0.4)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFFE65100)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Full payment is available only after a technician verifies your uploaded prescription.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF795548), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  _InfoRow('Original Price', '₹${test.originalPrice.toInt()}'),
                  if (test.hasOffer) ...[
                    _InfoRow('Discount',
                        '${(test.offerPercent ?? 0).toInt()}%'),
                    _InfoRow('Offer Valid',
                        '${test.startDate ?? ''} – ${test.endDate ?? ''}'),
                  ],
                  _InfoRow('Final Price', '₹${test.finalPrice.toInt()}',
                      highlight: true),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  onToggleCart();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      inCart ? Colors.red[700] : AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(inCart ? 'Remove from cart' : 'Add to cart',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _InfoRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: highlight
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: highlight
                        ? AppColors.brandGreen
                        : AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── All Tests Sheet ──────────────────────────────────────────────────────────

class _AllTestsSheet extends StatelessWidget {
  final List<TestModel> tests;
  final List<TestModel> cart;
  final ValueChanged<TestModel> onToggleCart;
  final bool Function(TestModel) inCart;
  const _AllTestsSheet({
    required this.tests,
    required this.cart,
    required this.onToggleCart,
    required this.inCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Text('All Tests & Packages',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              itemCount: tests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _TestCard(
                test: tests[i],
                inCart: inCart(tests[i]),
                onAdd: () => onToggleCart(tests[i]),
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cart Sheet ───────────────────────────────────────────────────────────────

class _CartSheet extends StatelessWidget {
  final List<TestModel> cart;
  final ValueChanged<TestModel> onRemove;
  final VoidCallback onCheckout;
  const _CartSheet({
    required this.cart,
    required this.onRemove,
    required this.onCheckout,
  });

  double get _total => cart.fold(0, (s, t) => s + t.finalPrice);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cart  (${cart.length} item${cart.length > 1 ? 's' : ''})',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text('₹${_total.toInt()}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandGreen)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: cart.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final t = cart[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(t.category,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Text('₹${t.finalPrice.toInt()}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => onRemove(t),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.textHint),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Proceed to Book  ·  ₹${_total.toInt()}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sidebar Drawer ───────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final MemberModel member;
  final bool isVip;
  const _AppDrawer({required this.member, required this.isVip});

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        member.photoBytes != null && member.photoBytes!.isNotEmpty;
    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              color: AppColors.brandGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.4), width: 1.5),
                    ),
                    child: ClipOval(
                      child: hasPhoto
                          ? Image.memory(member.photoBytes!,
                              fit: BoxFit.cover, width: 56, height: 56)
                          : Center(
                              child: Text(
                                member.name.isNotEmpty
                                    ? member.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                      if (isVip) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.star_rounded, size: 10, color: Colors.white),
                            SizedBox(width: 3),
                            Text('VIP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                          ]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('+91 \${member.mobile}',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _DrawerItem(icon: Icons.group_outlined, label: 'My Customers', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CustomerHomeScreen(mobile: member.mobile)));
            }),
            _DrawerItem(icon: Icons.calendar_month_outlined, label: 'My Bookings', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
            }),
            _DrawerItem(icon: Icons.receipt_long_outlined, label: 'Reports & Results', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
            }),
            _DrawerItem(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () => Navigator.pop(context)),
            _DrawerItem(icon: Icons.info_outline_rounded, label: 'About Us', onTap: () => Navigator.pop(context)),
            const Spacer(),
            const Divider(height: 1),
            _DrawerItem(icon: Icons.logout_rounded, label: 'Logout', isDestructive: true, onTap: () => Navigator.pop(context)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;
  final bool isDestructive;
  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.isActive = false, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFD32F2F) : isActive ? AppColors.brandGreen : AppColors.textSecondary;
    return ListTile(
      leading: Icon(icon, size: 20, color: color),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: color)),
      tileColor: isActive ? AppColors.brandGreenSurface : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }
}

// ─── Prescription Upload Sheet ────────────────────────────────────────────────

class _PrescriptionUploadSheet extends StatefulWidget {
  final MemberModel member;
  const _PrescriptionUploadSheet({required this.member});

  @override
  State<_PrescriptionUploadSheet> createState() => _PrescriptionUploadSheetState();
}

class _PrescriptionUploadSheetState extends State<_PrescriptionUploadSheet> {
  // Prescription state
  // In production: use image_picker to get Uint8List bytes
  bool _uploaded = false;
  String? _uploadedFileName;
  DateTime? _uploadedDate;
  String _status = 'Pending Review'; // updated by technician via API

  // Mock previous prescriptions
  final List<Map<String, dynamic>> _previous = [
    {
      'date': '08 May 2026',
      'file': 'prescription_ravi_08may.jpg',
      'status': 'Tests assigned by technician',
      'action': 'Technician assigned CBC + Lipid Profile based on prescription',
    },
    {
      'date': '15 Apr 2026',
      'file': 'prescription_ravi_15apr.jpg',
      'status': 'Reviewed',
      'action': 'Technician called and confirmed HbA1c test',
    },
  ];

  void _mockUpload() async {
    // TODO: use image_picker → POST /api/prescriptions
    // final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    // if (picked != null) { bytes = await picked.readAsBytes(); ... }
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _uploaded = true;
      _uploadedFileName = 'prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _uploadedDate = DateTime.now();
      _status = 'Pending Review';
    });
  }

  void _viewPrescription() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening prescription preview…'),
        backgroundColor: AppColors.brandGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    // TODO: open full-screen image viewer
  }

  void _callSupport() async {
    // TODO: launch('tel:+911800XXXXXX')
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.phone_outlined, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text('Calling support…')),
        ]),
        backgroundColor: AppColors.brandGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _submit() {
    if (!_uploaded) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text('Prescription submitted. Our technician will review and contact you.')),
        ]),
        backgroundColor: AppColors.brandGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${months[d.month]} ${d.year}, ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  Color _statusColor(String s) {
    if (s.contains('assigned') || s.contains('Reviewed')) return AppColors.brandGreen;
    if (s.contains('Pending')) return const Color(0xFFE65100);
    return const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // Header with support call button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Upload Prescription',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('For ${widget.member.name}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                // Support call button
                GestureDetector(
                  onTap: _callSupport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreenSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.brandGreenLight),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.support_agent_outlined, size: 16, color: AppColors.brandGreen),
                        SizedBox(width: 6),
                        Text('Support Call',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandGreen)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Info note ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.brandGreenSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.brandGreenLight),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: AppColors.brandGreen),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Upload your doctor\'s prescription. Our technician will review it and assign the right tests, or call you if clarification is needed.',
                            style: TextStyle(fontSize: 12, color: AppColors.brandGreen, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Customer name chip ────────────────────
                  Row(children: [
                    const Icon(Icons.person_outline, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(widget.member.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                    ),
                    if (widget.member.relation != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandGreenSurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(widget.member.relation!,
                            style: const TextStyle(fontSize: 11, color: AppColors.brandGreen, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 16),

                  // ── Upload area ───────────────────────────
                  const Text('New Prescription',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),

                  if (!_uploaded)
                    GestureDetector(
                      onTap: _mockUpload,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.divider, width: 1.5),
                        ),
                        child: Column(children: const [
                          Icon(Icons.upload_file_outlined, size: 36, color: AppColors.brandGreen),
                          SizedBox(height: 10),
                          Text('Tap to upload prescription',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.brandGreen)),
                          SizedBox(height: 4),
                          Text('JPG, PNG or PDF — max 5MB',
                              style: TextStyle(fontSize: 11, color: AppColors.textHint)),
                        ]),
                      ),
                    ),

                  if (_uploaded) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.brandGreenSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.brandGreen, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.insert_drive_file_outlined, size: 28, color: AppColors.brandGreen),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_uploadedFileName ?? 'prescription.jpg',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                                Text('Uploaded ${_uploadedDate != null ? _formatDate(_uploadedDate!) : ''}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // View icon
                          GestureDetector(
                            onTap: _viewPrescription,
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.brandGreenLight),
                              ),
                              child: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.brandGreen),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Remove icon
                          GestureDetector(
                            onTap: () => setState(() { _uploaded = false; _uploadedFileName = null; _uploadedDate = null; }),
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _statusColor(_status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor(_status).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: _statusColor(_status)),
                          const SizedBox(width: 6),
                          Text(_status,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(_status))),
                        ],
                      ),
                    ),
                  ],

                  // ── Previous prescriptions ────────────────
                  if (_previous.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Previous Uploads',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 10),
                    ..._previous.map((p) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.insert_drive_file_outlined, size: 16, color: AppColors.textHint),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(p['file'],
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              GestureDetector(
                                onTap: _viewPrescription,
                                child: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.brandGreen),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(p['date'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ]),
                          const SizedBox(height: 6),
                          // Status
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor(p['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(p['status'],
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(p['status']))),
                          ),
                          const SizedBox(height: 6),
                          // Action taken
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 13, color: AppColors.brandGreen),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(p['action'],
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Submit button
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _uploaded ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  disabledBackgroundColor: AppColors.brandGreen.withOpacity(0.35),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Submit Prescription',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
