import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'aadat',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var habits = <String>[];

  GlobalKey<AnimatedListState> historyListKey = GlobalKey<AnimatedListState>();

  void addHabit(String inputText) {
    habits.insert(0, inputText); // insert at the beginning
    if (historyListKey.currentState != null) {
      historyListKey.currentState?.insertItem(0); // animate at index 0
    }

    notifyListeners(); // optional, only if other widgets need to update
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
      case 1:
        page = HabitsPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.home),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.favorite),
                      label: Text('Habits'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) {
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GeneratorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 10),
          Padding(padding: const EdgeInsets.all(10.0), child: BigCard()),
          Expanded(flex: 3, child: HabitsListView()),
        ],
      ),
    );
  }
}

class BigCard extends StatefulWidget {
  const BigCard({super.key});

  @override
  State<BigCard> createState() => _BigCardState();
}

class _BigCardState extends State<BigCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose(); // free memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: TextField(
          onSubmitted: (inputText) {
            appState.addHabit(inputText);
            _controller.clear();
          },
          controller: _controller,
          style: style,
          decoration: InputDecoration(
            labelText: 'Enter your text',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

class HabitsListView extends StatefulWidget {
  const HabitsListView({super.key});

  @override
  State<HabitsListView> createState() => _HabitsListViewState();
}

class _HabitsListViewState extends State<HabitsListView> {
  /// Used to "fade out" the history items at the bottom, to suggest continuation.
  static const Gradient _maskingGradient = LinearGradient(
    // This gradient goes from fully transparent to fully opaque black...
    colors: [Colors.black, Colors.transparent],
    // ... from the top (transparent) to half (0.5) of the way to the bottom.
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  final _key = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    // Optional: pass the key to the app state if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyAppState>().historyListKey = _key;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      // This blend mode takes the opacity of the shader (i.e. our gradient)
      // and applies it to the destination (i.e. our animated list).
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: false,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: appState.habits.length,
        itemBuilder: (context, index, animation) {
          final habit = appState.habits[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  print("habit clicked");
                },
                label: Text(
                  habit.toLowerCase(),
                  semanticsLabel: habit.toLowerCase(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class HabitsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.habits.isEmpty) {
      return Center(child: Text('No habits yet.'));
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'You have '
            '${appState.habits.length} habits:',
          ),
        ),
        for (var habit in appState.habits)
          ListTile(
            leading: Icon(Icons.favorite),
            title: Text(habit.toLowerCase()),
          ),
      ],
    );
  }
}
