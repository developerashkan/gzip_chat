import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment:
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildLabel(isUser),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) _buildAvatar(),
              if (!isUser) const SizedBox(width: 8),
              Flexible(child: _buildBubble(isUser)),
              if (isUser) const SizedBox(width: 8),
              if (isUser) _buildUserAvatar(),
            ],
          ),
          if (message.stats != null && !isUser) ...[
            const SizedBox(height: 6),
            _buildStats(message.stats!),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLabel(bool isUser) {
    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 0 : 44,
        right: isUser ? 44 : 0,
      ),
      child: Text(
        isUser ? 'You' : 'gzip·lm',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          color: AppTheme.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.accentDim,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
      ),
      child: const Center(
        child: Text('⚙', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppTheme.userBubble,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.inputBorder),
      ),
      child: const Center(
        child: Icon(Icons.person, size: 18, color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildBubble(bool isUser) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isUser ? AppTheme.userBubble : AppTheme.aiBubble,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
        border: Border.all(
          color: isUser
              ? AppTheme.inputBorder
              : AppTheme.accent.withOpacity(0.15),
        ),
      ),
      child: _buildContent(isUser),
    );
  }

  Widget _buildContent(bool isUser) {
    if (message.status == MessageStatus.sending && message.content.isEmpty) {
      return _buildTypingIndicator();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.content.isEmpty ? '...' : message.content,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: message.status == MessageStatus.error
                ? AppTheme.error
                : AppTheme.textPrimary,
            height: 1.5,
          ),
        ),
        if (message.status == MessageStatus.sending &&
            message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _buildCursor(),
          ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: _DotPulse(delay: Duration(milliseconds: i * 200)),
        );
      }),
    );
  }

  Widget _buildCursor() {
    return Container(
      width: 2,
      height: 14,
      decoration: BoxDecoration(
        color: AppTheme.accent,
        borderRadius: BorderRadius.circular(1),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(duration: 400.ms)
        .then()
        .fadeOut(duration: 400.ms);
  }

  Widget _buildStats(GzipStats stats) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statChip(
              Icons.compress,
              'ratio ${stats.compressionRatio.toStringAsFixed(3)}',
            ),
            const SizedBox(width: 8),
            _statChip(
              Icons.radar,
              'beam ${stats.beamWidth}',
            ),
            const SizedBox(width: 8),
            _statChip(
              Icons.timer_outlined,
              '${stats.elapsed.inMilliseconds}ms',
            ),
            const SizedBox(width: 8),
            _statChip(
              Icons.calculate_outlined,
              '${stats.candidatesEvaluated} evals',
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AppTheme.accent.withOpacity(0.7)),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _DotPulse extends StatelessWidget {
  final Duration delay;

  const _DotPulse({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: AppTheme.accent,
        shape: BoxShape.circle,
      ),
    )
        .animate(
      onPlay: (c) => c.repeat(),
      delay: delay,
    )
        .scaleXY(begin: 0.5, end: 1.0, duration: 500.ms, curve: Curves.easeInOut)
        .then()
        .scaleXY(begin: 1.0, end: 0.5, duration: 500.ms, curve: Curves.easeInOut);
  }
}