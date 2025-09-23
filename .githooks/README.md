# Git Hooks

This directory contains information about the Git hooks configured for this project.

## Pre-commit Hook

A pre-commit hook has been set up to automatically run RuboCop with auto-correction (`-A` flag) on all staged Ruby files before each commit.

### What it does:

1. **Identifies staged Ruby files** (`.rb`, `.rake`, `Rakefile`, `Gemfile`)
2. **Runs RuboCop auto-correction** on those files
3. **Re-stages corrected files** automatically
4. **Prevents commit** if there are unfixable issues

### Example output:

```bash
$ git commit -m "Add new feature"
Running rubocop auto-correction...
Inspecting 3 files
..C

Offenses:

app/models/user.rb:15:1: C: [Corrected] Layout/TrailingEmptyLines: Final newline missing.

3 files inspected, 1 offense detected, 1 offense corrected
✅ Rubocop auto-correction completed successfully.

[main abc1234] Add new feature
 2 files changed, 15 insertions(+), 3 deletions(-)
```

### If RuboCop finds unfixable issues:

```bash
$ git commit -m "Add new feature"
Running rubocop auto-correction...

❌ Rubocop found issues that couldn't be auto-corrected.
Please fix the remaining issues and try committing again.

To see the issues:
  bundle exec rubocop app/models/user.rb

To fix auto-correctable issues:
  bundle exec rubocop -A app/models/user.rb
```

### Manual RuboCop commands:

```bash
# Check all files
bundle exec rubocop

# Auto-correct all fixable issues
bundle exec rubocop -A

# Check specific files
bundle exec rubocop app/models/user.rb

# Auto-correct specific files
bundle exec rubocop -A app/models/user.rb
```

### Bypassing the hook (not recommended):

```bash
# Skip pre-commit hooks (use sparingly)
git commit --no-verify -m "Emergency commit"
```

### Hook location:

The actual hook file is located at `.git/hooks/pre-commit` and is automatically executable.

### Benefits:

- **Consistent code style** across all commits
- **Automatic formatting** reduces manual work
- **Prevents style-related PR comments**
- **Maintains code quality** standards
- **Uses Rails Omakase** style guide automatically