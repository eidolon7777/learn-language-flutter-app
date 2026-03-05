import 'dart:developer';

import 'package:flutter/material.dart';
import '../data/model_service.dart';
import '../data/vocab_service.dart';
import '../domain/grammar_engine.dart';
import '../domain/grammar_token.dart';
import '../domain/rules/punctuation_rule.dart';

class GrammarAnalysisPage extends StatefulWidget {
  const GrammarAnalysisPage({super.key});

  @override
  State<GrammarAnalysisPage> createState() => _GrammarAnalysisPageState();
}

class _GrammarAnalysisPageState extends State<GrammarAnalysisPage> {
  final TextEditingController _controller = TextEditingController();
  List<GrammarToken> _tokens = [];
  bool _isLoading = true;
  String? _error;

  late GrammarEngine _engine;
  final _modelService = PosModelService();
  final _vocabService = VocabService();

  @override
  void initState() {
    super.initState();
    _initializeEngine();
  }

  Future<void> _initializeEngine() async {
    try {
      await Future.wait([
        _modelService.initialize(),
        _vocabService.load(),
      ]);
      // Pass rules
      _engine = GrammarEngine(_modelService, _vocabService, [
        PunctuationRule(),
      ]); 
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to initialize engine: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _analyze() async {
    if (_controller.text.isEmpty) return;
    
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    setState(() {
      _isLoading = true; 
      _error = null;
    });

    try {
      // Benchmark start
      final stopwatch = Stopwatch()..start();
      
      final tokens = await _engine.analyze(_controller.text);
      
      stopwatch.stop();
      print("Inference time: ${stopwatch.elapsedMilliseconds} ms");

      if (mounted) {
        setState(() {
          _tokens = tokens;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Analysis failed: $e";
          log("Error details: $e");
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(title: const Text("Grammar Analysis")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            TextField(
              controller: _controller,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                labelText: "Enter sentence (e.g., The dog runs.)",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _isLoading ? null : _analyze,
                ),
              ),
              onSubmitted: (_) => _analyze(),
            ),
            const SizedBox(height: 20),
            if (_isLoading) 
              const Center(child: CircularProgressIndicator())
            else if (_tokens.isNotEmpty)
              Expanded(
                child: ListView.separated(
                  itemCount: _tokens.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final token = _tokens[index];
                    return ListTile(
                      title: Text(token.word, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(token.pos, style: const TextStyle(color: Colors.blue)),
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[200],
                        child: Text("${token.index + 1}"),
                      ),
                    );
                  },
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text("Enter a sentence to analyze grammar."),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _modelService.dispose();
    _controller.dispose();
    super.dispose();
  }
}
