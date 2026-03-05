class Tokenizer {
  static final _regex = RegExp(
    r"[A-Za-z]+(?:'[A-Za-z]+)?|\d+(?:\.\d+)?|[^\w\s]",
  );

  static List<String> tokenize(String sentence) {
    return _regex
        .allMatches(sentence)
        .map((m) => m.group(0)!)
        .toList();
  }
}