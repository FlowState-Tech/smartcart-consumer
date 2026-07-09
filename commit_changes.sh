#!/bin/bash
git config user.email "stephano@smartcart.pe"
git config user.name "Stephano"

# Commit 1
git add lib/features/iam lib/features/experience lib/features/journey
git commit -m "feat: Implement IAM, Experience, and Journey modules"

# Commit 2
git rm -r lib/interface test/widget_test.dart 2>/dev/null
git add lib/core pubspec.yaml pubspec.lock lib/main.dart
git commit -m "refactor: Migrate project to modular clean architecture"

# Commit 3
git add lib/features/planning/domain lib/features/planning/infrastructure
git commit -m "feat: Implement Planning domain and remote data sources"

# Commit 4
git add lib/features/planning/application lib/features/planning/presentation
git commit -m "feat: Develop Basket Management and dynamic Price Comparison"

# Commit 5
git add web
git commit -m "fix(web): Inject Google Maps SDK script for web compatibility"

# Commit 6
git add .
git commit -m "chore: Add platform configurations and backend seed scripts"

git push origin main
