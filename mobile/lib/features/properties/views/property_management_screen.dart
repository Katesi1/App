import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/homestay_model.dart';
import '../../../shared/widgets/keep_alive_tab.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../properties/controllers/property_controller.dart';
import '../../verify/views/paywall_modal.dart';
import '../widgets/property_management_card.dart';

// gradient.brandHero stop "jade-mid" per spec section 3.7
const _jadeMidLight = Color(0xFF1B7E94);

/// Property management screen (Admin) — 3 tabs: Villa, Homestay, Hotel.
/// Uses homestay data — each homestay is one unit (villa/homestay/hotel).
/// Tap card → HomestayDetailScreen (images, info, amenities, pricing...).
class PropertyManagementScreen extends ConsumerStatefulWidget {
  const PropertyManagementScreen({super.key});

  @override
  ConsumerState<PropertyManagementScreen> createState() =>
      _PropertyManagementScreenState();
}

class _PropertyManagementScreenState
    extends ConsumerState<PropertyManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

  // typeValues matches PropertyType int: 0=VILLA, 1=HOMESTAY, 2=HOTEL.
  // typeValues == null = "All" tab — no type filter.
  static const _tabs = [
    (label: 'Tất cả', icon: Icons.apps_rounded, typeValues: null),
    (label: 'Villa', icon: Icons.villa_rounded, typeValues: [0]),
    (label: 'Homestay', icon: Icons.cottage_rounded, typeValues: [1]),
    (label: 'Khách sạn', icon: Icons.hotel_rounded, typeValues: [2]),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      } else {
        Future.delayed(const Duration(milliseconds: 100), () {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }

  /// Filter homestays by tab — compare int type field.
  /// [typeValues] null = "All" tab → no type filter.
  /// [typeValues] may contain multiple types (e.g. Homestay = [1]).
  List<HomestayModel> _filterByTab(
      List<HomestayModel> homestays, List<int>? typeValues) {
    var filtered = typeValues == null
        ? List<HomestayModel>.from(homestays)
        : homestays.where((h) => typeValues.contains(h.type)).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((h) =>
              h.name.toLowerCase().contains(query) ||
              h.address.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final homestaysAsync = ref.watch(homestayListProvider(true));
    final user = ref.watch(currentUserProvider);
    final canEdit = user?.canEdit ?? false;
    final canManageProperty = user?.canManageProperty ?? false;
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerGradient = isDark
        ? const [AppColors.darkBg, AppColors.darkBorder]
        : const [AppColors.jade500, _jadeMidLight];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.4, -1),
                  end: const Alignment(0.4, 1),
                  colors: headerGradient,
                ),
              ),
              child: Column(
                children: [
                  // Title row
                  Row(
                    children: [
                      GestureDetector(
                        // Fallback /dashboard when stack is empty (user entered
                        // directly via bottom nav `context.go` → cannot pop).
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/dashboard');
                          }
                        },
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Quản lý phòng',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      _HeaderIconBtn(
                        icon: _isSearching
                            ? Icons.close_rounded
                            : Icons.search_rounded,
                        onTap: _toggleSearch,
                      ),
                    ],
                  ),

                  // Search input
                  if (_isSearching) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        cursorColor: Colors.white,
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tên hoặc địa chỉ...',
                          hintStyle: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 18,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  }),
                                  child: Icon(
                                    Icons.clear_rounded,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    size: 18,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // TabBar — scrollable to avoid overflow with many tabs.
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                    labelStyle: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    dividerColor: Colors.transparent,
                    tabs: _tabs
                        .map((t) => Tab(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(t.icon, size: 16),
                                  const SizedBox(width: 6),
                                  Text(t.label),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          color: colors.brand,
          onRefresh: () async {
            ref.invalidate(homestayListProvider(true));
          },
          child: homestaysAsync.when(
            loading: () => SkeletonList(
              skeleton: const HomestayCardSkeleton(),
              count: 5,
            ),
            error: (e, _) => Center(
              child: ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(homestayListProvider(true)),
              ),
            ),
            data: (homestays) => TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final filtered = _filterByTab(homestays, tab.typeValues);
                return KeepAliveTab(
                  key: ValueKey('property-tab-${tab.label}'),
                  child: filtered.isEmpty
                      ? Center(
                          child: EmptyStateWidget(
                            icon: tab.icon,
                            message: 'Chưa có ${tab.label} nào',
                            subMessage:
                                canEdit ? 'Nhấn + để thêm mới' : null,
                          ),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => PropertyManagementCard(
                            homestay: filtered[i],
                            onTap: () => context
                                .push('/properties/${filtered[i].id}'),
                            onEdit: canEdit
                                ? () => context
                                    .push('/properties/${filtered[i].id}')
                                : null,
                          ),
                        ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      floatingActionButton: canManageProperty
          ? FloatingActionButton(
              onPressed: () => _onCreateProperty(),
              backgroundColor: colors.brand,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
  }

  /// Owner must verify CCCD before creating a property.
  /// - Owner approved → push property add screen directly
  /// - Owner not approved → show paywall, route per current status
  /// - Admin / Sale → bypass verify (no KYC required)
  Future<void> _onCreateProperty() async {
    final user = ref.read(currentUserProvider);

    // Gate on the SERVER truth (user.kycStatus), not the local verify draft —
    // a pending owner must NOT be offered KYC again.
    final needsVerify =
        (user?.isOwner ?? false) && !(user?.isKycApproved ?? false);

    if (!needsVerify) {
      context.push('/properties/new');
      return;
    }

    // Routing by server status: pending → /verify/pending,
    // rejected → /verify/rejected, otherwise → paywall → /verify/cccd-front.
    switch (user!.kycStatus) {
      case 'pending':
        context.push('/verify/pending');
        return;
      case 'rejected':
        context.push('/verify/rejected');
        return;
    }

    // The paywall returns the route that resumes at the step it offered
    // ("Tiếp tục bước X"), so we just push whatever it gives back.
    final route = await showPaywallModal(context);
    if (route != null && mounted) {
      context.push(route);
    }
  }
}

// ─── Header Icon Button ─────────────────────────────────────────────────────
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
