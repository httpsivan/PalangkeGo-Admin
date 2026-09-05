import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_models.dart';
import '../animations/animated_widgets.dart';
import '../animations/app_motion.dart';
import '../theme/category_colors.dart';
import '../theme/theme_extensions.dart';

export '../theme/category_colors.dart';

AppSemanticColors semanticColors(BuildContext context) =>
    Theme.of(context).extension<AppSemanticColors>()!;

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.compact = false,
    this.showTagline = true,
    this.showAdminBadge = false,
    this.dark = false,
  });

  final bool compact;
  final bool showTagline;
  final bool showAdminBadge;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final primaryTextColor = dark
        ? Colors.white
        : (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : const Color(0xFF1E293B));
    final accentColor = dark ? const Color(0xFF34D399) : colors.accent;

    final basketIcon = Image.asset(
      'assets/images/market_basket.png',
      width: compact ? 44 : 64,
      height: compact ? 44 : 64,
      fit: BoxFit.contain,
      semanticLabel: 'PalengkeGo Market Basket',
    );

    final titleText = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Palengke',
            style: GoogleFonts.plusJakartaSans(
              color: primaryTextColor,
              fontSize: compact ? 19 : 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          TextSpan(
            text: 'Go',
            style: GoogleFonts.plusJakartaSans(
              color: accentColor,
              fontSize: compact ? 19 : 23,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          if (showAdminBadge) ...[
            WidgetSpan(
              child: Container(
                margin: const EdgeInsets.only(left: 6, bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'ADMIN',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    final taglineText = Text(
      'SKIP THE ROAM, ORDER FROM HOME',
      style: GoogleFonts.inter(
        color: dark
            ? Colors.white70
            : Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
        fontSize: compact ? 7.5 : 8.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );

    return Semantics(
      label: 'PalengkeGo - Skip the Roam, Order from Home',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          basketIcon,
          SizedBox(width: compact ? 10 : 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleText,
              if (showTagline && !compact) ...[
                const SizedBox(height: 2),
                taglineText,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.name,
    this.size = 36,
    this.image,
    this.imageBytes,
  }) : assert(image == null || imageBytes == null);
  final String name;
  final double size;
  final ImageProvider<Object>? image;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((word) => word[0])
        .join()
        .toUpperCase();
    final resolvedImage =
        image ?? (imageBytes == null ? null : MemoryImage(imageBytes!));
    return CircleAvatar(
      radius: size / 2,
      backgroundColor:
          isDark ? colors.activeNavigation : colors.successContainer,
      backgroundImage: resolvedImage,
      child: resolvedImage == null
          ? Text(
              initials,
              style: TextStyle(
                color: isDark
                    ? colors.activeNavigationText
                    : colors.heroBackground,
                fontSize: size * .32,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.metrics = const [],
    this.tabs,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final List<MetricCardData> metrics;
  final Widget? tabs;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(36, 24, 36, 20),
      decoration: BoxDecoration(
        color: colors.heroBackground,
        border: Border(
          bottom: BorderSide(color: colors.borderOnHero),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: colors.heroForeground,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: colors.heroMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing!,
              ],
            ],
          ),
          if (tabs != null) ...[const SizedBox(height: 22), tabs!],
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 20),
            PageHeaderMetricRibbon(metrics: metrics),
          ],
        ],
      ),
    );
  }
}

class PageHeaderMetricRibbon extends StatelessWidget {
  const PageHeaderMetricRibbon({super.key, required this.metrics});
  final List<MetricCardData> metrics;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 750;
          if (!isWide) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(10),
              itemCount: metrics.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: constraints.maxWidth >= 450
                    ? (metrics.length > 4 ? 3 : 2)
                    : 1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 68,
              ),
              itemBuilder: (context, i) =>
                  PageHeaderMetricTile(data: metrics[i]),
            );
          }
          return IntrinsicHeight(
            child: Row(
              children: [
                for (int i = 0; i < metrics.length; i++) ...[
                  Expanded(
                    child: PageHeaderMetricTile(data: metrics[i]),
                  ),
                  if (i < metrics.length - 1)
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: colors.subtleBorder,
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class PageHeaderMetricTile extends StatelessWidget {
  const PageHeaderMetricTile({super.key, required this.data});
  final MetricCardData data;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              data.icon,
              size: 18,
              color: data.accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: colors.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedCounter(
                    value: data.value,
                    style: data.valueStyle ??
                        GoogleFonts.plusJakartaSans(
                          color: colors.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
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

class MetricCardData {
  const MetricCardData({
    required this.value,
    required this.label,
    required this.icon,
    required this.accent,
    this.onTap,
    this.valueStyle,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;
  final TextStyle? valueStyle;
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.data, this.compact = false});
  final MetricCardData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final icon = Container(
      width: compact ? 33 : 34,
      height: compact ? 33 : 34,
      decoration: BoxDecoration(
        color: data.accent.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(data.icon, color: data.accent, size: 18),
    );
    final Widget? arrow = data.onTap == null
        ? null
        : compact
            ? IconButton(
                tooltip: 'Open',
                onPressed: data.onTap,
                icon: Icon(
                  Icons.arrow_outward_rounded,
                  size: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: .72),
                ),
              )
            : InkWell(
                onTap: data.onTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.subtleBorder),
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    size: 15,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: .72),
                  ),
                ),
              );
    final valueStyle = GoogleFonts.montserrat(
      color: Theme.of(context).colorScheme.onSurface,
      fontSize: compact ? 21 : 26,
      fontWeight: FontWeight.w800,
    ).merge(data.valueStyle);
    final value = AnimatedCounter(value: data.value, style: valueStyle);
    final label = Text(
      data.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .64),
        fontSize: compact ? 11 : 11.5,
      ),
    );
    return Semantics(
      button: data.onTap != null,
      label: '${data.label}: ${data.value}',
      child: AnimatedHoverContainer(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(compact ? 12 : 14),
      child: Container(
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 14)
            : const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(compact ? 12 : 14),
          border: Border.all(color: colors.subtleBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: compact
            ? Row(
                children: [
                  icon,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: value,
                        ),
                        const SizedBox(height: 4),
                        Flexible(child: label),
                      ],
                    ),
                  ),
                  if (arrow != null) arrow,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      icon,
                      const Spacer(),
                      if (arrow != null) arrow,
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: value,
                  ),
                  const SizedBox(height: 3),
                  Flexible(child: label),
                ],
              ),
        ),
      ),
    );
  }
}

enum BadgeKind { success, warning, danger, info, purple, neutral }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.kind = BadgeKind.neutral,
    this.icon,
  });
  final String label;
  final BadgeKind kind;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final pair = switch (kind) {
      BadgeKind.success => (colors.success, colors.successContainer),
      BadgeKind.warning => (colors.warning, colors.warningContainer),
      BadgeKind.danger => (colors.danger, colors.dangerContainer),
      BadgeKind.info => (colors.info, colors.infoContainer),
      BadgeKind.purple => Theme.of(context).brightness == Brightness.dark
          ? (const Color(0xFFC2A5FF), const Color(0xFF34265C))
          : (const Color(0xFF8B5CF6), const Color(0xFFEDE9FE)),
      BadgeKind.neutral => (colors.mutedText, colors.hoverSurface),
    };
    return Semantics(
      label: 'Status: $label',
      container: true,
      child: AnimatedSwitcher(
        duration: AppMotion.duration(context, AppMotion.component),
        switchInCurve: AppMotion.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: .95, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: Container(
          key: ValueKey('$label-${kind.name}'),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: pair.$2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pair.$1.withValues(alpha: .12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 11, color: pair.$1),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: pair.$1,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Toolbar extends StatelessWidget {
  const Toolbar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.searchHint = 'Search by name, email, or application ID...',
    this.trailing = const [],
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final String searchHint;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final search = SizedBox(
      height: 38,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          hintText: searchHint,
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                    onClear?.call();
                  },
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
        ),
      ),
    );
    final controls = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...trailing,
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            child: const Text(
              'Clear Filters',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: semanticColors(context).subtleBorder),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 680
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [search, const SizedBox(height: 8), controls],
              )
            : Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 8),
                  controls,
                ],
              ),
      ),
    );
  }
}

class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    required this.label,
    this.icon = Icons.keyboard_arrow_down_rounded,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final isCategory = CategoryColors.isCategory(label);
    final categoryStyle = isCategory ? CategoryColors.get(label) : null;

    return AnimatedButtonFeedback(
      enabled: onTap != null,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: categoryStyle?.text ??
              Theme.of(context).colorScheme.onSurface.withValues(alpha: .76),
          side: BorderSide(
            color: categoryStyle?.border ?? colors.subtleBorder,
          ),
          backgroundColor: categoryStyle?.background ?? colors.hoverSurface,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCategory) ...[
              CategoryDot(category: label, size: 7),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCategory ? FontWeight.w700 : FontWeight.normal,
                color: categoryStyle?.text,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              icon,
              size: 15,
              color: categoryStyle?.text ??
                  Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: .76),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterMenuButton extends StatelessWidget {
  const FilterMenuButton({
    super.key,
    required this.label,
    required this.values,
    required this.onSelected,
    this.icon = Icons.keyboard_arrow_down_rounded,
  });

  final String label;
  final List<String> values;
  final ValueChanged<String> onSelected;
  final IconData icon;

  @override
  Widget build(BuildContext context) => MenuAnchor(
        alignmentOffset: const Offset(0, 4),
        menuChildren: [
          for (final value in values)
            MenuItemButton(
              onPressed: () => onSelected(value),
              child: SizedBox(
                width: 145,
                child: Row(
                  children: [
                    if (CategoryColors.isCategory(value)) ...[
                      CategoryDot(category: value, size: 7.5),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          color: CategoryColors.isCategory(value)
                              ? CategoryColors.get(value).text
                              : null,
                          fontWeight: CategoryColors.isCategory(value)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        builder: (context, controller, child) => FilterButton(
          label: label,
          icon: icon,
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        ),
      );
}

class DataPanel extends StatelessWidget {
  const DataPanel({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.headerAction,
    this.titleStyle,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? headerAction;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: titleStyle ??
                            TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: .58),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (headerAction != null) headerAction!,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class ApplicationStatusBadge extends StatelessWidget {
  const ApplicationStatusBadge({super.key, required this.status});
  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    final label = switch (status) {
      ApplicationStatus.verified => 'Verified',
      ApplicationStatus.reviewing => 'Reviewing',
      ApplicationStatus.invalidDocs => 'Invalid Docs',
      ApplicationStatus.rejected => 'Invalid Docs',
    };
    final kind = switch (status) {
      ApplicationStatus.verified => BadgeKind.success,
      ApplicationStatus.reviewing => BadgeKind.info,
      ApplicationStatus.invalidDocs => BadgeKind.danger,
      ApplicationStatus.rejected => BadgeKind.danger,
    };
    final icon = switch (status) {
      ApplicationStatus.verified => Icons.verified_rounded,
      ApplicationStatus.reviewing => Icons.pie_chart_outline_rounded,
      ApplicationStatus.invalidDocs => Icons.error_outline_rounded,
      ApplicationStatus.rejected => Icons.error_outline_rounded,
    };
    final color = switch (kind) {
      BadgeKind.success => colors.success,
      BadgeKind.info => colors.info,
      BadgeKind.danger => colors.danger,
      _ => colors.mutedText,
    };
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.component),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: .95, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: Row(
        key: ValueKey(status),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ScrollableDataTable extends StatelessWidget {
  const ScrollableDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.verticalController,
    this.columnSpacing = 18,
    this.rowHeight = 68,
    this.minWidth = 0,
    this.emptyState = const EmptyState(),
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final ScrollController verticalController;
  final double columnSpacing;
  final double rowHeight;
  final double minWidth;
  final Widget emptyState;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
          final tableWidth =
              constraints.maxWidth > minWidth ? constraints.maxWidth : minWidth;

          Widget table({
            required List<DataRow> tableRows,
            required double headingHeight,
          }) =>
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: tableWidth),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStatePropertyAll(
                    semanticColors(context).tableHeader,
                  ),
                  headingTextStyle: GoogleFonts.inter(
                    color: semanticColors(context).secondaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  dataTextStyle: GoogleFonts.inter(
                    color: semanticColors(context).primaryText,
                    fontSize: 13,
                  ),
                  headingRowHeight: headingHeight,
                  dataRowMinHeight: rowHeight,
                  dataRowMaxHeight: rowHeight,
                  columnSpacing: columnSpacing,
                  columns: columns,
                  rows: tableRows,
                  dataRowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return semanticColors(context).hoverSurface;
                    }
                    return semanticColors(context).cardBackground;
                  }),
                ),
              );

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: tableWidth),
              child: AnimatedSwitcher(
                duration: AppMotion.duration(context, AppMotion.component),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: rows.isEmpty
                    ? KeyedSubtree(
                        key: const ValueKey('empty'),
                        child: emptyState,
                      )
                    : KeyedSubtree(
                        key: const ValueKey('rows'),
                        child: table(tableRows: rows, headingHeight: 48),
                      ),
              ),
            ),
          );
        },
      ),
    );
}

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.total,
    required this.start,
    required this.end,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
    this.showSummary = false,
  });
  final int total;
  final int start;
  final int end;
  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;
  final bool showSummary;
  @override
  Widget build(BuildContext context) {
    if (total <= 0 || pageCount <= 0) {
      return const SizedBox.shrink();
    }

    final int safePage = page.clamp(0, pageCount - 1);
    final pagination = AnimatedSwitcher(
      duration: AppMotion.duration(context, AppMotion.component),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: KeyedSubtree(
        key: ValueKey(safePage),
        child: Wrap(
          spacing: 5,
          children: [
            _button(
              context,
              Icons.chevron_left_rounded,
              safePage > 0 ? () => onPageChanged(safePage - 1) : null,
            ),
            for (var i = 0; i < pageCount && i < 3; i++)
              _button(
                context,
                i + 1,
                () => onPageChanged(i),
                active: i == safePage,
              ),
            if (pageCount > 4) _button(context, '...', null),
            if (pageCount > 3)
              _button(
                context,
                pageCount,
                () => onPageChanged(pageCount - 1),
                active: safePage == pageCount - 1,
              ),
            _button(
              context,
              Icons.chevron_right_rounded,
              safePage < pageCount - 1
                  ? () => onPageChanged(safePage + 1)
                  : null,
            ),
          ],
        ),
      ),
    );

    final summary = Text(
      'Showing $start to $end of $total results',
      style: TextStyle(
        fontSize: 10.5,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .62),
      ),
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!showSummary) {
            return Align(
              alignment: Alignment.centerRight,
              child: pagination,
            );
          }

          if (constraints.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                summary,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: pagination,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: summary),
              pagination,
            ],
          );
        },
      ),
    );
  }

  Widget _button(
    BuildContext context,
    Object label,
    VoidCallback? onTap, {
    bool active = false,
  }) {
    final colors = semanticColors(context);
    final foreground = active
        ? colors.heroForeground
        : onTap == null
            ? colors.disabledText
            : colors.primaryText;

    return AnimatedButtonFeedback(
      enabled: onTap != null,
      child: Material(
        color: active ? colors.heroBackground : colors.cardBackground,
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          hoverColor: colors.hoverSurface,
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: active ? null : Border.all(color: colors.subtleBorder),
            ),
            child: label is IconData
                ? Icon(
                    label,
                    size: 16,
                    color: foreground,
                  )
                : Text(
                    '$label',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: foreground,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.message = 'No results found'});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              FadeSlideIn(
                child: Icon(
                  Icons.search_off_rounded,
                  size: 28,
                  color: semanticColors(context).mutedText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: semanticColors(context).secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Try changing your search or filter selection.',
                style: TextStyle(
                  color: semanticColors(context).mutedText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                letterSpacing: .6,
                fontWeight: FontWeight.w800,
                color: semanticColors(context).secondaryText,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      );
}

void copyToClipboard(BuildContext context, String value) {
  Clipboard.setData(ClipboardData(text: value));
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
}
