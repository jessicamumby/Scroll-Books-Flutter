import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final onboardingNotifier = OnboardingNotifier();

bool onboardingCompleted = false;
bool get isOnboardingCompleted => onboardingCompleted;

Future<void> loadOnboardingCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
}

Future<void> completeOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_completed', true);
  onboardingCompleted = true;
  onboardingNotifier.notify();
}

Future<void> resetOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('onboarding_completed');
  onboardingCompleted = false;
  onboardingNotifier.notify();
}
