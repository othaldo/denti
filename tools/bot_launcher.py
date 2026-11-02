"""Local desktop launcher for the existing Denti bot comparison runner."""
from __future__ import annotations

from contextlib import redirect_stderr
from dataclasses import asdict, dataclass
import io
import json
import os
from pathlib import Path
import queue
import re
import shutil
import subprocess
import sys
import threading

from run_bot_comparison import SKILLS, STRATEGIES, POLICIES, parse_args, weapon_ids
from run_tests import ROOT, stop_process

try:
    import tkinter as tk
    from tkinter import filedialog, messagebox, ttk
except ImportError:
    tk = ttk = None

SETTINGS_FILE = ROOT / ".godot/bot_launcher_settings.json"
DIFFICULTIES = ("easy", "normal", "hard", "hell")
LABELS = {
    "skills": {"novice": "Anfänger", "regular": "Geübt", "expert": "Erfahren"},
    "strategies": {"aggressive": "Nah herangehen", "kite": "Abstand halten", "collector": "Beute sammeln", "boss": "Boss fokussieren"},
    "build_policies": {"simple": "Feuer-Referenz", "synergy": "Synergie-Heuristik"},
    "difficulties": {"easy": "Easy", "normal": "Normal", "hard": "Hard", "hell": "Hell"},
}


def weapons():
    result = {}
    for key in weapon_ids():
        source = (ROOT / "data/weapons" / (key + ".tres")).read_text(encoding="utf-8")
        name = re.search(r'^display_name = "([^"]+)"', source, re.MULTILINE)
        result[key] = name.group(1) if name else key
    return result


def find_godot():
    for candidate in [os.environ.get("GODOT_BIN", ""), "Godot_v4.7.2-stable_win64_console.exe", "godot", "godot4"]:
        if candidate and (found := shutil.which(candidate)):
            return found
    return ""


@dataclass
class Settings:
    mode: str = "visible"
    weapons: str = "turbo_drill"
    skills: str = "expert"
    strategies: str = "kite"
    build_policies: str = "simple"
    difficulties: str = "normal"
    seeds: str = "13579"
    last_wave: str = "5"
    speed: str = "4"
    jobs: str = "4"
    capture: bool = False
    godot: str = ""

    def arguments(self):
        if self.mode not in ("visible", "comparison"):
            raise ValueError("Unbekannter Testmodus")
        if not self.godot or not shutil.which(self.godot):
            raise ValueError("Bitte die Godot-Anwendung auswählen.")
        arguments = ["--godot", self.godot, "--last-wave", self.last_wave, "--seeds", self.seeds.strip()]
        allowed = dict(weapons=weapon_ids(), skills=SKILLS, strategies=STRATEGIES,
                       build_policies=POLICIES, difficulties=DIFFICULTIES)
        for key, values in allowed.items():
            value = getattr(self, key)
            if value == "*":
                if self.mode == "visible":
                    raise ValueError("Zum Zuschauen bitte je eine Option wählen; Vergleiche können alle testen.")
                value = ",".join(values)
            arguments += ["--" + key.replace("_", "-"), value]
        if self.mode == "visible":
            arguments += ["--visible", "--speed", self.speed, "--timeout", "86400"]
            if self.capture:
                arguments.append("--capture")
        else:
            arguments += ["--jobs", self.jobs]
        errors = io.StringIO()
        try:
            with redirect_stderr(errors):
                parse_args(arguments)
        except SystemExit as error:
            raise ValueError(errors.getvalue().strip().splitlines()[-1].split("error: ")[-1]) from error
        return arguments

    def run_count(self):
        count = len(self.seeds.split(","))
        for key, values in dict(weapons=weapon_ids(), skills=SKILLS, strategies=STRATEGIES,
                                build_policies=POLICIES, difficulties=DIFFICULTIES).items():
            if getattr(self, key) == "*":
                count *= len(values)
        return count


class BotRun:
    """Own exactly one runner process tree; communicate with Tk through a queue."""

    def __init__(self, arguments):
        self.arguments = arguments
        self.events = queue.Queue()
        self.cancelled = threading.Event()
        self.lock = threading.Lock()
        self.process = None

    def start(self):
        threading.Thread(target=self._work, daemon=True).start()

    def _work(self):
        try:
            environment = os.environ.copy()
            environment.update(PYTHONUNBUFFERED="1", PYTHONIOENCODING="utf-8")
            # pythonw has no stdout and is unsuitable as the CLI child.
            executable = Path(sys.executable)
            if executable.name.lower() == "pythonw.exe":
                executable = executable.with_name("python.exe")
            command = [str(executable), str(ROOT / "tools/run_bot_comparison.py"), *self.arguments]
            with subprocess.Popen(command, cwd=ROOT, env=environment, stdout=subprocess.PIPE,
                                  stderr=subprocess.STDOUT, text=True, encoding="utf-8", errors="replace",
                                  start_new_session=sys.platform != "win32",
                                  creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == "win32" else 0) as process:
                with self.lock:
                    self.process = process
                if self.cancelled.is_set():
                    stop_process(process)
                for line in process.stdout:
                    self.events.put(("log", line))
                code = process.wait()
            self.events.put(("done", code))
        except Exception as error:
            self.events.put(("log", str(error) + "\n"))
            self.events.put(("done", -1))

    def cancel(self):
        self.cancelled.set()
        with self.lock:
            process = self.process
        if process is not None:
            threading.Thread(target=stop_process, args=(process,)).start()


class BotLauncher:
    def __init__(self, root):
        self.root = root
        self.run = None
        self.result_folder = None
        self.closing = False
        root.title("Denti · Bot-Test")
        root.geometry("840x730")
        root.minsize(760, 680)
        style = ttk.Style(root)
        if "vista" in style.theme_names():
            style.theme_use("vista")
        style.configure("TLabel", font=("Segoe UI", 10))
        style.configure("TButton", font=("Segoe UI", 10), padding=(10, 6))
        style.configure("Title.TLabel", font=("Segoe UI", 20, "bold"))
        settings = Settings(godot=find_godot())
        try:
            saved = json.loads(SETTINGS_FILE.read_text(encoding="utf-8"))
            if not isinstance(saved, dict): saved = {}
            for key, default in asdict(settings).items():
                if key in saved and type(saved[key]) is type(default):
                    setattr(settings, key, saved[key])
        except (OSError, ValueError, TypeError):
            pass
        if settings.mode not in ("visible", "comparison"):
            settings.mode = "visible"
        self.values = {key: (tk.BooleanVar(value=value) if key == "capture" else tk.StringVar(value=value))
                       for key, value in asdict(settings).items()}
        self.controls = []
        self.combos = {}
        self.options = dict(weapons=weapons(), **LABELS)
        self.defaults = asdict(Settings())
        frame = ttk.Frame(root, padding=20)
        frame.pack(fill="both", expand=True)
        frame.columnconfigure(0, weight=1)
        frame.rowconfigure(6, weight=1)
        ttk.Label(frame, text="Bot-Test", style="Title.TLabel").grid(row=0, column=0, sticky="w")
        ttk.Label(frame, text="Welle 1–5 · echte Beute, Aufstiege und Shops").grid(row=1, column=0, sticky="w", pady=(0, 14))
        modes = ttk.Frame(frame)
        modes.grid(row=2, column=0, sticky="ew", pady=(0, 12))
        for text, value in [("Zuschauen", "visible"), ("Vergleich berechnen", "comparison")]:
            control = ttk.Radiobutton(modes, text=text, value=value, variable=self.values["mode"], command=self.refresh_mode)
            control.pack(side="left", padx=(0, 22))
            self.controls.append(control)
        form = ttk.Frame(frame)
        form.grid(row=3, column=0, sticky="ew")
        form.columnconfigure(1, weight=1)
        form.columnconfigure(3, weight=1)
        for index, (key, title) in enumerate([( "weapons", "Startwaffe"), ("difficulties", "Schwierigkeit"),
                                              ("skills", "Botprofil"), ("strategies", "Kampfstrategie"),
                                              ("build_policies", "Buildregel")]):
            row, column = divmod(index, 2)
            column *= 2
            ttk.Label(form, text=title).grid(row=row, column=column, sticky="w", padx=(0, 10), pady=6)
            combo = ttk.Combobox(form, state="readonly", width=26)
            combo.grid(row=row, column=column + 1, sticky="ew", padx=(0, 18) if column == 0 else 0, pady=6)
            combo.bind("<<ComboboxSelected>>", lambda _event, axis=key: self.select_axis(axis))
            self.combos[key] = combo
            self.controls.append(combo)
        ttk.Label(form, text="Seeds (mit Komma)").grid(row=2, column=2, sticky="w", padx=(0, 10))
        self.entry(form, "seeds", 2, 3)
        for index, (key, title, choices) in enumerate([("last_wave", "Bis Welle", ["1", "2", "3", "4", "5"]),
                                                       ("speed", "Kampftempo", ["1", "4", "8", "16"]),
                                                       ("jobs", "Parallele Worker", ["1", "2", "3", "4"])]):
            row, column = 3 + index // 2, (index % 2) * 2
            ttk.Label(form, text=title).grid(row=row, column=column, sticky="w", padx=(0, 10), pady=6)
            control = ttk.Combobox(form, textvariable=self.values[key], values=choices, state="readonly", width=8)
            control.grid(row=row, column=column + 1, sticky="w", pady=6)
            control.bind("<<ComboboxSelected>>", lambda _event: self.refresh_summary())
            self.controls.append(control)
            if key == "speed": self.speed_control = control
            if key == "jobs": self.jobs_control = control
        self.capture_control = ttk.Checkbutton(form, text="Screenshots speichern", variable=self.values["capture"])
        self.capture_control.grid(row=4, column=2, columnspan=2, sticky="w", pady=6)
        self.controls.append(self.capture_control)
        ttk.Label(form, text="Godot").grid(row=5, column=0, sticky="w", pady=(10, 6))
        path_row = ttk.Frame(form)
        path_row.grid(row=5, column=1, columnspan=3, sticky="ew", pady=(10, 6))
        path_row.columnconfigure(0, weight=1)
        path_entry = ttk.Entry(path_row, textvariable=self.values["godot"])
        path_entry.grid(row=0, column=0, sticky="ew", padx=(0, 8))
        browse = ttk.Button(path_row, text="Auswählen…", command=self.choose_godot)
        browse.grid(row=0, column=1)
        self.controls.extend([path_entry, browse])
        self.summary = ttk.Label(frame)
        self.summary.grid(row=4, column=0, sticky="w", pady=(14, 8))
        actions = ttk.Frame(frame)
        actions.grid(row=5, column=0, sticky="ew", pady=(0, 12))
        self.start_button = ttk.Button(actions, text="Test starten", command=self.start)
        self.start_button.pack(side="left")
        self.stop_button = ttk.Button(actions, text="Abbrechen", command=self.cancel, state="disabled")
        self.stop_button.pack(side="left", padx=8)
        self.folder_button = ttk.Button(actions, text="Ergebnisordner", command=self.open_folder, state="disabled")
        self.folder_button.pack(side="right")
        self.report_button = ttk.Button(actions, text="Bericht öffnen", command=self.open_report, state="disabled")
        self.report_button.pack(side="right", padx=8)
        logs = ttk.Frame(frame)
        logs.grid(row=6, column=0, sticky="nsew")
        logs.columnconfigure(0, weight=1)
        logs.rowconfigure(0, weight=1)
        self.log = tk.Text(logs, height=9, width=60, wrap="word", state="disabled", font=("Consolas", 10), relief="solid", borderwidth=1)
        self.log.grid(row=0, column=0, sticky="nsew")
        scrollbar = ttk.Scrollbar(logs, command=self.log.yview)
        scrollbar.grid(row=0, column=1, sticky="ns")
        self.log.configure(yscrollcommand=scrollbar.set)
        self.status = ttk.Label(frame, text="Bereit")
        self.status.grid(row=7, column=0, sticky="w", pady=(8, 0))
        self.values["seeds"].trace_add("write", lambda *_: self.refresh_summary())
        self.refresh_mode()
        root.protocol("WM_DELETE_WINDOW", self.close)
        root.after(100, self.poll)

    def entry(self, parent, key, row, column):
        entry = ttk.Entry(parent, textvariable=self.values[key], width=20)
        entry.grid(row=row, column=column, sticky="ew")
        self.controls.append(entry)

    def settings(self):
        return Settings(**{key: value.get() for key, value in self.values.items()})

    def refresh_mode(self):
        visible = self.values["mode"].get() == "visible"
        for key, combo in self.combos.items():
            options = self.options[key]
            if self.values[key].get() not in options and (visible or self.values[key].get() != "*"):
                self.values[key].set(self.defaults[key])
            labels = list(options.values()) + ([] if visible else [f"Alle ({len(options)})"])
            combo.configure(values=labels)
            combo.set(options.get(self.values[key].get(), labels[-1]))
        self.speed_control.configure(state="readonly" if visible else "disabled")
        self.jobs_control.configure(state="disabled" if visible else "readonly")
        self.capture_control.configure(state="normal" if visible else "disabled")
        self.refresh_summary()

    def select_axis(self, key):
        label = self.combos[key].get()
        self.values[key].set(next((key for key, value in self.options[key].items() if value == label), "*"))
        self.refresh_summary()

    def refresh_summary(self):
        settings = self.settings()
        count = settings.run_count()
        self.summary.configure(text=f"{count} {'Lauf' if count == 1 else 'Läufe'} · Welle 1–{settings.last_wave}" +
                               (" · Pause im Spielfenster mit Leertaste" if settings.mode == "visible" else " · ohne Spielfenster"))

    def choose_godot(self):
        path = filedialog.askopenfilename(title="Godot auswählen", filetypes=[("Godot", "*.exe"), ("Alle Dateien", "*")])
        if path: self.values["godot"].set(path)

    def start(self):
        if self.run is not None: return
        settings = self.settings()
        try:
            arguments = settings.arguments()
        except ValueError as error:
            messagebox.showerror("Test nicht gestartet", str(error), parent=self.root)
            return
        try:
            SETTINGS_FILE.parent.mkdir(parents=True, exist_ok=True)
            SETTINGS_FILE.write_text(json.dumps(asdict(settings), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        except OSError:
            pass
        self.result_folder = None
        self.log.configure(state="normal")
        self.log.delete("1.0", "end")
        self.log.configure(state="disabled")
        for control in self.controls: control.configure(state="disabled")
        self.start_button.configure(state="disabled")
        self.report_button.configure(state="disabled")
        self.folder_button.configure(state="disabled")
        self.stop_button.configure(state="normal")
        self.status.configure(text="Test läuft…")
        self.run = BotRun(arguments)
        self.run.start()

    def cancel(self):
        if self.run is not None:
            self.status.configure(text="Wird abgebrochen…")
            self.stop_button.configure(state="disabled")
            self.run.cancel()

    def poll(self):
        if self.run is not None:
            try:
                while True:
                    kind, value = self.run.events.get_nowait()
                    if kind == "log":
                        self.log.configure(state="normal")
                        self.log.insert("end", value)
                        self.log.see("end")
                        self.log.configure(state="disabled")
                        match = re.match(r"\d+ bot runs, \d+ workers: (.+)", value.strip())
                        if match:
                            self.result_folder = Path(match.group(1))
                            self.folder_button.configure(state="normal")
                    elif kind == "done":
                        cancelled = self.run.cancelled.is_set()
                        self.run = None
                        if self.closing:
                            self.root.destroy()
                            return
                        for control in self.controls: control.configure(state="normal")
                        for control in self.controls:
                            if isinstance(control, ttk.Combobox): control.configure(state="readonly")
                        self.refresh_mode()
                        self.start_button.configure(state="normal")
                        self.stop_button.configure(state="disabled")
                        message = "Abgebrochen · vorhandene Logs bleiben im Ergebnisordner" if cancelled else ("Fertig" if value == 0 else "Fehlgeschlagen · Details im Log")
                        if value == 0 and self.result_folder:
                            try:
                                report = json.loads((self.result_folder / "report.json").read_text(encoding="utf-8"))
                                if any(row["outcome"] == "aborted" for row in report["samples"]):
                                    message = "Abgebrochen · Teilbericht gespeichert"
                            except (OSError, ValueError, KeyError, TypeError):
                                pass
                        self.status.configure(text=message)
                        if self.result_folder and (self.result_folder / "report.md").is_file():
                            self.report_button.configure(state="normal")
                        break
            except queue.Empty:
                pass
        self.root.after(100, self.poll)

    def open_path(self, path):
        if sys.platform == "win32": os.startfile(path)
        else: subprocess.Popen(["xdg-open", str(path)])

    def open_folder(self):
        if self.result_folder: self.open_path(self.result_folder)

    def open_report(self):
        if self.result_folder: self.open_path(self.result_folder / "report.md")

    def close(self):
        if self.run is None: self.root.destroy()
        else:
            self.closing = True
            self.cancel()


def main():
    if tk is None:
        raise SystemExit("Tkinter fehlt. Unter Windows Python mit Tcl/Tk installieren; unter Linux python3-tk.")
    root = tk.Tk()
    BotLauncher(root)
    root.mainloop()


if __name__ == "__main__":
    main()
