import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Models ---
class WordOfDay {
  final String word;
  final String pronunciation;
  final String definition;
  final String quote;

  const WordOfDay({
    required this.word,
    required this.pronunciation,
    required this.definition,
    required this.quote,
  });
}

enum MilestoneStatus { completed, active, locked }

class MilestoneSubItem {
  final String title;
  final MilestoneStatus status;
  final double progress; // 0.0 to 1.0

  const MilestoneSubItem({
    required this.title,
    this.status = MilestoneStatus.locked,
    this.progress = 0.0,
  });
}

class Milestone {
  final String title;
  final String subtitle;
  final MilestoneStatus status;
  final List<MilestoneSubItem> subItems;

  const Milestone({
    required this.title,
    required this.subtitle,
    this.status = MilestoneStatus.locked,
    this.subItems = const [],
  });
}

class JourneyState {
  final WordOfDay wordOfDay;
  final List<Milestone> milestones;

  const JourneyState({
    required this.wordOfDay,
    required this.milestones,
  });
}

// --- ViewModel ---
class JourneyViewModel extends StateNotifier<JourneyState> {
  JourneyViewModel() : super(_initialState());

  static JourneyState _initialState() {
    return const JourneyState(
      wordOfDay: WordOfDay(
        word: 'Resilience',
        pronunciation: '/rɪˈzɪljəns/',
        definition: 'The capacity to recover quickly from difficulties; toughness.',
        quote: '"The human capacity for resilience is quite remarkable."',
      ),
      milestones: [
        Milestone(
          title: 'Foundations',
          subtitle: 'Completed on May 12',
          status: MilestoneStatus.completed,
          subItems: [
            MilestoneSubItem(
              title: 'Core Concepts 1.1',
              status: MilestoneStatus.completed,
              progress: 1.0,
            ),
          ],
        ),
        Milestone(
          title: 'Mental Models',
          subtitle: 'Current Milestone',
          status: MilestoneStatus.active,
          subItems: [
            MilestoneSubItem(
              title: 'First Principles Thinking',
              status: MilestoneStatus.active,
              progress: 0.6,
            ),
            MilestoneSubItem(
              title: 'Probabilistic Thinking',
              status: MilestoneStatus.locked,
            ),
          ],
        ),
        Milestone(
          title: 'Advanced Systems',
          subtitle: 'Locked',
          status: MilestoneStatus.locked,
        ),
        Milestone(
          title: 'Mastery Exam',
          subtitle: 'Locked',
          status: MilestoneStatus.locked,
        ),
      ],
    );
  }
}

final journeyViewModelProvider = StateNotifierProvider<JourneyViewModel, JourneyState>((ref) {
  return JourneyViewModel();
});
