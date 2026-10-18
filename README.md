# Time Tracker

Time Tracker is a native macOS application for recording time against projects and tasks.

## Build and run

### In Xcode

1. Open `Time Tracker.xcodeproj`.
2. Select the **Time Tracker** scheme and **My Mac** as the run destination.
3. Choose **Product > Run** (⌘R). Xcode builds and launches the application.

The project currently targets macOS 12.0 or later.

## Download and launch

Download the latest ZIP from the [GitHub Releases page](https://github.com/rburgst/time-tracker-mac/releases), then open it to extract `Time Tracker.app`. You can move the app to Applications.

The release build is ad-hoc signed and is not notarized by Apple. The first time you open it, macOS may block it:

1. Try to open **Time Tracker** once from Finder.
2. Open **Apple menu > System Settings > Privacy & Security** and scroll to the **Security** section.
3. Click **Open Anyway** for Time Tracker, then confirm **Open** in the next alert.

Only do this if you downloaded the app from the project's GitHub Releases page and trust its source. Once approved, you can open it normally from Applications or Finder. See [Apple's instructions](https://support.apple.com/en-gb/guide/mac-help/mh40617/27/mac/27) for details.

### From Terminal

With Xcode and its command-line tools installed, build the app from the repository root:

```sh
xcodebuild \
  -project "Time Tracker.xcodeproj" \
  -scheme "Time Tracker" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  build
```

Launch the built app with:

```sh
open "build/Build/Products/Debug/Time Tracker.app"
```

## Getting started

1. Create a project using **New Project** in the toolbar.
2. Select the project, then create a task in it.
3. Select the task and click the green recording button to start tracking time.

The menu bar status item can start and stop recently used tasks. The number of recent tasks is configurable in the application settings.

## Data and export

Time records are stored in `~/Library/Application Support/TimeTracker/data.plist`. Back up this file to preserve recorded data. The application can export records to CSV; it does not import XLS or CSV files.

## Development notes

See [HACKING.txt](HACKING.txt) for the developer workflow and current release packaging and publishing steps.
