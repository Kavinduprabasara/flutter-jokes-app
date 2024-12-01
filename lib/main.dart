import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jokes App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent),
        useMaterial3: true,
      ),
      home: const JokesHomePage(),
    );
  }
}

// Joke model class to handle both single and two-part jokes
class Joke {
  final String type; // 'single' or 'twopart'
  final String? joke; // for single jokes
  final String? setup; // for twopart jokes
  final String? delivery; // for twopart jokes

  Joke({
    required this.type,
    this.joke,
    this.setup,
    this.delivery,
  });

  factory Joke.fromJson(Map<String, dynamic> json) {
    return Joke(
      type: json['type'],
      joke: json['joke'],
      setup: json['setup'],
      delivery: json['delivery'],
    );
  }

  String get fullJoke {
    if (type == 'single') {
      return joke ?? '';
    } else {
      return '${setup ?? ''}\n${delivery ?? ''}';
    }
  }
}

// Response model to handle the API response structure
class JokeApiResponse {
  final bool error;
  final int amount;
  final List<Joke> jokes;

  JokeApiResponse({
    required this.error,
    required this.amount,
    required this.jokes,
  });

  factory JokeApiResponse.fromJson(Map<String, dynamic> json) {
    List<Joke> jokesList = [];

    if (json['amount'] == 1) {
      // Single joke response
      jokesList.add(Joke.fromJson(json));
    } else {
      // Multiple jokes response
      jokesList = (json['jokes'] as List)
          .map((jokeJson) => Joke.fromJson(jokeJson))
          .toList();
    }

    return JokeApiResponse(
      error: json['error'],
      amount: json['amount'],
      jokes: jokesList,
    );
  }
}

class JokesHomePage extends StatefulWidget {
  const JokesHomePage({super.key});

  @override
  State<JokesHomePage> createState() => _JokesHomePageState();
}

class _JokesHomePageState extends State<JokesHomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Joke> jokes = [];
  List<Joke> filteredJokes = [];
  bool isLoading = false;
  String error = '';

  @override
  void initState() {
    super.initState();
    fetchJokes();
  }

  Future<void> fetchJokes() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://v2.jokeapi.dev/joke/Any?amount=10'),
      );

      if (response.statusCode == 200) {
        final JokeApiResponse apiResponse =
        JokeApiResponse.fromJson(json.decode(response.body));

        if (!apiResponse.error) {
          setState(() {
            jokes = apiResponse.jokes;
            filteredJokes = List.from(jokes);
            isLoading = false;
          });
        } else {
          setState(() {
            error = 'Failed to load jokes from API';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to load jokes. Please try again later.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void _filterJokes(String query) {
    setState(() {
      filteredJokes = jokes
          .where((joke) =>
          joke.fullJoke.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jokes App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchJokes,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Jokes',
                hintText: 'Enter keywords...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: _filterJokes,
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error.isNotEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    error,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchJokes,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : filteredJokes.isEmpty
                ? const Center(
              child: Text(
                'No jokes found!',
                style: TextStyle(fontSize: 18),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredJokes.length,
              itemBuilder: (context, index) {
                final joke = filteredJokes[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      joke.type == 'single'
                          ? joke.joke ?? ''
                          : joke.setup ?? '',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: joke.type == 'twopart'
                        ? Padding(
                      padding:
                      const EdgeInsets.only(top: 8.0),
                      child: Text(
                        joke.delivery ?? '',
                        style: const TextStyle(
                            fontSize: 14),
                      ),
                    )
                        : null,
                    leading:
                    const Icon(Icons.tag_faces, size: 30),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}