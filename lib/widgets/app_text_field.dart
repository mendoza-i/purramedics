import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary)),
          AppSpacing.vSm,
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          validator: validator,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: obscureText ? 1 : maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          autofocus: autofocus,
          style: AppTypography.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.textTertiary, size: 20)
                : null,
            suffixIcon: suffix,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
