class FacebookMessage {
  final String id;
  final String messageText;
  final DateTime createdTime;
  final String senderId;
  final String conversationId;

  FacebookMessage({
    required this.id,
    required this.messageText,
    required this.createdTime,
    required this.senderId,
    required this.conversationId,
  });

  factory FacebookMessage.fromJson(
    Map<String, dynamic> json,
    String conversationId,
  ) {
    return FacebookMessage(
      id: json['id'] ?? '',
      messageText: json['message'] ?? '',
      createdTime: DateTime.parse(json['created_time'] ?? ''),
      senderId: json['from']?['id'] ?? '',
      conversationId: conversationId,
    );
  }
}
