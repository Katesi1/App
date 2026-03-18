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
import '../controllers/room_controller.dart';
import '../widgets/room_card.dart';

class RoomListScreen extends ConsumerStatefulWidget {
  const RoomListScreen({super.key});

  @override
  ConsumerState<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends ConsumerState<RoomListScreen> {
  String? _selectedHomestayId;
  String _selectedFilter = 'all';

  List<RoomModel> _filter(List<RoomModel> rooms) {
    var list = rooms;
    if (_selectedHomestayId != null) {
      list =
          list.where((r) => r.homestayId == _selectedHomestayId).toList();
    }
    if (_selectedFilter == 'active') {
      list = list.where((r) => r.isActive).toList();
    } else if (_selectedFilter == 'inactive') {
      list = list.where((r) => !r.isActive).toList();
    }
    return list;
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
            // ── Header: "Quản lý phòng" ─────────────────────────────
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
                child: Row(
                  children: [
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
                      icon: Icons.search_rounded,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _HeaderIconBtn(
                      icon: Icons.filter_list_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            // ── Filter pills ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: roomsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (rooms) {
                    final total = rooms.length;
                    final active =
                        rooms.where((r) => r.isActive).length;
                    final inactive = total - active;
                    return SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _FilterPill(
                            label: 'Tất cả ($total)',
                            isActive: _selectedFilter == 'all',
                            onTap: () => setState(
                                () => _selectedFilter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'Trống ($active)',
                            isActive: _selectedFilter == 'active',
                            onTap: () => setState(
                                () => _selectedFilter = 'active'),
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'Đang ở (${rooms.length})',
                            isActive: false,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'Đã đặt',
                            isActive: false,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'Bảo trì ($inactive)',
                            isActive: _selectedFilter == 'inactive',
                            onTap: () => setState(
                                () => _selectedFilter = 'inactive'),
                          ),
                        ],
                      ),
                    );
                  },
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
      // FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/rooms/new'),
        backgroundColor: AppColors.ocean,
        child: const Icon(Icons.add_rounded,
            color: Colors.white, size: 24),
      ),
    );
  }
}

// ─── Filter Pill ───────────────────────────────────────────────────────────────
class _FilterPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.ocean : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.ocean : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.muted,
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
