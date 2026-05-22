import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agrinexa/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'product_detail_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import '../utils/app_router.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _searchController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedLocation = 'All';
  String _sortKey = 'newest'; // Internal key: newest, low_high, high_low
  double? _minPrice;
  double? _maxPrice;

  bool get _hasActiveFilters =>
      _selectedLocation != 'All' ||
      _minPrice != null ||
      _maxPrice != null ||
      _sortKey != 'newest';

  // Categories (names are universal/Cameroon crop names)
  static const List<Map<String, String>> _categories = [
    {'name': 'All',        'emoji': '🌿'},
    {'name': 'Vegetables', 'emoji': '🥬'},
    {'name': 'Fruits',     'emoji': '🍎'},
    {'name': 'Grains',     'emoji': '🌽'},
    {'name': 'Legumes',    'emoji': '🫘'},
    {'name': 'Tubers',     'emoji': '🍠'},
    {'name': 'Nuts',       'emoji': '🌰'},
    {'name': 'Spices',     'emoji': '🌶️'},
    {'name': 'Other',      'emoji': '🌾'},
  ];

  static const List<String> _locations = [
    'All', 'Douala', 'Yaoundé', 'Buea', 'Bamenda',
    'Bafoussam', 'Garoua', 'Maroua', 'Ngaoundéré', 'Bertoua',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedLocation = 'All';
      _sortKey = 'newest';
      _minPrice = null;
      _maxPrice = null;
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  /// Get translated sort label from internal key
  String _sortLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'low_high': return l10n.priceLowHigh;
      case 'high_low': return l10n.priceHighLow;
      default: return l10n.newest;
    }
  }

  void _showFilterSheet(AppLocalizations l10n) {
    String tempLocation = _selectedLocation;
    String tempSortKey = _sortKey;
    final tempMinController =
        TextEditingController(text: _minPrice?.toStringAsFixed(0) ?? '');
    final tempMaxController =
        TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? '');

    final sortOptions = [
      {'key': 'newest',   'label': l10n.newest},
      {'key': 'low_high', 'label': l10n.priceLowHigh},
      {'key': 'high_low', 'label': l10n.priceHighLow},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.filters,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              tempLocation = 'All';
                              tempSortKey = 'newest';
                              tempMinController.clear();
                              tempMaxController.clear();
                            });
                          },
                          child: Text(l10n.clearAll,
                              style:
                                  const TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  Flexible(
                    child: SingleChildScrollView(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Price Range
                          Text(l10n.priceRange,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(
                              child: TextFormField(
                                controller: tempMinController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: l10n.min,
                                  prefixText: 'FCFA ',
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: AppColors.divider),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: AppColors.divider),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 10),
                              child: Text('—',
                                  style: TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 18)),
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: tempMaxController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: l10n.max,
                                  prefixText: 'FCFA ',
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: AppColors.divider),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: AppColors.divider),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 20),

                          // Location
                          Text(l10n.locationFilter,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _locations.map((loc) {
                              final isSelected = tempLocation == loc;
                              return GestureDetector(
                                onTap: () => setSheetState(
                                    () => tempLocation = loc),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.background,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Text(loc,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : AppColors.textDark)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Sort By
                          Text(l10n.sortBy,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          ...sortOptions.map((opt) {
                            return RadioListTile<String>(
                              value: opt['key']!,
                              groupValue: tempSortKey,
                              onChanged: (val) =>
                                  setSheetState(() => tempSortKey = val!),
                              title: Text(opt['label']!,
                                  style: const TextStyle(fontSize: 14)),
                              activeColor: AppColors.primary,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Apply button
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedLocation = tempLocation;
                          _sortKey = tempSortKey;
                          _minPrice =
                              tempMinController.text.trim().isEmpty
                                  ? null
                                  : double.tryParse(
                                      tempMinController.text.trim());
                          _maxPrice =
                              tempMaxController.text.trim().isEmpty
                                  ? null
                                  : double.tryParse(
                                      tempMaxController.text.trim());
                        });
                        Navigator.pop(context);
                      },
                      child: Text(l10n.applyFilters),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _applyFilters(
      List<QueryDocumentSnapshot> docs, AppLocalizations l10n) {
    var filtered = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] as String? ?? '').toLowerCase();
      final location =
          (data['location'] as String? ?? '').toLowerCase();
      final category = (data['category'] as String? ?? '');
      final priceValue =
          (data['priceValue'] as num?)?.toDouble() ?? 0;

      final matchesSearch = _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          location.contains(_searchQuery);
      final matchesCategory =
          _selectedCategory == 'All' || category == _selectedCategory;
      final matchesLocation = _selectedLocation == 'All' ||
          location.contains(_selectedLocation.toLowerCase());
      final matchesMinPrice =
          _minPrice == null || priceValue >= _minPrice!;
      final matchesMaxPrice =
          _maxPrice == null || priceValue <= _maxPrice!;

      return matchesSearch &&
          matchesCategory &&
          matchesLocation &&
          matchesMinPrice &&
          matchesMaxPrice;
    }).toList();

    // Sort using internal key
    filtered.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      if (_sortKey == 'low_high') {
        final priceA = (dataA['priceValue'] as num?)?.toDouble() ?? 0;
        final priceB = (dataB['priceValue'] as num?)?.toDouble() ?? 0;
        return priceA.compareTo(priceB);
      } else if (_sortKey == 'high_low') {
        final priceA = (dataA['priceValue'] as num?)?.toDouble() ?? 0;
        final priceB = (dataB['priceValue'] as num?)?.toDouble() ?? 0;
        return priceB.compareTo(priceA);
      } else {
        final timeA =
            (dataA['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                0;
        final timeB =
            (dataB['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                0;
        return timeB.compareTo(timeA);
      }
    });

    return filtered;
  }

  Future<List<Map<String, dynamic>>> _loadRecommendations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    try {
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('buyerId', isEqualTo: user.uid)
          .limit(20)
          .get();
      if (ordersSnapshot.docs.isEmpty) return [];

      final Set<String> purchasedCategories = {};
      for (var order in ordersSnapshot.docs) {
        final category = order.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          purchasedCategories.add(category);
        }
      }
      if (purchasedCategories.isEmpty) return [];

      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category',
              whereIn: purchasedCategories.take(10).toList())
          .limit(10)
          .get();

      return productsSnapshot.docs
          .where((doc) => doc['sellerId'] != user.uid)
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final firstName =
        (user?.displayName ?? 'Farmer').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, $firstName 👋',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        Text(l10n.findFreshProducts,
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textMedium)),
                      ],
                    ),
                    Row(children: [
                      // Notifications
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('toUserId', isEqualTo: user?.uid)
                            .where('isRead', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final count = snapshot.hasData
                              ? snapshot.data!.docs.length
                              : 0;
                          return GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                AppRouter.slide(
                                    const NotificationsScreen())),
                            child: Stack(children: [
                              _IconBtn(Icons.notifications_outlined),
                              if (count > 0) _Badge(count),
                            ]),
                          );
                        },
                      ),
                      const SizedBox(width: 10),

                      // Chat
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .where('participants',
                                arrayContains: user?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          int unread = 0;
                          if (snapshot.hasData) {
                            for (var doc in snapshot.data!.docs) {
                              final d =
                                  doc.data() as Map<String, dynamic>;
                              unread +=
                                  (d['unread_${user?.uid}'] ?? 0)
                                      as int;
                            }
                          }
                          return GestureDetector(
                            onTap: () => Navigator.push(
                                context,
                                AppRouter.slide(const ChatScreen())),
                            child: Stack(children: [
                              _IconBtn(
                                  Icons.chat_bubble_outline_rounded),
                              if (unread > 0) _Badge(unread),
                            ]),
                          );
                        },
                      ),
                      const SizedBox(width: 10),

                      // Profile avatar
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primaryLighter,
                        backgroundImage: user?.photoURL != null
                            ? NetworkImage(user!.photoURL!)
                            : null,
                        child: user?.photoURL == null
                            ? Text(firstName[0].toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16))
                            : null,
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            // ── Search Bar + Filter Button ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      onChanged: (value) => setState(
                          () => _searchQuery = value.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textLight),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AppColors.textLight),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Filter button
                  GestureDetector(
                    onTap: () => _showFilterSheet(l10n),
                    child: Stack(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: _hasActiveFilters
                              ? AppColors.primary
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _hasActiveFilters
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Icon(Icons.tune_rounded,
                            color: _hasActiveFilters
                                ? Colors.white
                                : AppColors.primary),
                      ),
                      if (_hasActiveFilters)
                        Positioned(
                          top: 0, right: 0,
                          child: Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle),
                          ),
                        ),
                    ]),
                  ),
                ]),
              ),
            ),

            // ── Active Filters ───────────────────────────────────────
            if (_hasActiveFilters)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (_selectedLocation != 'All')
                        _ActiveFilterChip(
                          label: '📍 $_selectedLocation',
                          onRemove: () => setState(
                              () => _selectedLocation = 'All'),
                        ),
                      if (_minPrice != null)
                        _ActiveFilterChip(
                          label:
                              '💰 Min: ${_minPrice!.toStringAsFixed(0)} FCFA',
                          onRemove: () {
                            setState(() => _minPrice = null);
                            _minPriceController.clear();
                          },
                        ),
                      if (_maxPrice != null)
                        _ActiveFilterChip(
                          label:
                              '💰 Max: ${_maxPrice!.toStringAsFixed(0)} FCFA',
                          onRemove: () {
                            setState(() => _maxPrice = null);
                            _maxPriceController.clear();
                          },
                        ),
                      if (_sortKey != 'newest')
                        _ActiveFilterChip(
                          label: '↕️ ${_sortLabel(_sortKey, l10n)}',
                          onRemove: () =>
                              setState(() => _sortKey = 'newest'),
                        ),
                      GestureDetector(
                        onTap: _clearFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    AppColors.danger.withOpacity(0.3)),
                          ),
                          child: Text(l10n.clearAll,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Recommendations ──────────────────────────────────────
            SliverToBoxAdapter(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadRecommendations(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final recs = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        child: Text(l10n.recommendedForYou,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                      ),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          itemCount: recs.length,
                          itemBuilder: (context, index) {
                            final product = recs[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  AppRouter.slide(ProductDetailScreen(
                                    productId: product['id'],
                                    data: product,
                                  )),
                                ),
                                child: Container(
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.05),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top:
                                                    Radius.circular(14)),
                                        child: Image.network(
                                          product['imageUrl'] ?? '',
                                          height: 110,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              Container(
                                            height: 110,
                                            color:
                                                AppColors.primaryLighter,
                                            child: const Icon(
                                                Icons.image_outlined,
                                                color: AppColors.primary,
                                                size: 36),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                product['name'] ?? '',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .textDark),
                                                maxLines: 1,
                                                overflow: TextOverflow
                                                    .ellipsis),
                                            const SizedBox(height: 4),
                                            Text(
                                                product['price'] ?? '',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700,
                                                    fontSize: 12,
                                                    color: AppColors
                                                        .primary),
                                                maxLines: 1,
                                                overflow: TextOverflow
                                                    .ellipsis),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Category Chips ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(l10n.categories,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                  ),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected =
                            _selectedCategory == cat['name'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() =>
                                _selectedCategory = cat['name']!),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.white,
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.divider,
                                ),
                              ),
                              child: Text(
                                '${cat['emoji']} ${cat['name']}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textDark),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── Products Grid ────────────────────────────────────────
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary)),
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Icon(Icons.storefront_outlined,
                              size: 60, color: AppColors.textLight),
                          const SizedBox(height: 12),
                          Text(l10n.noProductsYet,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(l10n.beFirstToList,
                              style: TextStyle(
                                  color: AppColors.textMedium,
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }

                final docs =
                    _applyFilters(snapshot.data!.docs, l10n);

                if (docs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Column(children: [
                          const Text('😕',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(l10n.noProductsMatchFilters,
                              style: TextStyle(
                                  color: AppColors.textMedium)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _clearFilters,
                            child: Text(l10n.clearFilters,
                                style: const TextStyle(
                                    color: AppColors.primary)),
                          ),
                        ]),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.70,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = docs[index];
                        final data =
                            doc.data() as Map<String, dynamic>;
                        return _ProductCard(
                            productId: doc.id, data: data);
                      },
                      childCount: docs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  const _IconBtn(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge(this.count);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
            color: AppColors.danger, shape: BoxShape.circle),
        constraints:
            const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveFilterChip(
      {required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLighter,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> data;
  const _ProductCard({required this.productId, required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        AppRouter.slide(ProductDetailScreen(
            productId: productId, data: data)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: Image.network(
                data['imageUrl'] ?? '',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: AppColors.primaryLighter,
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.primary, size: 40),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 120,
                    color: AppColors.primaryLighter,
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['category'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLighter,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(data['category'],
                          style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  Text(data['name'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.textLight),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(data['location'] ?? '',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(data['price'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}