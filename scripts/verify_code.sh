#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "🚀 Starting local code verification..."

echo "📦 Fetching dependencies..."
flutter pub get

echo "🔍 Running Flutter Analyzer..."
flutter analyze

echo "🧪 Running Unit & Widget Tests..."
flutter test

echo "✅ All checks passed successfully!"
