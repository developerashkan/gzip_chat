import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';

/// GzipLM: A language model based on compression.
class GzipLanguageModel {
  final String corpus;
  final int beamWidth;
  final int maxTokens;

  GzipLanguageModel({
    required String corpus,
    this.beamWidth = 5,
    this.maxTokens = 30, 
  }) : corpus = _clean(corpus);

  /// Removes Project Gutenberg headers, footers, and TOC to ensure pure Shakespeare text.
  static String _clean(String raw) {
    const startMark = "*** START OF THE PROJECT GUTENBERG EBOOK";
    const endMark = "*** END OF THE PROJECT GUTENBERG EBOOK";
    
    int startIndex = raw.indexOf(startMark);
    if (startIndex != -1) {
      final sonnetStart = raw.indexOf('From fairest creatures', startIndex);
      if (sonnetStart != -1) {
        startIndex = sonnetStart;
      } else {
        startIndex = raw.indexOf('\n', startIndex) + 1;
      }
    } else {
      startIndex = 0;
    }
    
    int endIndex = raw.indexOf(endMark);
    if (endIndex == -1) endIndex = raw.length;
    
    return raw.substring(startIndex, endIndex).trim();
  }

  /// Scores a candidate by how much it reduces the total compressed size.
  int _score(String context, String candidate, String relevantCorpus) {
    // We use a specific non-ASCII salt to prevent the LZ77 window from 
    // finding trivial matches in the padding itself.
    const String salt = "\x00\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0B\x0C\x0E\x0F";
    
    final combined = '$relevantCorpus\n$context$candidate$salt';
    final bytes = utf8.encode(combined);
    
    return ZLibCodec(gzip: false, level: 9).encode(bytes).length;
  }

  /// Finds substrings in the corpus that follow the current prompt's tail.
  /// Returns a map of token -> frequency.
  Map<String, int> _getDynamicVocab(String context) {
    final List<String> baseVocab = [
      ' ', 'e', 't', 'a', 'o', 'i', 'n', 's', 'r', 'h', 'l', 'd', 'u', 'm', 'c', 'w', 
      'f', 'g', 'y', 'p', 'b', 'v', 'k', 'x', 'j', 'q', 'z',
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 
      'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
      '.', ',', '!', '?', "'", '"', ':', ';', '-', '(', ')', '\n',
    ];
    
    final Map<String, int> counts = {for (var v in baseVocab) v: 1};

    // Use a multi-length tail search to find relevant continuations
    for (int tailLen in [5, 4, 3]) {
      if (context.length < tailLen) continue;
      final tail = context.substring(context.length - tailLen);
      
      int lastIdx = 0;
      int foundCount = 0;
      while (true) {
        lastIdx = corpus.indexOf(tail, lastIdx);
        if (lastIdx == -1 || lastIdx + tail.length + 5 > corpus.length) break;
        
        for (int i = 1; i <= 5; i++) {
          final next = corpus.substring(lastIdx + tail.length, lastIdx + tail.length + i);
          counts[next] = (counts[next] ?? 0) + (6 - tailLen); // Higher weight for longer tail matches
        }
        
        lastIdx += 1;
        foundCount++;
        if (foundCount > 100) break;
      }
      if (foundCount > 10) break; // If we found enough specific matches, stop searching shorter tails
    }

    return counts;
  }

  Future<({String text, GzipStats stats})> generate(
    String prompt, {
    void Function(String partial)? onToken,
  }) async {
    final stopwatch = Stopwatch()..start();
    final cleanPrompt = prompt.trim();
    if (kDebugMode) {
      print('\n[GzipLM] Starting generation for prompt: "$cleanPrompt"');
    }

    // Move heavy computation to a background isolate
    final result = await compute(_generateInBackground, (
      prompt: cleanPrompt,
      corpus: corpus,
      beamWidth: beamWidth,
      maxTokens: maxTokens,
    ));

    stopwatch.stop();

    // Reconstruct stats with the actual elapsed time from the main thread perspective
    final finalStats = GzipStats(
      beamWidth: beamWidth,
      steps: result.steps,
      compressionRatio: result.compressionRatio,
      candidatesEvaluated: result.candidatesEvaluated,
      elapsed: stopwatch.elapsed,
    );

    // Call onToken once with the full result as we can't stream easily from compute
    // (A full isolate setup with ReceivePort would be needed for true streaming)
    onToken?.call(result.text);

    return (text: result.text, stats: finalStats);
  }

  static ({String text, int steps, double compressionRatio, int candidatesEvaluated}) _generateInBackground(
    ({String prompt, String corpus, int beamWidth, int maxTokens}) args,
  ) {
    final lm = GzipLanguageModel(corpus: args.corpus, beamWidth: args.beamWidth, maxTokens: args.maxTokens);
    final cleanPrompt = args.prompt;

    // Selection of corpus slice
    final words = cleanPrompt.split(' ');
    final lastWord = words.isNotEmpty ? words.last : '';
    int sliceStart = lastWord.length > 2 ? args.corpus.lastIndexOf(lastWord) : -1;
    if (sliceStart == -1) sliceStart = 0;

    final relevantCorpus = args.corpus.length > sliceStart + 15000
        ? args.corpus.substring(sliceStart, sliceStart + 15000)
        : args.corpus.substring(0, args.corpus.length < 15000 ? args.corpus.length : 15000);

    List<({String text, int score, int freq})> beams = [
      (text: '', score: lm._score(cleanPrompt, '', relevantCorpus), freq: 1),
    ];

    int totalCandidates = 0;
    int step = 0;

    for (; step < args.maxTokens; step++) {
      final List<({String text, int score, int freq})> candidates = [];
      final vocabMap = lm._getDynamicVocab(cleanPrompt + beams.first.text);
      final currentVocab = vocabMap.keys.toList();

      for (final beam in beams) {
        for (final token in currentVocab) {
          totalCandidates++;
          final nextText = beam.text + token;
          final nextScore = lm._score(cleanPrompt, nextText, relevantCorpus);
          candidates.add((
            text: nextText,
            score: nextScore,
            freq: vocabMap[token] ?? 1
          ));
        }
      }

      candidates.sort((a, b) {
        final scoreDiff = a.score.compareTo(b.score);
        if (scoreDiff != 0) return scoreDiff;
        return b.freq.compareTo(a.freq);
      });

      final nextBeams = <({String text, int score, int freq})>[];
      final seen = <String>{};
      for (final cand in candidates) {
        if (!seen.contains(cand.text)) {
          seen.add(cand.text);
          nextBeams.add(cand);
        }
        if (nextBeams.length >= args.beamWidth) break;
      }

      beams = nextBeams;
      final bestNew = beams.first.text;

      if (bestNew.endsWith('\n') || (bestNew.length > 40 && bestNew.endsWith('. '))) {
        break;
      }
    }

    final resultText = beams.first.text;
    final finalBytes = utf8.encode('${args.corpus}\n$cleanPrompt$resultText');
    final finalCompressedSize = ZLibCodec(gzip: true, level: 9).encode(finalBytes).length;

    return (
      text: resultText.isEmpty ? '...' : resultText,
      steps: step,
      compressionRatio: finalCompressedSize / finalBytes.length,
      candidatesEvaluated: totalCandidates,
    );
  }
}
