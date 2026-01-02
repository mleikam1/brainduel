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

class _PostQuizAdScreenState extends ConsumerState<PostQuizAdScreen> {
  Map<String, dynamic> _args = const {};
  bool _started = false;

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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Adding up your score & rankings'),
        ),
        body: SafeArea(
          child: SizedBox.expand(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
            ),
          ),
        ),
      ),
    );
  }
}
