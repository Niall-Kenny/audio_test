import 'dart:math';

import 'package:audio_lib_test/audio.dart';
import 'package:audio_lib_test/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fountain_audio/fountain_audio.dart';

/// An example of watching for state changes to AudioPlayer2State

class PageTwo extends ConsumerWidget {
  const PageTwo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const TrackInfo(),
        ElevatedButton(
          onPressed: () async {
            final player = ref.read(audioPlayer2Provider.notifier);
            final playerState = ref.read(audioPlayer2Provider);

            if (playerState.queue.isEmpty) {
              player.setQueue(tracks);
            }
          },
          child: const Text('set track list'),
        ),
        const QueuePanel(),
      ],
    );
  }
}

class TrackInfo extends ConsumerStatefulWidget {
  const TrackInfo({Key? key}) : super(key: key);

  @override
  ConsumerState<TrackInfo> createState() => _TrackInfoState();
}

class _TrackInfoState extends ConsumerState<TrackInfo> {
  late final AudioPlayer2 player;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(audioPlayer2Provider.select((s) => s.position));
    final trackIndex =
        ref.watch(audioPlayer2Provider.select((s) => s.trackIndex));
    final queue = ref.watch(audioPlayer2Provider.select((s) => s.queue));
    final duration = ref.watch(audioPlayer2Provider.select((s) => s.duration));

    final track = queue.isEmpty || trackIndex >= queue.length
        ? Track.empty
        : queue[trackIndex];

    return Column(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 16.0 / 9.0,
                    child: track.artwork != null
                        ? Image.network(
                            track.artwork!,
                            fit: BoxFit.cover,
                          )
                        : const FlutterLogo(),
                  ),
                  Text(track.artist),
                  Text(track.title),
                  Text(
                    '${position.toStringAsFixed(2)} / ${duration.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: ButtonControls(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: TimeSlider(),
            ),
          ],
        )
      ],
    );
  }
}

class ButtonControls extends ConsumerStatefulWidget {
  const ButtonControls({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ButtonControls> createState() => _ButtonControlsState();
}

class _ButtonControlsState extends ConsumerState<ButtonControls> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.read(audioPlayer2Provider.notifier);
    return Theme(
      data: Theme.of(context).copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(side: BorderSide(color: Colors.black)),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: const Size(48.0, 48.0),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // SKIP TO PREVIOUS SONG.
          ElevatedButton(
            onPressed: () async {
              try {
                await player.skipToPrevious();
              } on PlatformException catch (error) {
                if (error.code != 'no_previous_track') {
                  rethrow;
                }
              }
            },
            child: const Icon(Icons.skip_previous),
          ),
          // SKIP BACK 15 SECONDS.
          ElevatedButton(
            onPressed: () {
              final playerState = ref.read(audioPlayer2Provider);

              final position = max<double>(playerState.position - 15, 0);
              player.seekTo(position);
            },
            child: const Text('<15'),
          ),
          // TOGGLE PAUSE/PLAY.
          StreamBuilder<PlayerState>(
            initialData: PlayerState.none,
            stream: player.playerStateStream,
            builder:
                (BuildContext context, AsyncSnapshot<PlayerState> snapshot) {
              final state = snapshot.data!;
              final playable = [
                PlayerState.stopped,
                PlayerState.paused,
                PlayerState.ready,
                PlayerState.none
              ].contains(state);
              final pauseable = state == PlayerState.playing;
              return ElevatedButton(
                onPressed: () {
                  if (playable) {
                    player.play();
                  } else if (pauseable) {
                    player.pause();
                  }
                },
                child: Icon(pauseable ? Icons.pause : Icons.play_arrow),
              );
            },
          ),
          // SKIP FORWARD 15 SECONDS.
          ElevatedButton(
            onPressed: () async {
              final playerState = ref.read(audioPlayer2Provider);

              final duration = playerState.duration;
              final position = min<double>(playerState.position + 15, duration);
              player.seekTo(position);
            },
            child: const Text('15>'),
          ),
          // SKIP TO NEXT TRACK.
          ElevatedButton(
            onPressed: () async {
              try {
                await player.skipToNext();
              } on PlatformException catch (error) {
                if (error.code != 'queue_exhausted') {
                  rethrow;
                }
              }
            },
            child: const Icon(Icons.skip_next),
          ),
        ].map((el) => Expanded(child: el)).toList(),
      ),
    );
  }
}

class TimeSlider extends ConsumerWidget {
  const TimeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AudioPlayer2 player = ref.read(audioPlayer2Provider.notifier);
    final AudioPlayer2State playerState = ref.watch(audioPlayer2Provider);

    return Row(
      children: [
        Text(playerState.position.toStringAsFixed(2)),
        Expanded(
          child: Slider(
            min: 0,
            max: playerState.duration,
            value: playerState.position,
            onChanged: (_) {},
            onChangeEnd: (milliseconds) {
              player.seekTo(milliseconds);
            },
          ),
        ),
        Text((playerState.duration - playerState.position).toStringAsFixed(2)),
      ],
    );
  }
}

class QueuePanel extends ConsumerStatefulWidget {
  const QueuePanel({Key? key}) : super(key: key);

  @override
  ConsumerState<QueuePanel> createState() => _QueuePanelState();
}

class _QueuePanelState extends ConsumerState<QueuePanel> {
  // late final AudioPlayer2 player;
  // late final Stream<Track?> _currentTrackStream;
  // late List<_QueueItem> _queue;
  // late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // player = ref.read(audioPlayer2Provider);

    // _queue = [];
    // _currentIndex = 0;
    // _currentTrackStream = player.playerEventStream.asyncMap((_) async {
    //   final tracks = await player.queue();
    //   final newQueue = <_QueueItem>[];
    //   for (int index = 0; index < tracks.length; index++) {
    //     newQueue.add(_QueueItem(tracks[index], index));
    //   }
    //   _queue = newQueue;
    //   final currentTrack = await player.currentTrack();
    //   _currentIndex = currentTrack == null ? 0 : tracks.indexOf(currentTrack);
    //   return currentTrack;
    // }).asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.read(audioPlayer2Provider.notifier);
    final playerState =
        ref.read(audioPlayer2Provider.select((s) => s.playerState));

    final currentIndex =
        ref.read(audioPlayer2Provider.select((s) => s.trackIndex));

    final tracks = ref.watch(audioPlayer2Provider.select((s) => s.queue));

    final _queue = <_QueueItem>[];

    for (int index = 0; index < tracks.length; index++) {
      _queue.add(_QueueItem(tracks[index], index));
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final _QueueItem item in _queue)
              ListTile(
                title: Text(item.track.title),
                subtitle: Text(item.track.artist),
                leading: AspectRatio(
                  aspectRatio: 1.0,
                  child: item.track.artwork != null
                      ? Image.network(
                          item.track.artwork!,
                          fit: BoxFit.cover,
                        )
                      : const FlutterLogo(),
                ),
                trailing: Icon(_iconData(item.index, currentIndex)),
                onTap: () async {
                  final currentTrack = currentIndex == item.index;
                  final playing = playerState == PlayerState.playing;

                  if (currentTrack && playing) {
                    await player.pause();
                  } else if (currentTrack) {
                    await player.play();
                  } else {
                    await player.skip(item.index, playWhenReady: true);
                  }
                },
              )
          ],
        ),
      ),
    );
  }

  IconData _iconData(int trackIndex, int currentIndex) {
    final playing =
        ref.read(audioPlayer2Provider).playerState == PlayerState.playing;
    final currentTrack = trackIndex == currentIndex;

    if (currentTrack && playing) {
      return Icons.pause;
    }
    return Icons.play_arrow;
  }
}

class _QueueItem {
  const _QueueItem(this.track, this.index);

  final Track track;
  final int index;
}
