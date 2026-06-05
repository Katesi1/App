import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/section_label.dart';
import '../controllers/booking_controller.dart';
import '../utils/guest_flow_filter.dart';
import '../widgets/guest_flow_booking_tile.dart';

class GuestFlowListScreen extends ConsumerWidget {
  final GuestFlowType flowType;

  const GuestFlowListScreen({
    super.key,
    required this.flowType,
  });

  String get _title => flowType == GuestFlowType.checkIn
      ? 'Check-in sắp tới'
      : 'Check-out sắp tới';

  String get _emptyMessage => flowType == GuestFlowType.checkIn
      ? 'Không có khách check-in sắp tới'
      : 'Không có khách check-out sắp tới';

  String get _emptySubMessage => flowType == GuestFlowType.checkIn
      ? 'Các booking nhận phòng trong 14 ngày tới sẽ hiện ở đây'
      : 'Các booking trả phòng trong 14 ngày tới sẽ hiện ở đây';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(guestFlowBookingsProvider(flowType));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: Text(_title),
      ),
      body: async.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => ErrorStateWidget(
          message: error.toString().replaceAll('Exception: ', ''),
          onRetry: () {
            ref.invalidate(bookingListProvider(null));
            ref.invalidate(guestFlowBookingsProvider(flowType));
          },
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return EmptyStateWidget(
              icon: flowType == GuestFlowType.checkIn
                  ? Icons.login_rounded
                  : Icons.logout_rounded,
              message: _emptyMessage,
              subMessage: _emptySubMessage,
            );
          }

          final groups = GuestFlowFilter.groupByProperty(bookings);
          final sortedPropertyIds = groups.keys.toList()
            ..sort((a, b) {
              final nameA = groups[a]!.first.propertyName;
              final nameB = groups[b]!.first.propertyName;
              return nameA.compareTo(nameB);
            });

          return RefreshIndicator(
            color: colors.brand,
            onRefresh: () async {
              ref.invalidate(bookingListProvider(null));
              ref.invalidate(guestFlowBookingsProvider(flowType));
              await ref.read(guestFlowBookingsProvider(flowType).future);
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              itemCount: sortedPropertyIds.length,
              itemBuilder: (context, index) {
                final propertyId = sortedPropertyIds[index];
                final propertyBookings = groups[propertyId]!;
                final propertyName = propertyBookings.first.propertyName;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(label: propertyName.toUpperCase()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${propertyBookings.length} khách',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...propertyBookings.map(
                            (booking) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: GuestFlowBookingTile(
                                booking: booking,
                                flowType: flowType,
                                onTap: () => context.push(
                                  '/bookings/${booking.id}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class CheckInListScreen extends StatelessWidget {
  const CheckInListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuestFlowListScreen(flowType: GuestFlowType.checkIn);
  }
}

class CheckOutListScreen extends StatelessWidget {
  const CheckOutListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GuestFlowListScreen(flowType: GuestFlowType.checkOut);
  }
}
