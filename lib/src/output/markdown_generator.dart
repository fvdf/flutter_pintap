import '../models/annotation.dart';
import '../models/user_journey.dart';
import 'package:intl/intl.dart';

class MarkdownGenerator {
  String generate(List<Annotation> annotations) {
    // If empty
    if (annotations.isEmpty) {
      return 'No annotations.';
    }

    final buffer = StringBuffer();
    buffer.writeln('## UI Feedback (${annotations.length} annotations)');
    buffer.writeln();

    for (int i = 0; i < annotations.length; i++) {
      final a = annotations[i];
      final w = a.widgetData;

      buffer.writeln('### #${i + 1} ${w.type}');

      // Location
      String loc = '${w.file}:${w.line}';
      if (w.column != null) loc += ':${w.column}';
      buffer.writeln('- 📍 $loc');

      if (w.key != null) {
        buffer.writeln('- 🔑 Key: ${w.key}');
      }
      if (w.size != null) {
        buffer.writeln(
            '- 📐 Size: ${w.size!.width.toInt()}×${w.size!.height.toInt()}');
      }
      if (w.textContent != null) {
        buffer.writeln('- 🔤 Content: "${w.textContent}"');
      }

      // Properties - show top 5 or all?
      // Doc says "main properties (max 5)"
      final importantProps = w.properties.entries.take(5);
      for (final prop in importantProps) {
        buffer.writeln('- 🎨 ${prop.key}: ${prop.value}');
      }

      if (w.parentChain.isNotEmpty) {
        buffer.writeln('- 🌳 Parent: ${w.parentChain.join(' > ')}');
      }

      // Inner widget info
      if (w.childWidgets.isNotEmpty) {
        buffer.writeln('- 🔽 Contains:');
        for (final child in w.childWidgets) {
          buffer.writeln('  - ${child.type} (${child.file}:${child.line})');
        }
      }

      buffer.writeln('- 💬 "${a.note}"');
      buffer.writeln();
    }

    return buffer.toString();
  }

  String generateJourney(UserJourney journey) {
    final buffer = StringBuffer();
    final timeFormat = DateFormat('HH:mm:ss');

    buffer.writeln('## User Journey Feedback');
    buffer.writeln('📅 Recorded at: ${timeFormat.format(journey.createdAt)}');
    buffer.writeln();

    if (journey.finalNote.isNotEmpty) {
      buffer.writeln('### Final Note');
      buffer.writeln('> ${journey.finalNote}');
      buffer.writeln();
    }

    buffer.writeln('### Timeline');
    buffer.writeln();

    for (int i = 0; i < journey.events.length; i++) {
      final event = journey.events[i];
      final timeStr = timeFormat.format(event.createdAt);

      switch (event.type) {
        case JourneyEventType.pageChange:
          buffer.writeln('**[$timeStr]** 📄 Navigated to `${event.routeName ?? 'unknown route'}`');
          break;
        case JourneyEventType.widgetTap:
          final w = event.widgetData;
          if (w != null) {
            String textDetail = '';
            if (w.textContent != null && w.textContent!.isNotEmpty) {
              textDetail = ' ("${w.textContent}")';
            } else if (w.type == 'ElevatedButton' || w.type == 'TextButton' || w.type == 'OutlinedButton') {
                if (w.childWidgets.isNotEmpty) {
                    final child = w.childWidgets.firstWhere((c) => c.type == 'Text', orElse: () => w.childWidgets.first);
                    if (child.type == 'Text') {
                         textDetail = ' [Contains Text]';
                    }
                }
            }
            buffer.writeln('**[$timeStr]** 👆 Tapped `${w.type}`$textDetail at `${w.file}:${w.line}`');
          } else {
            buffer.writeln('**[$timeStr]** 👆 Tapped unknown widget');
          }
          break;
        case JourneyEventType.note:
          buffer.writeln('**[$timeStr]** 💬 Note added on `${event.widgetData?.type ?? 'unknown'}`:');
          buffer.writeln('  > ${event.note}');
          break;
      }
    }

    return buffer.toString();
  }
}
