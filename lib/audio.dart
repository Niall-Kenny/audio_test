import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fountain_audio/fountain_audio.dart';
import 'package:http/http.dart' as http;

class AudioPlayer {
  late FountainAudioPlatform _player;

  late final Stream<double> positionStream = _player.positionStream;
  late final Stream<PlayerState> playerStateStream = _player.playerStateStream;
  late final Stream<PlayerEvent> playerEventStream = _player.playerEventStream;

  AudioPlayer() {
    _player = FountainAudioMethodChannel(http.Client());
    FountainAudioPlatform.instance = _player;
    _player = FountainAudioPlatform.instance;
  }

  Future<void> setup() async {
    await _player.setupPlayer();
  }

  Future<List<Track>> queue() {
    return _player.queue;
  }

  Future<void> setQueue(List<Track> tracks) {
    return _player.addAll(tracks);
  }

  Future<Track?> currentTrack() async {
    final index = await _player.currentTrack;
    final queue = await _player.queue;
    if (queue.isEmpty || index > queue.length - 1) {
      return null;
    }
    return _player.track(index);
  }

  PlayerState currentState() {
    return _player.playerState;
  }

  double currentDuration() {
    return _player.currentDuration;
  }

  double currentPosition() {
    return _player.currentPosition;
  }

  Future<void> play() {
    return _player.play();
  }

  Future<void> pause() {
    return _player.pause();
  }

  Future<void> stop() async {
    if (_player.playerState != PlayerState.none) {
      await _player.stop();
    }
    if (Platform.isIOS) {
      await seekToZero();
    }
  }

  Future<void> skipToPrevious() {
    return _player.skipToPrevious();
  }

  Future<void> skipToNext() async {
    return _player.skipToNext();
  }

  Future<void> skipForward(num num) async {
    await seekTo(((await _player.position) + num));
  }

  Future<void> skipBack(num num) async {
    await seekTo(((await _player.position) - num));
  }

  Future<void> seekToZero() async {
    await seekTo(0);
  }

  double? _latestSeekSeconds;

  /// The same as [seekTo]. Duration is not a fitting argument
  /// as it rounds the second value
  Future<void> seekTo(double seconds) async {
    _latestSeekSeconds = seconds;
    if (Platform.isIOS) {
      await _seekToSeconds(seconds);
    }
    if (!Platform.isIOS) {
      await _player.seekTo(seconds);
    }
  }

  /// Seek events can sometimes be ignored in the ios lib if they happen
  /// in quick succession, therefore we handle seeking on ios differently.
  /// FYI seek events can be sourced from other methods like [_player.stop].
  Future<void> _seekToSeconds(
    double seconds, [
    Completer<dynamic>? completer,
    int attempts = 3,
  ]) async {
    final c = completer ?? Completer();
    // ignore: prefer_function_declarations_over_variables
    final cb = (_) async {
      final data = _ as SeekEventData;
      final canComplete =
          isWithinXOf(data.seconds, 2, seconds) && data.didFinish;
      if (c.isCompleted) return;
      if (_latestSeekSeconds != seconds) {
        return c.complete();
      }
      if (canComplete) {
        c.complete();
      }
      if (!canComplete && attempts > 0) {
        /// need to give time for the underlying lib to finish
        /// whatever it's doing.
        await Future.delayed(const Duration(milliseconds: 100));
        _seekToSeconds(seconds, c, attempts - 1);
      }
      if (!canComplete && attempts == 0) {
        c.complete();
      }
    };

    if (attempts == 3) {
      final isAlreadyAtPosition =
          isWithinXOf(seconds, 2, (await _player.position));
      if (isAlreadyAtPosition) {
        return c.complete();
      }
      _player.addEventListener(PlayerEvent.playbackSeek, cb);
      c.future.then(
          (value) => _player.removeEventListener(PlayerEvent.playbackSeek, cb));
    }

    /// Sometimes the seek event is not fired when position is 0 & seeking to 0.
    if ((seconds == 0 && (await _player.position) == 0) && !c.isCompleted) {
      c.complete();
    }

    await _player.seekTo(seconds);
    await c.future;
  }

  Future<void> skip(int index, {bool playWhenReady = false}) {
    return _player.skip(index, playWhenReady: playWhenReady);
  }
}

@immutable
class AudioPlayer2State {
  final double position;
  final double duration;
  final PlayerState playerState;
  final List<Track> queue;
  final int trackIndex;
  final double playbackSpeed;

  const AudioPlayer2State({
    required this.position,
    required this.duration,
    required this.playerState,
    required this.queue,
    required this.trackIndex,
    required this.playbackSpeed,
  });

  copyWith({
    position,
    duration,
    playerState,
    queue,
    trackIndex,
    playbackSpeed,
  }) {
    return AudioPlayer2State(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playerState: playerState ?? this.playerState,
      queue: queue ?? this.queue,
      trackIndex: trackIndex ?? this.trackIndex,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class AudioPlayer2 extends StateNotifier<AudioPlayer2State> {
  late FountainAudioPlatform _player;

  late final Stream<double> positionStream = _player.positionStream;
  late final Stream<PlayerState> playerStateStream = _player.playerStateStream;
  late final Stream<PlayerEvent> playerEventStream = _player.playerEventStream;

  AudioPlayer2()
      : super(
          const AudioPlayer2State(
            position: 0,
            duration: 0,
            playerState: PlayerState.none,
            queue: [],
            trackIndex: 0,
            playbackSpeed: 0,
          ),
        ) {
    _player = FountainAudioPlatform.instance;
  }

  Future<void> setup() async {
    // await _player.setupPlayer();
    _player.playerStateStream.listen((event) {
      state = state.copyWith(playerState: event);
    });
    _player.positionStream.distinct().listen((event) {
      state = state.copyWith(position: event);
    });
    _player.durationStream.distinct().listen((event) {
      state = state.copyWith(duration: event);
    });

    _player.playerEventStream.distinct().listen((event) async {
      state = AudioPlayer2State(
        position: _player.currentPosition,
        duration: _player.currentDuration,
        playerState: _player.playerState,
        queue: await _player.queue,
        trackIndex: await _player.currentTrack,
        playbackSpeed: _player.currentPlaybackRate,
      );
    });
  }

  Future<void> setQueue(List<Track> tracks) async {
    await _player.addAll(tracks);
    state = state.copyWith(queue: tracks);
  }

  Future<void> play() {
    return _player.play();
  }

  Future<void> pause() {
    return _player.pause();
  }

  Future<void> stop() async {
    if (_player.playerState != PlayerState.none) {
      await _player.stop();
    }
    if (Platform.isIOS) {
      await seekToZero();
    }
  }

  Future<void> skipToPrevious() {
    return _player.skipToPrevious();
  }

  Future<void> skipToNext() async {
    return _player.skipToNext();
  }

  Future<void> skipForward(num num) async {
    await seekTo(((await _player.position) + num));
  }

  Future<void> skipBack(num num) async {
    await seekTo(((await _player.position) - num));
  }

  Future<void> seekToZero() async {
    await seekTo(0);
  }

  double? _latestSeekSeconds;

  /// The same as [seekTo]. Duration is not a fitting argument
  /// as it rounds the second value
  Future<void> seekTo(double seconds) async {
    _latestSeekSeconds = seconds;
    if (Platform.isIOS) {
      await _seekToSeconds(seconds);
    }
    if (!Platform.isIOS) {
      await _player.seekTo(seconds);
    }
  }

  /// Seek events can sometimes be ignored in the ios lib if they happen
  /// in quick succession, therefore we handle seeking on ios differently.
  /// FYI seek events can be sourced from other methods like [_player.stop].
  Future<void> _seekToSeconds(
    double seconds, [
    Completer<dynamic>? completer,
    int attempts = 3,
  ]) async {
    final c = completer ?? Completer();
    // ignore: prefer_function_declarations_over_variables
    final cb = (_) async {
      final data = _ as SeekEventData;
      final canComplete =
          isWithinXOf(data.seconds, 2, seconds) && data.didFinish;
      if (c.isCompleted) return;
      if (_latestSeekSeconds != seconds) {
        return c.complete();
      }
      if (canComplete) {
        c.complete();
      }
      if (!canComplete && attempts > 0) {
        /// need to give time for the underlying lib to finish
        /// whatever it's doing.
        await Future.delayed(const Duration(milliseconds: 100));
        _seekToSeconds(seconds, c, attempts - 1);
      }
      if (!canComplete && attempts == 0) {
        c.complete();
      }
    };

    if (attempts == 3) {
      final isAlreadyAtPosition =
          isWithinXOf(seconds, 2, (await _player.position));
      if (isAlreadyAtPosition) {
        return c.complete();
      }
      _player.addEventListener(PlayerEvent.playbackSeek, cb);
      c.future.then(
          (value) => _player.removeEventListener(PlayerEvent.playbackSeek, cb));
    }

    /// Sometimes the seek event is not fired when position is 0 & seeking to 0.
    if ((seconds == 0 && (await _player.position) == 0) && !c.isCompleted) {
      c.complete();
    }

    await _player.seekTo(seconds);
    await c.future;
  }

  Future<void> skip(int index, {bool playWhenReady = false}) {
    return _player.skip(index, playWhenReady: playWhenReady);
  }
}

bool isWithinXOf(num numToCheck, num withinX, num of) {
  return numToCheck >= (of - withinX) && numToCheck <= (of + withinX);
}
