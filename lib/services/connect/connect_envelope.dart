// Adapted from Ariami (https://github.com/picccassso/Ariami),
// ariami_core/lib/models/websocket_models.dart, MIT License,
// Copyright (c) 2026 Alex (aka Picasso). See THIRD_PARTY_NOTICES.md.

/// The JSON envelope every Connect WebSocket frame uses, and the few
/// transport messages that are not part of the Connect protocol itself.
library;

class WsMessageType {
  static const String identify = 'identify';
  static const String ping = 'ping';
  static const String pong = 'pong';
}

class WsMessage {
  final String type;
  final Map<String, dynamic>? data;
  final String timestamp;

  WsMessage({required this.type, this.data, String? timestamp})
    : timestamp = timestamp ?? DateTime.now().toIso8601String();

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    return WsMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'data': data, 'timestamp': timestamp};
  }
}

class PingMessage extends WsMessage {
  PingMessage() : super(type: WsMessageType.ping);
}

class PongMessage extends WsMessage {
  PongMessage() : super(type: WsMessageType.pong);
}
