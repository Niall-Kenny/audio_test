import 'package:audio_lib_test/audio.dart';
import 'package:audio_lib_test/pages/page_2.dart';
import 'package:audio_lib_test/pages/page_1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fountain_audio/fountain_audio.dart';

void main() {
  runApp(const ProviderScope(child: Initializer()));
}

final audioPlayerProvider = Provider((_) => AudioPlayer());
final audioPlayer2Provider =
    StateNotifierProvider<AudioPlayer2, AudioPlayer2State>(
  (_) => AudioPlayer2(),
);

class Initializer extends ConsumerStatefulWidget {
  const Initializer({super.key});

  @override
  ConsumerState<Initializer> createState() => _InitializerState();
}

class _InitializerState extends ConsumerState<Initializer> {
  late Future setupFuture;
  @override
  void initState() {
    super.initState();
    final player = ref.read(audioPlayerProvider);
    final player2 = ref.read(audioPlayer2Provider.notifier);
    setupFuture = Future(() async {
      player.setup();
      player2.setup();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: setupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return const MyApp();
        }
        return const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final player = ref.read(audioPlayerProvider);
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: PageView(
        children: const [PageOne(), PageTwo()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          player.currentState() == PlayerState.playing
              ? player.pause()
              : player.play();
        },
        tooltip: 'Increment',
        child: StreamBuilder(
          initialData: PlayerState.none,
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            if (snapshot.data == PlayerState.buffering ||
                snapshot.data == PlayerState.connecting ||
                snapshot.data == PlayerState.loading ||
                snapshot.data == PlayerState.ready) {
              return const CircularProgressIndicator(
                color: Colors.white,
              );
            }
            return Icon(
              snapshot.data == PlayerState.playing
                  ? Icons.pause
                  : Icons.play_arrow,
            );
          },
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
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
