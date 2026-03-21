import 'package:flutter/material.dart';
import 'dart:ui';
import '../utils/constants.dart';
import '../icons/pintap_icons.dart';
import 'tool_button.dart';

class RecordToolbar extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final VoidCallback onToggleRecord;
  final VoidCallback onStop;
  final VoidCallback onAddNote;
  final VoidCallback onClose;

  const RecordToolbar({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.onToggleRecord,
    required this.onStop,
    required this.onAddNote,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(PintapConstants.toolbarRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 56,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: PintapColors.surfaceGlass,
            borderRadius: BorderRadius.circular(PintapConstants.toolbarRadius),
            border: Border.all(
              color: PintapColors.borderStrong,
              width: PintapConstants.toolbarBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _DragHandle(),
              const _Divider(),
              // Record/Pause button
              ToolButton(
                icon: isRecording && !isPaused
                    ? PintapIconType.pause
                    : PintapIconType.record,
                label: isRecording && !isPaused ? 'Pause' : 'Record',
                isActive: isRecording && !isPaused,
                onTap: onToggleRecord,
              ),
              const SizedBox(width: 4),
              // Stop button
              ToolButton(
                icon: PintapIconType.stop,
                label: 'Stop',
                isActive: false,
                onTap: onStop,
              ),
              const _Divider(),
              // Add Note button (enabled if paused)
              ToolButton(
                icon: PintapIconType.note,
                label: 'Note',
                isActive: isPaused,
                onTap: onAddNote,
              ),
              const SizedBox(width: 4),
              ToolButton(
                icon: PintapIconType.close,
                label: 'Close',
                isActive: false,
                onTap: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 3; i++)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: PintapColors.textMuted.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: PintapColors.border,
    );
  }
}
