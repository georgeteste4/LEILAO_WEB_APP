import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum ShadBadgeVariant { defaultVariant, secondary, outline, destructive, success, warning }

/// Badge profissional inspirado no Shadcn UI
class ShadBadge extends StatelessWidget {
  final Widget child;
  final ShadBadgeVariant variant;
  final EdgeInsetsGeometry? padding;

  const ShadBadge({
    super.key,
    required this.child,
    this.variant = ShadBadgeVariant.defaultVariant,
    this.padding,
  });

  const ShadBadge.secondary({
    super.key,
    required this.child,
    this.padding,
  }) : variant = ShadBadgeVariant.secondary;

  const ShadBadge.outline({
    super.key,
    required this.child,
    this.padding,
  }) : variant = ShadBadgeVariant.outline;

  const ShadBadge.destructive({
    super.key,
    required this.child,
    this.padding,
  }) : variant = ShadBadgeVariant.destructive;

  const ShadBadge.success({
    super.key,
    required this.child,
    this.padding,
  }) : variant = ShadBadgeVariant.success;

  const ShadBadge.warning({
    super.key,
    required this.child,
    this.padding,
  }) : variant = ShadBadgeVariant.warning;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color fg;

    switch (variant) {
      case ShadBadgeVariant.secondary:
        bg = AppColors.surfaceElevated;
        border = AppColors.borderSubtle;
        fg = AppColors.textMain;
        break;
      case ShadBadgeVariant.outline:
        bg = Colors.transparent;
        border = AppColors.borderSubtle;
        fg = AppColors.textMain;
        break;
      case ShadBadgeVariant.destructive:
        bg = AppColors.discountBg;
        border = AppColors.discount.withOpacity(0.4);
        fg = AppColors.discountLight;
        break;
      case ShadBadgeVariant.success:
        bg = AppColors.successBg;
        border = AppColors.success.withOpacity(0.4);
        fg = AppColors.successLight;
        break;
      case ShadBadgeVariant.warning:
        bg = AppColors.warningBg;
        border = AppColors.warning.withOpacity(0.4);
        fg = AppColors.warningLight;
        break;
      case ShadBadgeVariant.defaultVariant:
      default:
        bg = AppColors.brand.withOpacity(0.15);
        border = AppColors.brandLight.withOpacity(0.3);
        fg = AppColors.brandLight;
        break;
    }

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: DefaultTextStyle(
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        child: child,
      ),
    );
  }
}

/// Card contemporâneo inspirado no Shadcn UI com elevação zero e bordas sóbrias
class ShadCard extends StatelessWidget {
  final Widget? header;
  final Widget? content;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const ShadCard({
    super.key,
    this.header,
    this.content,
    this.footer,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.9),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (header != null) ...[header!, const SizedBox(height: 10)],
            if (content != null) content!,
            if (footer != null) ...[const SizedBox(height: 12), footer!],
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10), child: body);
    }
    return body;
  }
}
