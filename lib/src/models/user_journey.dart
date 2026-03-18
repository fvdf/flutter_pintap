import 'widget_data.dart';

enum JourneyEventType {
  pageChange,
  widgetTap,
  note,
}

class JourneyEvent {
  JourneyEvent({
    required this.type,
    required this.createdAt,
    this.routeName,
    this.widgetData,
    this.note,
  });

  final JourneyEventType type;
  final DateTime createdAt;

  // For pageChange
  final String? routeName;

  // For widgetTap
  final WidgetData? widgetData;

  // For note
  final String? note;
}

class UserJourney {
  UserJourney({
    required this.events,
    required this.finalNote,
    required this.createdAt,
  });

  final List<JourneyEvent> events;
  final String finalNote;
  final DateTime createdAt;
}
