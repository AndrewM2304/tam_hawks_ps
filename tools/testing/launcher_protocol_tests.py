#!/usr/bin/env python3
"""Launcher process/log/deadline checks with a labelled fake editor, not Godot tests."""
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
FAKE_EDITOR = r'''#!/usr/bin/env python3
import json,os,pathlib,subprocess,sys,time
root=pathlib.Path(os.environ['TAM_LAUNCH_FIXTURE'])
args=sys.argv[1:]
with (root/'calls.jsonl').open('a') as f:f.write(json.dumps(args)+'\n')
if args==['--version']:print('4.6.3.launcher_protocol_fixture');sys.exit(0)
if '--import' in args:
 (root/'import-pid').write_text(str(os.getpid()))
 print('Importer progress: FIXTURE_TEXTURE.png',flush=True)
 mode=os.environ.get('TAM_LAUNCH_FIXTURE_MODE','ok')
 if mode=='native-failure':print('Native fixture failure',flush=True);sys.exit(7)
 if mode=='logged-failure':print('SCRIPT ERROR: deliberate fixture error',flush=True);sys.exit(0)
 if mode=='worker-stall':
  child=subprocess.Popen([sys.executable,'-c','import time; time.sleep(60)'])
  (root/'worker-pid').write_text(str(child.pid))
 if mode in ('stall','worker-stall'):
  while True:time.sleep(.1)
 if mode=='handshake':
  until=time.monotonic()+10
  while not (root/'allow-import-finish').exists() and time.monotonic()<until:time.sleep(.02)
  if not (root/'allow-import-finish').exists():sys.exit(8)
 print('Fixture import complete',flush=True)
 (root/'import-complete').touch()
else:
 (root/'game-started').write_text(json.dumps(args))
 print('Fixture game invocation',flush=True)
'''


class LauncherProtocol(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='launcher protocol ')
        self.root = Path(self.temp.name) / 'game source with spaces'
        (self.root / 'tools').mkdir(parents=True)
        for name in ('run.sh', 'prepare_source_assets.sh'):
            shutil.copy2(ROOT / 'tools' / name, self.root / 'tools' / name)
        self.editor = Path(self.temp.name) / 'Godot fixture with spaces'
        self.editor.write_text(FAKE_EDITOR)
        self.editor.chmod(0o755)
        self.env = dict(os.environ, GODOT_BIN=str(self.editor),
                        TAM_LAUNCH_FIXTURE=str(self.root),
                        TAM_ASSET_IMPORT_TIMEOUT_SECONDS='8')

    def tearDown(self):
        self.temp.cleanup()

    def run_launcher(self, mode='ok', args=(), limit='8'):
        env = dict(self.env, TAM_LAUNCH_FIXTURE_MODE=mode,
                   TAM_ASSET_IMPORT_TIMEOUT_SECONDS=limit)
        return subprocess.run(['bash', str(self.root / 'tools/run.sh'), *args],
                              env=env, text=True, stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT, timeout=15)

    def test_success_spaces_and_exact_game_arguments(self):
        args = ['--headless', '--quit-after', '3', '--', 'an argument with spaces']
        result = self.run_launcher(args=args)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertEqual(json.loads((self.root / 'game-started').read_text()),
                         ['--path', str(self.root), *args])
        self.assertIn('Fixture import complete', result.stdout)
        self.assertIn('Game assets ready', result.stdout)
        calls = [json.loads(s) for s in (self.root / 'calls.jsonl').read_text().splitlines()]
        self.assertIn(['--path', str(self.root), '--headless', '--audio-driver',
                       'Dummy', '--editor', '--import'], calls)

    def test_live_progress_precedes_import_completion(self):
        env = dict(self.env, TAM_LAUNCH_FIXTURE_MODE='handshake')
        process = subprocess.Popen(['bash', str(self.root / 'tools/run.sh'), '--headless'],
                                   env=env, text=True, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, start_new_session=True)
        try:
            lines = []
            for line in process.stdout:
                lines.append(line)
                if 'Importer progress: FIXTURE_TEXTURE.png' in line:
                    self.assertFalse((self.root / 'import-complete').exists())
                    (self.root / 'allow-import-finish').touch()
                    break
            else:
                self.fail('Live importer output was not delivered')
            tail, _ = process.communicate(timeout=12)
            self.assertEqual(process.returncode, 0, ''.join(lines) + tail)
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=3)

    def test_native_failure_refuses_game(self):
        result = self.run_launcher('native-failure')
        self.assertEqual(result.returncode, 7, result.stdout)
        self.assertFalse((self.root / 'game-started').exists())
        self.assertIn('Game assets could not be prepared', result.stdout)

    def test_logged_error_with_zero_editor_exit_refuses_game(self):
        result = self.run_launcher('logged-failure')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / 'game-started').exists())
        self.assertIn('SCRIPT ERROR:', (self.root / '.local/source-import.log').read_text())

    def test_stalled_import_is_stopped_and_refuses_game(self):
        start = time.monotonic()
        result = self.run_launcher('stall', limit='1')
        self.assertEqual(result.returncode, 124, result.stdout)
        self.assertLess(time.monotonic() - start, 8)
        self.assertFalse((self.root / 'game-started').exists())
        self.assertIn('timed out after 1s', result.stdout)
        pid = int((self.root / 'import-pid').read_text())
        with self.assertRaises(ProcessLookupError):
            os.kill(pid, 0)

    def test_invalid_timeout_refuses_before_editor_import(self):
        for value in ('0', 'oops', '3601', '999999999999999999999'):
            with self.subTest(value=value):
                result = self.run_launcher(limit=value)
                self.assertEqual(result.returncode, 2, result.stdout)
                self.assertFalse((self.root / 'game-started').exists())
                self.assertFalse((self.root / 'import-pid').exists())

    def test_timeout_stops_an_importer_worker_too(self):
        result = self.run_launcher('worker-stall', limit='1')
        self.assertEqual(result.returncode, 124, result.stdout)
        self.assertFalse((self.root / 'game-started').exists())
        pid = int((self.root / 'worker-pid').read_text())
        # A terminated orphan may briefly await OS reaping. It must not run.
        check = subprocess.run(['ps', '-o', 'stat=', '-p', str(pid)],
                               text=True, stdout=subprocess.PIPE, check=False)
        self.assertTrue(not check.stdout.strip() or check.stdout.strip().startswith('Z'),
                        f'Importer worker still running: {pid} {check.stdout}')

    def test_script_editor_and_help_bypass_play_import(self):
        for args in (['--script', 'fixture.gd'], ['-s', 'fixture.gd'],
                     ['--editor'], ['--check-only'], ['--help'], ['--version']):
            with self.subTest(args=args):
                result = self.run_launcher(args=args)
                self.assertEqual(result.returncode, 0, result.stdout)
                self.assertFalse((self.root / 'import-pid').exists())
                self.assertFalse((self.root / '.local/source-import.log').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
