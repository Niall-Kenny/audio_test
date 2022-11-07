import 'dart:math';

import 'package:audio_lib_test/audio.dart';
import 'package:audio_lib_test/main.dart';
import 'package:audio_lib_test/pages/page_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fountain_audio/fountain_audio.dart';

/// An example of getting AudioPlayer via a provider and
/// updating widgets from streams

class PageOne extends ConsumerWidget {
  const PageOne({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AudioPlayer player = ref.read(audioPlayerProvider);

    return Column(
      children: [
        const TrackInfo(),
        ElevatedButton(
          onPressed: () async {
            if ((await player.queue()).isEmpty) {
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
  late final AudioPlayer player;
  late final Stream<Track> _trackStream;
  Track _track = Track.empty;

  @override
  void initState() {
    super.initState();
    player = ref.read(audioPlayerProvider);

    _trackStream = player.playerEventStream
        .where((event) => [
              PlayerEvent.initialized,
              PlayerEvent.playbackTrackChanged,
              PlayerEvent.playbackQueueEnded,
              PlayerEvent.playbackMetadataReceived,
              PlayerEvent.playbackUpdateDuration,
              PlayerEvent.playbackPositionChanged,
            ].contains(event))
        .asyncMap((event) => player.queue())
        .where((q) => q.isNotEmpty)
        .asyncMap((event) async {
      _track = (await player.currentTrack())!;
      return _track;
    }).asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<Track>(
          initialData: _track,
          stream: _trackStream,
          builder: (BuildContext context, AsyncSnapshot<Track> snapshot) {
            if (snapshot.hasError) {
              return ErrorWidget(snapshot.error!);
            } else if (snapshot.hasData) {
              final track = snapshot.requireData;
              return Column(
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
                          '${player.currentPosition().toStringAsFixed(2)} / ${player.currentDuration().toStringAsFixed(2)}',
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
              );
            }
            return const CircularProgressIndicator.adaptive();
          },
        ),
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
  late final AudioPlayer player;

  @override
  void initState() {
    super.initState();
    player = ref.read(audioPlayerProvider);
  }

  @override
  Widget build(BuildContext context) {
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
              final position = max<double>(player.currentPosition() - 15, 0);
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
              final duration = player.currentDuration();
              final position =
                  min<double>(player.currentPosition() + 15, duration);
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
    final AudioPlayer player = ref.read(audioPlayerProvider);

    return StreamBuilder<double>(
      initialData: player.currentPosition(),
      stream: player.positionStream,
      builder: (context, snapshot) {
        return Row(
          children: [
            Text(player.currentPosition().toStringAsFixed(2)),
            Expanded(
              child: Slider(
                min: 0,
                max: player.currentDuration(),
                value: snapshot.data!,
                onChanged: (_) {},
                onChangeEnd: (milliseconds) {
                  player.seekTo(milliseconds);
                },
              ),
            ),
            Text((player.currentDuration() - player.currentPosition())
                .toStringAsFixed(2)),
          ],
        );
      },
    );
  }
}

class QueuePanel extends ConsumerStatefulWidget {
  const QueuePanel({Key? key}) : super(key: key);

  @override
  ConsumerState<QueuePanel> createState() => _QueuePanelState();
}

class _QueuePanelState extends ConsumerState<QueuePanel> {
  late final AudioPlayer player;
  late final Stream<Track?> _currentTrackStream;
  late List<_QueueItem> _queue;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    player = ref.read(audioPlayerProvider);

    _queue = [];
    _currentIndex = 0;
    _currentTrackStream = player.playerEventStream.asyncMap((_) async {
      final tracks = await player.queue();
      final newQueue = <_QueueItem>[];
      for (int index = 0; index < tracks.length; index++) {
        newQueue.add(_QueueItem(tracks[index], index));
      }
      _queue = newQueue;
      final currentTrack = await player.currentTrack();
      _currentIndex = currentTrack == null ? 0 : tracks.indexOf(currentTrack);
      return currentTrack;
    }).asBroadcastStream();
  }

  IconData _iconData(int trackIndex, int currentIndex) {
    final playing = player.currentState() == PlayerState.playing;
    final currentTrack = trackIndex == currentIndex;

    if (currentTrack && playing) {
      return Icons.pause;
    }
    return Icons.play_arrow;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Track?>(
      initialData: null,
      stream: _currentTrackStream,
      builder: (BuildContext context, AsyncSnapshot<Track?> snapshot) {
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
                    trailing: Icon(_iconData(item.index, _currentIndex)),
                    onTap: () async {
                      final currentTrack = _currentIndex == item.index;
                      final playing =
                          player.currentState() == PlayerState.playing;

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
      },
    );
  }
}

class _QueueItem {
  const _QueueItem(this.track, this.index);

  final Track track;
  final int index;
}

const tracks = <Track>[
  Track(
    title: 'one',
    artist: 'one',
    url: 'https://www.bensound.com/bensound-music/bensound-dontforget.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
  Track(
    title: 'two',
    artist: 'two',
    url: 'https://www.bensound.com/bensound-music/bensound-worldonfire.mp3',
    artwork:
        'https://images.unsplash.com/photo-1564186763535-ebb21ef5277f?auto=format&fit=crop&w=512&q=80',
  ),
];
