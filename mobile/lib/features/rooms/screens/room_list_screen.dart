import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/room_model.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../homestays/providers/homestay_provider.dart';
import '../providers/room_provider.dart';
import '../widgets/room_card.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  String? _selectedHomestayId;
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RoomModel> _filter(List<RoomModel> rooms) {
    var list = rooms;
    if (_selectedHomestayId != null) {
      list = list.where((r) => r.homestayId == _selectedHomestayId).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((r) =>
              r.name.toLowerCase().contains(q) ||
              r.code.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final roomsAsync = ref.watch(roomListProvider(null));
    final homestaysAsync = ref.watch(homestayListProvider);
    final colors = Theme.of(context).colorScheme;

    return AppScaffold(
      title: '',
      selectedIndex: 0,
      showAppBar: false,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(roomListProvider);
          ref.invalidate(homestayListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Greeting header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + AppSpacing.md,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: greeting + actions
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: GoogleFonts.nunito(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.name ?? 'Homestay',
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Notification bell
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.notifications_outlined,
                                color: Colors.white),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),

                    const SizedBox(height: AppSpacing.lg),

                    // ── Search bar ─────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) =>
                            setState(() => _search = v.trim()),
                        style: GoogleFonts.nunito(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Tìm phòng, homestay...',
                          hintStyle: GoogleFonts.nunito(
                            fontSize: 14,
                            color: colors.outline,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: colors.primary,
                          ),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded,
                                      size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _search = '');
                                  },
                                )
                              : Icon(
                                  Icons.tune_rounded,
                                  size: 20,
                                  color: colors.primary,
                                ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: colors.surface,
                        ),
                      ),
                    )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.15, end: 0),
                  ],
                ),
              ),
            ),

            // ── Categories ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CategoryIcon(
                      icon: Icons.bed_rounded,
                      label: 'Phòng',
                      color: AppColors.primary,
                      isSelected: true,
                      onTap: () {},
                    ),
                    _CategoryIcon(
                      icon: Icons.home_work_rounded,
                      label: 'Homestay',
                      color: AppColors.info,
                      onTap: () => context.go('/homestays'),
                    ),
                    _CategoryIcon(
                      icon: Icons.event_note_rounded,
                      label: 'Booking',
                      color: AppColors.secondary,
                      onTap: () => context.go('/bookings'),
                    ),
                    _CategoryIcon(
                      icon: Icons.calendar_month_rounded,
                      label: 'Lịch',
                      color: AppColors.completed,
                      onTap: () => context.go('/bookings'),
                    ),
                  ],
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
              ),
            ),

            // ── Homestay filter chips ────────────────────────────────────
            SliverToBoxAdapter(
              child: homestaysAsync.when(
                loading: () => const SizedBox(height: 56),
                error: (_, __) => const SizedBox.shrink(),
                data: (homestays) {
                  if (homestays.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding:
                        const EdgeInsets.only(top: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Homestay',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: colors.onSurface,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    context.go('/homestays'),
                                child: Text(
                                  'Xem tất cả',
                                  style: GoogleFonts.nunito(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    right: AppSpacing.sm),
                                child: ChoiceChip(
                                  label: const Text('Tất cả'),
                                  selected:
                                      _selectedHomestayId == null,
                                  onSelected: (_) => setState(
                                      () => _selectedHomestayId =
                                          null),
                                  selectedColor: colors.primary,
                                  labelStyle: GoogleFonts.nunito(
                                    fontWeight:
                                        _selectedHomestayId == null
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                    color:
                                        _selectedHomestayId == null
                                            ? Colors.white
                                            : colors.onSurface,
                                    fontSize: 13,
                                  ),
                                  showCheckmark: false,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(
                                            AppRadius.full),
                                  ),
                                ),
                              ),
                              ...homestays.map(
                                (h) => Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppSpacing.sm),
                                  child: ChoiceChip(
                                    label: Text(h.name),
                                    selected:
                                        _selectedHomestayId == h.id,
                                    onSelected: (_) => setState(
                                        () =>
                                            _selectedHomestayId =
                                                h.id),
                                    selectedColor: colors.primary,
                                    labelStyle: GoogleFonts.nunito(
                                      fontWeight:
                                          _selectedHomestayId ==
                                                  h.id
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                      color:
                                          _selectedHomestayId ==
                                                  h.id
                                              ? Colors.white
                                              : colors.onSurface,
                                      fontSize: 13,
                                    ),
                                    showCheckmark: false,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppRadius.full),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Section title ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _search.isNotEmpty
                          ? 'Kết quả tìm kiếm'
                          : 'Phòng nổi bật',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh_rounded,
                          color: colors.primary, size: 22),
                      tooltip: 'Làm mới',
                      onPressed: () {
                        ref.invalidate(roomListProvider);
                        ref.invalidate(homestayListProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Room list ────────────────────────────────────────────────
            roomsAsync.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                sliver: SliverList.separated(
                  itemCount: 4,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
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
                      message: _search.isNotEmpty
                          ? 'Không tìm thấy phòng'
                          : 'Chưa có phòng nào',
                      subMessage: _search.isNotEmpty
                          ? 'Thử từ khóa khác'
                          : user?.canEdit == true
                              ? 'Nhấn + để thêm phòng mới'
                              : null,
                      onAction:
                          user?.canEdit == true && _search.isEmpty
                              ? () => context.push('/rooms/new')
                              : null,
                      actionLabel: 'Thêm phòng',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.xxl + AppSpacing.xl,
                  ),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng,';
    if (hour < 18) return 'Chào buổi chiều,';
    return 'Chào buổi tối,';
  }
}

// ─── Category Icon ───────────────────────────────────────────────────────────
class _CategoryIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryIcon({
    required this.icon,
    required this.label,
    required this.color,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected
                  ? color
                  : color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? color : colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
