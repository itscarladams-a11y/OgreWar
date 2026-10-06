from pathlib import Path
OUT=Path('/mnt/data/ogre_phase5/assets/ogre_modern/ui/phase5')
OUT.mkdir(parents=True,exist_ok=True)

def svg(name, body, accent='#e0b85c'):
    text=f'''<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96">
<defs><filter id="s"><feDropShadow dx="0" dy="2" stdDeviation="1.5" flood-opacity=".55"/></filter></defs>
<g fill="none" stroke="{accent}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" filter="url(#s)">{body}</g>
</svg>'''
    (OUT/f'{name}.svg').write_text(text)

icons={
'hunter': '<path d="M18 76L49 18M41 24l18-4-8 16M28 57l17 10"/><path d="M15 80l8-12"/>',
'slinger':'<path d="M23 22c18 11 25 22 25 37s-7 24-21 25"/><path d="M48 59l25-22M73 37l8 2-5 7"/><circle cx="25" cy="23" r="5"/>',
'hauler':'<path d="M21 71h54M28 69l10-38h20l10 38M34 48h28"/><circle cx="38" cy="76" r="8"/><circle cx="60" cy="76" r="8"/>',
'shield':'<path d="M48 14l25 9v22c0 18-10 29-25 37C33 74 23 63 23 45V23z"/><path d="M48 25v42M34 43h28"/>',
'bowman':'<path d="M24 17c29 20 29 42 0 62M25 18l42 30-42 31M58 42l13 6-13 6"/>',
'ram':'<path d="M19 58h55M26 58V33h41v25M34 34l14-14 14 14M17 50l58-8"/><circle cx="31" cy="72" r="9"/><circle cx="62" cy="72" r="9"/>',
'swordsman':'<path d="M26 76l45-55M61 18l14 3-4 14M33 59l12 12M23 79l8-3"/><path d="M20 25l20 20"/>',
'lancer':'<path d="M17 77L79 15M70 16h10v10M31 63l12 12"/><path d="M22 37c12-8 24-8 36 0"/>',
'torsion':'<path d="M20 67h58M29 67V41h38v26M38 41l10-18 10 18M25 52h46M48 23l30 25"/><circle cx="32" cy="75" r="7"/><circle cx="65" cy="75" r="7"/>',
'age':'<path d="M20 70h56M30 70V37h36v33M38 37V24h20v13M48 15v9"/>',
'hold':'<path d="M23 18v60M73 18v60M23 48h50"/>',
'repair':'<path d="M18 68l26-26M50 36l11-11 10 10-11 11M42 44l10 10-24 24H18v-10z"/>',
'fort':'<path d="M18 76h60V36H18zM24 36V22h12v14M42 36V18h12v18M60 36V22h12v14M38 76V57h20v19"/>',
'front':'<path d="M18 48h53M57 33l15 15-15 15"/><path d="M26 28v40"/>',
'ogres':'<path d="M24 67c0-22 10-38 24-38s24 16 24 38M35 34l-8-15M61 34l8-15M38 52h3M55 52h3M40 63c6 4 10 4 16 0"/>',
'pause':'<path d="M34 21v54M62 21v54"/>',
'gold':'<circle cx="48" cy="48" r="28"/><path d="M39 31h18M39 65h18M48 31v34"/>',
}
for name,body in icons.items(): svg(name,body)
print('icons',len(icons))
