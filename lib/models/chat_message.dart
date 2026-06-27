import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

enum MessageStatus { sending, done, error }

class ChatMessage extends Equatable {
  final String id;
  final String content;
  final MessageRole role;
  final MessageStatus status;
  final DateTime timestamp;
  final GzipStats? stats;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.status,
    required this.timestamp,
    this.stats,
  });

  ChatMessage copyWith({
    String? content,
    MessageStatus? status,
    GzipStats? stats,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      role: role,
      status: status ?? this.status,
      timestamp: timestamp,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props => [id, content, role, status, timestamp, stats];
}

class GzipStats extends Equatable {
  final int beamWidth;
  final int steps;
  final double compressionRatio;
  final int candidatesEvaluated;
  final Duration elapsed;

  const GzipStats({
    required this.beamWidth,
    required this.steps,
    required this.compressionRatio,
    required this.candidatesEvaluated,
    required this.elapsed,
  });

  @override
  List<Object?> get props => [
    beamWidth,
    steps,
    compressionRatio,
    candidatesEvaluated,
    elapsed,
  ];
}