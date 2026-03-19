import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_pintap/src/output/markdown_generator.dart';
import 'package:flutter_pintap/src/models/annotation.dart';
import 'package:flutter_pintap/src/models/widget_data.dart';
import 'dart:ui';

void main() {
  test('MarkdownGenerator sanitizes user inputs correctly', () {
    final generator = MarkdownGenerator();
    final widgetData = WidgetData(
      type: 'Text',
      file: 'test.dart',
      line: 10,
      textContent: '<script>alert("XSS")</script> *bold* _italic_',
      properties: {'color': '<script>console.log("XSS")</script>'},
      childWidgets: [],
      parentChain: [],
      position: Offset.zero,
      size: Size.zero,
    );
    final annotation = Annotation(
      id: '1',
      widgetData: widgetData,
      note: 'Hello\nWorld\r\n`code` [link](url)',
      index: 1,
      createdAt: DateTime.now(),
    );

    final result = generator.generate([annotation]);

    // Check that special characters and HTML are escaped
    expect(result.contains('<script>'), isFalse, reason: 'HTML tags should be escaped');
    expect(result.contains('&lt;script&gt;'), isTrue, reason: 'HTML tags should be escaped');

    // Check that markdown characters are escaped
    expect(result.contains('\\*bold\\*'), isTrue, reason: 'Asterisks should be escaped');
    expect(result.contains('\\_italic\\_'), isTrue, reason: 'Underscores should be escaped');
    expect(result.contains('\\`code\\`'), isTrue, reason: 'Backticks should be escaped');

    // Check that newlines are converted to <br>
    expect(result.contains('Hello<br>World<br>'), isTrue, reason: 'Newlines should be converted to <br>');

    // Original markdown structure should still be present
    expect(result.contains('## UI Feedback'), isTrue);
    expect(result.contains('- 💬'), isTrue);
    expect(result.contains('- 🔤 Content:'), isTrue);
    expect(result.contains('- 🎨'), isTrue);
  });
}
