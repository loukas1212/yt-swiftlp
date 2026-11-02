# YT-SwiftLP

A Swift/SwiftUI macOS application built to make using yt-dlp easier!

> **Please note:** This is the first Swift application I am making without any help from AI or agents. As this is the initial version (1.x), bugs and errors can occur. Please also note that not all functions are available yet. If you encounter any errors, please open an [issue](https://github.com/loukas1212/yt-swiftlp/issues/new) with a description and a screenshot or recording of the error.

## Installation
1. Make sure `yt-dlp` is installed, you can install it using Homebrew `brew install yt-dlp`
2. Download `YT-SwiftLP.zip` from the latest [Release](https://github.com/loukas1212/yt-swiftlp/releases).
3. Unzip it.
4. Move it inside your `Applications/` folder.
5. Open it (you may need to go to "Privacy & Security" and click "Open Anyway" if macOS Gatekeeper blocks it).

## Features

As this is version 1.x, this project is Work In Progress (WIP). However, here is a list of current features and what is coming in the future:

#### Current Features
- Auto-update system from the [Release](https://github.com/loukas1212/yt-swiftlp/releases) page (using the [Sparkle Project](https://sparkle-project.org/))
- Output quality selection
- Audio-only download
- Video metadata embedding
- Show video thumbnail/title when downloading
- Changelog system using `CHANGELOG.md` file (v1.1)

#### Upcoming Features
- Audio and video output format selection (comming in v1.2)
- UI customization and redesign (planned for v1.3)
- Audio and video output codec selection (planned for v1.3)
- Support for beta updates, latest commit instead of latest release (planned for v1.3)
- A button to install `yt-dlp` directly from the application (planned for v1.4)
- Downloaded video/audio history (planned for v1.4)

## Versioning System

```bash
v # Stands for "version"
1 # Incremented only on major updates (example : reworking the entire backend)
.
0 # Incremented whenever features are added, major bug fixes occur, or a feature PR is accepted
.
0 # Incremented with every small feature improvement (example : changing an icon and button style) or minor bug fix
```

## Contributing
Contributions and feedback are always welcome!

However, since this project primarily serves as a personal learning experience for me to pick up Swift, please do not submit PR or contributions for items listed under the "Upcoming Features" section. I'd love to tackle those features myself as part of my learning roadmap.

If you'd like to contribute, feel free to:
- Report bugs or issues
- Suggest new ideas not covered in the roadmap
- Help refactor existing non-roadmap code

Thank you for understanding! ❤️

## Structure

```bash
Sources/ # Source code
│    ├── Models/ # Models for DownloadService and other services
│    ├── Services/ # Services and functions
│    ├── Shared/ # Shared components across views and functions
│    ├── ViewModels/ # All ViewModels
│    ├── Views/ # All Views
│    └── main.swift # Main entry point containing @main
├── appicon.icon # Apple Icon Composer file
├── Package.swift # SPM Manifest
├── release.sh # Script to build the .app bundle
```

### Licence
This project is distributed under the MIT license. You can use, redistribute, fork, and edit it as long as the copyright notice is preserved.