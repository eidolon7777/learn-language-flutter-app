import '../grammar_token.dart';
import 'grammar_rule.dart';

class PunctuationRule implements GrammarRule {
  @override
  void apply(List<GrammarToken> tokens) {
    for (var token in tokens) {
      if (RegExp(r'[.!?,\":;]').hasMatch(token.word)) {
        token.pos = "PUNCT";
      }
    }
  }
}
