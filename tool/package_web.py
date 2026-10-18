"""Package a root-serving Flutter build with dependency-free local launchers."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parent.parent
TARGETS = {
    'windows-x64': ('windows', 'amd64', 'Start-iSkedyul.exe'),
    'linux-x64': ('linux', 'amd64', 'Start-iSkedyul'),
    'macos-intel': ('darwin', 'amd64', 'Start-iSkedyul'),
    'macos-apple-silicon': ('darwin', 'arm64', 'Start-iSkedyul'),
}
parser = argparse.ArgumentParser()
parser.add_argument('--target', choices=TARGETS, action='append')
args = parser.parse_args()
web = ROOT / 'build' / 'web'
if '<base href="/">' not in (web / 'index.html').read_text():
    raise SystemExit('Build the root version first: flutter build web --base-href / --no-web-resources-cdn')
output = ROOT / 'build' / 'downloads'
output.mkdir(parents=True, exist_ok=True)
shutil.make_archive(str(output / 'iskedyul-web-server'), 'zip', web)
for target in args.target or TARGETS:
    system, arch, executable = TARGETS[target]
    with tempfile.TemporaryDirectory() as temporary:
        package = Path(temporary)
        environment = dict(os.environ, GOOS=system, GOARCH=arch, CGO_ENABLED='0')
        subprocess.run(['go', 'build', '-trimpath', '-ldflags=-s -w', '-o', str(package / executable), '.'], cwd=ROOT / 'tool' / 'launcher', env=environment, check=True)
        shutil.copytree(web, package / 'web')
        (package / 'READ-ME.txt').write_text(
            'iSkedyul\n\nExtract this entire ZIP, then open ' + executable + '.\n'
            'The app opens in your browser. Keep the launcher window open.\n'
            'No Flutter, Android Studio, Python, Node, or Go installation is needed.\n'
            'If the browser does not open, visit http://127.0.0.1:8080\n'
            'Linux/macOS: run ./Start-iSkedyul in a terminal if double-click does not launch it.\n'
            'Only run this launcher if you trust its source. macOS/Windows may ask you to approve this unsigned download.\n'
            'Your planner is saved in this browser, separately from GitHub Pages.\n'
            'Use the same browser and address each time. This is a web app, not an Android APK.\n'
        )
        archive = output / f'iskedyul-{target}.zip'
        with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as result:
            for file in sorted(package.rglob('*')):
                if file.is_file():
                    result.write(file, file.relative_to(package))
        print(archive.name, flush=True)
