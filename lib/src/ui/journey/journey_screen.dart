import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learn_language/src/ui/core/widgets/staggered_item.dart';
import 'package:learn_language/src/ui/settings/settings_screen.dart';
import 'view_model/journey_view_model.dart';
import 'widgets/journey_header.dart';
import 'widgets/timeline_item.dart';
import 'widgets/word_of_day_card.dart';

class JourneyScreen extends ConsumerWidget {
  const JourneyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(journeyViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            const JourneyHeader(
              title: 'Your Journey',
              subtitle: 'Keep climbing, you\'re doing great.',
            ),
            
            // Scrollable Content
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // Word of the Day
                  SliverToBoxAdapter(
                    child: StaggeredItem(
                      index: 0,
                      child: WordOfTheDayCard(
                        word: state.wordOfDay.word,
                        pronunciation: state.wordOfDay.pronunciation,
                        definition: state.wordOfDay.definition,
                        quote: state.wordOfDay.quote,
                        onSave: () {}, // Implement save logic
                        onShare: () {}, // Implement share logic
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),

                  // Timeline
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return StaggeredItem(
                          index: index + 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: TimelineItem(
                              milestone: state.milestones[index],
                              isLast: index == state.milestones.length - 1,
                              index: index,
                            ),
                          ),
                        );
                      },
                      childCount: state.milestones.length,
                    ),
                  ),

                  // Footer Link
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                          },
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text('View detailed curriculum'),
                          iconAlignment: IconAlignment.end,
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            textStyle: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
