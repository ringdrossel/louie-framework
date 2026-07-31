Set or replace the application icon of a packaged desktop app on Linux (Electron or Qt/C++) across all four surfaces it lives in — packaging/desktop entry, in-code window icon, in-app usages, and the desktop environment's installed copies — with a repeatable swap procedure that survives DE icon caches and works on both X11 and Wayland.

# Desktop App Icon (Linux)

## Overview

An application icon looks like one asset. On a packaged Linux desktop app it is **four independent surfaces**, each with its own failure mode, and each resolved by a different actor (the packager, the UI toolkit, your own app code, the desktop environment). Replacing the PNG and rebuilding fixes at most one of them — which is why "the icon didn't change" is the normal outcome of a naive swap.

This recipe covers **Electron** and **Qt/C++** on Linux. The four-surface structure is identical for both; surfaces 1 and 2 differ in *mechanism*, surfaces 3 and 4 are the same regardless of toolkit.

### The four surfaces

1. **Packaging / desktop entry** — the icon the packager installs and the `.desktop` entry's `Icon=` key points at. This is what launchers and menus read.
2. **In-code window icon** — the icon the toolkit hands the window manager for a live window (titlebar, Alt-Tab, taskbar entry of a *running* window).
3. **In-app usages** — notifications, About dialog, splash screen: anything referencing the icon from your own code.
4. **Desktop-environment installed/extracted copies** — the PNGs that actually sit under `.../icons/hicolor/{256x256,512x512}/apps/<app>.png`. For an AppImage, the DE (KDE Plasma does this automatically) **copies** the icon there **once** on integration and never refreshes it. The taskbar and launcher read those files, not the icon inside your rebuilt artifact.

Surface 4 is the one that makes this recipe necessary: it lives outside the repo, outside the build, and outside the app — and it is the surface the user actually looks at.

| Surface | Electron | Qt/C++ |
|---|---|---|
| 1 — packaging / desktop entry | `build.linux.icon` in `package.json` / `electron-builder.yml` | CMake `install()` of the `.desktop` file + hicolor PNGs, or `linuxdeploy` / `appimage-builder` config |
| 2 — in-code window icon | `icon:` option on **every** `new BrowserWindow(...)` | `QGuiApplication::setWindowIcon()` — **app-wide, one call** |
| 3 — in-app usages | notification/About code referencing the asset | same, typically via a Qt resource path |
| 4 — DE copies + caches | identical for both — DE-side, toolkit-agnostic | identical for both |

### The display-server axis (do not skip this)

Surface 2 behaves differently under X11 and Wayland, and this is the most commonly misdiagnosed part of the whole problem:

- **X11** — the in-code window icon (surface 2) applies. What you set in code is what the WM shows.
- **Wayland** — there is no window-icon protocol in xdg-shell. The compositor resolves a window's icon by matching the window's **`app_id`** against an installed `.desktop` entry. The in-code icon is **largely ignored** for the taskbar and switcher; the icon comes from surfaces 1 and 4.

So on Wayland, `app_id` correctness is a hard requirement, not a nicety:

- **Qt:** `QGuiApplication::setDesktopFileName("com.example.myapp")`, matching the installed `.desktop` filename.
- **Electron:** `app.setDesktopName('com.example.myapp.desktop')` (and keep the builder-generated desktop entry's name in sync).

If `app_id` does not match an installed desktop entry, the compositor has nothing to resolve and falls back to a generic icon — which reads exactly like "my icon replacement didn't work."

KDE Plasma and GNOME both default to Wayland now, so treat this as the primary case and X11 as the fallback.

### The unifying rule

Establish **one canonical icon file** that surfaces 1–3 all reference, plus a documented **replace procedure** that also refreshes surface 4 and flushes the DE caches.

### Use this when

- You ship a Linux desktop app as a packaged artifact (AppImage, .deb, .rpm, Flatpak) built with Electron or Qt, and want a correct, replaceable application icon.
- The icon "won't change" after a rebuild — the taskbar or launcher still shows the old one.
- The window icon is missing or generic while the launcher icon is fine (or vice versa) — a classic symptom of surfaces disagreeing, or of an X11 assumption running under Wayland.
- New icon artwork renders visibly smaller than neighbouring taskbar icons and you need it normalized.

### Do not use this for

- **Windows `.ico` / macOS `.icns` generation** — different formats, different multi-resolution rules, different OS caches. Compose a per-platform recipe if you need those.
- **Tray / system-notification-area icons** — a separate API (`Tray` in Electron, `QSystemTrayIcon` in Qt) with its own sizing and theming (monochrome/symbolic) conventions.
- **Publishing a full multi-resolution icon theme** (16 through 512, scalable SVG, per-theme variants) — this recipe covers the canonical source plus the two hicolor sizes a DE actually uses.
- **Branding/design work** — choosing or drawing the artwork. The recipe assumes artwork exists and normalizes it.
- **Toolkits other than Electron and Qt** — GTK, wxWidgets, Tauri and friends follow the same four-surface model, but their surface-2 API and packaging conventions are not covered here.

## Requirements Seed

### Functional

1. **A single canonical icon file** exists in the repo (e.g. `assets/icons/icon.png`). Every surface references *this* file — swapping the icon is one file replacement plus the documented refresh procedure.
2. The canonical file is a **1024×1024 PNG, RGBA**, with the artwork **trimmed to fill ≥95% of the canvas** (see Non-Functional → full-bleed).
3. **Packaging (surface 1)** installs the icon and a `.desktop` entry whose `Icon=` key resolves to it:
   - *Electron:* `build.linux.icon` points at the canonical file (or its directory, per the packager's convention).
   - *Qt:* CMake `install()` rules place the `.desktop` file in `share/applications/` and the icon in `share/icons/hicolor/<size>/apps/`, or the AppImage tool's config does so.
4. **In-code window icon (surface 2)** is set:
   - *Electron:* **every** `BrowserWindow` instance — main and all popup/secondary windows — sets `icon:`. No window is left without an explicit icon.
   - *Qt:* one `QGuiApplication::setWindowIcon()` call at startup covers all windows; any per-window `setWindowIcon()` override must use the same canonical asset.
5. **`app_id` / desktop-file name is set explicitly** so Wayland compositors can resolve the icon: `QGuiApplication::setDesktopFileName(...)` / `app.setDesktopName(...)`, matching the installed `.desktop` filename.
6. **Asset resolution is correct in both dev and packaged layouts.** The path/handle used at runtime must resolve in the packaged artifact, not only in a dev run:
   - *Qt:* compile the icon into the binary via the Qt resource system (`:/icons/icon.png` from a `.qrc`) — this removes the problem entirely and is the recommended default.
   - *Electron:* branch on `app.isPackaged`:
     ```js
     const iconPath = app.isPackaged
       ? path.join(path.dirname(app.getPath('exe')), 'assets/icons/icon.png')
       : path.join(__dirname, '../../assets/icons/icon.png');
     ```
     A bare `path.join(__dirname, ...)` is not acceptable — see Pitfalls.
7. **In-app usages (surface 3)** — notifications, About dialog, splash — reference the same canonical asset through the same resolution mechanism.
8. A **repeatable "replace icon" procedure** is documented in the project's runbook and executable end to end:
   1. Normalize the new artwork (trim → resize → center on a 1024×1024 transparent canvas).
   2. Overwrite the canonical file.
   3. Rebuild the package.
   4. Refresh the DE-installed/extracted copies (256 + 512) and flush the DE icon caches.
   5. Relaunch the app.
9. A **verification step** confirms the swap actually landed:
   - `cmp` the icon inside/next to the packaged artifact against the canonical source — must be byte-identical.
   - `cmp` (or compare visually) the installed `hicolor/256x256` and `hicolor/512x512` copies against the resized canonical icon.

### Non-Functional

- **Full-bleed artwork.** Source images routinely carry large transparent margins — real case: artwork filled only ~75% of a 1024×1024 canvas, which made the icon render noticeably smaller than every neighbouring taskbar icon. The canonical file must be normalized so the visible artwork occupies ≥95% of the canvas.
- **Optical, not just geometric, match.** After trimming, scaling to ~105–110% (cropping only glow/shadow halo, never the subject) and nudging vertical position may be needed to sit correctly beside other taskbar icons. **Expect at least one visual iteration with the user** — plan for it rather than declaring the geometric result done.
- **One replacement, one file.** No surface may keep its own copy of the icon; duplicated PNGs are a defect, not a convenience. (Generated per-size copies produced *from* the canonical file by the build are fine — hand-maintained duplicates are not.)
- **Works on X11 and Wayland.** The icon is correct under both display servers, which means surfaces 1 and 4 must be right even when surface 2 is also set.
- **Idempotent refresh.** The replace procedure is safe to run repeatedly and does not depend on prior state of the DE caches.
- **Deterministic packaging.** The icon shipped in the artifact is byte-identical to the canonical file in the repo — no re-encoding step between them that could silently alter it.

### Out of Scope

- Windows `.ico` and macOS `.icns` generation (see *Variations*).
- Tray icons and notification-area/status icons.
- Multi-resolution icon themes beyond the two installed hicolor sizes, 256 and 512 (see *Variations*).
- Icon design/artwork creation; the recipe consumes supplied artwork.
- Non-KDE desktop environments' cache mechanics beyond the generic `gtk-update-icon-cache` step (see *Variations*).
- Adaptive / themed / monochrome icon variants.
- Toolkits other than Electron and Qt.

## Architecture Notes

### Canonical file and the packaged layout

```
repo/
  assets/icons/icon.png        ← canonical, 1024×1024 RGBA, full-bleed
  <packaging config>           ← surface 1: builder config / CMake install / linuxdeploy
  <app entry point>            ← surface 2: window icon + desktop-file name
```

The critical architectural fact is that **the dev-time path and the packaged path are not the same thing**, and each toolkit gets this wrong in its own way:

**Electron.** When assets ship via electron-builder's `extraFiles`, they land **next to the executable** in the packaged app, not inside `app.asar`. So the same relative path means two different things:

| | dev | packaged |
|---|---|---|
| `__dirname` | `repo/src/main` | inside `app.asar` |
| icon location | `repo/assets/icons/icon.png` | `<exeDir>/assets/icons/icon.png` |

Hence a single `resolveIconPath()` helper keyed on `app.isPackaged`, used by every surface that resolves the path at runtime.

**Qt.** The equivalent trap is a filesystem path relative to the build directory that does not exist after `make install` / inside the AppImage. The clean answer is to sidestep it: put the icon in a `.qrc` and reference `:/icons/icon.png`. The asset is then compiled into the binary and resolves identically everywhere. If you must ship it on disk instead, resolve relative to `QCoreApplication::applicationDirPath()`, never relative to the source or build tree.

### Integration points

- **Packaging config** — `package.json` / `electron-builder.yml` and its `extraFiles`/`extraResources` entry; or `CMakeLists.txt` `install()` rules plus the `.desktop` file, plus `linuxdeploy`/`appimage-builder` config.
- **The `.desktop` entry** — `Icon=`, and a filename that matches the `app_id` the app announces. Shared anchor for surfaces 1 and 4, and the *only* icon source under Wayland.
- **Application entry point** — `QGuiApplication` setup, or the main-process window factory (usually more than one `new BrowserWindow(...)` call site).
- **Notification / About code** — uses the same canonical asset.
- **Project runbook** — the replace procedure and its verification belong there (operational reference, exactly what the runbook is for).

### Things Sophie should validate

- **Which display server the target users run.** Wayland makes surfaces 1 and 4 mandatory and surface 2 near-decorative; X11 is the reverse. Assume both unless the project says otherwise.
- **How assets reach the packaged artifact.** *Electron:* `extraFiles` (next to exe) vs `extraResources` (under `resources/`) vs packed into the asar — the correct packaged path differs for each; confirm against this project's builder config rather than assuming. *Qt:* `.qrc` (recommended) vs installed data files.
- **The packaging format.** AppImage → the DE extracts and caches the icon on integration. `.deb`/`.rpm`/Flatpak → the package manager installs it into the system icon theme; different refresh mechanics.
- **The app id / desktop-entry name**, which determines both the installed filename `<app>.png` under `hicolor/*/apps/` and the Wayland `app_id` match.
- Whether the project already has an asset-path helper (Electron) or `.qrc` (Qt); extend it rather than adding a second one.
- Whether ImageMagick (`magick`, v7) is available where artwork is normalized, and whether normalization should be a committed script or a manual documented step.

## Implementation Guidance

### 1. Normalize the artwork (toolkit-independent)

ImageMagick v7, trim → resize → recenter on a fixed canvas:

```sh
magick src.png -trim +repage -resize <N>x<N> -background none -gravity center -extent 1024x1024 icon.png
```

- `-trim +repage` removes the transparent margin **and** resets the virtual canvas offset — without `+repage` the offset survives and downstream tools re-introduce the margin.
- `<N>` is the target artwork size. Start at ~1024 for a true full-bleed result; if the icon still reads small next to its neighbours, go **above** the canvas (e.g. `-resize 1100x1100`) so `-extent 1024x1024` crops the outer halo. Only ever crop glow/shadow, never the subject.
- Vertical nudge, when the icon sits optically high or low: use `-gravity north`/`south` with an explicit `-extent`, or add a `-geometry +0+<dy>` composite step.
- `-background none` keeps the padding transparent; omitting it yields a white box.

Expect to iterate this once with the user against a screenshot of the actual taskbar. Geometric correctness and optical correctness are not the same thing.

### 2. Wire surfaces 1–3

**Electron**

```json
{ "build": { "linux": { "icon": "assets/icons/icon.png" } } }
```

```js
function resolveIconPath() {
  return app.isPackaged
    ? path.join(path.dirname(app.getPath('exe')), 'assets/icons/icon.png')
    : path.join(__dirname, '../../assets/icons/icon.png');
}

app.setDesktopName('com.example.myapp.desktop');   // Wayland app_id match
```

Apply `resolveIconPath()` to **every** `new BrowserWindow({ icon: …, … })` — grep for all construction sites; popup windows are the ones that get forgotten.

**Qt/C++**

```cpp
// resources.qrc:  <qresource prefix="/"><file>icons/icon.png</file></qresource>
QGuiApplication app(argc, argv);
app.setDesktopFileName("com.example.myapp");   // Wayland app_id match
app.setWindowIcon(QIcon(":/icons/icon.png"));  // one call, covers all windows
```

Install the desktop entry and the hicolor PNGs alongside the binary:

```cmake
install(FILES com.example.myapp.desktop DESTINATION share/applications)
install(FILES icons/256.png DESTINATION share/icons/hicolor/256x256/apps
        RENAME com.example.myapp.png)
install(FILES icons/512.png DESTINATION share/icons/hicolor/512x512/apps
        RENAME com.example.myapp.png)
```

Generate `icons/256.png` and `icons/512.png` from the canonical file as a build step so they never drift.

**In-app usages (both)** — point notifications/About at the same canonical asset (`:/icons/icon.png` or `resolveIconPath()`).

### 3. Refresh the desktop environment (KDE Plasma) — identical for both toolkits

After rebuilding, the DE still serves its installed/extracted copies. Overwrite them from the canonical icon, then flush the caches:

```sh
magick assets/icons/icon.png -resize 256x256 ~/.local/share/icons/hicolor/256x256/apps/<app>.png
magick assets/icons/icon.png -resize 512x512 ~/.local/share/icons/hicolor/512x512/apps/<app>.png
rm -f ~/.cache/icon-cache.kcache
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor
kbuildsycoca6
```

If the taskbar still shows the old icon:
```sh
systemctl --user restart plasma-plasmashell.service
```
And note: **a running app keeps its old window icon until it is relaunched** — the window icon is bound at window creation.

### 4. Verify

```sh
cmp <packaged-app-dir>/assets/icons/icon.png assets/icons/icon.png    # Electron
```
For Qt with a `.qrc`, there is no on-disk copy to compare — verify instead that the installed hicolor PNGs match freshly resized copies of the canonical icon, and check the running window icon visually. If `cmp` differs, the build did not pick up the new file — stop and fix that before touching caches.

### Pitfalls

- **Packaged asset paths that only resolve in dev (the big one).** *Electron:* `path.join(__dirname, '../../assets/icons/icon.png')` resolves *inside* `app.asar` in a packaged build, but assets shipped via `extraFiles` sit **next to the executable**. The path silently does not exist — Electron does not throw, it just shows **no** window icon, and the WM falls back to the desktop entry's (stale) icon. This reads exactly like "the DE cache is stale", so it gets misdiagnosed. Use the `app.isPackaged` pattern. *Qt:* the same class of bug with a build-tree-relative path; use `.qrc` and it cannot happen.
- **Assuming X11 semantics on Wayland.** Setting the window icon in code and expecting the taskbar to follow. Under Wayland the compositor reads the `.desktop` entry via `app_id`; an unset or mismatched desktop-file name means a generic icon no matter what you set in code.
- **Fixing one surface and declaring victory.** Four surfaces, four failure modes. Change all four, or the icon changes in some places and not others.
- **Forgetting popup windows (Electron).** Every `BrowserWindow`, not just the main one. Qt's app-wide `setWindowIcon()` avoids this — unless a window overrides it.
- **Trusting the DE to refresh.** KDE extracts an AppImage's icon **once**. Rebuilding the artifact never updates `~/.local/share/icons/hicolor/...`. The installed copies must be overwritten by hand.
- **Skipping `+repage` after `-trim`.** The trim appears to work and the margin comes back.
- **Judging the result without relaunching.** Window icon = window creation time. Launcher icon = after cache flush, sometimes after a plasmashell restart.
- **Hand-maintained copies of the icon in the tree.** The moment a second hand-edited PNG exists, a swap is no longer one replacement and the surfaces drift. Per-size files must be *generated* from the canonical one.
- **Assuming margin-free source artwork.** Check the actual fill ratio (`magick identify` before/after `-trim`); ~75% fill is common and looks wrong beside other icons.

## Test Guidance

Icon work is mostly verification, not unit tests. Cover both.

### Automated / scriptable

- **Asset resolution:** *Electron:* `resolveIconPath()` returns the exe-relative path when `app.isPackaged` is true and the `__dirname`-relative path when false (stub `app`). *Qt:* `QFile::exists(":/icons/icon.png")` — a missing `.qrc` entry fails at test time, not in the taskbar.
- The resolved asset **exists** in both dev and packaged layouts — assert existence, so a silent missing icon fails loudly instead of degrading to no icon.
- **Electron only:** every `BrowserWindow` construction site passes an `icon` (a lint/grep-style guard is enough; it catches the forgotten popup).
- The desktop-file name set in code matches the installed `.desktop` filename (string comparison against the packaging config — catches the Wayland `app_id` mismatch).
- The canonical icon is 1024×1024 with an alpha channel, and its trimmed bounding box covers ≥95% of the canvas.
- Post-build: `cmp` of the packaged/installed icons against copies derived from the canonical source.

### Manual verification (the checklist for a swap)

- Launcher/menu entry shows the new icon after the cache flush.
- Taskbar entry of the **running** app shows the new icon after relaunch.
- Alt-Tab / window switcher shows it.
- Popup/secondary windows show it.
- In-app notification shows it.
- **Both display servers**, if the project supports both — a passing X11 check proves nothing about Wayland.
- The icon's visual size matches neighbouring taskbar icons (the optical check — screenshot beside others).

### Regression risks

- *Electron:* a new `BrowserWindow` added later without an `icon` → silently falls back.
- A build-config change moving assets into the asar or into `resources/` (Electron), or dropping a `.qrc` entry (Qt) → the packaged branch breaks while dev keeps working.
- A renamed `.desktop` file or app id → Wayland icon resolution breaks while X11 keeps working.
- Icon replaced in the repo but the DE-installed copies left stale → looks like the build failed.

## Variations

### Windows `.ico` / macOS `.icns`

Generate the platform formats from the same canonical 1024×1024 PNG (`magick icon.png -define icon:auto-resize=256,128,64,48,32,16 icon.ico`; `iconutil` or `png2icns` for `.icns`) and point `build.win.icon` / `build.mac.icon` — or the Qt/CMake per-platform resource — at them. Keeps the one-canonical-source property across platforms.

### Full hicolor theme install

Instead of only 256 and 512, install the whole ladder (16/24/32/48/64/128/256/512) into `.../icons/hicolor/*/apps/` — worthwhile if the app appears in contexts that request small sizes and a downscaled 512 looks muddy. Generate every size from the canonical file in the build.

### Scalable SVG icon

Ship an SVG at `.../icons/hicolor/scalable/apps/<app>.svg` in addition to the PNGs; the DE prefers it at arbitrary sizes. Requires the source artwork to be vector, and the full-bleed normalization to happen in the vector source rather than via ImageMagick.

### `.deb` / `.rpm` / Flatpak targets

The package manager installs the icon into the system icon theme instead of the DE extracting it from an AppImage. Surface 4 becomes `/usr/share/icons/hicolor/...` owned by the package; the refresh step is the package install plus `gtk-update-icon-cache`, not a manual copy.

### GNOME / other desktop environments

Drop the KDE-specific steps (`icon-cache.kcache`, `kbuildsycoca6`, plasmashell restart); `gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor` plus a re-login covers most GTK-based DEs. The `app_id` ↔ `.desktop` requirement under Wayland is the same everywhere.

### Scripted swap

Turn the replace procedure into a committed `scripts/set-icon.sh <src.png>` that normalizes, overwrites the canonical file, regenerates the per-size copies, refreshes the installed copies, flushes caches, and runs the verification — so the whole swap is one command and the pitfalls cannot be skipped.

### Tray icon

If the app also has a tray icon (`Tray` / `QSystemTrayIcon`), it needs its own asset — often monochrome/symbolic, small, theme-aware — derived from the same artwork but not the same file. Out of scope here by design.
