#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

need() { grep -Fq "$2" "$1" || { echo "Missing contract in $1: $2" >&2; exit 1; }; }

[ -f scripts/unit_refinement.gd ] || { echo "unit_refinement.gd missing" >&2; exit 1; }
need scripts/unit_visual.gd 'OgreWarUnitRefinement.apply(visual, kind, side, era)'
need scripts/unit_refinement.gd '"hunter":'
need scripts/unit_refinement.gd '"slinger":'
need scripts/unit_refinement.gd '"hauler":'
need scripts/unit_refinement.gd '"shield":'
need scripts/unit_refinement.gd '"bowman":'
need scripts/unit_refinement.gd '"swordsman":'
need scripts/unit_refinement.gd '"lancer":'
need scripts/unit_refinement.gd '"raider":'
need scripts/unit_refinement.gd '"thrower":'
need scripts/unit_refinement.gd '"brute":'
need scripts/unit_refinement.gd '"orc_guard":'
need scripts/unit_refinement.gd '"horn_bow":'
need scripts/unit_refinement.gd '"ram_beast":'
need scripts/unit_refinement.gd '"iron_breaker":'
need scripts/unit_refinement.gd '"warg":'
need scripts/unit_refinement.gd '"ogre_captain":'
need scripts/unit_refinement.gd 'BoneAttachment3D.new()'
need scripts/fortress_detail.gd 'Visible portcullis behind the timber gate.'
need scripts/fortress_detail.gd 'Iron citadel: enormous black-iron crown'
need scripts/fortress_detail.gd 'Bailey-era timber fighting platforms'
need scripts/siege_visual.gd '"enemy_archer"'
need scripts/siege_visual.gd 'OgreWarUnitRefinement.apply(model, refinement_kind, side, refinement_era)'
need scripts/fortress_skin.gd '_skin_node(fort.architecture, fort.side, fort.age)'

echo "Ogre War Castlehold Phase 3 visual refinement contract: PASS"
