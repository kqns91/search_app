import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List _blogs = [];
  final TextEditingController _controller = TextEditingController();

  Future<void> _fetchData(String query) async {
    if (query.isEmpty) {
      return;
    }
    final response = await http.get(Uri.parse(
        'https://kqns91.mydns.jp/api/documents/search?from=0&size=30&query=$query'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _blogs = data['blogs'];
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData('');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Blog Searcher',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Blog Searcher'),
          backgroundColor: const Color(0xFF812990),
          elevation: 0,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Search',
                  labelStyle: TextStyle(color: Color(0xFF812990)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    borderSide: BorderSide(width: 1, color: Color(0xFF812990)),
                  ),
                ),
                onSubmitted: (value) {
                  _fetchData(value);
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _blogs.length,
                itemBuilder: (BuildContext context, int index) {
                  final blog = _blogs[index];
                  final highlightedText = blog['highlight'] as List<dynamic>;
                  final highlightedSpans =
                      highlightedText.map<InlineSpan>((highlight) {
                    if (highlight is String) {
                      return TextSpan(
                        text: highlight.replaceAll("\n", ""),
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                      );
                    } else {
                      return const TextSpan(
                        text: '',
                      );
                    }
                  }).toList();
                  return ListTile(
                    title: Text(
                      blog['title'],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          blog['member'] + ' - ' + blog['created'],
                          style: const TextStyle(
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 80,
                          child: RichText(
                            text: TextSpan(
                              children: highlightedSpans,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 5,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        )
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WebView(
                          url: blog['url'],
                          title: blog['title'],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebView extends StatelessWidget {
  final String url;
  final String title;

  const WebView({required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return WebviewScaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF812990),
        elevation: 0,
      ),
      url: url,
      withJavascript: true,
    );
  }
}
