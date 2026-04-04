# TodoApp Design Tokens

This document defines the base UI design tokens for the Swift macOS demo.

Units:
- Layout, spacing, corner radius, icon size, and font size are measured in `pt` (points), not CSS pixels.
- Opacity values are unitless decimals from `0` to `1`.

Source of truth:
- Swift tokens live in [TodoApp/TodoApp/Helpers/DesignTokens.swift](/Users/huanyun/Desktop/MyGit/todo-app/TodoApp/TodoApp/Helpers/DesignTokens.swift)
- Views should reference the Swift tokens rather than hardcoding style numbers.

## Spacing Tokens

| Token | Value | Unit | Purpose |
| --- | ---: | --- | --- |
| `screenHorizontalInset` | 12 | pt | Main screen horizontal padding |
| `screenVerticalInset` | 13 | pt | Main screen vertical padding |
| `cardGap` | 9 | pt | Gap between cards |
| `sectionPaddingHorizontal` | 12 | pt | Header/footer horizontal padding |
| `sectionPaddingVertical` | 8 | pt | Standard section vertical padding |
| `sectionPaddingVerticalRelaxed` | 9 | pt | Slightly roomier section padding |
| `listEmptyHorizontal` | 16 | pt | Empty-state horizontal padding |
| `listEmptyVertical` | 10 | pt | Empty-state vertical padding |
| `rowHorizontal` | 9 | pt | Task row horizontal padding |
| `rowVertical` | 5 | pt | Task row vertical padding |
| `inputHorizontal` | 4 | pt | Inline input horizontal padding |
| `inputVertical` | 3 | pt | Inline input vertical padding |
| `modalHorizontal` | 16 | pt | Modal horizontal padding |
| `modalHeaderVertical` | 12 | pt | Modal header vertical padding |
| `modalFooterVertical` | 10 | pt | Modal footer vertical padding |
| `modalListRowVertical` | 3 | pt | Modal list row padding |

## Radius Tokens

| Token | Value | Unit | Purpose |
| --- | ---: | --- | --- |
| `card` | 11 | pt | Cards and major surfaces |
| `row` | 5 | pt | Task row hover state |
| `field` | 5 | pt | Inline edit field |

## Stroke Tokens

| Token | Value | Unit | Purpose |
| --- | ---: | --- | --- |
| `cardLineWidth` | 1 | pt | Card outline thickness |
| `checkboxLineWidth` | 1.5 | pt | Checkbox stroke |
| `cardOpacity` | 0.07 | alpha | Card border opacity |
| `dividerOpacity` | 0.24 | alpha | Divider visibility |

## Shadow Tokens

| Token | Value | Unit | Purpose |
| --- | ---: | --- | --- |
| `cardOpacity` | 0.05 | alpha | Card shadow opacity |
| `cardRadius` | 5 | pt | Card shadow blur radius |
| `cardYOffset` | 2 | pt | Card shadow vertical offset |

## Typography Tokens

| Token | Value | Unit | Purpose |
| --- | ---: | --- | --- |
| `partitionHeader` | 11 | pt | Partition/completed section title |
| `partitionHeaderTracking` | 0.55 | pt | Header letter spacing |
| `body` | 13 | pt | Default body text |
| `bodyMedium` | 13 | pt | Medium weight body text |
| `modalTitle` | 13 | pt | Modal title text |
| `caption` | 12 | pt | Supporting text |
| `captionStrong` | 12 | pt | Bold support text |
| `micro` | 10 | pt | Due date and micro label text |
| `icon` | 11 | pt | Small icon size |
| `star` | 12 | pt | Star icon size |
| `checkmark` | 8 | pt | Checkbox checkmark size |

## Size Tokens

| Token | Value | Unit | Purpose |
| --- | ---: | --- | --- |
| `partitionIndicator` | 8 | pt | Section color dot |
| `checkbox` | 14 | pt | Checkbox visual size |
| `checkboxTapTarget` | 24 | pt | Checkbox hit area |
| `trailingControl` | 20 | pt | Calendar and star control size |
| `partitionColorDot` | 14 | pt | Partition color picker size |
| `modalPartitionDot` | 10 | pt | Partition dot in modal |
| `resizeHandleHeight` | 6 | pt | Resize handle height |
| `completedMinHeight` | 120 | pt | Completed section minimum height |
| `modalWidth` | 330 | pt | Manage Partitions modal width |
| `modalMinHeight` | 300 | pt | Modal minimum height |
| `modalMaxHeight` | 500 | pt | Modal maximum height |
| `appMinWidth` | 300 | pt | Window minimum width |
| `appIdealWidth` | 380 | pt | Window ideal width |
| `appMaxWidth` | 500 | pt | Window maximum width |
| `appMinHeight` | 500 | pt | Window minimum height |
| `datePopoverWidth` | 280 | pt | Due date popover width |

## Motion Tokens

| Token | Value | Unit | Purpose |
| --- | ---: | --- | --- |
| `quick` | 0.15 | seconds | Fast hover animation |
| `hoverScale` | 1.15 | scale | Checkbox/calendar hover scale |
| `starHoverScale` | 1.2 | scale | Star hover scale |
| `dueDateHoverScale` | 1.05 | scale | Due date hover scale |

## Color Role Tokens

These are semantic roles rather than fixed brand hex values:

| Token | Purpose |
| --- | --- |
| `cardBackground` | Main card surface |
| `primaryText` | Primary text |
| `secondaryText` | Secondary text and helper text |
| `accent` | Accent/tint interactions |
| `dueDate` | Due date action color |
| `danger` | Destructive state |
| `successMuted` | Completed state neutral |
| `warning` | Star active state |
| `warningHover` | Star hover active state |
| `rowHover` | Hover fill for task rows |
| `inputBackground` | Inline editing field background |
| `footerBackground` | Add-task bar background |
| `cardBorder` | Card border color |
| `resizeHover` | Resize handle hover fill |
| `editPanelBackground` | Partition edit panel surface |

## Usage Rule

- When adjusting foundational UI, prefer updating `DesignTokens.swift` first.
- Hardcoded style numbers in views should be treated as exceptions, not the default.
- Functional logic must remain separate from design token changes.
