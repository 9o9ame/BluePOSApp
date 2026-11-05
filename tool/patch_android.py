"""Add only the permissions required by the BluePOS Android mobile client.

CI runs `flutter create` first. This patch is intentionally deterministic and
keeps the Flutter-generated native project aligned with the pinned SDK.
"""
from pathlib import Path
import xml.etree.ElementTree as ET

manifest_path = Path('android/app/src/main/AndroidManifest.xml')
if not manifest_path.exists():
    raise SystemExit('Android manifest missing: run flutter create first')

android_namespace = 'http://schemas.android.com/apk/res/android'
ET.register_namespace('android', android_namespace)
root = ET.parse(manifest_path).getroot()

permissions = [
    'android.permission.INTERNET',
    'android.permission.CAMERA',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
]
existing = {
    p.get(f'{{{android_namespace}}}name')
    for p in root.findall('uses-permission')
}
for permission in permissions:
    if permission not in existing:
        entry = ET.Element('uses-permission')
        entry.set(f'{{{android_namespace}}}name', permission)
        root.insert(0, entry)

application = root.find('application')
if application is None:
    raise SystemExit('Expected Flutter Android application element')
application.set(f'{{{android_namespace}}}label', 'BluePOS Mobile')
application.set(f'{{{android_namespace}}}usesCleartextTraffic', 'false')

ET.ElementTree(root).write(manifest_path, encoding='utf-8', xml_declaration=True)
print('Android manifest patched with camera, network and sign-in location permissions.')
