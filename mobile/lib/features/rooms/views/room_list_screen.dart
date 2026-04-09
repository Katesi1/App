import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/room_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/date_picker_tile.dart';
import '../../../shared/widgets/filter_chip_tile.dart';
import '../../../shared/widgets/guest_counter.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/section_label.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/room_controller.dart';
import '../widgets/room_card.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Search (debounce 300ms)
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;

  // Filters
  final Set<String> _selectedViews = {};
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 0;
  int _children = 0;

  // Sort theo giá: null = mặc định, true = tăng dần, false = giảm dần
  bool? _priceAscending;

  // Tabs
  // typeValues: 0=VILLA, 1=HOMESTAY, 2=HOTEL
  // typeValues == null nghĩa là tab "Tất cả" — không filter theo type
  static const _tabs = [
    (label: 'Tất cả', icon: Icons.apps_rounded, typeValues: null),
    (label: 'Villa', icon: Icons.villa_rounded, typeValues: [0]),
    (label: 'Homestay', icon: Icons.cottage_rounded, typeValues: [1]),
    (label: 'Khách sạn', icon: Icons.hotel_rounded, typeValues: [2]),
  ];

  bool get _hasActiveFilters =>
      _selectedViews.isNotEmpty ||
      _checkIn != null ||
      _checkOut != null ||
      _adults > 0 ||
      _children > 0;

  List<String> get _activeFilterLabels {
    final labels = <String>[];
    for (final v in _selectedViews) {
      labels.add(_viewLabels[v] ?? v);
    }
    if (_checkIn != null) {
      labels.add('Check-in: ${_checkIn!.day}/${_checkIn!.month}');
    }
    if (_checkOut != null) {
      labels.add('Check-out: ${_checkOut!.day}/${_checkOut!.month}');
    }
    if (_adults > 0) labels.add('$_adults người lớn');
    if (_children > 0) labels.add('$_children trẻ em');
    return labels;
  }

  static const _viewLabels = {
    'sea': 'View biển',
    'city': 'View thành phố',
    'garden': 'View sân vườn',
  };

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

  /// Lọc rooms theo tab.
  /// [typeValues] null = tab "Tất cả" → không filter theo type.
  /// [typeValues] có thể chứa nhiều type (vd: Homestay = [1]).
  List<RoomModel> _filterByTab(List<RoomModel> rooms, List<int>? typeValues) {
    var list = typeValues == null
        ? List<RoomModel>.from(rooms)
        : rooms.where((r) => typeValues.contains(r.type)).toList();

    // Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list
          .where((r) =>
              r.name.toLowerCase().contains(query) ||
              r.code.toLowerCase().contains(query))
          .toList();
    }

    // Sort theo giá (weekdayPrice). Phòng chưa có giá → đẩy xuống cuối.
    if (_priceAscending != null) {
      list.sort((a, b) {
        final pa = a.price?.weekdayPrice;
        final pb = b.price?.weekdayPrice;
        if (pa == null && pb == null) return 0;
        if (pa == null) return 1;
        if (pb == null) return -1;
        return _priceAscending! ? pa.compareTo(pb) : pb.compareTo(pa);
      });
    }

    // TODO: Apply view, date, guest filters khi API hỗ trợ
    return list;
  }

  void _cyclePriceSort() {
    setState(() {
      // null → asc → desc → null
      if (_priceAscending == null) {
        _priceAscending = true;
      } else if (_priceAscending == true) {
        _priceAscending = false;
      } else {
        _priceAscending = null;
      }
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

  void _resetFilters() {
    setState(() {
      _selectedViews.clear();
      _checkIn = null;
      _checkOut = null;
      _adults = 0;
      _children = 0;
    });
  }

  void _showFilterSheet() {
    final tempViews = Set<String>.from(_selectedViews);
    var tempCheckIn = _checkIn;
    var tempCheckOut = _checkOut;
    var tempAdults = _adults;
    var tempChildren = _children;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void toggleSet(Set<String> set, String key) {
            setSheetState(() {
              if (set.contains(key)) {
                set.remove(key);
              } else {
                set.add(key);
              }
            });
          }

          Future<void> pickSheetDate({required bool isCheckIn}) async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate:
                  (isCheckIn ? tempCheckIn : tempCheckOut) ?? now,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
              builder: (c, child) => Theme(
                data: Theme.of(c).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.ocean,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setSheetState(() {
                if (isCheckIn) {
                  tempCheckIn = picked;
                  if (tempCheckOut != null &&
                      tempCheckOut!.isBefore(picked)) {
                    tempCheckOut =
                        picked.add(const Duration(days: 1));
                  }
                } else {
                  tempCheckOut = picked;
                }
              });
            }
          }

          String formatDate(DateTime? d) {
            if (d == null) return 'Chọn ngày';
            return '${d.day.toString().padLeft(2, '0')}/'
                '${d.month.toString().padLeft(2, '0')}/'
                '${d.year}';
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'Bộ lọc',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            tempViews.clear();
                            tempCheckIn = null;
                            tempCheckOut = null;
                            tempAdults = 0;
                            tempChildren = 0;
                          });
                        },
                        child: Text(
                          'Đặt lại',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ocean,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                // ── View ──
                SectionLabel(label: 'VIEW'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: _viewLabels.entries.map((e) {
                      final selected = tempViews.contains(e.key);
                      return FilterChipTile(
                        label: e.value,
                        icon: switch (e.key) {
                          'sea' => Icons.waves_rounded,
                          'city' => Icons.location_city_rounded,
                          'garden' => Icons.park_rounded,
                          _ => Icons.home_rounded,
                        },
                        isSelected: selected,
                        onTap: () =>
                            toggleSet(tempViews, e.key),
                      );
                    }).toList(),
                  ),
                ),

                // ── Check-in / Check-out ──
                SectionLabel(label: 'NGÀY'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: DatePickerTile(
                          label: 'Check-in',
                          value: formatDate(tempCheckIn),
                          hasValue: tempCheckIn != null,
                          onTap: () =>
                              pickSheetDate(isCheckIn: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DatePickerTile(
                          label: 'Check-out',
                          value: formatDate(tempCheckOut),
                          hasValue: tempCheckOut != null,
                          onTap: () =>
                              pickSheetDate(isCheckIn: false),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Số khách ──
                SectionLabel(label: 'SỐ KHÁCH'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GuestCounter(
                          label: 'Người lớn',
                          value: tempAdults,
                          onChanged: (v) =>
                              setSheetState(() => tempAdults = v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GuestCounter(
                          label: 'Trẻ em',
                          value: tempChildren,
                          onChanged: (v) => setSheetState(
                              () => tempChildren = v),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // Apply button
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedViews
                            ..clear()
                            ..addAll(tempViews);
                          _checkIn = tempCheckIn;
                          _checkOut = tempCheckOut;
                          _adults = tempAdults;
                          _children = tempChildren;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ocean,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Áp dụng',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(ctx).padding.bottom,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userName = user?.name ?? user?.phone ?? '';
    final roomsAsync = ref.watch(roomListProvider(null));

    return AppScaffold(
      title: '',
      selectedIndex: 1,
      showAppBar: false,
      body: RefreshIndicator(
        color: AppColors.ocean,
        onRefresh: () async {
          ref.invalidate(roomListProvider(null));
        },
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // ── Header + TabBar ──
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 20,
                  right: 20,
                  bottom: 4,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.oceanDeep, AppColors.ocean],
                  ),
                ),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          right: -50,
                          top: -40,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.teal.withValues(alpha: 0.10),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -30,
                          bottom: -30,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.gold.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Danh sách phòng',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Villa · Homestay · Khách sạn',
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 12,
                                      color: Colors.white
                                          .withValues(alpha: 0.65),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _HeaderIconBtn(
                              icon: _isSearching
                                  ? Icons.close_rounded
                                  : Icons.search_rounded,
                              onTap: _toggleSearch,
                            ),
                            const SizedBox(width: 8),
                            _HeaderIconBtn(
                              icon: _priceAscending == null
                                  ? Icons.sort_rounded
                                  : _priceAscending == true
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                              badge: _priceAscending != null,
                              onTap: _cyclePriceSort,
                            ),
                            const SizedBox(width: 8),
                            _HeaderIconBtn(
                              icon: Icons.filter_list_rounded,
                              badge: _hasActiveFilters,
                              onTap: _showFilterSheet,
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.push('/profile'),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                      colors: [AppColors.teal, AppColors.gold]),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1.5),
                                ),
                                child: Center(
                                  child: Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : 'U',
                                    style: GoogleFonts.beVietnamPro(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // ── Search input ──
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
                            hintText: 'Tìm theo tên hoặc mã phòng...',
                            hintStyle: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color:
                                  Colors.white.withValues(alpha: 0.6),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color:
                                  Colors.white.withValues(alpha: 0.6),
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
                                const EdgeInsets.symmetric(
                                    vertical: 10),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // ── TabBar — scrollable để tránh overflow ──
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelPadding:
                          const EdgeInsets.symmetric(horizontal: 14),
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

            // ── Active filter chips ──
            if (_hasActiveFilters)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ..._activeFilterLabels.map((label) => Chip(
                            label: Text(
                              label,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ocean,
                              ),
                            ),
                            backgroundColor: AppColors.oceanPale,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          )),
                      GestureDetector(
                        onTap: _resetFilters,
                        child: Chip(
                          label: Text(
                            'Xoá bộ lọc',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.coral,
                            ),
                          ),
                          avatar: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: AppColors.coral,
                          ),
                          backgroundColor: AppColors.coralLight,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          body: roomsAsync.when(
            loading: () => SkeletonList(
              skeleton: const RoomCardSkeleton(),
              count: 4,
            ),
            error: (e, _) => Center(
              child: ErrorStateWidget(
                message:
                    e.toString().replaceAll('Exception: ', ''),
                onRetry: () =>
                    ref.invalidate(roomListProvider(null)),
              ),
            ),
            data: (rooms) => TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final filtered = _filterByTab(rooms, tab.typeValues);
                if (filtered.isEmpty) {
                  return Center(
                    child: EmptyStateWidget(
                      icon: tab.icon,
                      message: 'Chưa có ${tab.label} nào',
                      subMessage: 'Chưa có phòng trong danh mục này',
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                      16, 16, 16, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (_, i) => RoomCard(
                    room: filtered[i],
                    animationIndex: i,
                    onTap: () => context
                        .push('/rooms/${filtered[i].id}'),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header Icon Button ────────────────────────────────────────────────────────
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          if (badge)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
