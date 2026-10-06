# Phase 10.3 — Battlefield presentation pass

- A world-space ground shader replaces repeated straight road overlays with
  curved, worn tracks, uneven verges, trampled midfield and local soil around
  both castles. The previous one-sided castle stain has been fixed.
- Ridges receive a subtle top-to-base color gradient. Verges now hold 460
  color-varied grass clumps in one MultiMesh draw instead of 92 grass nodes.
- Status and all ten action buttons fit into compact top and single-row bottom
  panels at 1280×720, exposing more of the troops during battle. The first
  battle banner explains the drag and pinch gestures.
- Existing Phase 10.2 camera limits, loading cover and stronger ogre AI remain
  in place.

Run `bash tools/verify_codespaces.sh` and `bash tools/build_android_debug.sh`
from the Codespace repository root. Headless tests verify the assets, GDScript,
scene flow, UI bounds and game rules. Check scenery, text size, startup timing
and sustained frame rate on a real Android phone before judging the art pass.
