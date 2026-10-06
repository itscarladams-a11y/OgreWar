# Ogre War — Modern Mobile Presentation Pass

This update moves Ogre War from a visually competent 3D prototype toward a modern stylized mobile presentation without adding new gameplay systems.

## Fortress architecture

The visible castle/stronghold shell is no longer built primarily from runtime BoxMesh/CylinderMesh pieces. Eight reusable Ogre War OBJ modules are included under `assets/ogre_modern/fortress_modules/`:

- human wall
- human tower
- human gatehouse
- human keep
- ogre wall
- ogre tower
- ogre gatehouse
- ogre keep

The modules use Castlehold sandstone/oak/slate texture and normal maps at runtime. MarchFortress remains the gameplay authority for gate/keep health and age progression; the functional gate stays visible while the old procedural architecture is suppressed to avoid doubled walls and z-fighting.

Stone/Bronze/Iron continue to alter scale, trim and silhouette. Humans remain ordered Western-European fortifications; ogres remain asymmetric, spiked and dark-stone fantasy strongholds.

## Lighting and atmosphere

- Short-distance two-split directional shadows are enabled for battlefield depth.
- Imported Castlehold troop meshes explicitly cast shadows.
- Contact-shadow decal opacity is reduced so real shadows do not create black blobs.
- A cool non-shadowing fill light keeps dark ogre armor readable.
- Filmic tonemapping, height fog and SSAO are requested through Environment properties.
- Existing campfires now provide small non-shadowing warm OmniLight pools.

The shadow field is intentionally bounded for mobile rather than using an unlimited expensive shadow distance.

## Battle HUD

`scripts/battle_hud.gd` is replaced with a modernized battle layout:

- separate Human Keep and Ogre Stronghold panels;
- dedicated keep/gate ProgressBars;
- age labels for both factions;
- compact centered economy/army/time/progression presentation;
- styled recruit cards and command buttons;
- visually distinct age, order, repair, navigation and danger roles;
- branded pause/result modals.

All existing MarchMatch callbacks are preserved.

## Combat weight

- Heavy hits and structure impacts build a small trauma value instead of using full-screen flashes.
- The camera movement is short, decays quickly and uses squared trauma so ordinary combat stays stable.
- Heavy impacts add a localized expanding shock-disc VFX to the existing pooled sparks/chips/dust.
- Gate breaks and keep destruction receive stronger trauma than normal hits.

## Scope boundary

This pass deliberately does not add new troops, ages, resources or game modes. It is a presentation update.

A real Godot 4.7.2 import and Android device run is still required to judge final shadow stability, OBJ import scale, UI safe-area behavior and frame pacing.
