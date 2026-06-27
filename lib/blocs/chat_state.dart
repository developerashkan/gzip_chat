part of 'chat_bloc.dart';

enum ChatStatus { initial, loading, ready, error }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<ChatMessage> messages;
  final bool isGenerating;
  final String? error;
  final int beamWidth;
  final int maxTokens;
  final String corpusName;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.isGenerating = false,
    this.error,
    this.beamWidth = 5,
    this.maxTokens = 30,
    this.corpusName = 'Shakespeare\'s Works',
  });

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    bool? isGenerating,
    String? error,
    int? beamWidth,
    int? maxTokens,
    String? corpusName,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error ?? this.error,
      beamWidth: beamWidth ?? this.beamWidth,
      maxTokens: maxTokens ?? this.maxTokens,
      corpusName: corpusName ?? this.corpusName,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    isGenerating,
    error,
    beamWidth,
    maxTokens,
    corpusName,
  ];
}