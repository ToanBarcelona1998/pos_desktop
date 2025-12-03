/// Splash page state
sealed class SplashState {
  const SplashState();
}

/// Initial state - loading
class SplashLoading extends SplashState {
  const SplashLoading();
}

/// Navigate to login
class SplashNavigateToLogin extends SplashState {
  const SplashNavigateToLogin();
}

/// Navigate to home
class SplashNavigateToHome extends SplashState {
  const SplashNavigateToHome();
}

/// Navigate to onboarding
class SplashNavigateToOnBoarding extends SplashState {
  const SplashNavigateToOnBoarding();
}







