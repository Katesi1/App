import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/room_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../controllers/customer_controller.dart';

class SearchRoomScreen extends ConsumerStatefulWidget {
  const SearchRoomScreen({super.key});

  @override
  ConsumerState<SearchRoomScreen> createState() => _SearchRoomScreenState();
}

class _SearchRoomScreenState extends ConsumerState<SearchRoomScreen> {
  DateTime? _checkinDate;
  DateTime? _checkoutDate;
  int _guests = 2;
  String? _selectedView; // "sea", "city", null
  bool? _priceAscending; // null = mặc định, true = tăng, false = giảm
  PublicRoomFilter? _currentFilter;

  Future<void> _pickDate({required bool isCheckin}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckin
          ? (_checkinDate ?? now)
          : (_checkoutDate ?? (_checkinDate ?? now).add(const Duration(days: 1))),
      firstDate: isCheckin ? now : (_checkinDate ?? now),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckin) {
        _checkinDate = picked;
        // Auto-adjust checkout nếu trước checkin
        if (_checkoutDate != null && !_checkoutDate!.isAfter(picked)) {
          _checkoutDate = picked.add(const Duration(days: 1));
        }
      } else {
        _checkoutDate = picked;
      }
    });
  }

  void _search() {
    setState(() {
      _currentFilter = PublicRoomFilter(
        checkinDate: _checkinDate,
        checkoutDate: _checkoutDate,
        guests: _guests,
        view: _selectedView,
      );
    });
  }

  List<RoomModel> _sortRooms(List<RoomModel> rooms) {
    if (_priceAscending == null) return rooms;
    final sorted = List<RoomModel>.from(rooms);
    sorted.sort((a, b) {
      final pa = a.price?.weekdayPrice;
      final pb = b.price?.weekdayPrice;
      if (pa == null && pb == null) return 0;
      if (pa == null) return 1;
      if (pb == null) return -1;
      return _priceAscending! ? pa.compareTo(pb) : pb.compareTo(pa);
    });
    return sorted;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Chọn ngày';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(publicRoomsProvider(_currentFilter));

    return AppScaffold(
      title: 'Tìm phòng',
      selectedIndex: 1,
      body: Column(
        children: [
          // ── Filter bar ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              children: [
                // Date row
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Nhận phòng',
                        value: _formatDate(_checkinDate),
                        onTap: () => _pickDate(isCheckin: true),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded,
                          color: AppColors.slate, size: 20),
                    ),
                    Expanded(
                      child: _DateField(
                        label: 'Trả phòng',
                        value: _formatDate(_checkoutDate),
                        onTap: () => _pickDate(isCheckin: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // View + Sort row
                Row(
                  children: [
                    // View filter
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedView,
                            isExpanded: true,
                            icon: const Icon(Icons.expand_more_rounded,
                                size: 18, color: AppColors.slate),
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              color: AppColors.navy,
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: null, child: Text('Tất cả view')),
                              DropdownMenuItem(
                                  value: 'sea', child: Text('View biển')),
                              DropdownMenuItem(
                                  value: 'city',
                                  child: Text('View thành phố')),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedView = v),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Sort
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_priceAscending == null) {
                            _priceAscending = true;
                          } else if (_priceAscending == true) {
                            _priceAscending = false;
                          } else {
                            _priceAscending = null;
                          }
                        });
                      },
                      child: Container(
                        height: 38,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _priceAscending != null
                                ? AppColors.ocean
                                : AppColors.border,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                          color: _priceAscending != null
                              ? AppColors.oceanPale
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _priceAscending == null
                                  ? Icons.sort_rounded
                                  : _priceAscending == true
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                              size: 16,
                              color: _priceAscending != null
                                  ? AppColors.ocean
                                  : AppColors.slate,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _priceAscending == null
                                  ? 'Giá'
                                  : _priceAscending == true
                                      ? 'Giá ↑'
                                      : 'Giá ↓',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _priceAscending != null
                                    ? AppColors.ocean
                                    : AppColors.slate,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Guest + Search
                Row(
                  children: [
                    // Guest counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius:
                            BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline_rounded,
                              color: AppColors.slate, size: 18),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _guests > 1
                                ? () =>
                                    setState(() => _guests--)
                                : null,
                            child: Icon(
                              Icons.remove_circle_outline,
                              size: 20,
                              color: _guests > 1
                                  ? AppColors.ocean
                                  : AppColors.border,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10),
                            child: Text(
                              '$_guests',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _guests < 10
                                ? () =>
                                    setState(() => _guests++)
                                : null,
                            child: Icon(
                              Icons.add_circle_outline,
                              size: 20,
                              color: _guests < 10
                                  ? AppColors.ocean
                                  : AppColors.border,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Search button
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          onPressed: _search,
                          icon: const Icon(Icons.search_rounded,
                              size: 20),
                          label: Text(
                            'Tìm kiếm',
                            style: GoogleFonts.beVietnamPro(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.ocean,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Room list ───────────────────────────────────────
          Expanded(
            child: roomsAsync.when(
              data: (rawRooms) {
                final rooms = _sortRooms(rawRooms);
                return RefreshIndicator(
                color: AppColors.ocean,
                onRefresh: () async =>
                    ref.invalidate(publicRoomsProvider(_currentFilter)),
                child: rooms.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off_rounded,
                                    size: 48, color: AppColors.slate),
                                const SizedBox(height: 12),
                                Text(
                                  'Không tìm thấy phòng',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 15,
                                    color: AppColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Thử thay đổi bộ lọc',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 13,
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: rooms.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (_, i) => _RoomListCard(
                          room: rooms[i],
                          index: i,
                          onTap: () =>
                              context.push('/rooms/${rooms[i].id}'),
                        ),
                      ),
                );
              },
              loading: () => SkeletonList(
                skeleton: const RoomCardSkeleton(),
                count: 4,
              ),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.toString().replaceAll('Exception: ', ''),
                      style: GoogleFonts.beVietnamPro(
                        color: AppColors.coral,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => ref.invalidate(
                          publicRoomsProvider(_currentFilter)),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date Field ─────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.beVietnamPro(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: value == 'Chọn ngày'
                          ? AppColors.slate
                          : AppColors.navy,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: AppColors.ocean),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Room List Card ─────────────────────────────────────────────────────────

class _RoomListCard extends StatelessWidget {
  final RoomModel room;
  final int index;
  final VoidCallback onTap;

  const _RoomListCard({
    required this.room,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Image
            SizedBox(
              width: 110,
              height: 100,
              child: room.coverImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: room.coverImageUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 250,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (room.homestay != null)
                      Text(
                        room.homestay!.name,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          room.priceDisplay,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ocean,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.people_outline_rounded,
                            size: 14, color: AppColors.muted),
                        const SizedBox(width: 3),
                        Text(
                          '${room.maxGuests} người',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0);
  }

  Widget _placeholder() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.oceanLight, AppColors.tealLight],
          ),
        ),
        child: const Center(
          child: Icon(Icons.home_rounded,
              size: 28, color: AppColors.oceanMid),
        ),
      );
}
