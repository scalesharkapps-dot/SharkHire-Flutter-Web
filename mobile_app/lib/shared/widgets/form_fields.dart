import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'shark_loader.dart';

/// Small uppercase label shown above inputs (as in the guide mockups).
class FieldLabel extends StatelessWidget {
  const FieldLabel(
    this.text, {
    super.key,
    this.optional = false,
    this.sentenceCase = false,
  });

  final String text;
  final bool optional;

  /// Shows the label as written ("Email") instead of uppercase.
  final bool sentenceCase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final style = sentenceCase
        ? theme.labelMedium?.copyWith(color: AppColors.textSecondary)
        : theme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: sentenceCase ? text : text.toUpperCase()),
            if (optional)
              TextSpan(
                text: sentenceCase ? '  optional' : '  OPTIONAL',
                style: style?.copyWith(color: AppColors.textTertiary),
              ),
          ],
        ),
        style: style,
      ),
    );
  }
}

/// Labelled text input used by every form in the app.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.onSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.optional = false,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.initialValue,
    this.sentenceCaseLabel = false,
  });

  final String label;

  /// Label as written ("Email") instead of uppercase.
  final bool sentenceCaseLabel;
  final TextEditingController? controller;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final bool optional;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? initialValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FieldLabel(label, optional: optional, sentenceCase: sentenceCaseLabel),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          obscureText: obscureText,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          enabled: enabled,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// Password input with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.onSubmitted,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
    this.autofillHints = const [AutofillHints.password],
    this.sentenceCaseLabel = false,
  });

  final TextEditingController controller;
  final String label;

  /// Label as written ("Password") instead of uppercase.
  final bool sentenceCaseLabel;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      sentenceCaseLabel: widget.sentenceCaseLabel,
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _hidden,
      prefixIcon: Icons.lock_outline_rounded,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      suffix: IconButton(
        tooltip: _hidden ? 'Show password' : 'Hide password',
        icon: Icon(
          _hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
        ),
        onPressed: () => setState(() => _hidden = !_hidden),
      ),
    );
  }
}

/// Full-width primary button that shows a spinner while [loading].
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.style,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedSwitcher(
      duration: AppDurations.fast,
      child: loading
          ? SharkSwim(
              key: const ValueKey('spinner'),
              width: 56,
              finSize: 12,
              color: AppColors.onInk,
              trackColor: AppColors.onInk.withValues(alpha: 0.28),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        label: loading ? '$label, in progress' : label,
        excludeSemantics: loading,
        child: FilledButton(
          onPressed: loading ? () {} : onPressed,
          style: style,
          child: child,
        ),
      ),
    );
  }
}

/// Wrap of selectable chips for one or many values.
class ChoiceChipGroup<T> extends StatelessWidget {
  const ChoiceChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    this.multiSelect = true,
  });

  final List<T> options;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;
  final String Function(T) labelOf;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final o in options)
          FilterChip(
            label: Text(labelOf(o)),
            selected: selected.contains(o),
            showCheckmark: false,
            labelStyle: text.labelMedium?.copyWith(
              color: selected.contains(o) ? AppColors.onInk : AppColors.ink,
            ),
            side: BorderSide(
              color: selected.contains(o) ? AppColors.ink : AppColors.border,
            ),
            onSelected: (on) {
              if (!multiSelect) {
                onChanged({o});
                return;
              }
              final next = {...selected};
              on ? next.add(o) : next.remove(o);
              onChanged(next);
            },
          ),
      ],
    );
  }
}

enum BannerTone { info, success, warning, error }

/// Tinted inline message (errors, privacy notes, confirmations).
class InlineBanner extends StatelessWidget {
  const InlineBanner({
    super.key,
    required this.message,
    this.tone = BannerTone.info,
    this.title,
    this.showMark = true,
  });

  final String message;
  final String? title;
  final BannerTone tone;

  /// Shows the small tinted status tile; off for quiet notes.
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    // Quiet card: neutral surface and hairline border; colour lives only in
    // the small status mark, so the words stay calm and readable.
    final (tint, mark, icon) = switch (tone) {
      BannerTone.info => (
        AppColors.oceanTint,
        AppColors.ocean,
        Icons.info_outline_rounded,
      ),
      BannerTone.success => (
        AppColors.successTint,
        AppColors.success,
        Icons.check_rounded,
      ),
      BannerTone.warning => (
        AppColors.warningTint,
        AppColors.warning,
        Icons.priority_high_rounded,
      ),
      BannerTone.error => (
        AppColors.errorTint,
        AppColors.error,
        Icons.error_outline_rounded,
      ),
    };
    final text = Theme.of(context).textTheme;
    final hasTitle = title != null;
    return Semantics(
      liveRegion: tone == BannerTone.error,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showMark) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(icon, size: 16, color: mark),
              ),
              const SizedBox(width: AppSpacing.md),
            ] else
              const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Padding(
                // Centres a one-line message on the 28px mark.
                padding: EdgeInsets.only(
                  top: !showMark ? 0 : (hasTitle ? 2 : 4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTitle) ...[
                      Text(
                        title!,
                        style: text.titleSmall?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      message,
                      style: text.bodyMedium?.copyWith(
                        color: hasTitle
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
