#!/usr/bin/env python3
from pathlib import Path
from collections import defaultdict
import json, re, wave, xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
errors = []
files = [p for p in ROOT.rglob('*') if p.is_file() and '.git' not in p.parts and '.godot' not in p.parts and 'build' not in p.parts]

for p in files:
    if p.stat().st_size == 0:
        errors.append(f'zero-byte file: {p.relative_to(ROOT)}')

case_map = defaultdict(list)
for p in files:
    case_map[str(p.relative_to(ROOT)).lower()].append(str(p.relative_to(ROOT)))
for paths in case_map.values():
    if len(paths) > 1:
        errors.append('case-collision: ' + ', '.join(paths))

# Pillow is optional in Codespaces. Verify PNG signature/IHDR without it.
for p in ROOT.rglob('*.png'):
    data = p.read_bytes()
    if len(data) < 33 or data[:8] != b'\x89PNG\r\n\x1a\n' or data[12:16] != b'IHDR':
        errors.append(f'invalid PNG header: {p.relative_to(ROOT)}')

for p in ROOT.rglob('*.svg'):
    try:
        ET.parse(p)
    except Exception as exc:
        errors.append(f'invalid SVG {p.relative_to(ROOT)}: {exc}')

for p in ROOT.rglob('*.wav'):
    try:
        with wave.open(str(p), 'rb') as w:
            if w.getnframes() <= 0 or w.getframerate() <= 0 or w.getnchannels() <= 0:
                raise ValueError('empty/invalid WAV metadata')
    except Exception as exc:
        errors.append(f'invalid WAV {p.relative_to(ROOT)}: {exc}')

for p in ROOT.rglob('*.ogg'):
    if p.read_bytes()[:4] != b'OggS':
        errors.append(f'invalid OGG signature: {p.relative_to(ROOT)}')

for p in ROOT.rglob('*.gltf'):
    try:
        doc = json.loads(p.read_text())
        for buf in doc.get('buffers', []):
            uri = buf.get('uri', '')
            if uri and not uri.startswith('data:'):
                bp = p.parent / uri
                if not bp.is_file():
                    raise FileNotFoundError(uri)
                if buf.get('byteLength', 0) > bp.stat().st_size:
                    raise ValueError(f'buffer shorter than byteLength: {uri}')
    except Exception as exc:
        errors.append(f'invalid glTF {p.relative_to(ROOT)}: {exc}')

for p in ROOT.rglob('*.obj'):
    vertices = 0
    try:
        for line_no, raw in enumerate(p.read_text(errors='strict').splitlines(), 1):
            line = raw.strip()
            if line.startswith('v '):
                vertices += 1
            elif line.startswith('f '):
                for token in line.split()[1:]:
                    idx = int(token.split('/')[0])
                    if idx == 0 or (idx > 0 and idx > vertices):
                        raise ValueError(f'bad face index {idx} at line {line_no}, vertices={vertices}')
        if vertices == 0:
            raise ValueError('OBJ has no vertices')
    except Exception as exc:
        errors.append(f'invalid OBJ {p.relative_to(ROOT)}: {exc}')


# In a full repository checkout, verify literal res:// references as well. The
# standalone overlay intentionally omits original base-repo assets, so defer
# this check until project.godot is present.
if (ROOT / 'project.godot').is_file():
    ref_re = re.compile(r'res://[^"\'\s\)\],}]+')
    for source in [*ROOT.rglob('*.gd'), *ROOT.rglob('*.tscn'), ROOT / 'project.godot']:
        if not source.is_file():
            continue
        text = source.read_text(errors='strict')
        for ref in ref_re.findall(text):
            if '%' in ref or ref.endswith('/'):
                continue
            target = ROOT / ref[len('res://'):]
            if not target.exists():
                errors.append(f'missing resource reference {ref} from {source.relative_to(ROOT)}')

classes = defaultdict(list)
for p in ROOT.rglob('*.gd'):
    text = p.read_text(errors='strict')
    for cls in re.findall(r'^class_name\s+(\w+)', text, re.M):
        classes[cls].append(str(p.relative_to(ROOT)))
    for line_no, line in enumerate(text.splitlines(), 1):
        prefix = re.match(r'^[ \t]+', line)
        if prefix and ' ' in prefix.group(0) and '\t' in prefix.group(0):
            errors.append(f'mixed indentation: {p.relative_to(ROOT)}:{line_no}')
for cls, paths in classes.items():
    if len(paths) > 1:
        errors.append(f'duplicate class_name {cls}: {paths}')

if errors:
    print('RELEASE ASSET AUDIT FAILED')
    for err in errors:
        print(' -', err)
    raise SystemExit(1)
print(f'Ogre War release asset audit: PASS ({len(files)} files checked)')
