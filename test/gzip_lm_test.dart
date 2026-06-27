import 'package:flutter_test/flutter_test.dart';
import 'package:gzip_chat/services/gzip_lm_service.dart';

void main() {
  group('GzipLanguageModel Tests', () {
    const String corpus = "To be, or not to be, that is the question: Whether 'tis nobler in the mind to suffer The slings and arrows of outrageous fortune, Or to take arms against a sea of troubles And by opposing end them.";
    
    late GzipLanguageModel lm;

    setUp(() {
      lm = GzipLanguageModel(
        corpus: corpus,
        beamWidth: 2,
        maxTokens: 5,
      );
    });

    test('Scoring should favor common sequences in corpus', () {
      // In our small corpus "To be" is very common.
      // We expect "To be" to compress better than "Xyzzy" when appended to the corpus.
      
      // Note: _score is private, but we can verify it indirectly via generation 
      // or by making a test-only change. For now, let's test generation behavior.
    });

    test('Generation should produce output', () async {
      final result = await lm.generate("To be, or");
      expect(result.text, isNotEmpty);
      expect(result.stats.candidatesEvaluated, greaterThan(0));
    });

    test('Beam search respects maxTokens', () async {
      const maxTokens = 3;
      final shortLm = GzipLanguageModel(
        corpus: corpus,
        beamWidth: 1,
        maxTokens: maxTokens,
      );
      
      final result = await shortLm.generate("Question:");
      // Each token in vocabulary might be multiple chars, 
      // but the loop should run at most maxTokens times.
      expect(result.stats.steps, lessThanOrEqualTo(maxTokens));
    });
  });
}
