import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/homestay_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../properties/controllers/property_controller.dart';
import '../utils/create_property_flow.dart';
import '../widgets/property_management_card.dart';

// gradient.brandHero stop "jade-mid" theo spec section 3.7
const _jadeMidLight = Color(0xFF1B7E94);

/// Trang quản lý phòng (Admin) — 3 tabs: Villa, Homestay, Khách sạn
/// Dùng homestay data — mỗi homestay là 1 căn (villa/homestay/khách sạn).
/// Ấn vào card → HomestayDetailScreen (Ảnh, Thông tin, Tiện ích, Bảng giá...).
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

  // typeValues matches PropertyType int: 0=VILLA, 1=HOMESTAY, 2=HOTEL
  // typeValues == null nghĩa là tab "Tất cả" — không filter theo type
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

  /// Lọc homestay theo tab — so sánh int type field.
  /// [typeValues] null = tab "Tất cả" → không filter theo type.
  /// [typeValues] có thể chứa nhiều type (vd: Homestay = [1]).
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
                        // Fallback /dashboard khi stack rỗng (user vào trực
                        // tiếp qua bottom nav `context.go` → không pop được).
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
                        textAlignVertical: TextAlignVertical.center,
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
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // TabBar — scrollable để tránh overflow khi có nhiều tab
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
                if (filtered.isEmpty) {
                  return Center(
                    child: EmptyStateWidget(
                      icon: tab.icon,
                      message: 'Chưa có ${tab.label} nào',
                      subMessage: canEdit ? 'Nhấn + để thêm mới' : null,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => PropertyManagementCard(
                    homestay: filtered[i],
                    onTap: () => context.push('/properties/${filtered[i].id}'),
                    onEdit: canEdit
                        ? () => context.push('/properties/${filtered[i].id}')
                        : null,
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

  /// Luồng thêm phòng dùng chung (cổng SĐT → KYC → bank → quota).
  Future<void> _onCreateProperty() async {
    await startCreatePropertyFlow(context, ref);
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
