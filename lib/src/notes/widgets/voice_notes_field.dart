import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../audio/note_audio_path.dart';
import '../models/note_audio_clip.dart';

/// Record / playback / reorder UI for a note's voice clips. The parent owns the
/// list via [clips] + [onChanged]; this widget only appends / removes / reorders
/// in memory and reports changes upward (persistence happens on note save).
final class VoiceNotesField extends ConsumerStatefulWidget {
  final String noteId;
  final List<NoteAudioClip> clips;
  final ValueChanged<List<NoteAudioClip>> onChanged;

  const VoiceNotesField({
    super.key,
    required this.noteId,
    required this.clips,
    required this.onChanged,
  });

  @override
  ConsumerState<VoiceNotesField> createState() => _VoiceNotesFieldState();
}

final class _VoiceNotesFieldState extends ConsumerState<VoiceNotesField> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  bool _isRecording = false;
  DateTime? _recordStart;
  Timer? _tick;
  int _elapsedMs = 0;

  String? _playingId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    setState(() => _error = null);
    if (_isRecording) {
      await _stopRecording();
      return;
    }
    final granted = await _recorder.hasPermission();
    if (!granted) {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context)!.notesVoicePermissionDenied,
        );
      }
      return;
    }
    final (id, path) = await newClipLocation();
    try {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
      return;
    }
    setState(() {
      _isRecording = true;
      _recordStart = DateTime.now();
      _elapsedMs = 0;
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recordStart != null && mounted) {
        setState(
          () => _elapsedMs = DateTime.now().difference(_recordStart!).inMilliseconds,
        );
      }
    });
  }

  Future<void> _stopRecording() async {
    _tick?.cancel();
    String? path;
    try {
      path = await _recorder.stop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
    final durationMs = _recordStart != null
        ? DateTime.now().difference(_recordStart!).inMilliseconds
        : 0;
    setState(() {
      _isRecording = false;
      _recordStart = null;
      _elapsedMs = 0;
    });
    if (path == null || path.isEmpty) return;
    final clip = NoteAudioClip(
      id: const Uuid().v7(),
      noteId: widget.noteId,
      audioPath: path,
      durationMs: durationMs,
      createdAt: DateTime.now(),
    );
    widget.onChanged([...widget.clips, clip]);
  }

  Future<void> _togglePlay(NoteAudioClip clip) async {
    if (_playingId == clip.id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(clip.audioPath));
      setState(() => _playingId = clip.id);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _remove(NoteAudioClip clip) async {
    if (_playingId == clip.id) {
      await _player.stop();
      setState(() => _playingId = null);
    }
    await deleteClipFile(clip.audioPath);
    widget.onChanged(widget.clips.where((c) => c.id != clip.id).toList());
  }

  void _reorder(int oldIndex, int newIndex) {
    final list = [...widget.clips];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    widget.onChanged(list);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: _toggleRecord,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(
                _isRecording
                    ? l10n.notesVoiceRecording(_format(_elapsedMs))
                    : l10n.notesVoiceRecord,
              ),
            ),
            if (widget.clips.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                l10n.notesVoiceCount(widget.clips.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (widget.clips.isEmpty)
          Text(
            l10n.notesVoiceNone,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.clips.length,
            onReorder: _reorder,
            itemBuilder: (context, i) {
              final clip = widget.clips[i];
              final playing = _playingId == clip.id;
              return ListTile(
                key: ValueKey(clip.id),
                leading: IconButton(
                  tooltip: playing ? l10n.notesVoiceStopPlayback : l10n.notesVoicePlay,
                  icon: Icon(playing ? Icons.stop_circle : Icons.play_circle_outline),
                  onPressed: () => _togglePlay(clip),
                ),
                title: Text(l10n.notesVoiceClipLabel(i + 1)),
                subtitle: Text(_format(clip.durationMs)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: l10n.notesVoiceRemove,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _remove(clip),
                    ),
                    ReorderableDragStartListener(
                      index: i,
                      child: const Icon(Icons.drag_handle),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _format(int ms) {
    final s = (ms / 1000).round();
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
