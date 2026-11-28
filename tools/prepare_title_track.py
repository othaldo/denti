"""Prepare the approved Suno title take for Godot from its downloaded MP3."""

import argparse
from array import array
from pathlib import Path

from compose_score import MELODY, ROOT, SAMPLE_RATE, sample_note
from prepare_score_loop import crossfade_loop, decode_audio, encode_vorbis, frames


# Downbeats measured in the source take (a89c6c2f-4f24-40e8-88af-164600675ce6).
FIRST_DOWNBEAT = 0.42581
SECOND_DOWNBEAT = 2.72095
LOOP_START = 11.86667
LOOP_END = 83.94388
BEAT = (SECOND_DOWNBEAT - FIRST_DOWNBEAT) / 4
MOTIF_START = 0.48
SOURCE_START = MOTIF_START + 4 * BEAT - FIRST_DOWNBEAT
WRAP_FADE = 0.18


def prepare_title(source: Path, output: Path) -> None:
    pcm = decode_audio(source, LOOP_END)
    crossfade_loop(pcm, frames(LOOP_START), frames(LOOP_END), frames(WRAP_FADE))
    output_pcm = array("f", [0.0]) * (frames(SOURCE_START) * 2)
    output_pcm.extend(value * 1.15 for value in pcm)

    # Transpose the signature down a whole tone to the take's C minor.
    # Let the first plucked string pickup enter under the last bell's decay.
    room_taps = ((0.0, .31, .31), (.037, .035, .07), (.073, .068, .028), (.131, .024, .034))
    for offset, note, hold in MELODY[0]:
        sound = sample_note("bell", note - 2, frames(hold * BEAT))
        for delay, left, right in room_taps:
            start = frames(MOTIF_START + offset * BEAT + delay)
            for index, sample in enumerate(sound, start):
                output_pcm[index * 2] += sample * left
                output_pcm[index * 2 + 1] += sample * right

    encode_vorbis(output_pcm, output, "Ein Zahn erhebt sich")
    print(f"Godot loop_offset = {(frames(SOURCE_START) + frames(LOOP_START)) / SAMPLE_RATE:.6f}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="MP3 of Suno Take 2")
    parser.add_argument("--output", type=Path, default=ROOT / "assets/audio/ost/denti-title.ogg")
    args = parser.parse_args()
    prepare_title(args.source, args.output)
