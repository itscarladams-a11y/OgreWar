# Phase 10.2 — Battlefield controls and challenge

- Camera panning and the FORT/FRONT/OGRES shortcuts now stop before the valley
  ends. The camera limit adapts when a player pinches to zoom; more terrain is
  drawn beyond the legal view.
- The bottom command dock uses one row for the six recruiting/order buttons
  and a second for FORT, FRONT, OGRES and pause. A layout regression checks
  every button against the visible mobile viewport.
- Pinch on the battlefield to zoom between 29.5 and 20.0 world units. A mouse
  wheel provides the same zoom in the desktop build. Pinch gestures do not
  also pan the camera when Android sends synthesized mouse movement.
- The loading painting stays visible on a persistent canvas while the battle
  scene is constructed. It fades after the scene has had frames to render.
- Ogres have 275 starting gold, earn 66 per income interval, decide faster,
  recruit frontline, ranged and siege troops, and fall back to affordable
  defenders when a preferred unit costs too much.

The complete Godot 4.7.2 release gate passed locally, including eight runtime
checks for scene flow, mobile layout, controls, and gameplay. Run
`bash tools/verify_codespaces.sh` and `bash tools/build_android_debug.sh` from
the Codespace repository root to export an APK. A phone install remains
necessary to assess visual timing and difficulty on the actual device.
