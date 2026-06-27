import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/chat_message.dart';
import '../services/gzip_lm_service.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final _uuid = const Uuid();
  GzipLanguageModel? _lm;
  String _corpus = '';

  ChatBloc() : super(const ChatState()) {
    on<ChatInitialized>(_onInitialized);
    on<ChatMessageSent>(_onMessageSent);
    on<ChatTokenReceived>(_onTokenReceived);
    on<ChatResponseFinished>(_onResponseFinished);
    on<ChatResponseFailed>(_onResponseFailed);
    on<ChatBeamWidthChanged>(_onBeamWidthChanged);
    on<ChatMaxTokensChanged>(_onMaxTokensChanged);
    on<ChatCleared>(_onCleared);
  }

  Future<void> _onInitialized(
      ChatInitialized event,
      Emitter<ChatState> emit,
      ) async {
    emit(state.copyWith(status: ChatStatus.loading));
    try {
      _corpus = await rootBundle.loadString('assets/corpus/shakespeare.txt');
      _buildLM();
      emit(state.copyWith(status: ChatStatus.ready));
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        error: 'Failed to load corpus: $e',
      ));
    }
  }

  void _buildLM() {
    _lm = GzipLanguageModel(
      corpus: _corpus,
      beamWidth: state.beamWidth,
      maxTokens: state.maxTokens,
    );
  }

  Future<void> _onMessageSent(
      ChatMessageSent event,
      Emitter<ChatState> emit,
      ) async {
    if (state.isGenerating || _lm == null) return;

    final userMsg = ChatMessage(
      id: _uuid.v4(),
      content: event.text,
      role: MessageRole.user,
      status: MessageStatus.done,
      timestamp: DateTime.now(),
    );

    final assistantId = _uuid.v4();
    final assistantMsg = ChatMessage(
      id: assistantId,
      content: '',
      role: MessageRole.assistant,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMsg, assistantMsg],
      isGenerating: true,
    ));

    // Build conversation context
    final context = _buildContext(state.messages, event.text);

    try {
      final result = await _lm!.generate(
        context,
        onToken: (token) {
          add(ChatTokenReceived(assistantId, token));
        },
      );
      add(ChatResponseFinished(assistantId, result.stats));
    } catch (e) {
      add(ChatResponseFailed(assistantId, e.toString()));
    }
  }

  String _buildContext(List<ChatMessage> messages, String newUserText) {
    // For zero-weight Gzip modeling, isolation is key.
    // We feed ONLY the current prompt to ensure the compressor 
    // matches purely against the Shakespeare corpus.
    return newUserText;
  }

  void _onTokenReceived(
      ChatTokenReceived event,
      Emitter<ChatState> emit,
      ) {
    final updatedMessages = state.messages.map((msg) {
      if (msg.id == event.messageId) {
        return msg.copyWith(content: msg.content + event.token);
      }
      return msg;
    }).toList();
    emit(state.copyWith(messages: updatedMessages));
  }

  void _onResponseFinished(
      ChatResponseFinished event,
      Emitter<ChatState> emit,
      ) {
    final updatedMessages = state.messages.map((msg) {
      if (msg.id == event.messageId) {
        return msg.copyWith(
          status: MessageStatus.done,
          stats: event.stats,
        );
      }
      return msg;
    }).toList();
    emit(state.copyWith(
      messages: updatedMessages,
      isGenerating: false,
    ));
  }

  void _onResponseFailed(
      ChatResponseFailed event,
      Emitter<ChatState> emit,
      ) {
    final updatedMessages = state.messages.map((msg) {
      if (msg.id == event.messageId) {
        return msg.copyWith(
          content: '[Error: ${event.error}]',
          status: MessageStatus.error,
        );
      }
      return msg;
    }).toList();
    emit(state.copyWith(
      messages: updatedMessages,
      isGenerating: false,
    ));
  }

  void _onBeamWidthChanged(
      ChatBeamWidthChanged event,
      Emitter<ChatState> emit,
      ) {
    emit(state.copyWith(beamWidth: event.beamWidth));
    _buildLM();
  }

  void _onMaxTokensChanged(
      ChatMaxTokensChanged event,
      Emitter<ChatState> emit,
      ) {
    emit(state.copyWith(maxTokens: event.maxTokens));
    _buildLM();
  }

  void _onCleared(ChatCleared event, Emitter<ChatState> emit) {
    emit(state.copyWith(messages: []));
  }
}