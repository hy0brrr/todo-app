# Sidebar Todo for macOS

A native macOS todo app built with SwiftUI.

This project focuses on a lightweight sidebar-style task experience with custom partitions, tags, and parent-child task hierarchy.

## Current version

The current public milestone is **V2**.

Main additions in V2:

- Tags
- Parent-child task hierarchy
- Refined completed-task flow

## What this app supports

- Custom partitions
- Task completion and completed section
- Inline tags with bracket syntax such as `Write review [work] [weekly]`
- Parent tasks and child tasks
- Child-task due dates
- Parent-context display for completed child tasks

## Releases

- [MVP](https://github.com/hy0brrr/todo-app/releases/tag/v1.0.0-mvp)
- [V2](https://github.com/hy0brrr/todo-app/releases/tag/v2.0.0)

## Notes

- The repository currently tracks the SwiftUI desktop version of the app.
- If you want the UI to look exactly like the original authoring environment, install `Neue Montreal` and place it at:

```text
~/Library/Fonts/TitlePreview/neue-montreal.ttf
```

- If that font is missing, the app will fall back to the system title font and remain usable.
- `PingFang SC` is used for the main app UI copy and is included with macOS.

## Memo

- MVP marked the baseline native macOS SwiftUI version.
- V2 marked the completion of two major additions:
  - Tags
  - Parent-child hierarchy
