import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:convert';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NewsProvider.configureFirebaseMessaging();
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

  // Constructor for JSON format
  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      title: json['title'],
      content: json['content'],
      date: DateTime.parse(json['date']),
      lastEditDate: DateTime.parse(json['lastEditDate']),
    );
  }
}

// Class is expanded too much.
class NewsProvider extends ChangeNotifier {
  List<News> _newsList = [];

  List<News> get newsList => _newsList;

  set newsList(List<News> value) {
    _newsList = value;
    notifyListeners();
  }

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<void> initData() async {
    // Simulate fetching data from the database after a delay
    await Future.delayed(const Duration(seconds: 3));

    // Get the latest news
    List<News> latestNews = getLatestNews();
    newsList.addAll(latestNews);

    // Notify listeners to update UI
    notifyListeners();

    // Do something if there are new updates
    if (latestNews.isNotEmpty) {}
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

  static Future<void> showNotification(
      String? title, String? body, String? payload) async {
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
      title,
      body,
      platform,
      payload: payload,
    );
  }

  static Future<void> configureFirebaseMessaging() async {
    // Request permission for receiving push notifications
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Get the token
    String? token = await messaging.getToken();
    String? userId = generateUserId();
    print("Firebase Messaging Token: $token");
    sendTokenToServer(userId, token);

    // Handle incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received message: ${message.notification?.title}");
      showNotification(
          message.notification?.title, message.notification?.body, null);

      // Process the received message, e.g., update news data
      // Optionally, show a notification
    });

    // Handle when the app is in the background but opened by tapping the notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("App opened via notification: ${message.notification?.title}");
      // Navigate to the relevant screen based on the notification
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  // Background message handler
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print("Handling background message: ${message.notification?.title}");
    showNotification(
        message.notification?.title, message.notification?.body, null);
    // Process the background message, e.g., update news data
  }

  // Method to send the FCM token to the remote server
  static Future<void> sendTokenToServer(
      String? userId, String? fcmToken) async {
    try {
      // Replace with server's API endpoint
      final apiUrl = 'https://myserver.com/api/store-fcm-token';

      // Replace with any additional parameters
      final Map<String, dynamic> requestData = {
        'userId': userId,
        'fcmToken': fcmToken,
      };

      final response = await http.post(Uri.parse(apiUrl), body: requestData);

      if (response.statusCode == 200) {
        print('FCM token sent to server successfully.');
      } else {
        print(
            'Failed to send FCM token to server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  // Fetch news data from remote database server
  static Future<List<News>> fetchNewsFromRemote() async {
    try {
      final apiUrl = 'https://myserver.com/api/get-latest-news';
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final List<News> newsList =
            data.map((item) => News.fromJson(item)).toList();
        return newsList;
      } else {
        print(
            'Failed to fetch news from server. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  static String? generateUserId() {
    // Use the uuid package to generate a UUID (Universally Unique Identifier)
    final uuid = Uuid();
    return uuid.v4();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NewsListScreen(),
    );
  }
}




class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  _NewsListScreenState createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  Timer? timer;

  // List to store multiple instances of NewsProvider
  List<NewsProvider> newsProviders = [];

  // Current index to track the selected provider
  int selectedProviderIndex = 0;

  @override
  void initState() {
    super.initState();

    // Initialize at least one provider
    newsProviders.add(NewsProvider());

    timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Call initData on the selected provider
      await newsProviders[selectedProviderIndex].initData();
      print(timer.tick);
    });
    print("out of timer body");
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: newsProviders[selectedProviderIndex],
      child: Scaffold(
        appBar: AppBar(
          title: Text('News Service Provider ${selectedProviderIndex + 1}'),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  'News Service Providers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
              // Build list tiles for each provider
              for (int i = 0; i < newsProviders.length; i++)
                ListTile(
                  title: Text('Provider ${i + 1}'),
                  onTap: () {
                    setState(() {
                      // Switch to the selected provider
                      selectedProviderIndex = i;
                      Navigator.pop(context);
                    });
                  },
                ),
              // Add more list items for other actions
            ],
          ),
        ),
        body: ListView.builder(
          itemCount: newsProviders[selectedProviderIndex].newsList.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(newsProviders[selectedProviderIndex].newsList[index].title),
              subtitle: Text(
                'Published: ${newsProviders[selectedProviderIndex].newsList[index].date.toString()}',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewsDetailScreen(
                        news: newsProviders[selectedProviderIndex].newsList[index]),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddProviderDialog(context);
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }

  void _showAddProviderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Service Provider'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Add form fields for entering server credentials
                TextField(
                  decoration: InputDecoration(labelText: 'Provider Name'),
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Server URL'),
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Handle saving the new service provider
                setState(() {
                  newsProviders.add(NewsProvider());
                  selectedProviderIndex = newsProviders.length - 1;
                });
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
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
