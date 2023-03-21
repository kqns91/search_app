import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _editingcontroller;
  late ScrollController _blogScrollController;
  late ScrollController _commentScrollController;
  late FocusNode _focusNode;
  bool _isFocused = false;
  String query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _editingcontroller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
    _blogScrollController = ScrollController();
    _blogScrollController.addListener(_onBlogScrollEnd);
    _commentScrollController = ScrollController();
    _commentScrollController.addListener(_onCommentScrollEnd);
  }

  @override
  void dispose() {
    _commentScrollController.dispose();
    _blogScrollController.dispose();
    _focusNode.dispose();
    _editingcontroller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onBlogScrollEnd() {
    if (_blogScrollController.position.maxScrollExtent -
            _blogScrollController.position.pixels <
        200.0) {
      _fetchBlogs();
    }
  }

  void _onCommentScrollEnd() {
    if (_commentScrollController.position.maxScrollExtent -
            _commentScrollController.position.pixels <
        200.0) {
      _fetchComments();
    }
  }

  Future<void> _fetchBlogs() async {
    final response = await http.get(Uri.parse(
        'https://kqns91.mydns.jp/api/blogs/search?from=$blogOffset&size=$limit&query=$query'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        if (blogOffset == 0) {
          _blogs = data['result'];
        } else {
          _blogs.addAll(data['result']);
        }
      });
      blogOffset = blogOffset + limit;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> _fetchComments() async {
    final response = await http.get(Uri.parse(
        'https://kqns91.mydns.jp/api/comments/search?from=$commnetOffset&size=$limit&query=$query'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        if (commnetOffset == 0) {
          _comments = data['result'];
        } else {
          _comments.addAll(data['result']);
        }
      });
      commnetOffset = commnetOffset + limit;
    } else {
      throw Exception('Failed to load data');
    }
  }

  final int limit = 30;
  int blogOffset = 0;
  int commnetOffset = 0;
  List _blogs = [];
  List _comments = [];

  TextSpan getTextSpans(String text) {
    final List<String> parts = text.split(RegExp(r'<em>|<\/em>'));
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

  Image getImage(List<dynamic>? images) {
    if (images == null ||
        images.isEmpty ||
        images[0].toString().contains('/staff/')) {
      return Image.network(
        "https://www.nogizaka46.com/files/46/assets/img/blog/none.png",
        fit: BoxFit.fitWidth,
      );
    }

    return Image.network(
      images[0].toString(),
      fit: BoxFit.fitWidth,
      errorBuilder:
          (BuildContext context, Object exception, StackTrace? stackTrace) {
        return const Text('no image');
      },
    );
  }

  Column blogView() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 10, 3, 1),
            child: ListView.builder(
                controller: _blogScrollController,
                itemCount: _blogs.length,
                itemBuilder: (BuildContext context, int index) {
                  final blog = _blogs[index];
                  final highlightedText = blog['highlight'] as List<dynamic>;

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
                        getImage(blog["images"]),
                        const SizedBox(height: 10),
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
                          height: 20,
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
                }),
          ),
        ),
      ],
    );
  }

  Column commentView() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(3, 10, 3, 1),
            child: ListView.builder(
                controller: _commentScrollController,
                itemCount: _comments.length,
                itemBuilder: (BuildContext context, int index) {
                  final comment = _comments[index];
                  return ListTile(
                    title: Text(
                      comment['comment1'],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment['date'],
                          style: const TextStyle(
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(49, 163, 153, 152),
                            border: Border(),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              comment['body'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
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
                          url:
                              "https://www.nogizaka46.com/s/n46/diary/detail/${comment['kijicode']}",
                          title: '',
                        ),
                      ),
                    ),
                  );
                }),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 81, 29, 90),
        title: TextField(
          controller: _editingcontroller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.all(1),
            filled: true,
            fillColor: const Color.fromARGB(50, 255, 255, 255),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(100),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.search),
            hintText: "キーワード検索",
          ),
          onSubmitted: (value) {
            query = value;
            blogOffset = 0;
            commnetOffset = 0;
            if (query == "") {
              setState(() {
                _blogs = [];
                _comments = [];
              });
              return;
            }
            _fetchBlogs();
            _fetchComments();
            if (_tabController.index == 0) {
              _blogScrollController.animateTo(
                0,
                duration: const Duration(
                  milliseconds: 300,
                ),
                curve: Curves.easeInOut,
              );
            } else if (_tabController.index == 1) {
              _commentScrollController.animateTo(
                0,
                duration: const Duration(
                  milliseconds: 300,
                ),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(45),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(
                child: Text(
                  'ブログ',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Tab(
                child: Text(
                  'コメント',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        elevation: 0,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          blogView(),
          commentView(),
        ],
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   currentIndex: _tabController.index,
      //   onTap: (index) {
      //     setState(() {
      //       _tabController.index = index;
      //     });
      //   },
      //   items: const [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.search),
      //       label: '検索',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.newspaper),
      //       label: 'ニュース',
      //     ),
      //   ],
      // ),
    );
  }
}

class WebView extends StatelessWidget {
  final String url;
  final String title;

  const WebView({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return WebviewScaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color.fromARGB(255, 81, 29, 90),
        elevation: 0,
      ),
      url: url,
      withJavascript: true,
    );
  }
}
