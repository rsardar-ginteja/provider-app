import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider_app/services/authServices.dart';
import 'package:provider_app/stores/bookingProviders.dart';
import 'package:provider_app/stores/providers.dart';
import '../theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    // Fetch the provider profile when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Map<String, dynamic>? profileState = ref.read(
        providerProfileProvider,
      );
      if (profileState == null) {
        // Fetch the profile data and update the state
        ref
            .read(authServiceProvider)
            .getUserProfile()
            .then((response) {
              ref.read(providerProfileProvider.notifier).state =
                  response.data?['user'];
            })
            .catchError((error) {
              debugPrint('Error fetching profile: $error');
            });
        ref.read(providerProfileProvider.notifier).state = {};
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final Map<String, dynamic>? profileState = ref.watch(
      providerProfileProvider,
    );

    final asyncAvailable = ref.watch(availableBookingsProvider);
    final asyncInProgress = ref.watch(
      providerAssignedBookingsProvider('in_progress'),
    );
    final asyncAccepted = ref.watch(
      providerAssignedBookingsProvider('accepted'),
    );
    final asyncCompleted = ref.watch(
      providerAssignedBookingsProvider('completed'),
    );

    final availableCount = asyncAvailable.value?.length ?? 0;
    final inProgressList = asyncInProgress.value ?? [];
    final acceptedList = asyncAccepted.value ?? [];
    final completedList = asyncCompleted.value ?? [];

    // Prioritize active (in_progress) job, otherwise upcoming accepted job
    final activeJob = inProgressList.isNotEmpty
        ? inProgressList.first
        : (acceptedList.isNotEmpty ? acceptedList.first : null);

    // Calculate total earned from completed jobs
    double totalEarned = 0;
    for (final c in completedList) {
      final b = c['booking'] as Map<String, dynamic>? ?? {};
      final amount = b['totalAmount'] ?? b['originalAmount'] ?? 0;
      if (amount is num) {
        totalEarned += amount.toDouble();
      }
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(availableBookingsProvider);
            ref.invalidate(providerAssignedBookingsProvider('in_progress'));
            ref.invalidate(providerAssignedBookingsProvider('accepted'));
            ref.invalidate(providerAssignedBookingsProvider('completed'));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Top Header Panel
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.05,
                        ),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  profileState?['username'] != null &&
                                          profileState!['username']
                                              .isNotEmpty
                                      ? profileState['username'][0]
                                          .toUpperCase()
                                      : 'P',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Operational Console',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyMedium?.color,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    '${profileState?['username'] ?? 'Service Provider'}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Online Toggle Button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isOnline = !_isOnline;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _isOnline
                                        ? '🟢 Operations Status: ONLINE'
                                        : '🔴 Operations Status: OFFLINE',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _isOnline
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isOnline
                                      ? AppColors.success.withValues(alpha: 0.3)
                                      : AppColors.danger.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _isOnline
                                          ? AppColors.success
                                          : AppColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _isOnline ? 'ONLINE' : 'OFFLINE',
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _isOnline
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Mini stats grid
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBg
                                    : AppColors.lightBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL SETTLED PAYOUT',
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${totalEarned.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${completedList.length} jobs completed',
                                    style: const TextStyle(
                                      color: AppColors.success,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkBg
                                    : AppColors.lightBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DISPATCH REQUESTS',
                                    style: GoogleFonts.inter(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$availableCount',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Available for claim',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Content
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Operational Flow Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ACTIVE OPERATIONAL FLOW',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyMedium?.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.go('/bookings'),
                            child: Text(
                              'View Dispatch ($availableCount)',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dynamic Active Booking Flow Card
                      _buildActiveJobSection(activeJob, theme),

                      const SizedBox(height: 24),

                      // Velocity Distribution Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Velocity Distribution',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Activity Log',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 9,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 64,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildBar(theme, 32, false),
                                  _buildBar(theme, 48, false),
                                  _buildBar(theme, 64, true),
                                  _buildBar(theme, 40, false),
                                  _buildBar(theme, 56, true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveJobSection(
    Map<String, dynamic>? activeJob,
    ThemeData theme,
  ) {
    if (activeJob == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 36,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'No Active Jobs in Progress or Accepted',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Check the Dispatch Terminal to claim incoming requests.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/bookings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Open Dispatch Terminal',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    final booking = activeJob['booking'] as Map<String, dynamic>? ?? {};
    final service = activeJob['service'] as Map<String, dynamic>? ?? {};
    final address = activeJob['address'] as Map<String, dynamic>? ?? {};
    final customer = activeJob['customer'] as Map<String, dynamic>? ?? {};

    final serviceName = service['name']?.toString() ?? 'Service Booking';
    final customerName = customer['username']?.toString() ?? 'Customer';
    final addressText = [
      address['house_number'],
      address['street_no_or_name'],
      address['city'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');

    final totalAmount = booking['totalAmount'] != null
        ? '\$${booking['totalAmount']}'
        : '\$${service['basePrice'] ?? '0.00'}';
    final status = (booking['bookingStatus']?.toString() ?? 'ACCEPTED').toUpperCase();
    final isInProgress = status == 'IN_PROGRESS';

    return GestureDetector(
      onTap: () => context.go('/bookings/detail', extra: activeJob),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isInProgress ? 'ACTIVE IN PROGRESS' : 'MANIFEST ALLOCATED',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isInProgress ? AppColors.success : AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'STATE: $status',
                      style: GoogleFonts.inter(
                        color: isInProgress ? AppColors.success : AppColors.warning,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              serviceName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Client Target: $customerName ${addressText.isNotEmpty ? '• $addressText' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Est. Payout Value: ',
                    style: GoogleFonts.inter(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 9.5,
                    ),
                    children: [
                      TextSpan(
                        text: totalAmount,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Open System Manifest',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(ThemeData theme, double height, bool isPrimary) {
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : theme.dividerColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
    );
  }
}
