"""Patch Flutter-generated Android project for secure BluePOS hardware integration.

Runs after `flutter create` on a clean GitHub Actions machine. Fails closed if
native files drift rather than publishing a broken biometric experience.
"""
from pathlib import Path
import xml.etree.ElementTree as ET

manifest_path = Path('android/app/src/main/AndroidManifest.xml')
if not manifest_path.exists():
    raise SystemExit('Android manifest missing: run flutter create first')

android_ns = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('android', android_ns)
root = ET.parse(manifest_path).getroot()
permissions = (
    'android.permission.INTERNET',
    'android.permission.CAMERA',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.USE_BIOMETRIC',
)
existing = {p.get(f'{{{android_ns}}}name') for p in root.findall('uses-permission')}
for name in permissions:
    if name not in existing:
        p = ET.Element('uses-permission')
        p.set(f'{{{android_ns}}}name', name)
        root.insert(0, p)

application = root.find('application')
if application is None:
    raise SystemExit('Expected Flutter Android application element')
application.set(f'{{{android_ns}}}label', 'BluePOS Mobile')
application.set(f'{{{android_ns}}}usesCleartextTraffic', 'false')
ET.ElementTree(root).write(manifest_path, encoding='utf-8', xml_declaration=True)

# local_auth Android needs FragmentActivity for BiometricPrompt.
activities = list(Path('android/app/src/main/kotlin').rglob('MainActivity.kt'))
if len(activities) != 1:
    raise SystemExit(f'Expected one Android MainActivity.kt, found {len(activities)}')
activity_path = activities[0]
source = activity_path.read_text()
source = source.replace('import io.flutter.embedding.android.FlutterActivity',
    'import io.flutter.embedding.android.FlutterFragmentActivity')
source = source.replace('class MainActivity : FlutterActivity()',
    'class MainActivity : FlutterFragmentActivity()')
source = source.replace('class MainActivity: FlutterActivity()',
    'class MainActivity: FlutterFragmentActivity()')
if 'FlutterFragmentActivity()' not in source:
    raise SystemExit('FlutterFragmentActivity conversion failed')
activity_path.write_text(source)

for path in [Path('android/app/src/main/res/values/styles.xml'),
             Path('android/app/src/main/res/values-night/styles.xml')]:
    if not path.exists():
        raise SystemExit(f'Missing Android theme {path}')
    contents = path.read_text()
    contents = contents.replace('@android:style/Theme.Light.NoTitleBar',
        'Theme.AppCompat.DayNight.NoActionBar')
    contents = contents.replace('@android:style/Theme.Black.NoTitleBar',
        'Theme.AppCompat.DayNight.NoActionBar')
    contents = contents.replace('@android:style/Theme.NoTitleBar',
        'Theme.AppCompat.DayNight.NoActionBar')
    if 'Theme.AppCompat' not in contents:
        raise SystemExit(f'AppCompat theme missing in {path}')
    path.write_text(contents)
print('Android permissions, FragmentActivity and AppCompat themes configured.')
