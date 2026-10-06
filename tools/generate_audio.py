"""Build original deterministic, royalty-free Ogre War PCM audio with numpy.

Run from the project root: python3 tools/generate_audio.py
Generated 22.05 kHz mono PCM WAV files are included in each release.
"""

from pathlib import Path
import math
import wave

import numpy as np


RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
OUT.mkdir(parents=True, exist_ok=True)
RNG = np.random.default_rng(20471)


def midi(note):
    return 440.0 * 2.0 ** ((note - 69) / 12.0)


def write(name, samples):
    samples = np.asarray(samples, dtype=np.float64)
    samples -= np.mean(samples)
    peak = np.max(np.abs(samples))
    if peak > 0:
        samples *= min(1.0, 0.89 / peak)
    samples = np.tanh(samples * 1.13) * 0.88
    with wave.open(str(OUT / f"{name}.wav"), "wb") as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(np.int16(np.clip(samples, -1, 1) * 32767).tobytes())


def lowpass(signal, hz):
    coefficient = min(0.99, 2 * math.pi * hz / RATE)
    output = np.empty_like(signal)
    previous = 0.0
    for i, value in enumerate(signal):
        previous += coefficient * (value - previous)
        output[i] = previous
    return output


def noise(duration, cutoff=1300):
    n = max(1, int(duration * RATE))
    return lowpass(RNG.normal(0, 1, n), cutoff)


def envelope(n, attack, decay, sustain=0.0):
    t = np.arange(n) / RATE
    return (1 - np.exp(-t / max(0.0005, attack))) * (sustain + (1 - sustain) * np.exp(-t / max(0.002, decay)))


def kick(duration=0.44, body=72):
    n = int(duration * RATE)
    t = np.arange(n) / RATE
    phase = 2 * np.pi * (body * t + 67 * (1 - np.exp(-t * 32)) / 32)
    return (np.sin(phase) * np.exp(-t * 13) + noise(duration, 750) * np.exp(-t * 90) * 0.12) * 0.8


def drum(duration=0.24, tone=260, bright=False):
    n = int(duration * RATE)
    t = np.arange(n) / RATE
    grit = noise(duration, 3300 if bright else 1200)
    return (np.sin(2 * np.pi * (tone * t + 19 * (1 - np.exp(-t * 24)) / 24)) * 0.5 + grit * (0.8 if bright else 0.36)) * np.exp(-t * (18 if bright else 14))


def rattle(duration=0.1, metallic=False):
    n = int(duration * RATE)
    t = np.arange(n) / RATE
    grit = RNG.normal(0, 1, n)
    grit -= lowpass(grit, 1800 if metallic else 780)
    ring = np.sin(2 * np.pi * (3861 if metallic else 1450) * t) * (0.24 if metallic else 0.05)
    return (grit * 0.35 + ring) * np.exp(-t * (42 if metallic else 52))


def tone(note, duration, timbre, attack=0.008, decay=0.8):
    n = max(1, int(duration * RATE))
    t = np.arange(n) / RATE
    frequency = midi(note)
    phase = 2 * np.pi * frequency * t
    if timbre == "bone":
        core = np.sin(phase) + 0.27 * np.sin(phase * 2.01) + 0.12 * np.sin(phase * 3.93)
        core += noise(duration, 560) * 0.065
    elif timbre == "lyre":
        core = np.sin(phase) + 0.35 * np.sin(2 * phase) + 0.19 * np.sin(3 * phase) + 0.1 * np.sin(5 * phase)
        core *= np.exp(-t * 2.3)
    elif timbre == "horn":
        core = np.sin(phase) + 0.33 * np.sin(2 * phase) + 0.17 * np.sin(3 * phase) + 0.08 * np.sin(4 * phase)
    elif timbre == "strings":
        vibrato = 0.007 * np.sin(2 * np.pi * 5.1 * t)
        core = np.sin(phase + vibrato) + 0.4 * np.sin(2 * phase + vibrato) + 0.21 * np.sin(3 * phase)
    else:
        core = np.sin(phase)
    return core * envelope(n, attack, decay, 0.21 if timbre in ("horn", "strings") else 0)


def place(mix, sound, start, level=1.0, wrap=False):
    offset = int(round(start * RATE))
    if wrap:
        offset %= len(mix)
    if offset >= len(mix):
        return
    count = min(len(sound), len(mix) - offset)
    mix[offset:offset + count] += sound[:count] * level
    if wrap and count < len(sound):
        mix[:len(sound) - count] += sound[count:] * level


def make_music(name, bpm, chords, melody, style):
    beat = 60.0 / bpm
    bar = beat * 4
    duration = 8 * bar
    mix = np.zeros(int(round(duration * RATE)))
    for index in range(8):
        begin = index * bar
        chord = chords[index % len(chords)]
        if style == "stone":
            for step in (0, 2):
                place(mix, kick(0.42, 68), begin + step * beat, 0.54, True)
            for step in (1, 3):
                place(mix, drum(0.26, 165), begin + step * beat, 0.25, True)
            for step in (0, 1.5, 2.5, 3.5):
                place(mix, rattle(0.08), begin + step * beat, 0.18, True)
            place(mix, tone(chord[0] - 12, bar * 0.93, "bone", 0.08, 1.25), begin, 0.14, True)
            if index % 2 == 0:
                for j, note in enumerate(melody[index // 2]):
                    place(mix, tone(note, beat * 0.78, "bone", 0.025, 0.4), begin + j * beat, 0.23, True)
        elif style == "bronze":
            for step in (0, 2, 2.75):
                place(mix, kick(0.37, 82), begin + step * beat, 0.47, True)
            for step in (1, 3):
                place(mix, drum(0.22, 300, True), begin + step * beat, 0.23, True)
            for step in np.arange(0, 4, 0.5):
                place(mix, rattle(0.07, True), begin + step * beat, 0.10, True)
            place(mix, tone(chord[0] - 12, beat * 1.7, "horn", 0.1, 1.1), begin, 0.11, True)
            place(mix, tone(chord[0] - 12, beat * 1.4, "horn", 0.1, 0.8), begin + 2 * beat, 0.09, True)
            for j, note in enumerate((chord[0] + 12, chord[1] + 12, chord[2] + 12, chord[1] + 12)):
                place(mix, tone(note, beat * 0.55, "lyre", 0.003, 0.55), begin + j * beat, 0.21, True)
            if index % 2 == 0:
                for j, note in enumerate(melody[index // 2]):
                    place(mix, tone(note, beat * 0.95, "horn", 0.07, 0.62), begin + j * beat, 0.15, True)
        else:
            for step in (0, 1.5, 2, 3.5):
                place(mix, kick(0.42, 66), begin + step * beat, 0.58, True)
            for step in (1, 3):
                place(mix, drum(0.29, 340, True), begin + step * beat, 0.34, True)
            for step in np.arange(0, 4, 0.5):
                place(mix, rattle(0.09, True), begin + step * beat, 0.13, True)
            for note in chord:
                place(mix, tone(note - 12, bar * 0.95, "strings", 0.15, 1.85), begin, 0.073, True)
            for step, note in enumerate((chord[0] - 12, chord[0], chord[2], chord[1], chord[0] - 12, chord[0], chord[2], chord[1])):
                place(mix, tone(note, beat * 0.37, "strings", 0.005, 0.22), begin + step * beat * 0.5, 0.13, True)
            if index % 2 == 0:
                for j, note in enumerate(melody[index // 2]):
                    place(mix, tone(note, beat * 0.91, "horn", 0.06, 0.54), begin + j * beat, 0.17, True)
    # Small fade removes single-sample discontinuities without muting the beat.
    edge = int(0.009 * RATE)
    mix[:edge] *= np.linspace(0, 1, edge)
    mix[-edge:] *= np.linspace(1, 0, edge)
    write(name, mix * 0.8)


def whoosh(duration=0.25, brightness=2200):
    n = int(duration * RATE)
    t = np.arange(n) / RATE
    return (noise(duration, brightness) - noise(duration, 460)) * np.sin(np.pi * t / duration) ** 1.5


def ring(duration, frequencies, decay):
    t = np.arange(int(duration * RATE)) / RATE
    return sum(np.sin(2 * np.pi * f * t) * (1 - i * 0.2) for i, f in enumerate(frequencies)) * np.exp(-t * decay)


def effect(name, layers, duration):
    mix = np.zeros(int(duration * RATE))
    for sound, delay, volume in layers:
        place(mix, sound, delay, volume)
    edge = min(int(0.012 * RATE), len(mix) // 3)
    mix[-edge:] *= np.linspace(1, 0, edge)
    write(name, mix)


def make_effects():
    effect("stone_club", [(whoosh(0.21, 750), 0, 0.24), (kick(0.39, 72), 0.13, 0.67), (drum(0.24, 105), 0.13, 0.35)], 0.58)
    effect("bone_spear", [(whoosh(0.18, 1350), 0, 0.37), (drum(0.19, 310), 0.14, 0.36)], 0.41)
    effect("stone_sling", [(whoosh(0.19, 1600), 0, 0.3), (ring(0.2, (840, 1110), 24), 0.16, 0.23)], 0.4)
    effect("stone_rock", [(whoosh(0.23, 950), 0, 0.23), (drum(0.36, 120), 0.16, 0.55), (noise(0.23, 600), 0.18, 0.16)], 0.57)
    effect("ogre_club", [(whoosh(0.27, 650), 0, 0.32), (kick(0.52, 52), 0.2, 0.83), (drum(0.3, 99), 0.2, 0.48)], 0.77)
    effect("bronze_shield", [(whoosh(0.18, 1100), 0, 0.2), (ring(0.55, (510, 840, 1370), 8), 0.12, 0.28), (drum(0.2, 240, True), 0.12, 0.25)], 0.75)
    effect("bronze_blade", [(whoosh(0.27, 3000), 0, 0.25), (ring(0.48, (920, 1260, 1980), 12), 0.15, 0.21), (rattle(0.1, True), 0.15, 0.30)], 0.67)
    effect("bow", [(ring(0.34, (112, 224, 448), 18), 0, 0.26), (whoosh(0.26, 2800), 0.05, 0.16)], 0.39)
    effect("ram", [(whoosh(0.24, 820), 0, 0.16), (kick(0.53, 51), 0.19, 0.8), (ring(0.43, (86, 173, 280), 7), 0.2, 0.25)], 0.78)
    # Dissonant detuned partials and a falling sweep give Iron blades a flanging tail.
    t = np.arange(int(0.64 * RATE)) / RATE
    sweep = np.sin(2 * np.pi * (840 * t + 330 * (1 - np.exp(-7 * t)) / 7))
    flange = (np.sin(2 * np.pi * 1330 * t) + np.sin(2 * np.pi * 1344 * t)) * np.exp(-t * 10)
    effect("iron_sword", [(whoosh(0.2, 3500), 0, 0.22), ((sweep * 0.48 + flange * 0.38) * np.exp(-t * 6), 0.11, 0.37), (rattle(0.1, True), 0.11, 0.33)], 0.81)
    effect("iron_lance", [(whoosh(0.26, 2900), 0, 0.31), (ring(0.53, (760, 1510, 2275), 11), 0.18, 0.24), (drum(0.19, 260, True), 0.18, 0.2)], 0.77)
    effect("torsion", [(ring(0.25, (115, 230, 410), 18), 0, 0.28), (whoosh(0.29, 1700), 0.12, 0.23), (drum(0.34, 95), 0.32, 0.48)], 0.78)
    effect("warg", [(ring(0.38, (93, 148, 209), 9), 0, 0.36), (noise(0.31, 700), 0, 0.15), (drum(0.21, 152), 0.26, 0.39)], 0.59)
    effect("shield_hit", [(ring(0.43, (390, 718, 1240), 13), 0, 0.32), (rattle(0.1, True), 0, 0.25)], 0.47)
    effect("gate_hit", [(kick(0.46, 59), 0, 0.57), (ring(0.42, (99, 188, 278), 10), 0.02, 0.24)], 0.49)
    effect("age_up", [(ring(0.81, (261, 329, 392), 4), 0, 0.19), (ring(0.83, (392, 523, 659), 4), 0.37, 0.25), (drum(0.4, 135), 0, 0.25)], 1.2)
    effect("victory", [(ring(1.3, (261, 329, 392), 2.9), 0, 0.19), (ring(1.12, (392, 493, 587), 3), 0.25, 0.22), (ring(1.3, (523, 659, 784), 2.7), 0.52, 0.24)], 2.1)
    effect("defeat", [(ring(1.5, (97, 146, 185), 2.5), 0, 0.25), (ring(1.5, (82, 123, 155), 2.7), 0.4, 0.24), (drum(0.61, 73), 0, 0.26)], 2.15)


if __name__ == "__main__":
    make_music("music_stone", 96, [(45, 48, 52), (43, 47, 50), (41, 45, 48), (43, 47, 50)], [(69, 72, 74, 72), (67, 69, 72, 67), (65, 69, 72, 69), (67, 69, 72, 74)], "stone")
    make_music("music_bronze", 112, [(50, 53, 57), (46, 50, 53), (48, 52, 55), (45, 48, 52)], [(74, 77, 76, 74), (70, 74, 72, 70), (72, 76, 74, 72), (69, 72, 76, 77)], "bronze")
    make_music("music_iron", 126, [(40, 43, 47), (36, 40, 43), (38, 41, 45), (35, 38, 42)], [(76, 79, 83, 79), (72, 76, 79, 76), (74, 77, 81, 77), (71, 74, 78, 83)], "iron")
    make_effects()
    for path in sorted(OUT.glob("*.wav")):
        print(path.name, path.stat().st_size)
