import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/legal_sheet.dart';
import '../providers/subscription_provider.dart';

/// Premium subscription (guide §3.8, mockup 4.4): 3-day free trial, then
/// $10/month with the store's local price, plus Restore Purchases.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _buying = false;
  bool _restoring = false;

  static const _features = [
    (
      Icons.fact_check_outlined,
      'CV-based job recommendations',
      'Every job ranked by how well it fits your CV.',
    ),
    (
      Icons.public_rounded,
      'Pakistan and international job leads',
      'Local roles and remote jobs worldwide.',
    ),
    (
      Icons.tune_rounded,
      'Advanced search and filters',
      'Filter by salary, work mode, type and more.',
    ),
    (
      Icons.travel_explore_rounded,
      'Premium job discovery',
      'See new matches first, with daily alerts.',
    ),
  ];

  Future<void> _start() async {
    setState(() => _buying = true);
    try {
      await ref.read(subscriptionProvider.notifier).startTrial();
      if (mounted) AppFeedback.show(context, 'Your free trial has started');
    } catch (_) {
      if (mounted) {
        AppFeedback.show(
          context,
          'The purchase didn\'t go through. You haven\'t been charged.',
        );
      }
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final r = await ref.read(subscriptionProvider.notifier).restorePurchases();
    if (!mounted) return;
    setState(() => _restoring = false);
    AppFeedback.show(
      context,
      r.restored
          ? 'Purchases restored'
          : 'No previous purchases were found for this account.',
    );
  }

  static String _date(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sub = ref.watch(subscriptionProvider);
    final price = '\$${AppConstants.monthlyPriceUsd.toStringAsFixed(0)}';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              title: const Text('SharkHire Premium'),
              titleTextStyle: text.titleMedium?.copyWith(
                color: AppColors.white,
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.sm,
                  AppSpacing.xxl,
                  AppSpacing.xxxl,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: AppRadius.pillAll,
                      ),
                      child: Text(
                        sub.hasPremium
                            ? 'Premium active'
                            : '${AppConstants.freeTrialDays}-day free trial',
                        style: text.labelMedium?.copyWith(
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      sub.hasPremium ? 'You\'re on Premium' : 'Unlock Premium',
                      textAlign: TextAlign.center,
                      style: text.displaySmall?.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: price,
                            style: text.headlineLarge?.copyWith(
                              color: AppColors.cyan,
                            ),
                          ),
                          TextSpan(
                            text: ' / month',
                            style: text.titleMedium?.copyWith(
                              color: AppColors.textOnDarkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Local price shown at checkout (PKR in Pakistan)',
                      textAlign: TextAlign.center,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.textOnDarkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenHorizontal,
                AppSpacing.xxl,
                AppSpacing.screenHorizontal,
                AppSpacing.xxl,
              ),
              sliver: SliverList.list(
                children: [
                  for (final (icon, title, body) in _features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.oceanTint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: AppColors.ocean, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: text.titleSmall),
                                Text(body, style: text.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  if (sub.hasPremium)
                    InlineBanner(
                      tone: BannerTone.success,
                      title: sub.status == SubscriptionStatus.trial
                          ? 'Free trial active'
                          : 'Premium active',
                      message: sub.status == SubscriptionStatus.trial
                          ? 'Your trial ends on ${_date(sub.renewsOrEndsAt!)}. After that it renews at $price a month '
                                'unless you cancel in your store account.'
                          : 'Renews on ${_date(sub.renewsOrEndsAt!)}.',
                    )
                  else
                    InlineBanner(
                      tone: BannerTone.info,
                      title: 'Your free trial',
                      message:
                          '${AppConstants.freeTrialDays} days free. Then it renews at the displayed price '
                          'every month unless you cancel at least 24 hours before the trial ends.',
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  Center(
                    child: TextButton(
                      onPressed: _restoring ? null : _restore,
                      child: Text(
                        _restoring ? 'Restoring…' : 'Restore purchases',
                      ),
                    ),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () =>
                            showLegalSheet(context, LegalDocument.terms),
                        child: const Text('Terms of Use'),
                      ),
                      TextButton(
                        onPressed: () =>
                            showLegalSheet(context, LegalDocument.privacy),
                        child: const Text('Privacy Policy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Payment is handled by Google Play on Android and the App Store on iOS. '
                    'Manage or cancel any time in your store account settings.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: sub.hasPremium
            ? null
            : BottomActionBar(
                child: LoadingButton(
                  label: 'Start free trial',
                  loading: _buying,
                  onPressed: _start,
                ),
              ),
      ),
    );
  }
}
