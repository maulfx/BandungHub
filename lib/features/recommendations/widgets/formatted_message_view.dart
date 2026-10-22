import 'package:flutter/material.dart';

class FormattedMessageView extends StatelessWidget {
  final String text;
  final TextStyle baseStyle;
  final Color bulletColor;

  const FormattedMessageView({
    super.key,
    required this.text,
    required this.baseStyle,
    required this.bulletColor,
  });

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trimRight();
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Horizontal rule: --- or ***
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              thickness: 0.8,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
        );
        continue;
      }

      // Heading: #, ##, ###
      if (trimmed.startsWith('#')) {
        final headingText = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              _cleanAsterisks(headingText),
              style: baseStyle.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: (baseStyle.fontSize ?? 13) + 1.5,
              ),
            ),
          ),
        );
        continue;
      }

      // Bullet points: * , - , • 
      if (trimmed.startsWith('* ') ||
          trimmed.startsWith('- ') ||
          trimmed.startsWith('• ')) {
        final bulletContent = trimmed.substring(2).trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: bulletColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: _parseInlineSpans(bulletContent, baseStyle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Numbered lists: 1. , 2. 
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(trimmed);
      if (numMatch != null) {
        final numStr = numMatch.group(1)!;
        final content = numMatch.group(2)!;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 18,
                  child: Text(
                    '$numStr.',
                    style: baseStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: bulletColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: _parseInlineSpans(content, baseStyle),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Regular paragraph
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text.rich(
            TextSpan(
              children: _parseInlineSpans(trimmed, baseStyle),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  static String _cleanAsterisks(String s) {
    return s.replaceAll('**', '').replaceAll('*', '');
  }

  static List<TextSpan> _parseInlineSpans(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    // Regex matches **bold**, *italic*, or normal text
    final regex = RegExp(r'(\*\*(.*?)\*\*|\*(.*?)\*)');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(2) != null) {
        // Bold
        spans.add(TextSpan(
          text: match.group(2),
          style: baseStyle.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(3) != null) {
        // Italic
        spans.add(TextSpan(
          text: match.group(3),
          style: baseStyle.copyWith(fontStyle: FontStyle.italic),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }
}
