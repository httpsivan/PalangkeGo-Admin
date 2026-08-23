# Project Rules & Guidelines

## 🦥 Ponytail Dev Philosophy (YAGNI & Minimal Code)

Keep development extremely clean, minimal, and secure. Avoid over-engineering, unrequested abstractions, and boilerplate.

Before writing any code, always check the **Ponytail Decision Ladder**:
1. **Does this need to exist?** If it is a speculative feature, skip it. (YAGNI)
2. **Already exists?** Reuse helpers, widgets, API models, or patterns already in the codebase rather than writing new ones.
3. **Stdlib does it?** Use native Dart/Flutter core library features.
4. **Native platform covers it?** Use built-in Flutter/platform/browser components rather than third-party packages where possible.
5. **Existing dependency solves it?** Utilize already installed packages (like Riverpod or Shared Preferences) instead of adding new ones.
6. **Can it be one line/minimal?** Make it a one-liner if possible.
7. **Absolute minimum:** Only write code if all other steps are passed, implementing the minimum secure and accessible solution that works.

### Key Rules:
- Deletion over addition. Boring over clever. Fewest files possible.
- Bug fixes must address the root cause, not just symptoms. Check all callers before making edits.
- Never compromise on security, data validation, error handling, or accessibility in the name of laziness.
