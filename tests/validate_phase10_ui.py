#!/usr/bin/env python3
"""Verify the playable menu, boot screen, and user-supplied cinematic."""
from pathlib import Path
from struct import unpack

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/ui/phase10'
STUDIO = ROOT / 'assets/ui/bantam'

def png(path: Path, min_width: int, min_height: int, transparent: bool = False) -> None:
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    width, height = unpack('>II', data[16:24])
    assert width >= min_width and height >= min_height, (path, width, height)
    if transparent:
        from PIL import Image
        alpha = Image.open(path).getchannel('A')
        assert alpha.getextrema() == (0, 255), 'Logo must retain alpha transparency'

png(ASSETS / 'menu_backdrop.png', 1280, 720)
png(ASSETS / 'loading_backdrop.png', 1280, 720)
png(ASSETS / 'boot_splash.png', 1280, 720)
png(ASSETS / 'ogre_war_logo.png', 650, 240, transparent=True)
png(ASSETS / 'launcher_crest.png', 512, 512)
png(ASSETS / 'launcher_foreground.png', 432, 432, transparent=True)
png(ASSETS / 'launcher_background.png', 432, 432)
png(STUDIO / 'studio_logo.png', 1600, 600, transparent=True)
png(STUDIO / 'studio_loading_screen.png', 1600, 900)

video = (ASSETS / 'humanitys_last_stand.ogv').read_bytes()
assert video[:4] == b'OggS' and b'theora' in video[:2048]
assert b'vorbis' in video[:8192], 'Cinematic audio track is missing'
assert len(video) > 100_000

project = (ROOT / 'project.godot').read_text()
home = (ROOT / 'scripts/home.gd').read_text()
intro = (ROOT / 'scripts/intro.gd').read_text()
loading = (ROOT / 'scripts/loading.gd').read_text()
assert 'res://assets/ui/phase10/launcher_crest.png' in project
assert 'res://assets/ui/phase10/boot_splash.png' in project
assert 'run/main_scene="res://scenes/studio_splash.tscn"' in project
assert 'launcher_icons/adaptive_foreground_432x432' in (ROOT / 'export_presets.cfg').read_text()
assert 'not OgreWarIntro.has_seen_intro()' in home and 'WATCH STORY' in home
assert 'CINEMATIC_PATH' in intro and 'video.finished.connect(_finish_intro)' in intro
assert 'video.play()' in intro and 'SKIP INTRO' in intro
assert 'res://assets/ui/phase10/loading_backdrop.png' in loading
assert 'BATTLEFIELD COULD NOT LOAD' in loading and 'load_threaded_get_status' in loading
studio = (ROOT / 'scripts/studio_splash.gd').read_text()
assert 'res://assets/ui/bantam/studio_loading_screen.png' in studio
assert 'ResourceLoader.load_threaded_get_status' in studio
assert 'min_value = 0' in studio and 'max_value = 100' in studio
assert 'res://assets/ui/bantam/studio_logo.png' in home
print('PASS: Phase 10 premium menu, loading, and playable cinematic contract')
