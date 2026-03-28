import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/homestay_model.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../properties/controllers/property_controller.dart';
import '../widgets/property_management_card.dart';

/// Trang quản lý phòng (Admin) — 3 tabs: Villa, Homestay, Khách sạn
/// Dùng homestay data — mỗi homestay là 1 căn (villa/homestay/khách sạn).
/// Ấn vào card → HomestayDetailScreen (Ảnh, Thông tin, Tiện ích, Bảng giá...).
class PropertyManagementScreen extends ConsumerStatefulWidget {
  const PropertyManagementScreen({super.key});

  @override
  ConsumerState<PropertyManagementScreen> createState() =>
      _PropertyManagementScreenState();
}

class _PropertyManagementScreenState extends ConsumerState<PropertyManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

  static const _tabs = [
    (label: 'Villa', icon: Icons.villa_rounded, keyword: 'villa'),
    (label: 'Homestay', icon: Icons.cottage_rounded, keyword: 'homestay'),
    (label: 'Khách sạn', icon: Icons.hotel_rounded, keyword: 'hotel'),
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

  /// Lọc homestay theo tab — dựa trên tên
  List<HomestayModel> _filterByTab(
      List<HomestayModel> homestays, String keyword) {
    var filtered = homestays.where((h) {
      final name = h.name.toLowerCase();
      return name.contains(keyword);
    }).toList();

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
    final homestaysAsync = ref.watch(homestayListProvider);
    final user = ref.watch(currentUserProvider);
    final canEdit = user?.canEdit ?? false;

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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.4, -1),
                  end: Alignment(0.4, 1),
                  colors: [AppColors.oceanDeep, AppColors.ocean],
                ),
              ),
              child: Column(
                children: [
                  // Title row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
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
                                    color: Colors.white
                                        .withValues(alpha: 0.6),
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

                  // TabBar
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor:
                        Colors.white.withValues(alpha: 0.6),
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
          color: AppColors.ocean,
          onRefresh: () async {
            ref.invalidate(homestayListProvider);
          },
          child: homestaysAsync.when(
            loading: () => SkeletonList(
              skeleton: const HomestayCardSkeleton(),
              count: 5,
            ),
            error: (e, _) => Center(
              child: ErrorStateWidget(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(homestayListProvider),
              ),
            ),
            data: (homestays) => TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final filtered = _filterByTab(homestays, tab.keyword);
                if (filtered.isEmpty) {
                  return Center(
                    child: EmptyStateWidget(
                      icon: tab.icon,
                      message: 'Chưa có ${tab.label} nào',
                      subMessage:
                          canEdit ? 'Nhấn + để thêm mới' : null,
                    ),
                  );
                }
                return ListView.separated(
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
                );
              }).toList(),
            ),
          ),
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              onPressed: () => context.push('/properties/new'),
              backgroundColor: AppColors.ocean,
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
    );
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
