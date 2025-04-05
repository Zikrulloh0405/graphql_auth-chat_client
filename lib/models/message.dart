// dart
class Message {
  final String message;
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String receiverEmail;

  Message({
    required this.message,
    required this.senderID,
    required this.senderEmail,
    required this.receiverID,
    required this.receiverEmail,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      message: json['message'],
      senderID: json['senderID'],
      senderEmail: json['senderEmail'],
      receiverID: json['receiverID'],
      receiverEmail: json['receiverEmail'],
    );
  }
}