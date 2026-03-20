import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/room_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/date_picker_tile.dart';
import '../../../shared/widgets/filter_chip_tile.dart';
import '../../../shared/widgets/guest_counter.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/section_label.dart';
import '../controllers/room_controller.dart';
import '../widgets/room_card.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  // Search
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  // Filters
  final Set<String> _selectedViews = {};
  final Set<String> _selectedTypes = {};
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 0;
  int _children = 0;

  bool get _hasActiveFilters =>
      _selectedViews.isNotEmpty ||
      _selectedTypes.isNotEmpty ||
      _checkIn != null ||
      _checkOut != null ||
      _adults > 0 ||
      _children > 0;

  List<String> get _activeFilterLabels {
    final labels = <String>[];
    for (final v in _selectedViews) {
      labels.add(_viewLabels[v] ?? v);
    }
    for (final t in _selectedTypes) {
      labels.add(_typeLabels[t] ?? t);
    }
    if (_checkIn != null) {
      labels.add(
          'Check-in: ${_checkIn!.day}/${_checkIn!.month}');
    }
    if (_checkOut != null) {
      labels.add(
          'Check-out: ${_checkOut!.day}/${_checkOut!.month}');
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

  static const _typeLabels = {
    'villa': 'Villa',
    'homestay': 'Homestay',
    'hotel': 'Khách sạn',
  };

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<RoomModel> _filter(List<RoomModel> rooms) {
    var list = rooms;

    // Search by name or code
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list
          .where((r) =>
              r.name.toLowerCase().contains(query) ||
              r.code.toLowerCase().contains(query))
          .toList();
    }

    // TODO: Apply view, type, date, guest filters khi API hỗ trợ
    return list;
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
      _selectedTypes.clear();
      _checkIn = null;
      _checkOut = null;
      _adults = 0;
      _children = 0;
    });
  }

  void _showFilterSheet() {
    // Tạo bản copy để user có thể huỷ
    final tempViews = Set<String>.from(_selectedViews);
    final tempTypes = Set<String>.from(_selectedTypes);
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
                            tempTypes.clear();
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

                // ── Loại ──
                SectionLabel(label: 'LOẠI'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: _typeLabels.entries.map((e) {
                      final selected = tempTypes.contains(e.key);
                      return FilterChipTile(
                        label: e.value,
                        icon: switch (e.key) {
                          'villa' => Icons.villa_rounded,
                          'homestay' => Icons.cottage_rounded,
                          'hotel' => Icons.apartment_rounded,
                          _ => Icons.home_rounded,
                        },
                        isSelected: selected,
                        onTap: () =>
                            toggleSet(tempTypes, e.key),
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
                          _selectedTypes
                            ..clear()
                            ..addAll(tempTypes);
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
    final roomsAsync = ref.watch(roomListProvider(null));

    return AppScaffold(
      title: '',
      selectedIndex: 1,
      showAppBar: false,
      body: RefreshIndicator(
        color: AppColors.ocean,
        onRefresh: () async {
          ref.invalidate(roomListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 14,
                  left: 20,
                  right: 20,
                  bottom: 16,
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Danh sách phòng',
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
                        const SizedBox(width: 8),
                        _HeaderIconBtn(
                          icon: Icons.filter_list_rounded,
                          badge: _hasActiveFilters,
                          onTap: _showFilterSheet,
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
                          onChanged: (v) =>
                              setState(() => _searchQuery = v),
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
                  ],
                ),
              ),
            ),

            // ── Active filter chips ───────────────────────────────────
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
                      // Nút xoá tất cả
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

            const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.md)),

            // ── Room cards ──────────────────────────────────────────
            roomsAsync.when(
              loading: () => SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: 3,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (_, i) => RoomCardSkeleton()
                      .animate(
                          delay: Duration(milliseconds: i * 60))
                      .fadeIn(duration: 300.ms),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorStateWidget(
                  message:
                      e.toString().replaceAll('Exception: ', ''),
                  onRetry: () => ref.invalidate(roomListProvider),
                ),
              ),
              data: (rooms) {
                final filtered = _filter(rooms);
                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.bed_outlined,
                      message: 'Chưa có phòng nào',
                      subMessage: 'Nhấn + để thêm phòng mới',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) => RoomCard(
                      room: filtered[i],
                      animationIndex: i,
                      onTap: () => context
                          .push('/rooms/${filtered[i].id}'),
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
