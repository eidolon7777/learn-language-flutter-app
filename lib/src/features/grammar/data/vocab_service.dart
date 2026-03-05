import 'dart:convert';
import 'package:flutter/services.dart';

class VocabService {
  late Map<String, int> word2idx;
  late Map<int, String> idx2tag;

  bool _isInitialized = false;

  Future<void> load() async {
    if (_isInitialized) return;

    try {
      // Load Vocab
      final vocabString = await rootBundle.loadString('assets/models/vocab.json');
      word2idx = Map<String, int>.from(json.decode(vocabString));

      // Load Tag Map
      final tagMapString = await rootBundle.loadString('assets/models/tag_map.json');
      final Map<String, dynamic> tagMap = json.decode(tagMapString);
      
      // Invert tag map for decoding: { "NOUN": 0 } -> { 0: "NOUN" }
      idx2tag = {};
      tagMap.forEach((key, value) {
        if (value is int) {
          idx2tag[value] = key;
        }
      });

      _isInitialized = true;
    } catch (e) {
      print("Error loading vocabulary or tag map: $e");
      // Handle error appropriately, maybe rethrow
    }
  }

  int encodeWord(String word) {
    if (!_isInitialized) return 0;
    // Check exact match first
    if (word2idx.containsKey(word)) {
      return word2idx[word]!;
    }
    // Check lowercase match if not found
    final lower = word.toLowerCase();
    if (word2idx.containsKey(lower)) {
      return word2idx[lower]!;
    }
    // Return UNK
    return word2idx["<UNK>"] ?? 0;
  }

  String decodeTag(int tagId) {
    if (!_isInitialized) return "UNKNOWN";
    return idx2tag[tagId] ?? "UNKNOWN";
  }
}
