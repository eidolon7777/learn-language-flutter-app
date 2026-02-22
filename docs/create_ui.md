# Rules for Flutter Screen Architecture

---

## Rule 1: Folder Structure
```
ALWAYS create screens inside src/ui/ with this EXACT structure:

src/ui/<feature_name>/
├── widgets/          → All sub-widgets (child components)
├── view_model/       → All view models for this feature
└── <feature>_screen.dart  → Parent widget (ONLY assembles children)

❌ WRONG:
src/ui/home_screen.dart  → Never put screen directly in ui/

✅ CORRECT:
src/ui/home/
├── widgets/
├── view_model/
└── home_screen.dart
```

---

## Rule 2: Parent Widget Rules
```
The parent screen file MUST follow these rules:
1. It ONLY composes child widgets - NO business logic
2. It MUST be a ConsumerWidget (Riverpod) or StatelessWidget
3. It should NEVER rebuild itself unnecessarily
4. It should NEVER contain styling, padding or UI details

❌ WRONG - Parent doing too much:
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ❌ Direct UI code in parent
          Container(
            padding: EdgeInsets.all(16),
            child: Text('Hello User',
              style: TextStyle(fontSize: 24),
            ),
          ),
          // ❌ Logic in parent
          if(isLoading) 
            CircularProgressIndicator()
          else
            ListView.builder(...)
        ],
      ),
    );
  }
}

✅ CORRECT - Parent only assembles:
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          HomeHeader(),   // ← Just references
          HomeBody(),     // ← child widgets
          HomeFooter(),   // ← nothing else
        ],
      ),
    );
  }
}
```

---

## Rule 3: Child Widget Rules
```
Every child widget MUST follow these rules:
1. Single Responsibility - ONE widget, ONE job
2. MUST accept properties via constructor
3. MUST have required/optional parameters defined
4. MUST be small and focused
5. Text data is ALWAYS a required parameter - NEVER hardcoded
6. Padding/spacing is ALWAYS a parameter with a default value

❌ WRONG:
class HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('Welcome Back!'); // ❌ Hardcoded text
  }
}

✅ CORRECT:
class HomeHeader extends StatelessWidget {
  final String title;           // ✅ Required - text is mandatory
  final String? subtitle;       // ✅ Optional
  final EdgeInsets padding;     // ✅ Has default value
  final VoidCallback? onTap;    // ✅ Optional callback

  const HomeHeader({
    super.key,
    required this.title,        // ✅ Text is always required
    this.subtitle,
    this.padding = const EdgeInsets.all(16), // ✅ Default padding
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(title),
    );
  }
}
```

---

## Rule 4: Light/Dark Mode Rules
```
ALWAYS use Theme.of(context) or ColorScheme - NEVER hardcode colors

❌ WRONG:
Container(
  color: Colors.white,          // ❌ Breaks dark mode
  child: Text(
    'Hello',
    style: TextStyle(
      color: Colors.black,      // ❌ Breaks dark mode
      fontSize: 16,
    ),
  ),
)

✅ CORRECT:
Container(
  color: Theme.of(context).colorScheme.surface,     // ✅ Adapts to mode
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.bodyMedium,  // ✅ Adapts to mode
  ),
)

// ─── Color Usage Rules ───────────────────────────────────────
// Backgrounds  → colorScheme.surface / colorScheme.background
// Primary UI   → colorScheme.primary
// Text         → colorScheme.onSurface / colorScheme.onPrimary
// Errors       → colorScheme.error
// Cards        → colorScheme.surfaceVariant
```

---

## Rule 5: Stagger Animation Rules
```
EVERY list/grid of items MUST have staggered animation.
Reuse the SAME stagger component everywhere.

// ─── Reusable Stagger Widget (create ONCE, reuse everywhere) ─
class StaggeredItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration delay;

  const StaggeredItem({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(
        milliseconds: 300 + (index * delay.inMilliseconds),
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ─── Usage ───────────────────────────────────────────────────
// ✅ CORRECT - Reusing stagger component
ListView.builder(
  itemBuilder: (context, index) {
    return StaggeredItem(    // ← Reuse everywhere
      index: index,
      child: BookingCard(    // ← Your actual widget
        booking: bookings[index],
      ),
    );
  },
)
```

---

## Rule 6: Component Reuse Rules
```
BEFORE creating a new widget, CHECK if one exists.
NEVER duplicate widgets.

// ─── Shared components live here ─────────────────────────────
src/ui/core/widgets/
├── app_button.dart          → Used everywhere
├── app_text_field.dart      → Used everywhere
├── app_card.dart            → Used everywhere
├── app_avatar.dart          → Used everywhere
├── app_loading.dart         → Used everywhere
└── staggered_item.dart      → Used everywhere

// ─── Example of a Reusable AppButton ─────────────────────────
class AppButton extends StatelessWidget {
  final String label;                     // ✅ Required text
  final VoidCallback? onPressed;          // ✅ Optional callback
  final bool isLoading;                   // ✅ Loading state
  final EdgeInsets padding;               // ✅ Default padding
  final ButtonType type;                  // ✅ primary/secondary/text

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 24, 
      vertical: 12
    ),
    this.type = ButtonType.primary,
  });
}

// ─── Usage across features ────────────────────────────────────
// In Login:  AppButton(label: 'Login', onPressed: viewModel.login)
// In Home:   AppButton(label: 'Book Now', onPressed: viewModel.book)
// ✅ Same component, different data - NO new widget created
```

---

## Complete Example (Home Screen)

### Folder Structure
```
src/ui/home/
├── widgets/
│   ├── home_header.dart
│   ├── home_body.dart
│   └── home_footer.dart
├── view_model/
│   └── home_viewmodel.dart
└── home_screen.dart
```

### home_screen.dart (Parent - Light)
```dart
// ✅ Parent only assembles - no logic, no styling
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          HomeHeader(),
          Expanded(child: HomeBody()),
          HomeFooter(),
        ],
      ),
    );
  }
}
```

### widgets/home_header.dart
```dart
// ✅ Single responsibility - only header UI
// ✅ All text is a required parameter
// ✅ Uses theme for light/dark mode
// ✅ Padding is a parameter with default
class HomeHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback? onAvatarTap;
  final EdgeInsets padding;

  const HomeHeader({
    super.key,
    required this.title,           // ✅ Mandatory text
    required this.subtitle,        // ✅ Mandatory text
    this.avatarUrl,
    this.onAvatarTap,
    this.padding = const EdgeInsets.all(16), // ✅ Default
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding,
      child: Row(
        children: [
          // Text section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.headlineMedium, // ✅ Theme text
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Avatar section
          if (avatarUrl != null)
            AppAvatar(           // ✅ Reusing shared component
              url: avatarUrl!,
              onTap: onAvatarTap,
            ),
        ],
      ),
    );
  }
}
```

### widgets/home_body.dart
```dart
// ✅ Uses stagger animation
// ✅ Reuses AppCard component
// ✅ Accepts data as parameter
class HomeBody extends ConsumerWidget {
  final EdgeInsets padding;

  const HomeBody({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);

    return state.when(
      loading: () => const AppLoading(),   // ✅ Reused component
      error: (e) => AppError(message: e),  // ✅ Reused component
      data: (bookings) => ListView.builder(
        padding: padding,
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return StaggeredItem(            // ✅ Reused stagger
            index: index,
            child: AppCard(               // ✅ Reused card
              title: bookings[index].name,
              subtitle: bookings[index].date,
            ),
          );
        },
      ),
    );
  }
}
```

### view_model/home_viewmodel.dart
```dart
// ✅ All business logic lives here NOT in widgets
class HomeViewModel extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    return _fetchBookings();
  }

  Future<List<Booking>> _fetchBookings() async {
    final repo = ref.read(bookingRepositoryProvider);
    final result = await repo.getBookings();
    return switch (result) {
      Ok(:final value) => value,
      Error(:final error) => throw error,
    };
  }
}

final homeViewModelProvider =
    AsyncNotifierProvider<HomeViewModel, List<Booking>>(
  HomeViewModel.new,
);
```

---

## Quick Rules Summary for LLM
```
FOLDER    → src/ui/<feature>/widgets/ + view_model/ + <feature>_screen.dart
PARENT    → ONLY assembles children. No logic. No styling. No rebuilds.
CHILDREN  → Small. Single job. All text = required param. Padding = default param.
COLORS    → ALWAYS Theme.of(context). NEVER hardcoded Colors.xxx
ANIMATION → ALWAYS StaggeredItem for lists. Reuse same component.
REUSE     → CHECK src/ui/core/widgets/ before making new widget.
VIEWMODEL → ALL logic goes here. NEVER in widgets.
```