# Chess for Beginners: Learn with Ai

These guidelines describe how to use GitHub Copilot while working on the Flutter OpenAI API Example App. They ensure contributors share a consistent workflow and apply Copilot responsibly.

## 1. Overview
- **Purpose**: Accelerate feature work, spike prototypes, and draft tests without replacing thoughtful design or reviews.
- **Supported surfaces**: VS Code, Android Studio/IntelliJ, Neovim (any IDE with the official Copilot plugin).
- **References**: [Copilot documentation](https://docs.github.com/copilot), Flutter [style guide](https://dart.dev/guides/language/effective-dart/style), project README for architecture notes.

## 2. Setup
1. **Prerequisites**
   - Active GitHub account with Copilot subscription or org entitlement.
   - Flutter SDK installed per `README.md` and `flutter doctor` passing.
2. **Install plugin**
   - VS Code: `Extensions → GitHub Copilot → Install`.
   - Android Studio/IntelliJ: `Settings → Plugins → Marketplace → GitHub Copilot`.
3. **Authenticate**
   - Trigger the sign-in flow from the IDE command palette or status bar.
   - Confirm Copilot status icon shows "Ready" before relying on suggestions.
4. **Project-specific tuning**
   - Enable inline completions; disable whole-file autocompletion to avoid large, noisy diffs.
   - Set suggestion keybinds to non-conflicting shortcuts (e.g., `Alt+\` accept, `Alt+]` next).

## 3. Workflow
- **Prompt intentionally**: Highlight context window (widgets, services, tests) before requesting suggestions; add inline comments describing desired behavior.
- **Review every suggestion**: Never accept blind; validate imports, null-safety, and platform behavior.
- **Iterate in small chunks**: Generate focused snippets (e.g., single widget, helper method) and run `flutter analyze`/tests as you go.
- **Traceability**: When Copilot contributes non-trivial logic, mention it in PR description if attribution is required by your org.
- **Testing**: For UI or API changes, request Copilot test scaffolds but curate final expectations manually.

## 4. Usage Guidelines
- **Security & privacy**: Do not include secrets, API keys, or proprietary data in prompts. Mask sample responses before sharing with Copilot.
- **Code style**: Align with Effective Dart naming, `analysis_options.yaml`, and existing patterns in `lib/` and `test/`.
- **Accessibility**: Ensure Copilot-generated widgets expose semantics, labels, and theming consistent with Flutter best practices.
- **Licensing**: If Copilot suggests code identical to known copyrighted snippets, discard it.
- **Reviews**: Flag Copilot-heavy sections during code review so peers pay extra attention to logic and edge cases.
- **Documentation**: Update `README.md` or inline comments when Copilot introduces new workflows, config flags, or build steps.

Following this document keeps Copilot contributions predictable, reviewable, and secure across the Flutter OpenAI API Example App.

