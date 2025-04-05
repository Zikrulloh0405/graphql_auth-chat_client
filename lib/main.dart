import 'package:client/pages/home_page.dart';
import 'package:client/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'graphql/config.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // String? token = prefs.getString("token");
    bool isLoggedIn = token != null;

    runApp(MyApp(isLoggedIn: isLoggedIn,
        // token: token
    ));
  }

  class MyApp extends StatelessWidget {
    final bool isLoggedIn;
    // final String? token;
    const MyApp({super.key, required this.isLoggedIn,
      // this.token
    });

    @override
    Widget build(BuildContext context) {
      return GraphQLProvider(
        client: GraphQLConfig.client,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: "GraphQL Auth",
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: GoogleFonts.poppinsTextTheme(),
          ),
          home: isLoggedIn ? HomePage() : LoginPage(),
        ),
      );
    }
  }