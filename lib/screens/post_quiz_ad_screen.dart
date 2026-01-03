import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app.dart';
import '../state/ad_provider.dart';

class PostQuizAdScreen extends ConsumerStatefulWidget {
  const PostQuizAdScreen({super.key});

  @override
  ConsumerState<PostQuizAdScreen> createState() => _PostQuizAdScreenState();
}

class _PostQuizAdScreenState extends ConsumerState<PostQuizAdScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> _args = const {};
  bool _started = false;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _args = (ModalRoute.of(context)?.settings.arguments as Map?)?.cast<String, dynamic>() ?? {};
    _started = true;
    final isPaidUser = _args['isPaidUser'] as bool? ?? false;
    if (isPaidUser) {
      _goToResults();
      return;
    }
    _loadAndShowAd();
  }

  void _loadAndShowAd() {
    ref.read(adServiceProvider).showPostQuizInterstitial(onCompleted: _goToResults);
  }

  void _goToResults() {
    if (!mounted) return;
    context.goNamed(TriviaApp.nameResults, extra: _args);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: SizedBox.expand(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  child: Text(
                    'Please view this ad while we collect your score and rank!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                        ),
                  ),
                  builder: (context, child) {
                    final colors = Theme.of(context).colorScheme;
                    final base = colors.onSurface.withOpacity(0.6);
                    final highlight = colors.onSurface.withOpacity(0.95);
                    final shimmerValue = _shimmerController.value;
                    return ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (rect) {
                        return LinearGradient(
                          colors: [base, highlight, base],
                          stops: const [0.2, 0.5, 0.8],
                          begin: Alignment(-1.2 + shimmerValue * 2.4, 0),
                          end: Alignment(1.2 + shimmerValue * 2.4, 0),
                        ).createShader(rect);
                      },
                      child: child,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
