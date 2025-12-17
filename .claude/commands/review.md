Review the current git changes for code quality.

1. Run `git diff` to see all changes
2. Review the changes for:
   - iOS best practices
   - SwiftUI patterns (iOS 17+): @Observable, NavigationStack, .task {}
   - Memory leaks and retain cycles (check for [weak self])
   - Architecture: Screen/ScreenContent pattern, ViewModel usage
   - Concurrency: @MainActor on ViewModels
   - No force unwraps

3. Provide feedback in format:
   - **Critical issues** (must fix)
   - **Improvements** (should fix)
   - **Suggestions** (nice to have)
