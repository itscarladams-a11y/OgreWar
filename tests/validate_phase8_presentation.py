from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
required = [
    'assets/ogre_modern/ui/phase8/human_crest.svg',
    'assets/ogre_modern/ui/phase8/ogre_crest.svg',
    'assets/ogre_modern/ui/phase8/coin.svg',
    'assets/ogre_modern/ui/phase8/army.svg',
    'assets/ogre_modern/ui/phase8/timer.svg',
    'scripts/home.gd','scripts/loading.gd','scripts/battle_hud.gd','PHASE8_PREMIUM_PRESENTATION.md'
]
for rel in required:
    p=ROOT/rel
    assert p.is_file() and p.stat().st_size > 0, f'missing {rel}'
hud=(ROOT/'scripts/battle_hud.gd').read_text()
loading=(ROOT/'scripts/loading.gd').read_text()
home=(ROOT/'scripts/home.gd').read_text()
battle=(ROOT/'scripts/battlefield_art.gd').read_text()
units=(ROOT/'scripts/unit_visual.gd').read_text()
assert 'Stack/Age' not in hud
assert 'human_progress_bar' in hud and 'orc_progress_bar' in hud
assert 'banner_wrap.visible = false' in hud
assert 'human_crest.svg' in hud and 'ogre_crest.svg' in hud
assert 'ENTERING THE VALLEY' in loading and 'load_threaded_get_status' in loading
assert 'THE VALLEY WILL REMEMBER WHO HOLDS IT' in home
assert 'fog_density", 0.003' in battle
assert 'fog_height_density", 0.035' in battle
assert 'Color("d9c7aa")' in units and 'Color("a89472")' in units
print('PASS: Ogre War Phase 8 premium presentation contract')
