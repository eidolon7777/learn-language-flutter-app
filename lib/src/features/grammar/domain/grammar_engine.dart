import 'dart:developer' as developer;
import 'package:learn_language/src/features/grammar/data/model_service.dart';
import 'package:learn_language/src/features/grammar/data/vocab_service.dart';
import 'tokenizer.dart';
import 'grammar_token.dart';
import 'rules/grammar_rule.dart';

class GrammarEngine {
  final PosModelService _modelService;
  final VocabService _vocabService;
  final List<GrammarRule> _rules;

  GrammarEngine(this._modelService, this._vocabService, this._rules);

  Future<List<GrammarToken>> analyze(String sentence) async {
    developer.log('[DEBUG] [GrammarEngine] : analyze called with sentence: "$sentence"');
    
    // 1. Tokenize
    final words = Tokenizer.tokenize(sentence);
    developer.log('[DEBUG] [GrammarEngine] : Tokenized words: $words');
    
    if (words.isEmpty) {
      developer.log('[DEBUG] [GrammarEngine] : No words found, returning empty list');
      return [];
    }

    // 2. Encode
    final inputIds = words.map((w) => _vocabService.encodeWord(w)).toList();
    developer.log('[DEBUG] [GrammarEngine] : Encoded inputIds: $inputIds');

    // 3. Run Model
    // Returns [seq_len, num_tags]
    developer.log('[DEBUG] [GrammarEngine] : Calling model service...');
    final logits = await _modelService.run(inputIds);
    developer.log('[DEBUG] [GrammarEngine] : Model returned logits with length: ${logits.length}');
    if (logits.isNotEmpty) {
      developer.log('[DEBUG] [GrammarEngine] : Logits[0] length (tags count): ${logits[0].length}');
    }
    
    // 4. Decode Tags
    final tags = _decodeTags(logits);
    developer.log('[DEBUG] [GrammarEngine] : Decoded tags: $tags');

    // 5. Create Tokens
    // Ensure tags length matches words length. 
    // ONNX might return fixed length or padding if not dynamic.
    // But we used dynamic axes.
    // If mismatch, truncate or pad? Truncate to min length.
    final len = words.length < tags.length ? words.length : tags.length;
    
    final tokens = List.generate(len, (i) {
      return GrammarToken(
        word: words[i],
        pos: tags[i],
        index: i,
      );
    });
    developer.log('[DEBUG] [GrammarEngine] : Created ${tokens.length} tokens');

    // 6. Apply Rules
    developer.log('[DEBUG] [GrammarEngine] : Applying rules...');
    for (final rule in _rules) {
      rule.apply(tokens);
    }
    developer.log('[DEBUG] [GrammarEngine] : Analysis complete.');

    return tokens;
  }

  List<String> _decodeTags(List<List<double>> logits) {
    return logits.map((tokenLogits) {
      if (tokenLogits.isEmpty) return "UNKNOWN";
      
      // Find argmax
      int maxIdx = 0;
      double maxVal = tokenLogits[0];
      for (int i = 1; i < tokenLogits.length; i++) {
        if (tokenLogits[i] > maxVal) {
          maxVal = tokenLogits[i];
          maxIdx = i;
        }
      }
      return _vocabService.decodeTag(maxIdx);
    }).toList();
  }
}
