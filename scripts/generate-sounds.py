#!/usr/bin/env python3
"""Deterministic offline Foley synthesis; no recordings or third-party samples."""
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "Sources/CyberBlessing/Resources"
RATE = 44100
rng = random.Random(20261005)

def write(name, samples, peak=0.85):
    bound = max(abs(x) for x in samples) or 1
    pcm = b''.join(struct.pack('<h', int(max(-1, min(1, x / bound * peak)) * 32767)) for x in samples)
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as wav:
        wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(RATE); wav.writeframes(pcm)

def clack(duration, impacts, bead=False):
    samples = [0.0] * int(duration * RATE)
    for onset, gain in impacts:
        start = int(onset * RATE)
        previous_noise = 0
        for n in range(len(samples) - start):
            t = n / RATE
            noise = rng.uniform(-1, 1)
            crisp = (noise - previous_noise * 0.75) * math.exp(-t / 0.0035)
            previous_noise = noise
            # Inharmonic, rapidly damped hard-wood modes with a short broadband attack.
            resonant = sum(a * math.sin(2 * math.pi * f * t + p) * math.exp(-t / d)
                for f, a, d, p in [(780, .22, .021, .1), (1740, .43, .015, .4),
                                  (2860, .32, .010, 1.2), (4120, .14, .007, .9)])
            thud = .12 * math.sin(2 * math.pi * 310 * t) * math.exp(-t / .025)
            attack = min(1, t / .0004)
            samples[start+n] += gain * attack * (.62 * crisp + resonant + thud)
    return samples

# Two slightly offset wooden cups contact a hard floor, followed by small rebounds.
write('wood-clack', clack(.40, [(0, 1), (.021, .78), (.113, .22), (.178, .09)]))
write('bead-click', clack(.085, [(0, 1)]), peak=.55)

scratch = []
last = 0
for n in range(int(.34 * RATE)):
    t = n / RATE
    noise = rng.uniform(-1, 1)
    envelope = math.sin(math.pi * min(1, t / .31)) ** .8 if t < .31 else 0
    grit = .7 + .3 * math.sin(2 * math.pi * (45 * t + 70 * t*t))
    scratch.append((noise - .55*last) * envelope * grit)
    last = noise
write('match-strike', scratch, peak=.58)

flare=[]
last=0
for n in range(int(.47 * RATE)):
    t=n/RATE
    noise=rng.uniform(-1,1)
    last=last*.91+noise*.09
    env=(1-math.exp(-t/.007))*math.exp(-t/.10)
    crackle=noise if rng.random() > .996 else 0
    flare.append((last*2+.20*crackle)*env)
write('match-light', flare, peak=.5)
print('Created wood-clack, bead-click, match-strike and match-light (44.1 kHz PCM)')
