import 'dart:convert';
import 'dart:io';

void main() async {
  final corpusFile = File('assets/corpus/shakespeare.txt');
  final fullCorpus = await corpusFile.readAsString();
  
  final startMark = "*** START OF THE PROJECT GUTENBERG EBOOK";
  final startIndex = fullCorpus.indexOf(startMark);
  final cleanCorpus = startIndex != -1 ? fullCorpus.substring(startIndex) : fullCorpus;

  final prompt = "To be, or not to ";
  
  void testCandidate(String cand) {
    const String padding = " !@#\$%^&*()_+1234567890qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM";
    
    // Test with a VERY SMALL slice of corpus to see if sensitivity increases
    final tinyCorpus = cleanCorpus.substring(cleanCorpus.length - 2000);
    final combined = '$tinyCorpus\n$prompt$cand$padding';
    final bytes = utf8.encode(combined);
    final size = ZLibCodec(gzip: true, level: 9).encode(bytes).length;
    print("Tiny | Cand: '$cand' | PaddedSize: $size");
  }

  print("Testing prompt: '$prompt'");
  testCandidate("be");
  testCandidate("ze");
  testCandidate("me");
}
