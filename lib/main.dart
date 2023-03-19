import 'dart:ffi';

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
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String query = "";
  int offset = 0;
  final int limit = 30;

  List _blogs = [];

  Future<void> _fetchData() async {
    final response = await http.get(Uri.parse(
        'https://kqns91.mydns.jp/api/blogs/search?from=$offset&size=$limit&query=$query'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        if (offset == 0) {
          _blogs = data['result'];
        } else {
          _blogs.addAll(data['result']);
        }
      });
      offset = offset + limit;
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollEnd);
  }

  void _onScrollEnd() {
    if (_scrollController.position.maxScrollExtent -
            _scrollController.position.pixels <
        200.0) {
      _fetchData();
    }
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
          title: const Text('のぎさーち'),
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
                  hintText: "検索",
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    borderSide: BorderSide(width: 1, color: Color(0xFF812990)),
                  ),
                ),
                onSubmitted: (value) {
                  query = value;
                  offset = 0;
                  if (query == "") {
                    setState(() {
                      _blogs = [];
                    });
                    return;
                  }
                  _fetchData();
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(
                      milliseconds: 300,
                    ),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _blogs.length,
                itemBuilder: (BuildContext context, int index) {
                  final blog = _blogs[index];
                  final highlightedText = blog['highlight'] as List<dynamic>;
                  TextSpan getTextSpans(String text) {
                    final List<String> parts =
                        text.split(RegExp(r'<em>|<\/em>'));
                    final List<RegExpMatch> matches =
                        RegExp(r'<em>(.*?)<\/em>').allMatches(text).toList();
                    final List<TextSpan> spans = [];
                    for (final String part in parts) {
                      bool appended = false;
                      for (final RegExpMatch match in matches) {
                        if (part == match.group(1)) {
                          spans.add(
                            TextSpan(
                              text: part,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                  fontWeight: FontWeight.bold),
                            ),
                          );
                          appended = true;
                          break;
                        }
                      }
                      if (!appended) {
                        spans.add(
                          TextSpan(
                            text: part,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF888888),
                            ),
                          ),
                        );
                      }
                    }
                    return TextSpan(children: spans);
                  }

                  return ListTile(
                    title: Text(
                      blog['title'],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 22,
                        color: Color.fromARGB(255, 22, 22, 168),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          blog['member'] + ' - ' + blog['date'],
                          style: const TextStyle(
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          child: RichText(
                            text: getTextSpans(
                                ("${highlightedText.join("...")}...")
                                    .replaceAll("\n", "")
                                    .replaceAll(RegExp(r'&\w+;'), "")),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 5,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        )
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WebView(
                          url: blog['link'],
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
