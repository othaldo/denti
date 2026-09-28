"""Generate Denti's short, original combat sound effects as mono WAV files."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


RATE = 44_100
TAU = math.tau
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "sfx"


def chirp(time: float, start_hz: float, end_hz: float, duration: float) -> float:
    sweep = (end_hz - start_hz) / duration
    return math.sin(TAU * (start_hz * time + 0.5 * sweep * time * time))


def edge(time: float, duration: float, attack: float = 0.004, release: float = 0.025) -> float:
    return min(time / attack, 1.0, (duration - time) / release)


def ping(time: float, start: float, frequency: float, decay: float = 26.0) -> float:
    if time < start:
        return 0.0
    age = time - start
    return math.sin(TAU * frequency * age) * math.exp(-decay * age) * min(age / 0.003, 1.0)


def generate(name: str, duration: float, seed: int) -> None:
    random_source = random.Random(seed)
    low_noise = 0.0
    samples: list[int] = []
    for index in range(round(duration * RATE)):
        time = index / RATE
        noise = random_source.uniform(-1.0, 1.0)
        low_noise += (noise - low_noise) * 0.09
        airy_noise = noise - low_noise
        envelope = edge(time, duration)

        if name == "toothpaste_shot":
            tone = 0.34 * chirp(time, 880.0, 390.0, duration) * math.exp(-25.0 * time)
            sound = tone + 0.13 * airy_noise * math.exp(-28.0 * time)
        elif name == "enemy_hit":
            tone = 0.43 * chirp(time, 210.0, 75.0, duration) * math.exp(-32.0 * time)
            sound = tone + 0.21 * airy_noise * math.exp(-65.0 * time)
        elif name == "player_hurt":
            tone = chirp(time, 440.0, 180.0, duration)
            sound = (0.30 * tone + 0.07 * chirp(time, 880.0, 360.0, duration)) * math.exp(-8.0 * time)
        elif name == "floss_swish":
            swish = math.sin(math.pi * time / duration)
            sound = 0.28 * airy_noise * swish + 0.11 * chirp(time, 430.0, 1080.0, duration) * swish
        elif name == "drill_strike":
            phase = TAU * (130.0 * time + 0.5 * 115.0 * time * time / duration)
            buzz = math.sin(phase) + 0.34 * math.sin(phase * 3.0) + 0.18 * math.sin(phase * 5.0)
            sound = (0.23 * buzz + 0.09 * airy_noise) * math.exp(-7.0 * time)
        elif name == "acid_shot":
            sound = 0.30 * chirp(time, 360.0, 135.0, duration) * math.exp(-13.0 * time)
            sound += 0.14 * low_noise * math.exp(-8.0 * time)
        elif name == "enemy_down":
            sound = 0.32 * chirp(time, 340.0, 105.0, duration) * math.exp(-20.0 * time)
            sound += 0.14 * ping(time, 0.025, 980.0, 31.0)
        elif name == "pickup":
            sound = 0.29 * ping(time, 0.0, 890.0, 29.0)
            sound += 0.25 * ping(time, 0.068, 1320.0, 25.0)
            sound += 0.07 * ping(time, 0.068, 2640.0, 36.0)
        else:
            raise ValueError(name)

        sample = max(-0.9, min(0.9, sound * envelope))
        samples.append(round(sample * 32767))

    OUTPUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(struct.pack(f"<{len(samples)}h", *samples))


if __name__ == "__main__":
    for cue, length in {
        "toothpaste_shot": 0.15,
        "enemy_hit": 0.12,
        "player_hurt": 0.27,
        "floss_swish": 0.19,
        "drill_strike": 0.24,
        "acid_shot": 0.20,
        "enemy_down": 0.19,
        "pickup": 0.23,
    }.items():
        generate(cue, length, sum(ord(character) for character in cue))
