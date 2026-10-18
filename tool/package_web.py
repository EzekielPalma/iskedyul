"""Package the root-serving Flutter build for a Windows laptop."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parent.parent
web = ROOT / 'build' / 'web'
if '<base href="/">' not in (web / 'index.html').read_text():
    raise SystemExit('Build with --base-href / --no-web-resources-cdn first.')
output = ROOT / 'build' / 'downloads'
output.mkdir(parents=True, exist_ok=True)
# Remove only previously generated download ZIPs, including old OS packages.
for archive in output.glob('iskedyul-*.zip'):
    archive.unlink()
with tempfile.TemporaryDirectory() as temporary:
    package = Path(temporary)
    environment = dict(os.environ, GOOS='windows', GOARCH='amd64', CGO_ENABLED='0')
    subprocess.run(['go', 'build', '-trimpath', '-ldflags=-s -w', '-o', str(package / 'Start-iSkedyul.exe'), '.'], cwd=ROOT / 'tool' / 'launcher', env=environment, check=True)
    shutil.copytree(web, package / 'web')
    (package / 'READ-ME.txt').write_text(
        'iSkedyul for Windows (64-bit)\n\n'
        'Extract this entire ZIP, then open Start-iSkedyul.exe.\n'
        'The app opens in your browser. Keep the launcher window open.\n'
        'No Flutter, Android Studio, emulator, Python, Node, or Go is needed.\n'
        'If the browser does not open, visit http://127.0.0.1:8080\n'
        'Windows may ask you to approve this unsigned download. Only run it if you trust its source.\n'
        'Your planner is saved in this browser, separately from the hosted site.\n'
        'The ZIP does not transfer your planner between laptops.\n'
        'App files, fonts, icons and runtime are bundled; no internet is needed to run them.\n'
        'Use the same browser and address each time. This is a web app, not an Android APK.\n'
    )
    revision = os.environ.get('GITHUB_SHA') or subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True
    ).strip()
    flutter_version = (ROOT / '.flutter-version').read_text().strip()
    (package / 'BUILD-INFO.txt').write_text(
        f'Source commit: {revision}\nFlutter: {flutter_version} stable\n'
        'Windows x64 launcher: Go 1.27.2\n'
    )
    archive = output / 'iskedyul-windows-x64.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as result:
        for file in sorted(package.rglob('*')):
            if file.is_file():
                result.write(file, file.relative_to(package))
    print(archive.name, flush=True)
