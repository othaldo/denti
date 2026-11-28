"""Render Denti's instrumental score with Python and FFmpeg."""

import argparse
import math
import struct
import subprocess
import tempfile
import wave
from array import array
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SAMPLE_RATE = 32_000
TAU = math.tau


@dataclass(frozen=True)
class Arrangement:
    bpm: int
    bars: int
    lead: str
    accompaniment: str
    rhythm: str
    harmony: str = "dorian"


SCORE = {
    "denti": Arrangement(104, 32, "bell", "pizz", "march"),
    "intermission": Arrangement(80, 24, "harp", "pizz", "quiet"),
    "victory": Arrangement(96, 20, "strings", "harp", "quiet", "victory"),
    "arena": Arrangement(130, 32, "pizz", "harp", "march"),
    "arena-late": Arrangement(138, 32, "strings", "pluck", "running"),
    "pillow": Arrangement(98, 28, "bell", "harp", "lullaby"),
    "sugar": Arrangement(144, 32, "pizz", "bell", "swing", "sugar"),
    "acid": Arrangement(118, 32, "pluck", "bell", "pulse", "minor"),
    "palace": Arrangement(124, 32, "strings", "harp", "march", "minor"),
    "boss": Arrangement(148, 32, "pizz", "organ", "swing", "minor"),
    "boss-alt": Arrangement(142, 32, "pluck", "organ", "pulse", "minor"),
    "finale": Arrangement(150, 32, "strings", "organ", "running", "minor"),
    "finale-overtime": Arrangement(158, 32, "organ", "pluck", "pulse", "minor"),
    "endless": Arrangement(154, 32, "pluck", "harp", "running", "dorian"),
    "endless-double": Arrangement(164, 32, "organ", "bell", "running", "minor"),
}

CHORDS = {
    "Dm": (38, 53, 57, 62),
    "Bb": (34, 53, 58, 62),
    "F": (41, 53, 57, 60),
    "C": (36, 52, 55, 60),
    "G": (43, 55, 59, 62),
    "Gm": (43, 55, 58, 62),
    "Am": (45, 52, 57, 60),
    "A": (45, 52, 57, 61),
    "D": (38, 54, 57, 62),
}

HARMONIES = {
    "dorian": ("Dm Bb G Am", "Dm F C A", "Bb F G A", "Dm Bb G A"),
    "sugar": ("Dm F Bb A", "Dm Gm F A", "F C Bb A", "Dm F G A"),
    "minor": ("Dm Bb Gm A", "Dm C Bb A", "Gm Bb Dm A", "Dm Bb Gm A"),
    "victory": ("D G F A", "D F G A", "Bb F G A", "D G D D"),
}

# Each row is one bar. The first row is the five-note motif shared by all cues.
MELODY = (
    ((0, 74, .42), (.5, 77, .42), (1, 79, .42), (1.5, 81, 1.33), (3, 77, .78)),
    ((0, 77, .85), (1, 74, .88), (2, 72, .45), (2.5, 74, 1.35)),
    ((0, 74, .42), (.5, 79, .42), (1, 77, .42), (1.5, 81, 1.55)),
    ((0, 76, 1.22), (1.5, 72, .44), (2, 73, 1.35)),
    ((.5, 81, .43), (1, 84, .84), (2, 86, 1.7)),
    ((0, 84, .88), (1, 81, .42), (1.5, 79, .42), (2, 77, 1.78)),
    ((0, 79, .83), (1, 77, .42), (1.5, 74, 1.35)),
    ((.5, 76, .42), (1, 77, .42), (1.5, 73, 1.95)),
)

GM_PROGRAM = {"bell": 8, "harp": 46, "strings": 48, "pizz": 45, "organ": 19, "pluck": 80, "bass": 42}


def score_events(arrangement):
    """Return note events as beats, duration, MIDI note, voice, gain and pan."""
    for bar in range(arrangement.bars):
        start = bar * 4
        phrase, step = divmod(bar, 4)
        section = (phrase // 2) % 4
        chord_name = HARMONIES[arrangement.harmony][section].split()[step]
        root, low, middle, high = CHORDS[chord_name]
        rhythm = arrangement.rhythm
        is_quiet = rhythm in ("quiet", "lullaby")
        is_climax = section in (2, 3)
        is_victory = arrangement.harmony == "victory"
        descent = is_victory and bar == arrangement.bars - 1

        if bar % 8 < 4 or section != 1:
            melodic_bar = bar % 8 if is_climax or phrase % 2 else step
            melody = MELODY[melodic_bar]
            if descent:
                melody = ((0, 74, 2.7),)
            for offset, note, hold in melody:
                if is_victory and chord_name in ("D", "G") and note % 12 == 5:
                    note += 1
                if chord_name == "Am" and note == 73:
                    note = 72
                if rhythm in ("swing", "lullaby") and offset % 1 == .5:
                    offset += .12
                yield start + offset, hold, note, arrangement.lead, .37, -.13
                if is_climax and not is_quiet:
                    yield start + offset, hold, note - 12, "strings", .13, .19
        else:
            yield start + .5, 1.1, middle + 12, arrangement.accompaniment, .23, .2
            yield start + 2, 1.5, low + 12, arrangement.accompaniment, .22, -.2

        arpeggio = (low, middle, high, middle + 12, high, middle, low, high)
        if rhythm == "lullaby":
            pattern = ((0, 0), (.66, 1), (1.33, 2), (2, 3), (2.66, 4), (3.33, 2))
        elif rhythm == "quiet":
            pattern = ((0, 0), (1, 2), (2.5, 1), (3.25, 4))
        elif rhythm == "pulse":
            pattern = ((0, 0), (.75, 1), (1.5, 2), (2.5, 4), (3, 6), (3.5, 5))
        elif rhythm == "swing":
            pattern = ((0, 0), (.66, 1), (1, 2), (1.66, 3), (2, 2), (2.66, 5), (3, 6), (3.66, 7))
        elif rhythm == "march":
            pattern = ((0, 0), (.5, 1), (1.5, 2), (2, 3), (2.5, 4), (3.5, 6))
        else:
            pattern = tuple((index * .5, index) for index in range(8))
        for offset, index in pattern:
            yield start + offset, .45 if is_quiet else .31, arpeggio[index], arrangement.accompaniment, .155, .39 - index * .09

        yield start, 3.5, low, "strings", .11, -.34
        yield start, 3.55, high if is_climax else middle, "strings", .095, .38
        bass_pattern = ((0, 3.7),) if is_quiet else ((0, 1.18), (1.5, .41), (2, .79), (3.25, .38))
        for index, (offset, hold) in enumerate(bass_pattern):
            yield start + offset, hold, root + (7 if index == 2 else 0), "bass", .26, 0

        if rhythm != "quiet":
            for offset in ((0, 1.5, 3) if rhythm == "pulse" else (0, 2.5)):
                yield start + offset, .34, 35, "drum", .22, 0
            for offset in (1, 3):
                yield start + offset, .15, 38, "rim", .13, .18
            for offset in (0.5, 1.5, 2.5, 3.5):
                yield start + offset, .10, 42, "shaker", .07, -.35
        elif is_victory and bar in (0, 8):
            yield start, .7, 35, "drum", .18, 0


@lru_cache(maxsize=1024)
def sample_note(voice, note, frames):
    frequency = 440 * 2 ** ((note - 69) / 12)
    angular_frequency = TAU * frequency
    partials = {
        "bell": ((1, .73), (2.01, .19), (3.98, .045), (5.42, .012)),
        "harp": ((1, .70), (2, .17), (3, .08), (4, .035), (5, .025)),
        "pizz": ((1, .55), (2, .21), (3, .14), (4, .05), (6, .022)),
        "strings": ((1, .59), (1.0025, .19), (2, .13), (3, .07), (5, .05)),
        "organ": ((1, .62), (.5, .15), (2, .16), (3, .06), (4, .03)),
        "pluck": ((1, .60), (2, .16), (3.002, .11), (4, .05), (5, .045)),
        "bass": ((1, .78), (2, .16), (3, .06)),
    }
    transients = {"bell": 4.3, "harp": 7.5, "pizz": 9.0, "strings": .35, "organ": .30, "pluck": 5.1, "bass": 1.1}
    attack = {"strings": .12, "organ": .055, "bass": .027}.get(voice, .007)
    release = {"strings": .19, "organ": .15, "bell": .24, "harp": .10}.get(voice, .067)
    duration = frames / SAMPLE_RATE
    harmonics = partials.get(voice, ())
    decay = transients.get(voice, 20)
    signal = array("f")
    noise_seed = 2231 + note
    previous_noise = 0.0
    for index in range(frames + round(release * SAMPLE_RATE)):
        time = index / SAMPLE_RATE
        gate = min(1.0, time / attack, (duration + release - time) / release)
        if voice == "drum":
            tone = math.sin(TAU * (48 * time + 2.2 * (1 - math.exp(-time * 42))))
            envelope = math.exp(-time * 17)
        elif voice in ("rim", "shaker"):
            noise_seed = (1664525 * noise_seed + 1013904223) & 0xFFFFFFFF
            noise = noise_seed / 2**31 - 1
            tone = (noise - previous_noise * .8) * .45
            previous_noise = noise
            if voice == "rim":
                tone += .36 * math.sin(TAU * 195 * time)
            envelope = math.exp(-time * (39 if voice == "shaker" else 24))
        else:
            phase = angular_frequency * time
            if voice == "strings":
                phase += .10 * math.sin(TAU * 4.7 * time)
            tone = sum(math.sin(phase * ratio) * gain for ratio, gain in harmonics)
            envelope = math.exp(-time * decay)
        signal.append(tone * envelope * max(0.0, gate))
    return signal


def render(arrangement, output):
    beat_seconds = 60 / arrangement.bpm
    frame_count = round(arrangement.bars * 4 * beat_seconds * SAMPLE_RATE)
    left = array("f", [0]) * frame_count
    right = array("f", [0]) * frame_count
    for start, duration, note, voice, gain, pan in score_events(arrangement):
        offset = round(start * beat_seconds * SAMPLE_RATE)
        sample_length = round(duration * beat_seconds * SAMPLE_RATE)
        sound = sample_note(voice, note, sample_length)
        left_gain = gain * math.sqrt((1 - pan) * .5)
        right_gain = gain * math.sqrt((1 + pan) * .5)
        for index, value in enumerate(sound, offset):
            target = index % frame_count
            left[target] += value * left_gain
            right[target] += value * right_gain

    # Circular stereo room taps decay naturally across the loop join.
    taps = tuple((round(delay * SAMPLE_RATE), level) for delay, level in ((.029, .105), (.047, .085), (.089, .065), (.137, .045), (.241, .035)))
    peak = max(max(map(abs, left)), max(map(abs, right)))
    level = .79 / peak
    pcm = array("h")
    for index, (left_sample, right_sample) in enumerate(zip(left, right)):
        for tap, amount in taps:
            left_sample += right[index - tap] * amount
            right_sample += left[index - tap] * amount
        pcm.append(round(32767 * math.tanh(left_sample * level)))
        pcm.append(round(32767 * math.tanh(right_sample * level)))
    with tempfile.TemporaryDirectory() as temp_dir:
        path = Path(temp_dir) / "cue.wav"
        with wave.open(str(path), "wb") as audio:
            audio.setparams((2, 2, SAMPLE_RATE, 0, "NONE", "not compressed"))
            audio.writeframes(pcm.tobytes())
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(path), "-c:a", "libvorbis", "-q:a", "4", str(output)], check=True)


def midi_delta(value):
    result = [value & 0x7F]
    while value >= 128:
        value >>= 7
        result.insert(0, (value & 0x7F) | 0x80)
    return bytes(result)


def write_midi(arrangement, path):
    ticks_per_beat = 480
    tempo = round(60_000_000 / arrangement.bpm)
    events = [(0, b"\xff\x51\x03" + tempo.to_bytes(3, "big"))]
    channels = {}
    for start, duration, note, voice, gain, _ in score_events(arrangement):
        if voice in GM_PROGRAM and voice not in channels:
            channel = channels[voice] = len(channels)
            events.append((0, bytes((0xC0 + channel, GM_PROGRAM[voice]))))
        channel = channels.get(voice, 9)
        velocity = min(110, round(42 + 150 * gain))
        events.append((round(start * ticks_per_beat), bytes((0x90 + channel, note, velocity))))
        events.append((round((start + duration) * ticks_per_beat), bytes((0x80 + channel, note, 0))))
    previous_tick = 0
    track = bytearray()
    for tick, data in sorted(events, key=lambda event: event[0]):
        track.extend(midi_delta(tick - previous_tick) + data)
        previous_tick = tick
    end = arrangement.bars * 4 * ticks_per_beat
    track.extend(midi_delta(end - previous_tick) + b"\xff\x2f\x00")
    path.write_bytes(b"MThd" + struct.pack(">IHHH", 6, 0, 1, ticks_per_beat) + b"MTrk" + struct.pack(">I", len(track)) + track)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("cues", nargs="*", metavar="CUE", help="Cue names from SCORE. Omit to render all.")
    parser.add_argument("--midi", action="store_true", help="Export MIDI arrangements instead of Ogg.")
    parser.add_argument("--output", type=Path, default=ROOT / "assets/audio/ost")
    args = parser.parse_args()
    unknown = set(args.cues) - SCORE.keys()
    if unknown:
        parser.error(f"unknown cues: {', '.join(sorted(unknown))}")
    args.output.mkdir(parents=True, exist_ok=True)
    for cue in args.cues or SCORE:
        print(cue, flush=True)
        if args.midi:
            write_midi(SCORE[cue], args.output / f"{cue}.mid")
        else:
            render(SCORE[cue], args.output / f"{cue}.ogg")
            sample_note.cache_clear()


if __name__ == "__main__":
    main()
