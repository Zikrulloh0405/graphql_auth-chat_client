import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GraphQLService {
  static WebSocketLink websocketLink = WebSocketLink(
    'ws://localhost:4000/graphql',
    config: SocketClientConfig(
      autoReconnect: true,
      inactivityTimeout: const Duration(seconds: 30),
      initialPayload: () async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token");
        return {"authorization": "Bearer $token"}; // Match server key
      },
    ),
  );

  static Future<GraphQLClient> getAuthenticatedClient() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString("token");

    if (token == null) {
      throw Exception("Authentication token is missing or invalid.");
    }

    print("Using token: $token");
    final AuthLink authLink = AuthLink(getToken: () async => 'Bearer $token');
    final Link link = authLink.concat(websocketLink);

    return GraphQLClient(cache: GraphQLCache(), link: link);
  }

  static Future<Map<String, dynamic>> authenticateUser(
      String email,
      String password,
      ) async {
    print("Starting authentication for user: $email");
    final HttpLink httpLink = HttpLink("http://localhost:4000/graphql");

    String mutation = """
      mutation {
        login(email: "$email", password: "$password") {
          userID
          email
          token
        }
      }
    """;

    final GraphQLClient client = GraphQLClient(
      cache: GraphQLCache(),
      link: httpLink,
    );
    final MutationOptions options = MutationOptions(document: gql(mutation));
    final QueryResult result = await client.mutate(options);

    if (result.hasException) {
      print("❌ Authentication failed: ${result.exception.toString()}");
      return {"error": "❌ Authentication Failed"};
    } else {
      final String token = result.data?["login"]["token"];
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", token);

      print("✅ Authentication successful for user: $email");
      return {
        "token": token,
        "userID": result.data?["login"]["userID"],
        "email": result.data?["login"]["email"],
      };
    }
  }

  static Stream<List<Map<String, dynamic>>> subscribeMessages() async* {
    const String subscription = r'''
    subscription {
      msgs {
        message
        senderID
        senderEmail
        recieverID
        recieverEmail
      }
    }
  ''';

    final GraphQLClient client = await getAuthenticatedClient();
    print("Subscribing to messages...");
    final Stream<QueryResult> result = client.subscribe(
      SubscriptionOptions(document: gql(subscription)),
    );

    List<Map<String, dynamic>> accumulatedMessages = [];
    yield accumulatedMessages; // Yield empty list initially

    await for (var event in result) {
      print("Subscription event received: ${event.data}");
      if (event.hasException) {
        print("Subscription error: ${event.exception.toString()}");
        yield [
          {"error": event.exception.toString()}
        ];
        continue;
      }

      final dynamic msg = event.data?['msgs'];
      if (msg != null) {
        print("New message received: $msg");
        final newMessage = {
          "message": msg["message"],
          "senderID": msg["senderID"],
          "senderEmail": msg["senderEmail"],
          "recieverID": msg["recieverID"],
          "recieverEmail": msg["recieverEmail"],
        };
        accumulatedMessages.add(newMessage);
        yield List.from(accumulatedMessages);
      } else {
        print("No 'msgs' data in event: ${event.data}");
      }
    }
  }

  static Future<void> sendMessage(String message) async {
    try {
      const String mutation = """
        mutation SendMessage(\$message: String!, \$senderID: ID!, \$recieverID: ID!) {
          sendMessage(message: \$message, senderID: \$senderID, recieverID: \$recieverID) {
            message
            senderID
            senderEmail
            recieverID
            recieverEmail
          }
        }
      """;

      final client = await getAuthenticatedClient();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("token");

      print("Sending message: $message");
      print("Using token: $token");

      final result = await client.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {"senderID": "1", "message": message, "recieverID": "2"},
        ),
      );

      if (result.hasException) {
        throw Exception(result.exception.toString());
      }

      print("✅ Message sent: $message");
    } catch (e) {
      print("❌ Send message error: $e");
      throw Exception("Send message error: $e");
    }
  }
}