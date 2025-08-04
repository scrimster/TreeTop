# TreeTop Team Setup Instructions

## 🚀 Getting Started

After cloning this repository, run the setup script to avoid bundle identifier conflicts:

```bash
./setup-project.sh
```

This script configures git to ignore your local changes to bundle identifiers and signing settings.

## 📱 Xcode Configuration

1. Open `TreeTop.xcodeproj` in Xcode
2. Change the bundle identifier to your own:
   - Select the TreeTop project in the navigator
   - Go to the TreeTop target
   - Change Bundle Identifier to `com.yourname.TreeTop`
3. Set your development team in Signing & Capabilities
4. Your changes will stay local and not conflict with teammates!

## 🔧 Troubleshooting

If you're still seeing bundle identifier conflicts:

1. Make sure you ran the setup script: `./setup-project.sh`
2. Check if skip-worktree is active: `git ls-files -v TreeTop.xcodeproj/project.pbxproj`
   - Should show `S TreeTop.xcodeproj/project.pbxproj`
3. If needed, manually run: `git update-index --skip-worktree TreeTop.xcodeproj/project.pbxproj`

## 🌲 Happy Coding!

Each team member can now work with their own bundle identifier without stepping on each other's toes.
