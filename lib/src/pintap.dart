import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'overlay/fab_button.dart';
import 'overlay/toolbar.dart';
import 'overlay/record_toolbar.dart';
import 'pintap_observer.dart';
import 'models/user_journey.dart';
import 'overlay/annotation_overlay.dart';
import 'overlay/note_dialog.dart';
import 'overlay/annotation_list_modal.dart';
import 'models/annotation.dart';
import 'models/widget_data.dart';
import 'inspector/widget_picker.dart';
import 'inspector/widget_info.dart';
import 'output/markdown_generator.dart';

/// FlutterPintap main widget.
class FlutterPintap extends StatefulWidget {
  const FlutterPintap({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
    this.verbose = false,
    this.initialPosition,
  });

  final Widget child;
  final bool enabled;
  final bool verbose;
  final Offset? initialPosition;

  @override
  State<FlutterPintap> createState() => _FlutterPintapState();
}

class _FlutterPintapState extends State<FlutterPintap> {
  late final WidgetPicker _picker;
  final _extractor = WidgetInfoExtractor();
  final _childKey = GlobalKey();

  static const int _maxAnnotations = 10;

  bool _isOpen = false;
  bool _isSelectMode = false;
  bool _isFreezeMode = false;
  bool _copySuccess = false;
  bool _showAnnotationList = false;

  bool _isRecordMode = false;
  bool _isRecording = false;
  bool _isRecordingPaused = false;
  final List<JourneyEvent> _journeyEvents = [];

  final List<Annotation> _annotations = [];
  WidgetData? _selectedWidgetData;
  WidgetData? _hoveredWidgetData;

  Offset _position = const Offset(0, 0);
  bool _isPositionInitialized = false;

  @override
  void initState() {
    super.initState();
    _picker = WidgetPicker(verbose: widget.verbose);
    PintapObserver.onRouteChanged = _handleRouteChanged;
  }

  @override
  void dispose() {
    PintapObserver.onRouteChanged = null;
    super.dispose();
  }

  void _handleRouteChanged(String routeName) {
    if (_isRecording && !_isRecordingPaused) {
      setState(() {
        _journeyEvents.add(JourneyEvent(
          type: JourneyEventType.pageChange,
          createdAt: DateTime.now(),
          routeName: routeName,
        ));
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isPositionInitialized) {
      _position = widget.initialPosition ?? const Offset(16, 16);
      _isPositionInitialized = true;
    }
  }

  void _toggleOpen() => setState(() => _isOpen = !_isOpen);
  void _toggleSelect() => setState(() => _isSelectMode = !_isSelectMode);

  void _toggleFreeze() {
    setState(() => _isFreezeMode = !_isFreezeMode);
  }

  void _copy() async {
    final generator = MarkdownGenerator();
    final text = generator.generate(_annotations);
    await Clipboard.setData(ClipboardData(text: text));
    setState(() => _copySuccess = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copySuccess = false);
    });
  }

  void _closeToolbar() {
    setState(() {
      _isSelectMode = false;
      _isOpen = false;
      _selectedWidgetData = null;
    });
  }

  void _clear() {
    setState(() {
      _isSelectMode = false;
      _annotations.clear();
      _selectedWidgetData = null;
    });
  }

  void _openRecordMode() {
    setState(() {
      _isRecordMode = true;
      _isSelectMode = false;
      _isOpen = true; // Toolbar must be open
    });
  }

  void _closeRecordMode() {
    setState(() {
      _isRecordMode = false;
      _isRecording = false;
      _isRecordingPaused = false;
      _journeyEvents.clear();
    });
  }

  void _toggleRecord() {
    if (!_isRecording) {
      // Start recording
      setState(() {
        _isRecording = true;
        _isRecordingPaused = false;
      });
    } else if (!_isRecordingPaused) {
      // Pause recording
      setState(() {
        _isRecordingPaused = true;
      });
    } else {
      // Resume recording
      setState(() {
        _isRecordingPaused = false;
        _isSelectMode = false; // exit note selection mode if any
      });
    }
  }

  void _stopRecord() {
    // Finish recording, prompt for final note
    setState(() {
      _isRecordingPaused = true;
      _isSelectMode = false;
      // We can use a dummy widget data for the final note prompt, or handle final note separately.
      // We will show a NoteDialog with a dummy WidgetData, and save it as the final note.
      _selectedWidgetData = const WidgetData(
        type: "Journey Complete",
        file: "User Journey",
        line: 0,
      );
    });
  }

  void _addRecordNote() {
    if (_isRecordingPaused) {
      // Enter select mode to pick a widget to note on
      setState(() {
        _isSelectMode = true;
      });
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isRecording && !_isRecordingPaused) {
      // Record widget tap
      final position = event.position;
      final result = _findWidgetAtPosition(position);

      if (result.element != null) {
        final data = _extractor.extractWidgetData(
          result.element!,
          childWidgets: result.childWidgets,
        );
        setState(() {
          _journeyEvents.add(JourneyEvent(
            type: JourneyEventType.widgetTap,
            createdAt: DateTime.now(),
            widgetData: data,
          ));
        });
      }
    }
  }

  void _handleTap(TapDownDetails details) {
    if (!_isSelectMode || _selectedWidgetData != null) return;

    final position = details.globalPosition;
    final result = _findWidgetAtPosition(position);

    if (result.element != null) {
      final data = _extractor.extractWidgetData(
        result.element!,
        childWidgets: result.childWidgets,
      );
      setState(() {
        _selectedWidgetData = data;
        _hoveredWidgetData = null; // Clear hover on selection
      });
    }
  }

  void _handleHover(PointerEvent event) {
    if (!_isSelectMode || _selectedWidgetData != null) return;

    final position = event.position;
    final result = _findWidgetAtPosition(position);

    if (result.element != null) {
      final data = _extractor.extractWidgetData(
        result.element!,
        childWidgets: result.childWidgets,
      );
      if (_hoveredWidgetData?.type != data.type ||
          _hoveredWidgetData?.position != data.position) {
        setState(() => _hoveredWidgetData = data);
      }
    } else {
      if (_hoveredWidgetData != null) {
        setState(() => _hoveredWidgetData = null);
      }
    }
  }

  WidgetPickResult _findWidgetAtPosition(Offset position) {
    final childContext = _childKey.currentContext;
    final childRenderObject = childContext?.findRenderObject();
    return _picker.findWidgetInRenderObject(position, childRenderObject);
  }

  void _saveAnnotation(String note) {
    if (_selectedWidgetData != null) {
      if (_isRecordMode && _isRecordingPaused && _selectedWidgetData!.type == "Journey Complete") {
        // Saving final journey note
        final journey = UserJourney(
          events: List.from(_journeyEvents),
          finalNote: note,
          createdAt: DateTime.now(),
        );

        final generator = MarkdownGenerator();
        final text = generator.generateJourney(journey);

        setState(() {
          // Add as a special annotation to the list
          _annotations.add(Annotation(
            id: DateTime.now().toIso8601String(),
            widgetData: const WidgetData(
              type: "User Journey",
              file: "timeline",
              line: 0,
            ),
            note: "```markdown\n$text\n```",
            index: _annotations.length + 1,
            createdAt: DateTime.now(),
          ));
          _selectedWidgetData = null;
          _isRecordMode = false;
          _isRecording = false;
          _isRecordingPaused = false;
          _journeyEvents.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journey added to annotations list'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        return;
      }

      if (_isRecordMode && _isRecordingPaused) {
        // Saving a note on a widget during paused journey
        setState(() {
          _journeyEvents.add(JourneyEvent(
            type: JourneyEventType.note,
            createdAt: DateTime.now(),
            widgetData: _selectedWidgetData,
            note: note,
          ));
          _selectedWidgetData = null;
          _isSelectMode = false; // exit selection mode
        });
        return;
      }

      if (_annotations.length >= _maxAnnotations) {
        _selectedWidgetData = null;
        _showMaxLimitWarning();
        setState(() {});
        return;
      }
      setState(() {
        _annotations.add(Annotation(
          id: DateTime.now().toIso8601String(),
          widgetData: _selectedWidgetData!,
          note: note,
          index: _annotations.length + 1,
          createdAt: DateTime.now(),
        ));
        _selectedWidgetData = null;
      });
    }
  }

  void _showMaxLimitWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maximum $_maxAnnotations annotations reached'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleAnnotationList() {
    setState(() => _showAnnotationList = !_showAnnotationList);
  }

  void _deleteAnnotation(String id) {
    setState(() {
      _annotations.removeWhere((a) => a.id == id);
      // Reindex annotations
      for (int i = 0; i < _annotations.length; i++) {
        _annotations[i] = Annotation(
          id: _annotations[i].id,
          widgetData: _annotations[i].widgetData,
          note: _annotations[i].note,
          index: i + 1,
          createdAt: _annotations[i].createdAt,
        );
      }
    });
  }

  void _cancelAnnotation() => setState(() => _selectedWidgetData = null);

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _position += details.delta);
  }

  /// Return highlight box and label as separate Positioned widgets
  List<Widget> _buildHighlight(
      WidgetData data, Color borderColor, Color labelColor) {
    final pos = data.position;
    final size = data.size!;
    const labelHeight = 18.0;

    return [
      // Highlight box
      Positioned(
        left: pos.dx,
        top: pos.dy,
        width: size.width,
        height: size.height,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 2),
              color: borderColor.withAlpha(30),
            ),
          ),
        ),
      ),
      // Info label (displayed above the box)
      Positioned(
        left: pos.dx,
        top: pos.dy - labelHeight - 2,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: labelColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${data.type} · ${data.file.split('/').last}:${data.line} · (${pos.dx.toInt()}, ${pos.dy.toInt()})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        // 1. Original App Content (wrapped in RepaintBoundary for hitTest targeting)
        RepaintBoundary(
          key: _childKey,
          child: TickerMode(
            enabled: !_isFreezeMode,
            child: Listener(
              onPointerUp: _isRecording && !_isRecordingPaused ? _handlePointerUp : null,
              behavior: HitTestBehavior.deferToChild,
              child: widget.child,
            ),
          ),
        ),

        // 2~5: Overlay widgets - wrapped in DisableWidgetInspectorScope to exclude from Inspector
        DisableWidgetInspectorScope(
          child: Stack(
            children: [
              // 2. Highlight Overlay (ignored by pointer)
              if (_isOpen)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnnotationOverlay(annotations: _annotations),
                  ),
                ),

              // 2-1. Hovered widget highlight (light color)
              if (_isOpen &&
                  _hoveredWidgetData != null &&
                  _hoveredWidgetData!.size != null &&
                  _selectedWidgetData == null)
                ..._buildHighlight(_hoveredWidgetData!, Colors.grey.shade600,
                    Colors.grey.shade700),

              // 2-2. Selected widget highlight (blue)
              if (_isOpen &&
                  _selectedWidgetData != null &&
                  _selectedWidgetData!.size != null)
                ..._buildHighlight(
                    _selectedWidgetData!, Colors.blue, Colors.blue),

              // 3. Selection Layer (captures tap and hover)
              if (_isOpen && _isSelectMode)
                Positioned.fill(
                  child: MouseRegion(
                    onHover: _handleHover,
                    onExit: (_) => setState(() => _hoveredWidgetData = null),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: _handleTap,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ),

              // 4. FAB / Toolbar
              Positioned(
                left: _position.dx,
                top: _position.dy,
                child: GestureDetector(
                  onPanUpdate: _onPanUpdate,
                  child: _isOpen
                      ? (_isRecordMode
                          ? RecordToolbar(
                              isRecording: _isRecording,
                              isPaused: _isRecordingPaused,
                              onToggleRecord: _toggleRecord,
                              onStop: _stopRecord,
                              onAddNote: _addRecordNote,
                              onClose: _closeRecordMode,
                            )
                          : PintapToolbar(
                              isSelectMode: _isSelectMode,
                              isFreezeMode: _isFreezeMode,
                              annotationCount: _annotations.length,
                              onToggleSelect: _toggleSelect,
                              onToggleFreeze: _toggleFreeze,
                              onShowList: _toggleAnnotationList,
                              onCopy: _copy,
                              onClear: _clear,
                              onOpenRecord: _openRecordMode,
                              onClose: _closeToolbar,
                              copySuccess: _copySuccess,
                            ))
                      : PintapFab(
                          onTap: _toggleOpen,
                          badgeCount: _annotations.length,
                        ),
                ),
              ),

              // 5. Note Dialog
              if (_selectedWidgetData != null)
                Positioned.fill(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _cancelAnnotation,
                        child: Container(color: Colors.black.withAlpha(76)),
                      ),
                      Center(
                        child: Material(
                          type: MaterialType.transparency,
                          child: NoteDialog(
                            widgetData: _selectedWidgetData!,
                            onSave: _saveAnnotation,
                            onCancel: _cancelAnnotation,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 6. Annotation List Modal
              if (_showAnnotationList)
                Positioned.fill(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _toggleAnnotationList,
                        child: Container(color: Colors.black.withAlpha(76)),
                      ),
                      Center(
                        child: AnnotationListModal(
                          annotations: _annotations,
                          onDelete: _deleteAnnotation,
                          onClose: _toggleAnnotationList,
                          maxAnnotations: _maxAnnotations,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
