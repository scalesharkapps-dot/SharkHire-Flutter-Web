import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Small uppercase label shown above inputs (as in the guide mockups).
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.textSecondary,
      letterSpacing: 0.8,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text.toUpperCase()),
            if (optional)
              TextSpan(
                text: '  OPTIONAL',
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
  });

  final String label;
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
        FieldLabel(label, optional: optional),
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
  });

  final TextEditingController controller;
  final String label;
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
          _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
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
          ? const SizedBox.square(
              key: ValueKey('spinner'),
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.white,
              ),
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
              color: selected.contains(o) ? AppColors.white : AppColors.navy,
            ),
            side: BorderSide(
              color: selected.contains(o) ? AppColors.navy : AppColors.border,
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
  });

  final String message;
  final String? title;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = switch (tone) {
      BannerTone.info => (
        AppColors.oceanTint,
        AppColors.oceanDeep,
        Icons.info_outline_rounded,
      ),
      BannerTone.success => (
        AppColors.successTint,
        AppColors.success,
        Icons.check_circle_outline_rounded,
      ),
      BannerTone.warning => (
        AppColors.warningTint,
        AppColors.warning,
        Icons.lightbulb_outline_rounded,
      ),
      BannerTone.error => (
        AppColors.errorTint,
        AppColors.error,
        Icons.error_outline_rounded,
      ),
    };
    final text = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: tone == BannerTone.error,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.lgAll),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title!, style: text.titleSmall?.copyWith(color: fg)),
                  Text(
                    message,
                    style: text.bodyMedium?.copyWith(color: fg, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
