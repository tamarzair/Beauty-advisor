# Baddie Blueprint

This repo is Swift source only — there's no `.xcodeproj` checked in. It gets generated from `project.yml` using a free tool called XcodeGen. You only need to do this on a Mac, once (and again any time `project.yml` changes).

## First-time setup (on your Mac)

1. Install Xcode from the Mac App Store, if you don't have it already.
2. Install [Homebrew](https://brew.sh) if you don't have it (one line in Terminal, shown on that site).
3. Install XcodeGen:
   ```
   brew install xcodegen
   ```
4. Clone this repo and generate the Xcode project:
   ```
   git clone <this-repo-url>
   cd Beauty-advisor
   xcodegen generate
   ```
5. Open the project that appears:
   ```
   open BaddieBlueprint.xcodeproj
   ```

## Before you build

In Xcode, select each target (**BaddieBlueprint** and **BaddieBlueprintWidget**) → **Signing & Capabilities** tab → set **Team** to your own Apple ID/developer team. Without this, Xcode won't let you build to a device or simulator.

A few placeholder values you'll want to swap for your own eventually (not required just to build and run locally):

- **App Group ID** (`group.com.tamarzair.baddieblueprint`) — used in `project.yml` (both targets' entitlements) and in `BaddieBlueprint/Shared/SharedDefaults.swift`. If you change one, change both to match.
- **Cloudflare Worker URL** — `VisionAPIClient.endpoint` in `BaddieBlueprint/Networking/VisionAPIClient.swift` still points at a placeholder domain until you deploy `Backend/VisionAnalysisWorker/index.js` and set your own `ANTHROPIC_API_KEY` on it.

## If you change project.yml later

Re-run `xcodegen generate` from the repo root. It's safe to run repeatedly — it regenerates the `.xcodeproj` from scratch each time, so don't hand-edit project settings in Xcode's UI expecting them to stick; put changes in `project.yml` instead.
