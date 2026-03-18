import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/room_model.dart';
import '../../../shared/providers/auth_provider.dart';
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
  String? _selectedHomestayId; // null = all
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

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(roomListProvider);
          ref.invalidate(homestayListProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Collapsible header ─────────────────────────────────────────
            SliverAppBar.large(
              title: Text(
                'Danh sách phòng',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
              floating: false,
              pinned: true,
              actions: [
                if (user?.canEdit == true)
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    tooltip: 'Thêm phòng',
                    onPressed: () => context.push('/rooms/new'),
                  ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Làm mới',
                  onPressed: () => ref.invalidate(roomListProvider),
                ),
              ],
            ),

            // ── Search bar ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _search = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm phòng...',
                    hintStyle: GoogleFonts.nunito(fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),

            // ── Homestay filter chips ──────────────────────────────────────
            SliverToBoxAdapter(
              child: homestaysAsync.when(
                loading: () => const SizedBox(height: 48),
                error: (_, __) => const SizedBox.shrink(),
                data: (homestays) {
                  if (homestays.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      children: [
                        // "Tất cả" chip
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterChip(
                            label: const Text('Tất cả'),
                            selected: _selectedHomestayId == null,
                            onSelected: (_) =>
                                setState(() => _selectedHomestayId = null),
                            selectedColor:
                                colors.primary.withValues(alpha: 0.15),
                            checkmarkColor: colors.primary,
                            labelStyle: GoogleFonts.nunito(
                              fontWeight: _selectedHomestayId == null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedHomestayId == null
                                  ? colors.primary
                                  : colors.onSurface,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ...homestays.map((h) => Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.sm),
                              child: FilterChip(
                                label: Text(h.name),
                                selected: _selectedHomestayId == h.id,
                                onSelected: (_) =>
                                    setState(() => _selectedHomestayId = h.id),
                                selectedColor:
                                    colors.primary.withValues(alpha: 0.15),
                                checkmarkColor: colors.primary,
                                labelStyle: GoogleFonts.nunito(
                                  fontWeight: _selectedHomestayId == h.id
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _selectedHomestayId == h.id
                                      ? colors.primary
                                      : colors.onSurface,
                                  fontSize: 12,
                                ),
                              ),
                            )),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Room list ──────────────────────────────────────────────────
            roomsAsync.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.md),
                sliver: SliverList.separated(
                  itemCount: 4,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) => RoomCardSkeleton()
                      .animate(delay: Duration(milliseconds: i * 60))
                      .fadeIn(duration: 300.ms),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorStateWidget(
                  message: e.toString().replaceAll('Exception: ', ''),
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
                      onAction: user?.canEdit == true && _search.isEmpty
                          ? () => context.push('/rooms/new')
                          : null,
                      actionLabel: 'Thêm phòng',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md,
                      AppSpacing.sm, AppSpacing.md, AppSpacing.xxl),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => RoomCard(
                      room: filtered[i],
                      animationIndex: i,
                      onTap: () => context.push('/rooms/${filtered[i].id}'),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // FAB for canEdit users
      floatingActionButton: user?.canEdit == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/rooms/new'),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Thêm phòng',
                style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
              .animate()
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: 300.ms,
                curve: Curves.elasticOut,
                delay: 400.ms,
              )
              .fadeIn(duration: 200.ms, delay: 400.ms)
          : null,
    );
  }
}
