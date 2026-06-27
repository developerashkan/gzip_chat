part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatInitialized extends ChatEvent {
  const ChatInitialized();
}

class ChatMessageSent extends ChatEvent {
  final String text;
  const ChatMessageSent(this.text);

  @override
  List<Object?> get props => [text];
}

class ChatTokenReceived extends ChatEvent {
  final String messageId;
  final String token;
  const ChatTokenReceived(this.messageId, this.token);

  @override
  List<Object?> get props => [messageId, token];
}

class ChatResponseFinished extends ChatEvent {
  final String messageId;
  final GzipStats stats;
  const ChatResponseFinished(this.messageId, this.stats);

  @override
  List<Object?> get props => [messageId, stats];
}

class ChatResponseFailed extends ChatEvent {
  final String messageId;
  final String error;
  const ChatResponseFailed(this.messageId, this.error);

  @override
  List<Object?> get props => [messageId, error];
}

class ChatBeamWidthChanged extends ChatEvent {
  final int beamWidth;
  const ChatBeamWidthChanged(this.beamWidth);

  @override
  List<Object?> get props => [beamWidth];
}

class ChatMaxTokensChanged extends ChatEvent {
  final int maxTokens;
  const ChatMaxTokensChanged(this.maxTokens);

  @override
  List<Object?> get props => [maxTokens];
}

class ChatCleared extends ChatEvent {
  const ChatCleared();
}