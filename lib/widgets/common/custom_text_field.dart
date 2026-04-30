import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Reusable styled text field used throughout the app.
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isPassword;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final String? prefix;

  const CustomTextField({super.key, required this.controller, required this.label, this.hint, this.isPassword = false,
    this.keyboardType, this.prefixIcon, this.validator, this.maxLines = 1, this.prefix});

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: AppTextStyles.label),
      const SizedBox(height: 8),
      TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType,
        maxLines: widget.isPassword ? 1 : widget.maxLines,
        style: AppTextStyles.bodyLarge,
        validator: widget.validator,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, color: AppColors.textHint, size: 20) : null,
          prefixText: widget.prefix,
          prefixStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          suffixIcon: widget.isPassword
              ? IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textHint, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure))
              : null,
        ),
      ),
    ]);
  }
}
