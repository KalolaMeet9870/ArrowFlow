# ArrowFlow — 2D Mobile Logic Puzzle Game (Godot 4.x)

An original, polished 2D mobile arrow puzzle game built with **Godot 4.7** and **GDScript**.

---

## 🎮 Game Overview

- **Genre**: 2D Logic Puzzle
- **Engine**: Godot Engine 4.x (Tested on 4.7)
- **Language**: GDScript (Typed)
- **Platforms**: Android, iOS, and Desktop (macOS / Windows / Linux)
- **Orientation**: Portrait (720 × 1280 base viewport with responsive canvas expand)
- **Aesthetic**: "Eye Comfort" Warm Paper theme (`#FAF4E8` background, `#4A3525` espresso lines, subtle grid dots, debossed bottom banner, procedural water drop lives).
- **Audio**: 100% procedural 16-bit PCM synthesized audio (slide whoosh, error buzz, paint chords, victory fanfare, tactile clicks) with zero external audio asset dependencies.
- **Offline Support**: 100% local persistence with zero backend or account dependencies.

---

## 🕹 Core Mechanics

1. **Grid-Based Arrow Puzzle**:
   - The board displays interlocking straight and multi-segment arrows pointing in four directions: **UP**, **DOWN**, **LEFT**, or **RIGHT**.
   - Arrows occupy one or more grid cells.
2. **Forward Path Checking**:
   - Tapping an arrow queries `CollisionChecker.can_arrow_exit(arrow, remaining_arrows, grid_size)`.
   - The algorithm projects forward along the arrow's heading from its arrowhead to the grid boundary.
3. **Smooth Slide Exit**:
   - If the path to the boundary is clear, the arrow animates smoothly off the board with an airy ASMR slide whoosh.
   - The arrow is immediately removed from active occupancy, dynamically unblocking subsequent arrows.
   - Consecutive clears advance the pentatonic combo chime!
4. **Long-Press Guidance (Signature Mechanic)**:
   - **Press & hold** any arrow (>= 220ms) to activate **Guidance Mode** without penalty!
   - Projects an animated marching trajectory beam forward along the arrow's flight path:
     - **Clear Lane**: Glowing emerald/gold trajectory line to the grid edge (`Release to launch!`).
     - **Blocked Lane**: Red/amber stop marker at the blocking arrow (`Release safely to cancel without losing hearts!`).
5. **Rejection & Drop/Life Deduction**:
   - Tapping an arrow with a blocked forward path flashes red (`#E53935`), shakes with rejection wiggle, plays error buzz, vibrates haptics, and deducts 1 water drop (`💧`).
6. **5 Zen Eye Comfort Themes**:
   - **Eye Comfort (Warm Paper)** (`#FAF4E8` / Espresso `#4A3525`)
   - **Midnight Zen (Dark Mode)** (`#181A20` / Porcelain `#E2E8F0`)
   - **Matcha Garden (Sage & Olive)** (`#EDF4EE` / Forest `#2D4A3E`)
   - **Nordic Frost (Cool Slate Blue)** (`#EEF2F6` / Navy `#2C3E50`)
   - **Sunset Clay (Warm Terracotta)** (`#FDF5F0` / Clay `#6E3826`)
7. **Win & Loss Conditions**:
   - Clearing all arrows triggers the **Level Complete Screen** (star rating, moves, next level).
   - Losing all 3 drops triggers **Level Failed Screen** (Retry or Extra Life to resume immediately).

---

## 📁 Project Architecture

```
res://
├── scenes/
│   ├── main/
│   │   └── Main.tscn              # Root scene coordinator
│   ├── screens/
│   │   ├── HomeScreen.tscn        # Title, Play, Continue, Daily, Settings
│   │   ├── GameScreen.tscn        # Header, GameBoard, HeartDisplay, Action buttons
│   │   ├── LevelComplete.tscn     # Win modal with stars and stats
│   │   ├── LevelFailed.tscn       # Failure modal with retry & extra life
│   │   └── SettingsScreen.tscn    # Sound, vibration, progress reset
│   ├── game/
│   │   ├── GameBoard.tscn         # 2D grid rendering & touch dispatch
│   │   └── Arrow.tscn             # Reusable Area2D arrow entity
│   └── ui/
│       ├── HeartDisplay.tscn      # Water drops / lives counter
│       ├── PausePopup.tscn        # In-game pause modal
│       └── HintButton.tscn        # Vector lightbulb hint button
├── scripts/
│   ├── main.gd                    # Screen switching & top-level coordinator
│   ├── game_manager.gd            # State management & progression
│   ├── game_board.gd              # Grid layout, collision queries, exit tweens
│   ├── arrow.gd                   # Arrow rendering, tweens, touch hit-test
│   ├── collision_checker.gd       # Independent pure collision checker
│   ├── puzzle_generator.gd        # Handcrafted tutorials & reverse synthesis
│   ├── puzzle_solver.gd           # Backtracking solver & hint generator
│   ├── level_manager.gd           # Level loading & progression cache
│   ├── save_manager.gd            # user:// JSON save persistence
│   └── sound_manager.gd           # Procedural PCM audio synthesizer
├── data/
│   └── levels.json                # 50 verified authentic level layouts
├── test/
│   ├── test_suite.gd              # Automated test runner (38 tests)
│   └── test_full_gameplay_flow.gd # End-to-end acceptance test
├── export_presets.cfg             # Android, iOS, macOS export configurations
└── project.godot                  # Engine project configuration
```

---

## 🚀 Running and Testing Locally

### 1. Open in Godot Editor
1. Launch Godot Engine 4.x.
2. Click **Import** and select the `/Users/dws-mac001/amaze-go!/project.godot` file.
3. Press **Run Project (F5)** to launch the game.

### 2. Run Automated Tests Headless
To run the automated test suite from the terminal:

```bash
# Run 38 unit & integration tests (Collision, Exits, Hearts, 50-Level Solvability, Save/Load)
/Volumes/Transcend/Godot.app/Contents/MacOS/Godot --headless --script res://test/test_suite.gd

# Run End-to-End Acceptance Test (Launch -> Play -> Blocked Tap -> Clear Board -> Win Screen -> Save)
/Volumes/Transcend/Godot.app/Contents/MacOS/Godot --headless --script res://test/test_full_gameplay_flow.gd
```

---

## 📱 Mobile Export Configuration

### Android Export

#### Prerequisites:
1. Install **Android Studio** or Android command-line tools.
2. Download Android SDK Platform-Tools and build-tools (version 34+).
3. Install OpenJDK 17.
4. Set Android SDK path in Godot: **Editor Settings → Export → Android → Android SDK Path**.

#### Generating a Debug Keystore:
```bash
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
```
Place `debug.keystore` in your project or home directory and reference it in Godot's Android export settings.

#### Export Steps:
1. Open Godot → **Project → Export...**
2. Select the **Android** preset (already configured in `export_presets.cfg`).
3. Set your target APK path (e.g. `builds/android/arrow_escape.apk`).
4. Click **Export Project** (Debug or Release).

---

### iOS Export (macOS & Xcode)

#### Prerequisites:
1. macOS with **Xcode 15+** installed.
2. Apple Developer Account (for device signing and App Store distribution).

#### Export Steps:
1. Open Godot → **Project → Export...**
2. Select the **iOS** preset (preconfigured with bundle identifier `com.arrowflow.puzzle`).
3. Click **Export Project** and select an output folder (e.g. `builds/ios/`).
4. Godot generates an Xcode project (`.xcodeproj`).
5. Open the generated project in Xcode:
   ```bash
   open builds/ios/ArrowEscape.xcodeproj
   ```
6. In Xcode, select your **Signing & Capabilities** tab and choose your Apple Developer Team.
7. Select an iOS device or simulator, and press **Cmd + R** to build and run.

---

## 🧩 50 Levels Progression & Solvability

The game includes a complete 50-level difficulty curve:
- **Beginner / Simple (Levels 1–10)**: 4×4 to 5×5 grids, 3–6 arrows, gentle introduction to blocking.
- **Easy (Levels 11–20)**: 6×6 grids, 8–12 arrows, multi-cell paths and corner locks.
- **Medium (Levels 21–35)**: 7×7 to 14×14 grids, 14–20 arrows, complex interlocking dependencies.
- **Hard (Levels 36–45)**: 8×8 to 18×18 grids, 20–28 arrows, intricate shapes (Trophy, Dog, Castle).
- **Expert (Levels 46–50)**: Large 24×24 labyrinths with dense dependencies.

Every single level is mathematically verified by `PuzzleSolver` with a guaranteed clear sequence.
