"""Exercise the actual PowerShell 5.1 installer against disposable portable builds."""

import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
HELPER = ROOT / "scripts/platform/windows_updater.ps1"
POWERSHELL = Path(os.environ.get("SystemRoot", "C:/Windows")) / "System32/WindowsPowerShell/v1.0/powershell.exe"


@unittest.skipUnless(sys.platform == "win32", "Windows PowerShell installer runs on the Windows CI job")
class WindowsUpdaterTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="Denti Update ä ")
        self.root = Path(self.temporary.name)
        self.install = self.root / "Game with spaces & apostrophe's"
        self.install.mkdir()
        self.work = self.root / "cache"
        self.work.mkdir()
        self.old = {"version": "0.5.0", "commit": "a" * 40, "channel": "stable", "save_schema": 1, "repository": "othaldo/denti"}
        self.new = dict(self.old, version="0.6.0", commit="b" * 40)
        self.original = {"Denti.exe": b"MZold engine", "Denti.pck": b"GDPCold pack", "build-info.json": json.dumps(self.old).encode()}
        for name, data in self.original.items():
            (self.install / name).write_bytes(data)
        self.payload = {"Denti.exe": b"MZnew engine", "Denti.pck": b"GDPCnew pack", "build-info.json": json.dumps(self.new).encode()}
        self.pack()

    def tearDown(self):
        self.temporary.cleanup()

    def pack(self, additions=None):
        archive = self.work / "package.zip"
        with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as output:
            for name, data in self.payload.items():
                output.writestr(name, data)
            for name, data in (additions or {}).items():
                output.writestr(name, data)
        job = dict(self.new, schema_version=1, install_dir=str(self.install), current_version=self.old["version"],
                   current_build=self.old["commit"][:7], parent_pid=0, archive=str(archive), size=archive.stat().st_size,
                   sha256=hashlib.sha256(archive.read_bytes()).hexdigest())
        (self.work / "job.json").write_text(json.dumps(job), encoding="utf-8")

    def ps(self, body, success=True):
        # The test script is a file with a UTF-8 BOM for Windows PowerShell 5.1.
        script = self.root / "test.ps1"
        literal = lambda path: "'" + str(path).replace("'", "''") + "'"
        source = ". " + literal(HELPER) + "\n$job = Read-UpdateJob " + literal(self.work / "job.json") + "\n" + body
        script.write_text(source, encoding="utf-8-sig")
        result = subprocess.run([str(POWERSHELL), "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", str(script)],
                                capture_output=True, text=True, timeout=30)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, "Unsafe update was accepted")
        return result

    def assert_original(self):
        for name, data in self.original.items():
            self.assertEqual((self.install / name).read_bytes(), data)

    def test_atomic_install_and_full_rollback_preserve_unrelated_files(self):
        sentinel = self.install / "my-notes.txt"
        sentinel.write_text("keep")
        self.ps("$stage = Prepare-Update $job\nInstall-UpdateFiles $job $stage\n")
        for name, data in self.payload.items():
            self.assertEqual((self.install / name).read_bytes(), data)
        # Restore uses the same backup logic used after a missing startup ack.
        (self.install / "build-info.json").write_text(json.dumps(self.old))
        self.ps("$stage = (Get-ChildItem -LiteralPath $job.InstallDir -Directory -Filter '.denti-update-*').FullName\nRestore-UpdateFiles $job $stage\nRemove-KnownStage $stage\n")
        self.assert_original()
        self.assertEqual(sentinel.read_text(), "keep")
        self.assertFalse(list(self.install.glob(".denti-update-*")))

    def test_locked_second_file_rolls_back_first_replacement(self):
        self.ps("$stage = Prepare-Update $job\n$locked = [IO.File]::Open((Join-Path $job.InstallDir 'Denti.pck'), 'Open', 'Read', 'None')\n"
                "try { Install-UpdateFiles $job $stage; throw 'Expected replacement failure' }\n"
                "catch { if ($_.Exception.Message -eq 'Expected replacement failure') { throw } }\nfinally { $locked.Dispose() }\nRemove-KnownStage $stage\n")
        self.assert_original()

    def test_corrupt_checksum_never_touches_installation(self):
        with (self.work / "package.zip").open("ab") as output:
            output.write(b"changed")
        self.ps("Prepare-Update $job\n", success=False)
        self.assert_original()

    def test_path_traversal_duplicate_and_unknown_entries_are_rejected(self):
        for name in ["../outside.txt", "Denti.exe/child", "extra.dll", "DENTI.EXE"]:
            with self.subTest(name=name):
                self.pack({name: b"unsafe"})
                self.ps("Prepare-Update $job\n", success=False)
                self.assert_original()
                self.assertFalse((self.root / "outside.txt").exists())

    def test_wrong_build_or_save_schema_is_rejected_before_replacement(self):
        self.payload["build-info.json"] = json.dumps(dict(self.new, commit="c" * 40)).encode()
        self.pack()
        self.ps("Prepare-Update $job\n", success=False)
        self.assert_original()
        self.assertFalse(list(self.install.glob(".denti-update-*")))

    def test_newest_backup_cleanup_never_deletes_unknown_files(self):
        self.ps("$stage = Prepare-Update $job\n[IO.File]::WriteAllText((Join-Path $stage 'user-file.txt'), 'keep')\nRemove-KnownStage $stage\n")
        self.assertEqual(next(self.install.glob(".denti-update-*/user-file.txt")).read_text(), "keep")
        self.assert_original()

    def _stub_exe(self, destination, version, acknowledge):
        compiler = Path(os.environ['SystemRoot']) / 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
        source = self.root / (version + '.cs')
        source.write_text('''using System; using System.IO; using System.Diagnostics; using System.Threading;
class Fixture { static void Main(string[] args) {
File.WriteAllText(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "''' + version + '''.started"), Process.GetCurrentProcess().Id.ToString());
''' + ('''if (args.Length >= 3 && args[1] == "--denti-update-job") {
File.WriteAllText(Path.Combine(Path.GetDirectoryName(args[2]), "status.json"), "{\\"state\\":\\"started\\",\\"version\\":\\"0.6.0\\"}");
}''' if acknowledge else '') + ('''Thread.Sleep(45000);''' if version == 'old' or acknowledge else '') + '\n}}', encoding='utf-8')
        result = subprocess.run([str(compiler), '/nologo', '/target:winexe', '/out:' + str(destination), str(source)], capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def _full_process(self, acknowledge):
        self._stub_exe(self.install / 'Denti.exe', 'old', False)
        self.original['Denti.exe'] = (self.install / 'Denti.exe').read_bytes()
        new_exe = self.root / 'new.exe'
        self._stub_exe(new_exe, 'new', acknowledge)
        self.payload['Denti.exe'] = new_exe.read_bytes()
        self.pack()
        parent = subprocess.Popen([str(self.install / 'Denti.exe')])
        helper = None
        helper_log = (self.work / 'helper.log').open('w')
        try:
            job_path = self.work / 'job.json'
            job = json.loads(job_path.read_text())
            job['parent_pid'] = parent.pid
            job_path.write_text(json.dumps(job), encoding='utf-8')
            helper = subprocess.Popen([str(POWERSHELL), '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', str(HELPER), '-JobPath', str(job_path)], stdout=helper_log, stderr=helper_log)
            deadline = time.monotonic() + 20
            while time.monotonic() < deadline:
                try:
                    status = json.loads((self.work / 'status.json').read_text(encoding='utf-8-sig'))
                    if status['state'] == 'ready': break
                except (OSError, ValueError): pass
                if helper.poll() is not None: self.fail('helper exited before ready: ' + (self.work / 'helper.log').read_text())
                time.sleep(.05)
            else: self.fail('helper did not prepare the update')
            # No installation may happen while the original game is still running.
            self.assert_original()
            parent.terminate()
            parent.wait(timeout=5)
            helper.wait(timeout=20)
            self.assertEqual(helper.returncode, 0 if acknowledge else 1, (self.work / 'helper.log').read_text())
            status = json.loads((self.work / 'status.json').read_text(encoding='utf-8-sig'))
            self.assertEqual(status['state'], 'complete' if acknowledge else 'failed')
            if acknowledge:
                for name, data in self.payload.items(): self.assertEqual((self.install / name).read_bytes(), data)
                self.assertFalse((self.work / 'package.zip').exists())
                self.assertEqual(len(list(self.install.glob('.denti-update-*/backup/Denti.exe'))), 1)
            else: self.assert_original()
        finally:
            if parent.poll() is None: parent.terminate(); parent.wait(timeout=5)
            if helper is not None and helper.poll() is None: helper.terminate(); helper.wait(timeout=5)
            helper_log.close()
            for marker in ['old.started', 'new.started']:
                path = self.install / marker
                if path.exists():
                    # These PIDs were written only by the disposable fixture EXEs.
                    subprocess.run(['taskkill', '/PID', path.read_text(), '/F'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def test_complete_handoff_waits_for_exit_and_acknowledges_restart(self):
        self._full_process(True)

    def test_missing_startup_ack_restores_previous_game_and_restarts_it(self):
        self._full_process(False)


if __name__ == "__main__":
    unittest.main()
