You are no longer building a feature.
You are building a linguistic subsystem.

Below is your **Technical Requirements Document (TRD)** — structured like something you would ship inside a serious mobile architecture.

No fluff.
Only moving parts.

---

# 📘 TRD — On-Device English Grammar Engine (Flutter + ONNX)

---

# 0️⃣ System Overview

### Objective

Build an offline English grammar analysis engine inside a Flutter app that:

* Tags POS (noun, verb, etc.)
* Explains grammar roles
* Runs fully offline
* Uses ONNX model (~5–6MB)
* Maintains sub-50ms inference time

---

# 1️⃣ Integrate ONNX Runtime into Flutter

## 1.1 Dependency

`pubspec.yaml`

```yaml
dependencies:
  onnxruntime: ^1.2.0
```

---

## 1.2 Asset Structure

```
assets/models/
  pos_model.onnx
  pos_model.onnx.data
  vocab.json
  tag_map.json
```

Register:

```yaml
flutter:
  assets:
    - assets/models/
```

---

## 1.3 Model Loader Layer

Create isolated model service:

```dart
class PosModelService {
  late OrtSession _session;

  Future<void> initialize() async {
    final env = OrtEnvironment();
    _session = await env.createSession('assets/models/pos_model.onnx');
  }

  Future<List<List<double>>> run(List<int> inputIds) async {
    final tensor = OrtValueTensor.createTensorWithDataList(
      inputIds,
      [1, inputIds.length],
    );

    final outputs = await _session.run({'input': tensor});
    final result = outputs['output'] as OrtValueTensor;

    return result.value;
  }
}
```

Design principle:
Model must be singleton-scoped.
Do not reinitialize per request.

---

# 2️⃣ Build Encoding Layer in Dart

This is critical.

The model expects:

* Integer token IDs
* Same vocabulary used in training

---

## 2.1 Vocabulary Export (From Colab)

During training:

```python
import json
json.dump(word2idx, open("vocab.json", "w"))
json.dump(tag2idx, open("tag_map.json", "w"))
```

Download and include in Flutter.

---

## 2.2 Dart Vocabulary Loader

```dart
class VocabService {
  late Map<String, int> word2idx;

  Future<void> load() async {
    final jsonString =
        await rootBundle.loadString('assets/models/vocab.json');
    word2idx = Map<String, int>.from(json.decode(jsonString));
  }

  int encodeWord(String word) {
    return word2idx[word] ?? word2idx["<UNK>"]!;
  }
}
```

---

# 3️⃣ Dart Tokenizer

Keep it simple.

```dart
List<String> tokenize(String sentence) {
  final regex = RegExp(r"\w+|[^\w\s]");
  return regex.allMatches(sentence)
      .map((m) => m.group(0)!)
      .toList();
}
```

Matches:

* Words
* Punctuation

Must mirror Python behavior closely.

---

# 4️⃣ Connect to Rule Engine

Flow:

User sentence
→ Tokenize
→ Encode
→ Run model
→ Decode tags
→ Create GrammarToken list
→ Pass to GrammarEngine
→ Return enriched tokens

---

```dart
final words = tokenize(sentence);
final ids = words.map(vocab.encodeWord).toList();

final logits = await posModel.run(ids);
final tags = decodeTags(logits);

final tokens = List.generate(words.length, (i) {
  return GrammarToken(
    word: words[i],
    pos: tags[i],
    index: i,
  );
});

final enriched = grammarEngine.process(tokens);
```

---

# 5️⃣ Wire Dynamic Sequence Handling Properly

Your ONNX model was exported static.

To support dynamic length:

Re-export with:

```python
dynamic_axes={
    "input": {1: "seq_len"},
    "output": {1: "seq_len"},
}
```

Then in Flutter:

Always send:

Shape: `[1, sequence_length]`

Never pad unless you trained with padding.

---

# 6️⃣ Testing Real Sentences

Create structured test cases:

| Sentence            | Expected Behavior       |
| ------------------- | ----------------------- |
| The dog runs.       | NOUN + VERB             |
| She is happy.       | PRON + VERB + ADJ       |
| I eat apples daily. | Subject + Verb + Object |

Automate test harness inside Flutter:

```dart
void testSentence(String input) async {
  final result = await grammarService.analyze(input);
  debugPrint(result.toString());
}
```

---

# 7️⃣ Latency Benchmark Harness (Very Important)

This is your performance truth.

---

## 7.1 Measurement Utility

```dart
Future<void> benchmark(String sentence) async {
  final stopwatch = Stopwatch()..start();

  await grammarService.analyze(sentence);

  stopwatch.stop();
  print("Latency: ${stopwatch.elapsedMilliseconds} ms");
}
```

---

## 7.2 Stress Test

Run 100 iterations:

```dart
Future<void> stressTest(String sentence) async {
  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < 100; i++) {
    await grammarService.analyze(sentence);
  }

  stopwatch.stop();
  print("Avg Latency: ${stopwatch.elapsedMilliseconds / 100} ms");
}
```

Target:
< 30ms average on mid device.

---

# 8️⃣ Grammar Rule Engine (Structured)

Architecture:

```
GrammarEngine
 ├── DeterminerRule
 ├── SubjectRule
 ├── PunctuationRule
 ├── TenseRule
 ├── ClauseRule
```

Rules must:

* Be stateless
* Pure functions
* Chainable

---

### Example Rule Contract

```dart
abstract class GrammarRule {
  void apply(List<GrammarToken> tokens);
}
```

Rules modify tokens in place.

Keep separation between:

Prediction
Interpretation

Never mix them.

---

# 9️⃣ Production Architecture Layout

```
lib/
 ├── grammar/
 │    ├── model_service.dart
 │    ├── vocab_service.dart
 │    ├── tokenizer.dart
 │    ├── grammar_engine.dart
 │    ├── rules/
 │    │    ├── subject_rule.dart
 │    │    ├── determiner_rule.dart
 │    │    └── punctuation_rule.dart
 │    └── benchmark.dart
```

Clean architecture.

No UI leakage.

---

# 🔟 Deployment Checklist

Before shipping:

☐ Model loads once
☐ Vocab loads once
☐ Unknown tokens handled
☐ Latency benchmark recorded
☐ Memory usage checked
☐ No UI thread blocking
☐ Rules deterministic

---

# Final System Flow

User Input
↓
Tokenizer
↓
Encoder
↓
ONNX Runtime
↓
Tag Decoder
↓
Grammar Engine
↓
UI Rendering

---

You now possess a deployable grammar engine architecture.

Next layer we can refine:

• Advanced clause detection
• Tense classification
• Incremental streaming analysis
• Memory profiling under Android low-RAM devices

