"""Render a mastered Godot Ogg loop from a Denti soundtrack take."""

import argparse
import math
import subprocess
from array import array
from pathlib import Path

from compose_score import SAMPLE_RATE


def frames(seconds: float) -> int:
    return round(seconds * SAMPLE_RATE)


def decode_audio(source: Path, end_seconds: float, audio_filter: str = "") -> array:
    filters = ["-af", audio_filter] if audio_filter else []
    pcm = array("f")
    pcm.frombytes(subprocess.check_output([
        "ffmpeg", "-v", "error", "-i", str(source), "-map", "0:a:0",
        *filters, "-t", str(end_seconds + 0.10), "-ac", "2", "-ar", str(SAMPLE_RATE),
        "-f", "f32le", "pipe:1",
    ]))
    end = frames(end_seconds) * 2
    if len(pcm) < end:
        raise ValueError("The source take is shorter than the loop end.")
    del pcm[end:]
    return pcm


def crossfade_loop(pcm: array, start: int, end: int, width: int) -> None:
    # Mix the pickup into the outgoing beat. The native loop then lands on
    # the next downbeat without duplicating its attack.
    pickup = start - width
    tail = end - width
    for index in range(width):
        weight = .5 - .5 * math.cos(math.pi * index / (width - 1))
        for channel in range(2):
            incoming = pcm[2 * (pickup + index) + channel]
            outgoing = 2 * (tail + index) + channel
            pcm[outgoing] += (incoming - pcm[outgoing]) * weight


def encode_vorbis(pcm: array, output: Path, title: str) -> None:
    subprocess.run([
        "ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SAMPLE_RATE),
        "-ac", "2", "-i", "pipe:0", "-c:a", "libvorbis", "-q:a", "5",
        "-metadata", f"title={title}", str(output),
    ], input=pcm.tobytes(), check=True)


def render_loop(
    source: Path, output: Path, title: str, entry: float, start: float,
    end: float, wrap: float, gain_db: float, *, audio_filter: str = "",
) -> float:
    entry_frame, start_frame, end_frame, width = map(frames, (entry, start, end, wrap))
    if not 0 <= entry_frame <= start_frame - width < start_frame < end_frame - width or width < 2:
        raise ValueError("Choose distinct loop boundaries with enough pre-roll for the crossfade.")
    pcm = decode_audio(source, end, audio_filter)
    crossfade_loop(pcm, start_frame, end_frame, width)
    del pcm[:entry_frame * 2]
    gain = min(10 ** (gain_db / 20), .89 / max(max(map(abs, pcm)), .01))
    attack_frames = frames(.018)
    for index in range(len(pcm)):
        pcm[index] *= gain * min(1.0, (index // 2) / attack_frames)
    encode_vorbis(pcm, output, title)
    return (start_frame - entry_frame) / SAMPLE_RATE


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--title", required=True)
    parser.add_argument("--entry", type=float, default=0.0, help="Start of the first playback in seconds.")
    parser.add_argument("--start", type=float, required=True, help="Loop start downbeat in source seconds.")
    parser.add_argument("--end", type=float, required=True, help="Loop end downbeat in source seconds.")
    parser.add_argument("--wrap", type=float, default=.18, help="Length of the wrap crossfade in seconds.")
    parser.add_argument("--gain-db", type=float, default=0.0)
    args = parser.parse_args()
    offset = render_loop(args.source, args.output, args.title, args.entry, args.start, args.end, args.wrap, args.gain_db)
    print(f"Godot loop_offset = {offset:.6f}")
