class GrammarToken {
  final String word;
  String pos; // Mutable to allow rules to update it
  final int index;

  GrammarToken({
    required this.word,
    required this.pos,
    required this.index,
  });

  @override
  String toString() => 'GrammarToken(word: $word, pos: $pos, index: $index)';
}
