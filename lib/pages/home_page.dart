import 'package:client/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../graphql/graphql_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.email, required this.userID,});

  final String email;
  final String userID;


  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List messages = [];
  String errorMessage = "";
  bool _isLoading = false;

  Future<void> fetchMessages() async {
    setState(() {
      _isLoading = true;
      errorMessage = ""; // Clear previous errors
    });

    final result = await GraphQLService.getMessagesByID(userID: widget.userID);

    setState(() {
      _isLoading = false;
      if (result.containsKey("error")) {
        errorMessage = result["error"];
      } else {
        messages = result["data"];
      }
    });
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
       title: Text(
          widget.email,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
       actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.grey[800]),
            onPressed: logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchMessages, // Pull-to-refresh
        color: Colors.blueAccent,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : errorMessage.isNotEmpty
            ? Center(
          child: Text(
            errorMessage,
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        )
            : messages.isEmpty
            ? LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                alignment: Alignment.center,
                child: Text("No books available. Pull down to refresh.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ),
            );
          },
        )
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
          itemBuilder: (context, index) {
            final book = messages[index];
            return Card(
              elevation: 2,
              shadowColor: Colors.grey[50],
              surfaceTintColor: Colors.white,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent.withOpacity(0.8),
                  child: Icon(Icons.book, color: Colors.white),
                ),
                title: Text(
                  book["message"],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                ),
                subtitle: Text(
                  "Author: ${book["senderID"]}",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
                onTap: () {
                  // Implement book details navigation here
                  print("Tapped on book: ${book["message"]}");
                },
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchMessages,
        tooltip: 'Refresh Books',
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}