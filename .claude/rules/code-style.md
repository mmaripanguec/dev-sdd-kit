# Code style
> Base: Google Style Guides (google.github.io/styleguide) · Google eng-practices (code review)

- Follow the Google style guide for the project's language; the linter codifies it
  and is the final authority. Zero warnings to commit.
- Short functions with a single responsibility; descriptive names without abbreviations.
- No `any` / dynamic types in new code; strict typing enabled.
- Comments explain the WHY, not the what. Dead code is deleted, not commented out.
- Small, self-contained changes: one commit = one intention (small CLs are
  easier to review and revert painlessly).
- Explicit error handling: never swallow exceptions; errors with actionable context.
