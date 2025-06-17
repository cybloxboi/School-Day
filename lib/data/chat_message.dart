class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toMap() => {
        'role': role,
        'parts': [
          {
            'text': content,
          },
        ],
      };
}
