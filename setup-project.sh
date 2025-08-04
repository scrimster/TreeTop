#!/bin/bash

# TreeTop Project Setup Script
# Run this after cloning the repository to avoid bundle identifier conflicts

echo "🌲 TreeTop Project Setup"
echo "========================"

# Check if we're in the right directory
if [ ! -f "TreeTop.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the TreeTop project root directory"
    exit 1
fi

# Set up git to ignore local changes to project.pbxproj
echo "🔧 Configuring git to ignore bundle identifier changes..."
git update-index --skip-worktree TreeTop.xcodeproj/project.pbxproj

# Verify it worked
if git ls-files -v TreeTop.xcodeproj/project.pbxproj | grep -q "^S"; then
    echo "✅ Success! Your local bundle identifier changes will not be tracked by git."
    echo ""
    echo "📝 Instructions:"
    echo "1. Open TreeTop.xcodeproj in Xcode"
    echo "2. Change the bundle identifier to your own (e.g., com.yourname.TreeTop)"
    echo "3. Set your development team in Signing & Capabilities"
    echo "4. Your changes will stay local and not affect other teammates!"
else
    echo "❌ Something went wrong. Please check git status."
fi

echo ""
echo "🎉 Setup complete! Happy coding!"
