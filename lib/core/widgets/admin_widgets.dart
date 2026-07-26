import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme_extensions.dart';

AppSemanticColors semanticColors(BuildContext context) =>
    Theme.of(context).extension<AppSemanticColors>()!;

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/palengkego_admin_logo.png',
        width: compact ? 128 : 150,
        height: compact ? 32 : 36,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        semanticLabel: 'PalengkeGo - Skip the Roam, Order from Home',
      );
}

class AvatarCircle extends StatelessWidget {
  const AvatarCircle({
    super.key,
    required this.name,
    this.size = 36,
    this.image,
  });
  final String name;
  final double size;
  final ImageProvider<Object>? image;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((word) => word[0])
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: const Color(0xFFD7EEE5),
      backgroundImage: image,
      child: image == null
          ? Text(
              initials,
              style: TextStyle(
                color: semanticColors(context).heroBackground,
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
  });
  final String title;
  final String subtitle;
  final List<MetricCardData> metrics;
  final Widget? tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(34, 20, 34, 14),
      decoration: BoxDecoration(
        color: semanticColors(context).heroBackground,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(.15)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withOpacity(.7), fontSize: 12),
          ),
          if (tabs != null) ...[const SizedBox(height: 22), tabs!],
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth >= 1100
                    ? metrics.length
                    : constraints.maxWidth >= 650
                        ? 2
                        : 1;
                return GridView.builder(
                  itemCount: metrics.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 63,
                  ),
                  itemBuilder: (context, index) =>
                      MetricCard(data: metrics[index], compact: true),
                );
              },
            ),
          ],
        ],
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
        color: data.accent.withOpacity(.13),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(data.icon, color: data.accent, size: 18),
    );
    final arrow = compact
        ? IconButton(
            tooltip: 'Open',
            onPressed: data.onTap,
            icon: Icon(
              Icons.arrow_outward_rounded,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.72),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.72),
              ),
            ),
          );
    final value = Text(
      data.value,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: compact ? 21 : 26,
        fontWeight: FontWeight.w800,
      ).merge(data.valueStyle),
    );
    final label = Text(
      data.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(.64),
        fontSize: compact ? 11 : 11.5,
      ),
    );
    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 14)
          : const EdgeInsets.fromLTRB(14, 16, 12, 14),
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: colors.subtleBorder),
        boxShadow: compact
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
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
                    children: [value, const SizedBox(height: 4), label],
                  ),
                ),
                arrow,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [icon, const Spacer(), arrow],
                ),
                const Spacer(),
                value,
                const SizedBox(height: 3),
                label,
              ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: pair.$2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pair.$1.withOpacity(.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: pair.$1),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: pair.$1,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              Theme.of(context).colorScheme.onSurface.withOpacity(.76),
          side: BorderSide(color: semanticColors(context).subtleBorder),
          backgroundColor: semanticColors(context).hoverSurface,
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
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
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    final colors = semanticColors(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                        style: TextStyle(
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
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(.58),
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

class ScrollableDataTable extends StatelessWidget {
  const ScrollableDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.height = 360,
    this.columnSpacing = 18,
    this.rowHeight = 68,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;
  final double height;
  final double columnSpacing;
  final double rowHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          Widget table({
            required List<DataRow> tableRows,
            required double headingHeight,
          }) =>
              SizedBox(
                width: constraints.maxWidth,
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: WidgetStatePropertyAll(
                    semanticColors(context).tableHeader,
                  ),
                  headingRowHeight: headingHeight,
                  dataRowMinHeight: rowHeight,
                  dataRowMaxHeight: rowHeight,
                  columnSpacing: columnSpacing,
                  columns: columns,
                  rows: tableRows,
                ),
              );

          return Column(
            children: [
              table(tableRows: const [], headingHeight: 48),
              SizedBox(
                height: height,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: table(tableRows: rows, headingHeight: 0),
                  ),
                ),
              ),
            ],
          );
        },
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
    this.showSummary = true,
  });
  final int total;
  final int start;
  final int end;
  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;
  final bool showSummary;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: showSummary
                  ? Text(
                      'Showing $start to $end of $total results',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(.62),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Wrap(
              spacing: 5,
              children: [
                _button(
                  context,
                  Icons.chevron_left_rounded,
                  page > 0 ? () => onPageChanged(page - 1) : null,
                ),
                for (var i = 0; i < pageCount && i < 3; i++)
                  _button(
                    context,
                    i + 1,
                    () => onPageChanged(i),
                    active: i == page,
                  ),
                if (pageCount > 4) _button(context, '...', null),
                if (pageCount > 3)
                  _button(
                    context,
                    pageCount,
                    () => onPageChanged(pageCount - 1),
                    active: page == pageCount - 1,
                  ),
                _button(
                  context,
                  Icons.chevron_right_rounded,
                  page < pageCount - 1 ? () => onPageChanged(page + 1) : null,
                ),
              ],
            ),
          ],
        ),
      );
  Widget _button(
    BuildContext context,
    Object label,
    VoidCallback? onTap, {
    bool active = false,
  }) =>
      Material(
        color: active
            ? semanticColors(context).heroBackground
            : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: !active && label is IconData
                  ? Border.all(color: semanticColors(context).subtleBorder)
                  : null,
            ),
            child: label is IconData
                ? Icon(
                    label,
                    size: 16,
                    color: onTap == null
                        ? semanticColors(context).mutedText
                        : Theme.of(context).colorScheme.onSurface,
                  )
                : Text(
                    '$label',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: active
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.message = 'No matching records found.'});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 28,
                color: semanticColors(context).mutedText,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(.55),
                  fontSize: 12,
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.7),
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
