# Sidebar Todo V2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add partition-scoped tags and parent/child task workflows to the SwiftUI macOS app while preserving the current visual language.

**Architecture:** Keep the existing SwiftUI card layout and extend the domain model in-place. Move the new behavior into `TodoViewModel` and small helper models so the view layer can render active task trees, completed-context rows, and partition-scoped tag history without duplicating business logic.

**Tech Stack:** SwiftUI, AppKit interop, Swift Observation, XCTest via Swift Package Manager, xcodebuild for app packaging

---

### Task 1: Establish testable foundation for V2 logic

**Files:**
- Modify: `TodoApp/Package.swift`
- Create: `TodoApp/Tests/TodoAppTests/TodoViewModelV2Tests.swift`

- [ ] Add a test target so the SwiftUI app logic can be exercised via `swift test`.
- [ ] Fix the package manifest tools version mismatch so `swift build` and `swift test` can run on the current Xcode toolchain.
- [ ] Write failing tests that lock down:
  - partition-scoped tag history
  - parent/child creation rules
  - child-only starring behavior
  - child-first completion context
  - parent completion cascading to children

### Task 2: Extend the task model and view model for V2 workflows

**Files:**
- Modify: `TodoApp/TodoApp/Models/TodoTask.swift`
- Modify: `TodoApp/TodoApp/ViewModels/TodoViewModel.swift`

- [ ] Add parent/child structure and parent-only tags to the task model.
- [ ] Add view-model APIs for:
  - creating root tasks and child tasks
  - editing tags on parent tasks
  - storing and querying partition-specific tag history
  - computing active root tasks with nested children
  - computing completed-section rows with parent context
- [ ] Keep sorting rules aligned with the PRD:
  - root ordering unchanged by child starring
  - child starring only affects sibling order
  - parent completion is always manual

### Task 3: Update task row UI and lightweight editors

**Files:**
- Modify: `TodoApp/TodoApp/Views/TaskItemView.swift`
- Create: `TodoApp/TodoApp/Views/TagEditorPopover.swift`

- [ ] Add parent-tag rendering using the existing visual system.
- [ ] Add gray-state completed tag rendering.
- [ ] Add right-click actions for:
  - add child task
  - edit tags
- [ ] Reuse the lightweight popover interaction style for tag editing with:
  - choose from current partition history
  - add a new tag manually

### Task 4: Render hierarchy inside partitions and completed context rows

**Files:**
- Modify: `TodoApp/TodoApp/Views/PartitionView.swift`
- Modify: `TodoApp/TodoApp/Views/CompletedSectionView.swift`
- Modify: `TodoApp/TodoApp/Views/ContentView.swift`

- [ ] Render root tasks with indented child rows underneath.
- [ ] Keep the current card spacing, typography, and glass styling intact.
- [ ] Show completed child rows inside the completed section together with their unfinished parent context.
- [ ] Show full parent subtree completion when a parent is completed.

### Task 5: Verify V2 against the checklist and package the app

**Files:**
- Reference: `docs/superpowers/plans/2026-04-12-sidebar-todo-v2.md`
- Reference: `/Users/huanyun/Library/Mobile Documents/iCloud~md~obsidian/Documents/Base/1 Make/todo/测试清单：Sidebar Todo for MacOS (V2).md`

- [ ] Run `swift test` and confirm the new V2 logic passes.
- [ ] Run an app build with `xcodebuild -project TodoApp.xcodeproj -scheme TodoApp -configuration Debug build`.
- [ ] Produce a standalone `.app` bundle location and open it for manual review.
- [ ] Walk the Obsidian V2 checklist line-by-line and note any remaining gaps before claiming completion.
