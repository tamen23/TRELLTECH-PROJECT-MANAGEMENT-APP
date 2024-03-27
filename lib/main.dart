import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'models/user_data.dart';
import 'screens/user_profile.dart';
import 'screens/workflow_page.dart';
import 'package:trello_wish/api/trello_api.dart' as trelloApi;

void main() => runApp(
  ChangeNotifierProvider(
    create: (context) => UserData(),
    child: MyApp(),
  ),
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getUserInfo(trelloApi.TrelloAPI.apiToken);
  }

  void getUserInfo(String token) async {
    final apiKey = trelloApi.TrelloAPI.apiKey;
    final response = await http.get(Uri.parse('https://api.trello.com/1/members/me?key=$apiKey&token=$token'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      Provider.of<UserData>(context, listen: false).setUserData(
        userName: data['fullName'],
        workspaces: [],
      );
      setState(() {
        userName = data['fullName'];
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Impossible de récupérer les informations de l'utilisateur")));
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TRELLTECH'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(userName.isNotEmpty ? 'Bienvenue, $userName' : 'Bienvenue', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserProfile()),
                  );
                },
                child: Column(
                  children: [
                    Icon(Icons.person, size: 80, color: Colors.deepPurple),
                    SizedBox(height: 10),
                    Text('Mon Profil', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(100), // Ajustez le rayon selon vos préférences
                child: Image.asset(
                  'assets/images/dalle_trelltech.webp',
                  width: 200, // Ajustez selon vos besoins
                  height: 200, // Ajustez selon vos besoins
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WorkflowsPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  textStyle: TextStyle(fontSize: 22),
                ),
                child: Text('Mes workspaces', style: TextStyle(color: Colors.black)),
              ),
              if (isLoading) CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
