import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class News {
  final String title;
  final String content;
  final DateTime date;
  final DateTime lastEditDate;

  News({
    required this.title,
    required this.content,
    required this.date,
    required this.lastEditDate,
  });
}

class NewsProvider extends ChangeNotifier{
  List<News> _newsList = [];

  List<News> get newsList => _newsList;

  set newsList(List<News> value) {
    _newsList = value;
    notifyListeners();
  }
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initData() async {
    // Simulate fetching data from the database after a delay
    await Future.delayed(const Duration(seconds: 3));

    // Get the latest news
    List<News> latestNews = getLatestNews();
    newsList.addAll(latestNews);

    // Notify listeners to update UI
    notifyListeners();

    // Show a notification if there are new updates
    if (latestNews.isNotEmpty) {
      showNotification();
    }
  }

  static List<News> getLatestNews() {
    // This is a placeholder. In a real app, you'd fetch data from the actual database.
    return [
      News(
        title: 'New News',
        content: 'Content for the new news',
        date: DateTime.now(),
        lastEditDate: DateTime.now(),
      ),
    ];
  }

  static Future<void> showNotification() async {
    var android = const AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'channel_description',
      priority: Priority.high,
      importance: Importance.max,
      icon: '@mipmap/ic_launcher', // Add this line
    );
    var iOS = const DarwinNotificationDetails();
    var platform = NotificationDetails(android: android, iOS: iOS);

    await flutterLocalNotificationsPlugin.show(
      0,
      'New News Available',
      'Check out the latest news for updates!',
      platform,
      payload: 'news',
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NewsListScreen(),
    );
  }
}


// Create a NewsProvider instance
NewsProvider newsProvider = NewsProvider();
class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  _NewsListScreenState createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {

  // Create a Timer instance
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Create a periodic timer that calls the initData() method every 2 seconds
    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      newsProvider.initData();
      print(timer.tick);
    });
    print("out of timer body");
  }

  @override
  void dispose() {
    super.dispose();
    // Cancel the timer when the widget is disposed
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Pass the NewsProvider instance here
      create: (context) => newsProvider,
      child: Consumer<NewsProvider>(
        builder: (context, newsProvider, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('News List'),
            ),
            body: ListView.builder(
              itemCount: newsProvider.newsList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(newsProvider.newsList[index].title),
                  subtitle: Text(
                    'Published: ${newsProvider.newsList[index].date.toString()}',
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailScreen(news: newsProvider.newsList[index]),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}


class NewsDetailScreen extends StatelessWidget {
  final News news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              news.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              news.content,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              'Published: ${news.date.toString()}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              'Last Edited: ${news.lastEditDate.toString()}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
