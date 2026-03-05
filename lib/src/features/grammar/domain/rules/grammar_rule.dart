import '../grammar_token.dart';

abstract class GrammarRule {
  void apply(List<GrammarToken> tokens);
}
