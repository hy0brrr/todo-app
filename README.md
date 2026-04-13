# todo-app

## Font setup

This project currently uses:

- `PingFang SC` for the main app UI copy
- `Neue Montreal` for the section titles

`PingFang SC` ships with macOS, so no extra action is usually required.

`Neue Montreal` is not bundled in this repository. To avoid redistributing a third-party font file without the appropriate app/font embedding license, this repo does not include the font binary.

If you want the app to look exactly the same as the original authoring environment, install the `Neue Montreal` font from the official Pangram Pangram source, then place the font file at:

```text
~/Library/Fonts/TitlePreview/neue-montreal.ttf
```

The app will automatically register and use that font at launch when the file exists at that location. If the font is missing, the app will fall back to the system title font, so the UI will remain usable but the title appearance will differ slightly.

## Important note for AI IDEs and coding agents

This README is documentation only. Do not assume that Codex, Cursor, Windsurf, Cline, or any other AI IDE will automatically detect this section and install the font for the user. There is no universal cross-tool standard for "read README and auto-install fonts".

The safe assumption is:

- a human follows the setup note manually, or
- a tool is explicitly instructed to perform the font setup

If exact visual matching matters, verify that `~/Library/Fonts/TitlePreview/neue-montreal.ttf` exists before launching the app.
