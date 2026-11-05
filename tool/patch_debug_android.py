"""Configure a separate BluePOS Dev Android app for local Flutter Hot Reload.

Run after the repository's normal "flutter create" and "patch_android.py"
steps. This changes only generated local Android files (not tracked release
sources), is safe to rerun, and leaves the release application ID unchanged.
"""
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
GRADLE = ROOT / "android" / "app" / "build.gradle.kts"
DEBUG_MANIFEST = ROOT / "android" / "app" / "src" / "debug" / "AndroidManifest.xml"
RELEASE_APPLICATION_ID = "pk.com.bluemarketing.bluepos_app"
DEBUG_APPLICATION_ID = RELEASE_APPLICATION_ID + ".dev"

if not GRADLE.is_file() or not DEBUG_MANIFEST.is_file():
    raise SystemExit(
        "Generated Android project not found. Run 'flutter create "
        "--platforms=android --org pk.com.bluemarketing "
        "--project-name bluepos_app .' first."
    )

gradle = GRADLE.read_text(encoding="utf-8")
application_id = re.search(
    r'(?m)^[ \t]*applicationId[ \t]*=[ \t]*"([^"]+)"[ \t]*$',
    gradle,
)
if application_id is None or application_id.group(1) != RELEASE_APPLICATION_ID:
    raise SystemExit(
        "Unexpected release applicationId; refusing to change Android configuration."
    )

if 'applicationIdSuffix = ".dev"' not in gradle:
    # Avoid duplicating or changing any existing debug build configuration.
    if "applicationIdSuffix" in gradle or 'getByName("debug")' in gradle:
        raise SystemExit(
            "An Android build variant is already customized. Review it before "
            "running this script."
        )
    build_types = re.search(
        r'(?m)^([ \t]+)buildTypes[ \t]*\{[ \t]*$',
        gradle,
    )
    if build_types is None:
        raise SystemExit("Kotlin Gradle buildTypes block not found.")

    indent = build_types.group(1) + "    "
    debug_block = (
        "\n" + indent + 'getByName("debug") {' +
        "\n" + indent + '    applicationIdSuffix = ".dev"' +
        "\n" + indent + '    versionNameSuffix = "-dev"' +
        "\n" + indent + "}" +
        "\n"
    )
    gradle = (
        gradle[:build_types.end()] + debug_block +
        gradle[build_types.end():]
    )
elif 'versionNameSuffix = "-dev"' not in gradle:
    raise SystemExit("Incomplete debug build configuration; review manually.")

android_ns = "http://schemas.android.com/apk/res/android"
tools_ns = "http://schemas.android.com/tools"
ET.register_namespace("android", android_ns)
ET.register_namespace("tools", tools_ns)
tree = ET.parse(
    DEBUG_MANIFEST,
    parser=ET.XMLParser(target=ET.TreeBuilder(insert_comments=True)),
)
root = tree.getroot()
if root.tag != "manifest":
    raise SystemExit("Unexpected Android debug manifest root.")
application = root.find("application")
if application is None:
    application = ET.SubElement(root, "application")
label = application.get(f"{{{android_ns}}}label")
if label is not None and label != "BluePOS Dev":
    raise SystemExit("Debug manifest already has a different app label.")
application.set(f"{{{android_ns}}}label", "BluePOS Dev")
# Debug manifest has higher priority than the main Android manifest.
# Explicitly override only the launcher label, not release configuration.
application.set(f"{{{tools_ns}}}replace", "android:label")

if GRADLE.read_text(encoding="utf-8") != gradle:
    GRADLE.write_text(gradle, encoding="utf-8")
tree.write(DEBUG_MANIFEST, encoding="utf-8", xml_declaration=True)
print(f"Configured BluePOS Dev: {DEBUG_APPLICATION_ID}")
print(f"Release app remains: {RELEASE_APPLICATION_ID}")
print("Next: flutter run -d d2b1f972 --debug")
