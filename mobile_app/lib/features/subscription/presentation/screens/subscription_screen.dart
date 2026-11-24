import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../shared/widgets/bottom_action_bar.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../../../shared/widgets/legal_sheet.dart';
import '../../../authentication/presentation/widgets/sign_out_sheet.dart';
import '../../data/billing_service.dart';
import '../../domain/subscription_status.dart';
import '../providers/subscription_providers.dart';

/// Paywall and subscription overview (guide §3.8): status from the backend,
/// the store's localized price, subscribe, restore, manage and history.
///
/// [next] is where the user was going when the access guard sent them
/// here; they return there once the backend confirms access.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key, this.next});

  final String? next;

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _buying = false;
  bool _restoring = false;
  bool _checking = false;
  SubscriptionFeedback? _feedback;

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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(subscriptionProvider.notifier).ensureLoaded();
    });
  }

  bool get _busy => _buying || _restoring || _checking;

  ButtonStyle get _linkStyle =>
      TextButton.styleFrom(foregroundColor: AppColors.textSecondary);

  Future<void> _subscribe(BillingPackage package) async {
    setState(() {
      _buying = true;
      _feedback = null;
    });
    final result = await ref
        .read(subscriptionProvider.notifier)
        .purchase(package);
    if (!mounted) return;
    setState(() {
      _buying = false;
      _feedback = result.message == null ? null : result;
    });
  }

  Future<void> _restore() async {
    setState(() {
      _restoring = true;
      _feedback = null;
    });
    final result = await ref.read(subscriptionProvider.notifier).restore();
    if (!mounted) return;
    setState(() {
      _restoring = false;
      _feedback = result.message == null ? null : result;
    });
  }

  Future<void> _checkAgain() async {
    setState(() => _checking = true);
    await ref.read(subscriptionProvider.notifier).sync();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _feedback = null;
    });
  }

  Future<void> _manage(String? backendUrl) async {
    final url =
        backendUrl ?? await ref.read(billingServiceProvider).managementUrl();
    if (!mounted) return;
    final ok =
        url != null &&
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      AppFeedback.show(
        context,
        'Manage your subscription in Google Play or App Store settings.',
      );
    }
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
    final l = d.toLocal();
    return '${l.day} ${m[l.month - 1]} ${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = ref.watch(subscriptionProvider);
    final billing = ref.watch(billingServiceProvider);
    final packages = billing.isAvailable
        ? ref.watch(billingPackagesProvider)
        : const AsyncValue<List<BillingPackage>>.data([]);
    final package = packages.value?.firstOrNull;

    // Back to where the guard stopped the user, once access is confirmed.
    ref.listen(subscriptionProvider, (_, next) {
      final target = widget.next;
      if (next.hasAccess && target != null) context.go(target);
    });

    final canBuy =
        billing.isAvailable &&
        package != null &&
        !status.isLoading &&
        !status.serviceUnavailable &&
        !status.isPaid;
    final blocked = widget.next != null && !status.hasAccess;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: !blocked,
              backgroundColor: AppColors.navy,
              foregroundColor: AppColors.white,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              title: const Text('SharkHire Premium'),
              titleTextStyle: text.titleMedium?.copyWith(
                color: AppColors.white,
              ),
            ),
            SliverToBoxAdapter(
              child: _Hero(
                status: status,
                package: package,
                pricesLoading: packages.isLoading,
                date: _date,
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
                  if (status.state != AccessState.trialActive)
                    _StatusBanner(
                      status: status,
                      date: _date,
                      onRetry: _busy
                          ? null
                          : () => ref
                                .read(subscriptionProvider.notifier)
                                .refresh(),
                      onManage: () => _manage(status.managementUrl),
                    ),
                  if (!billing.isAvailable &&
                      !status.hasAccess &&
                      !status.serviceUnavailable) ...[
                    const SizedBox(height: AppSpacing.md),
                    InlineBanner(message: billing.unavailableReason!),
                  ],
                  if (billing.isAvailable && packages.hasError) ...[
                    const SizedBox(height: AppSpacing.md),
                    const InlineBanner(
                      tone: BannerTone.warning,
                      message:
                          'We couldn\'t load the price from the store. '
                          'Check your connection and try again.',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.xlAll,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < _features.length; i++) ...[
                          if (i > 0) const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _features[i].$2,
                                        style: text.titleSmall,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _features[i].$3,
                                        style: text.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const SizedBox(height: AppSpacing.sm),
                  if (_feedback != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      liveRegion: true,
                      child: InlineBanner(
                        tone: _feedback!.isError
                            ? BannerTone.error
                            : BannerTone.info,
                        message: _feedback!.message!,
                      ),
                    ),
                    if (_feedback!.message == confirmingPurchaseMessage)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _busy ? null : _checkAgain,
                          child: Text(_checking ? 'Checking…' : 'Check again'),
                        ),
                      ),
                  ],
                  Wrap(
                    children: [
                      TextButton(
                        style: _linkStyle,
                        onPressed: _busy ? null : _restore,
                        child: Text(
                          _restoring ? 'Restoring…' : 'Restore purchases',
                        ),
                      ),
                      if (status.state == AccessState.subscriptionActive ||
                          status.state ==
                              AccessState.subscriptionCancelledButActive ||
                          status.state == AccessState.billingIssue)
                        TextButton(
                          style: _linkStyle,
                          onPressed: () => _manage(status.managementUrl),
                          child: const Text('Manage subscription'),
                        ),
                      TextButton(
                        style: _linkStyle,
                        onPressed: () =>
                            context.push(AppRoutes.subscriptionHistory),
                        child: const Text('Billing history'),
                      ),
                    ],
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
                      if (blocked) ...[
                        TextButton(
                          onPressed: () => context.push(AppRoutes.help),
                          child: const Text('Help'),
                        ),
                        TextButton(
                          onPressed: () => confirmSignOut(context, ref),
                          child: const Text('Log out'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Payment is charged to your Google Play or App Store '
                    'account. The subscription renews automatically every '
                    'month at the price shown unless you cancel at least 24 '
                    'hours before the end of the current period. Manage or '
                    'cancel any time in your store account settings.',
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
        bottomNavigationBar: canBuy
            ? BottomActionBar(
                child: LoadingButton(
                  label: 'Subscribe for ${package.priceString} / month',
                  loading: _buying,
                  onPressed: _busy ? null : () => _subscribe(package),
                ),
              )
            : null,
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.status,
    required this.package,
    required this.pricesLoading,
    required this.date,
  });

  final SubscriptionStatus status;
  final BillingPackage? package;
  final bool pricesLoading;
  final String Function(DateTime) date;

  static const _muted = Color(0xFF9AA8B6);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final days = status.trialDaysLeft();
    final trial = status.state == AccessState.trialActive;
    final kicker = switch (status.state) {
      AccessState.loading => 'Checking your access…',
      AccessState.trialActive =>
        days == null
            ? 'Free trial active'
            : 'Free trial · $days ${days == 1 ? 'day' : 'days'} left',
      AccessState.subscriptionActive => 'Subscription active',
      AccessState.subscriptionCancelledButActive => 'Cancelled · still active',
      AccessState.billingIssue => 'Payment problem',
      AccessState.subscriptionExpired => 'Subscription ended',
      AccessState.paymentRequired => 'Free trial ended',
      AccessState.error => 'Status unavailable',
    };
    final title = status.hasAccess
        ? 'You have full access'
        : 'Keep finding your next job';
    final trialEnd = status.trialEndsAt;
    final note = trial && trialEnd != null
        ? 'Your trial ends on ${date(trialEnd)}. Cancel any time in the store.'
        : 'Every new account starts with a '
              '${AppConstants.freeTrialDays}-day free trial.';
    final totalDays = AppConstants.freeTrialDays;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Container(
        color: AppColors.navy,
        child: Stack(
          children: [
            // Faint rings, an echo of the Your roles wheel.
            const Positioned(
              right: -60,
              top: -40,
              child: _Ring(size: 220, alpha: 0.16),
            ),
            const Positioned(
              right: -20,
              top: 0,
              child: _Ring(size: 140, alpha: 0.10),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.sm,
                AppSpacing.xxl,
                AppSpacing.xxl + 6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (trial && days != null) ...[
                        for (var i = 0; i < totalDays; i++) ...[
                          if (i > 0) const SizedBox(width: 4),
                          Container(
                            width: 22,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i < days
                                  ? AppColors.teal
                                  : AppColors.navySoft,
                              borderRadius: AppRadius.pillAll,
                            ),
                          ),
                        ],
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          kicker,
                          style: text.labelMedium?.copyWith(
                            color: _muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    style: text.displaySmall?.copyWith(
                      color: AppColors.white,
                      fontSize: 38,
                      height: 1.05,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg + 2),
                  if (package != null)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: package!.priceString,
                            style: text.displaySmall?.copyWith(
                              color: AppColors.white,
                              fontSize: 46,
                              height: 1,
                              letterSpacing: -1,
                            ),
                          ),
                          TextSpan(
                            text: trial
                                ? ' / month after the trial'
                                : ' / month',
                            style: text.titleSmall?.copyWith(
                              color: _muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      pricesLoading
                          ? 'Loading price…'
                          : 'One monthly plan. Your local price is shown by '
                                'the store.',
                      style: text.bodyMedium?.copyWith(color: _muted),
                    ),
                  const SizedBox(height: 6),
                  Text(note, style: text.bodyMedium?.copyWith(color: _muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.teal.withValues(alpha: alpha)),
      ),
    ),
  );
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.status,
    required this.date,
    required this.onRetry,
    required this.onManage,
  });

  final SubscriptionStatus status;
  final String Function(DateTime) date;
  final VoidCallback? onRetry;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final trialEnd = status.trialEndsAt;
    final periodEnd = status.currentPeriodEndsAt;
    final banner = switch (status.state) {
      AccessState.loading => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      AccessState.trialActive => InlineBanner(
        tone: BannerTone.success,
        title: 'Free trial active',
        message: trialEnd == null
            ? 'Subscribe before your trial ends to keep full access.'
            : 'Your trial ends on ${date(trialEnd)}. Subscribe before then '
                  'to keep full access.',
      ),
      AccessState.subscriptionActive => InlineBanner(
        tone: BannerTone.success,
        title: 'Subscription active',
        message: periodEnd == null
            ? 'Thanks for subscribing.'
            : status.willRenew == false
            ? 'Access until ${date(periodEnd)}.'
            : 'Renews on ${date(periodEnd)}.',
      ),
      AccessState.subscriptionCancelledButActive => InlineBanner(
        tone: BannerTone.info,
        title: 'Subscription cancelled',
        message: periodEnd == null
            ? 'You keep access until the end of the period you paid for.'
            : 'You keep access until ${date(periodEnd)}. It won\'t renew.',
      ),
      AccessState.billingIssue => InlineBanner(
        tone: BannerTone.warning,
        title: 'Payment problem',
        message:
            'The store couldn\'t take your renewal payment. Update your '
            'payment method in your store account to keep access.',
      ),
      AccessState.subscriptionExpired => const InlineBanner(
        tone: BannerTone.warning,
        title: 'Your subscription has ended',
        message: 'Subscribe again to keep using SharkHire.',
      ),
      AccessState.paymentRequired => const InlineBanner(
        tone: BannerTone.warning,
        title: 'Your free trial has ended',
        message: 'Subscribe to keep using SharkHire.',
      ),
      AccessState.error => InlineBanner(
        tone: status.serviceUnavailable ? BannerTone.info : BannerTone.error,
        message: status.message ?? 'We couldn\'t check your subscription.',
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(liveRegion: true, child: banner),
        if (status.state == AccessState.error)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: onRetry, child: const Text('Retry')),
          ),
        if (status.state == AccessState.billingIssue)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onManage,
              child: const Text('Update payment method'),
            ),
          ),
      ],
    );
  }
}
