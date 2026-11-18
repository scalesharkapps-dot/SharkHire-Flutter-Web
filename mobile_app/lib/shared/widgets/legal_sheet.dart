import 'package:material_ui/material_ui.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum LegalDocument {
  terms('Terms of Use'),
  privacy('Privacy Policy');

  const LegalDocument(this.title);
  final String title;
}

/// Shows where the legal document will live. Scale Shark provides the final
/// Terms and Privacy Policy (guide §1.4); this sheet never invents legal text.
Future<void> showLegalSheet(BuildContext context, LegalDocument doc) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (sheet) {
      final text = Theme.of(sheet).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            0,
            AppSpacing.screenHorizontal,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(doc.title, style: text.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'The ${doc.title} is published by ${AppConstants.companyLegalName}. '
                'The final version will be available here and on ${AppConstants.companyWebsite} before launch.',
                style: text.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => Navigator.of(sheet).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
