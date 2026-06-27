import 'dart:io';

void main() async {
  final raw = await File('assets/corpus/shakespeare.txt').readAsString();
  const startMark = "*** START OF THE PROJECT GUTENBERG EBOOK";
  const endMark = "*** END OF THE PROJECT GUTENBERG EBOOK";
  
  int startIndex = raw.indexOf(startMark);
  if (startIndex != -1) {
    startIndex = raw.indexOf('\n', startIndex) + 1;
    startIndex = raw.indexOf('\n', startIndex) + 1;
  } else {
    startIndex = 0;
  }
  
  int endIndex = raw.indexOf(endMark);
  if (endIndex == -1) endIndex = raw.length;
  
  final clean = raw.substring(startIndex, endIndex).trim();
  print("Cleaned Corpus Sample (first 500 chars):");
  print(clean.substring(0, 500));
}
