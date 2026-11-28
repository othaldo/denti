"""Prepare the in-game loops from Denti's seven original Suno recordings."""

import argparse
from dataclasses import dataclass

from compose_score import ROOT
from prepare_score_loop import render_loop

SOURCE_DIR = ROOT / "assets/audio"
CUE_DIR = SOURCE_DIR / "classic"


@dataclass(frozen=True)
class Cue:
    source: str
    title: str
    loop_start: float
    loop_end: float
    entry: float = 0.0
    wrap: float = .18
    gain_db: float = 0.0
    audio_filter: str = ""


CUES = {
    "menu": Cue("main-manu", "The Little Hero's Quest", 12.44109, 109.89971),
    "arena": Cue("wave-1", "Celesta Loop", 18.10685, 112.70850),
    "arena-late": Cue("wave-2", "Buant Loop", 11.94779, 124.32498),
    "boss": Cue("mini-boss-1", "Celestial Marimba Motif", 10.53390, 97.98523),
    "boss-alt": Cue("mini-boss-2", "The Boss's Theme", 21.84146, 117.17790),
    "finale": Cue("final-boss-1", "Divine Tooth Battle", 9.37788, 120.36912),
    "finale-overtime": Cue("final-boss-2", "Divine Tooth Battle (Entzündung)", 19.51925, 131.24850),
    "intermission": Cue("main-manu", "Rast", 12.44109, 41.66502, entry=8.55, wrap=.38, gain_db=-4,
                        audio_filter="highpass=f=85,lowpass=f=5300"),
    "victory": Cue("main-manu", "Sieg", 66.02935, 124.52498, entry=60.85, wrap=.26),
    "pillow": Cue("main-manu", "Unter dem Kissen", 97.71538, 136.72058, entry=97.2, wrap=.30,
                  gain_db=-1, audio_filter="lowpass=f=8400"),
    "sugar": Cue("wave-2", "Das süße Verderben", 23.70219, 85.79402, entry=19.75, wrap=.20),
    "acid": Cue("wave-1", "Tief im Säurestrom", 61.67583, 97.08679, entry=55.28, wrap=.28,
                gain_db=-1, audio_filter="lowpass=f=5400"),
    "palace": Cue("final-boss-2", "Die letzte Krone", 38.65752, 82.79479, entry=30.927, wrap=.24,
                  gain_db=-2, audio_filter="lowpass=f=7200"),
    "endless": Cue("mini-boss-2", "Endlos", 61.29223, 146.76160, entry=54.62, wrap=.20),
    "endless-double": Cue("final-boss-2", "Endlos-Doppelboss", 113.64412, 145.92400, entry=104.6),
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("cues", nargs="*", help="Cue names to render. Omit to render all cues.")
    args = parser.parse_args()
    unknown = set(args.cues) - CUES.keys()
    if unknown:
        parser.error(f"unknown cues: {', '.join(sorted(unknown))}")

    CUE_DIR.mkdir(parents=True, exist_ok=True)
    for name in args.cues or CUES:
        cue = CUES[name]
        offset = render_loop(
            SOURCE_DIR / f"{cue.source}.mp3", CUE_DIR / f"{name}.ogg", cue.title,
            cue.entry, cue.loop_start, cue.loop_end, cue.wrap, cue.gain_db,
            audio_filter=cue.audio_filter,
        )
        print(f"{name}={offset:.6f}", flush=True)


if __name__ == "__main__":
    main()
