import 'package:flutter/material.dart';

const _linkColor = Color(0xFF2563EB);

/// Regex matching HTML formatting tags.
final _htmlTagRegex = RegExp(
  r'(</?b>|</?i>|<a\s+href="[^"]*">|</a>)',
  caseSensitive: false,
);

/// Custom [TextEditingController] that hides HTML tags visually while keeping
/// them in the underlying text. Tags are rendered at near-zero font size so
/// they are invisible; content between tags is styled (bold, italic, link).
///
/// IMPORTANT: [buildTextSpan] must return spans whose concatenated text equals
/// [text] exactly — we can only change *styles*, never omit characters.
class FormattedTextEditingController extends TextEditingController {
  FormattedTextEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle();
    if (text.isEmpty) return TextSpan(text: text, style: baseStyle);

    // Tags are kept in the span text but rendered invisibly.
    final tagStyle = baseStyle.copyWith(
      fontSize: 0.01,
      color: Colors.transparent,
    );

    final spans = <InlineSpan>[];
    bool bold = false, italic = false, link = false;
    int offset = 0;

    for (final m in _htmlTagRegex.allMatches(text)) {
      // Content before this tag — styled with current formatting state.
      if (m.start > offset) {
        spans.add(TextSpan(
          text: text.substring(offset, m.start),
          style: _apply(baseStyle, bold, italic, link),
        ));
      }

      // The tag itself — invisible but still part of the text.
      spans.add(TextSpan(text: m.group(0)!, style: tagStyle));

      // Update formatting state.
      final t = m.group(0)!.toLowerCase();
      if (t == '<b>') {
        bold = true;
      } else if (t == '</b>') {
        bold = false;
      } else if (t == '<i>') {
        italic = true;
      } else if (t == '</i>') {
        italic = false;
      } else if (t.startsWith('<a ')) {
        link = true;
      } else if (t == '</a>') {
        link = false;
      }

      offset = m.end;
    }

    // Remaining text after last tag.
    if (offset < text.length) {
      spans.add(TextSpan(
        text: text.substring(offset),
        style: _apply(baseStyle, bold, italic, link),
      ));
    }

    return TextSpan(style: baseStyle, children: spans);
  }
}

/// Renders formatted text for display (strips tags entirely).
class FormattedText extends StatelessWidget {
  const FormattedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final s = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(style: s, children: _displaySpans(text, s)),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// Renders selectable formatted text for display (strips tags entirely).
class FormattedSelectableText extends StatelessWidget {
  const FormattedSelectableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final s = style ?? DefaultTextStyle.of(context).style;
    return SelectableText.rich(
      TextSpan(style: s, children: _displaySpans(text, s)),
      textAlign: textAlign,
    );
  }
}

// ── Private helpers ─────────────────────────────────────────

TextStyle _apply(TextStyle base, bool bold, bool italic, bool link) {
  var s = base;
  if (bold) s = s.copyWith(fontWeight: FontWeight.bold);
  if (italic) s = s.copyWith(fontStyle: FontStyle.italic);
  if (link) {
    s = s.copyWith(
      color: _linkColor,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );
  }
  return s;
}

/// Builds display-only spans: HTML tags are stripped, content is styled.
/// Also handles • bullets, markdown links [label](url), and raw URLs.
List<InlineSpan> _displaySpans(String rawText, TextStyle baseStyle) {
  final text = rawText.replaceAll('*', '');
  if (text.isEmpty) return [];

  // Combined regex: HTML tags | markdown links | raw URLs
  final regex = RegExp(
    r'(</?b>|</?i>|<a\s+href="[^"]*">|</a>)|'
    r'(\[([^\]]+)\]\(([^)]+)\))|'
    r'(https?:\/\/[^\s)]+)',
    caseSensitive: false,
  );

  final spans = <InlineSpan>[];
  bool bold = false, italic = false, link = false;
  int offset = 0;

  for (final m in regex.allMatches(text)) {
    if (m.start > offset) {
      _addBulletSpans(
        spans,
        text.substring(offset, m.start),
        _apply(baseStyle, bold, italic, link),
      );
    }

    if (m.group(1) != null) {
      // HTML tag — strip from output, just update state.
      final t = m.group(0)!.toLowerCase();
      if (t == '<b>') {
        bold = true;
      } else if (t == '</b>') {
        bold = false;
      } else if (t == '<i>') {
        italic = true;
      } else if (t == '</i>') {
        italic = false;
      } else if (t.startsWith('<a ')) {
        link = true;
      } else if (t == '</a>') {
        link = false;
      }
    } else if (m.group(2) != null) {
      // Markdown link [label](url)
      spans.add(TextSpan(
        text: m.group(3)!,
        style: _apply(baseStyle, bold, italic, true),
      ));
    } else if (m.group(5) != null) {
      // Raw URL
      spans.add(TextSpan(
        text: m.group(5)!,
        style: baseStyle.copyWith(
          color: _linkColor,
          decoration: TextDecoration.underline,
        ),
      ));
    }

    offset = m.end;
  }

  if (offset < text.length) {
    _addBulletSpans(
      spans,
      text.substring(offset),
      _apply(baseStyle, bold, italic, link),
    );
  }

  return spans;
}

/// Adds text spans, styling bullet (•) prefixes distinctly.
void _addBulletSpans(List<InlineSpan> spans, String text, TextStyle style) {
  final lines = text.split('\n');
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('• ')) {
      spans.add(TextSpan(
        text: '• ',
        style: style.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F766E),
        ),
      ));
      spans.add(TextSpan(text: line.substring(2), style: style));
    } else {
      spans.add(TextSpan(text: line, style: style));
    }
    if (i < lines.length - 1) {
      spans.add(TextSpan(text: '\n', style: style));
    }
  }
}
