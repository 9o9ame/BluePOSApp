"""Configure a separate BluePOS Dev installation for local Flutter Hot Reload.

Run once after `flutter create` and `tool/patch_android.py`:
    py -3 tool/configure_local_debug.py

Only edits the *generated local Android* Gradle file and debug manifest.
Release build identity, production signing, and main Android manifest are untouched.
Safe to run again after rebuilding the generated Android platform.
"""

from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
GRADLE = ROOT / "android" / "app" / "build.gradle.kts"
DEBUG_MANIFEST = ROOT / "android" / "app" / "src" / "debug" / "AndroidManifest.xml"
GRADLE_PROPERTIES = ROOT / "android" / "gradle.properties"

ANDROID_NS = "http://schemas.android.com/apk/res/android"
TOOLS_NS = "http://schemas.android.com/tools"



def configure_windows_kotlin_cache() -> None:
    """Avoid Kotlin incremental path errors across C: Pub cache and D: app.

    This changes only locally generated Android gradle.properties on Windows.
    It does not change tracked app sources or GitHub Android release builds.
    """
    if sys.platform != "win32":
        return
    if not GRADLE_PROPERTIES.is_file():
        raise SystemExit(
            "Missing android/gradle.properties: run flutter create first."
        )

    original = GRADLE_PROPERTIES.read_text(encoding="utf-8")
    property_pattern = re.compile(
        r"(?m)^[ \\t]*kotlin\\.incremental[ \\t]*=[ \\t]*[^\\r\\n]*$"
    )
    matches = list(property_pattern.finditer(original))
    if len(matches) > 1:
        raise SystemExit(
            "Multiple kotlin.incremental properties found. "
            "Review android/gradle.properties before continuing."
        )
    if matches:
        match = matches[0]
        if match.group().strip().replace(" ", "") == "kotlin.incremental=false":
            print("Windows Kotlin incremental cache fix already configured.")
            return
        updated = original[:match.start()] + "kotlin.incremental=false" + original[match.end():]
    else:
        newline = "\\r\\n" if "\\r\\n" in original else "\\n"
        separator = "" if not original or original.endswith(("\\n", "\\r")) else newline
        updated = (
            original + separator
            + "# Local Windows fix for Kotlin C:/D: plugin cache root mismatch"
            + newline + "kotlin.incremental=false" + newline
        )
    GRADLE_PROPERTIES.write_text(updated, encoding="utf-8")
    print("Configured Kotlin incremental cache workaround for Windows.")


def configure_gradle() -> None:
    if not GRADLE.is_file():
        raise SystemExit("Missing android/app/build.gradle.kts: run flutter create first.")

    original = GRADLE.read_text(encoding="utf-8")
    if not re.search(
        r'applicationId\s*=\s*"pk\.com\.bluemarketing\.bluepos_app"',
        original,
    ):
        raise SystemExit(
            "Unexpected Android applicationId. No changes made. "
            "Check the generated Flutter Android project."
        )

    existing_debug = re.search(
        r'getByName\("debug"\)\s*\{([^{}]*)\}', original, flags=re.DOTALL
    )
    if existing_debug:
        block = existing_debug.group(1)
        if not re.search(r'applicationIdSuffix\s*=\s*"\.dev"', block):
            raise SystemExit(
                "An existing debug build type has a different package suffix. "
                "No changes made."
            )
        if not re.search(r'versionNameSuffix\s*=\s*"-dev"', block):
            raise SystemExit(
                "An existing debug build type has a different version suffix. "
                "No changes made."
            )
        print("Android debug package suffix already configured.")
        return

    if re.search(r'applicationIdSuffix\s*=\s*"\.dev"', original):
        raise SystemExit(
            "Found a debug package suffix outside the expected block. "
            "No changes made."
        )

    match = re.search(r'(?m)^([ \t]*)buildTypes[ \t]*\{[ \t]*$', original)
    if not match:
        raise SystemExit("Expected Kotlin DSL buildTypes block not found. No changes made.")

    indent = match.group(1) + "    "
    nested = indent + "    "
    added = (
        "\n"
        + indent
        + 'getByName("debug") {\n'
        + nested
        + 'applicationIdSuffix = ".dev"\n'
        + nested
        + 'versionNameSuffix = "-dev"\n'
        + indent
        + "}\n"
    )
    updated = original[: match.end()] + added + original[match.end() :]
    GRADLE.write_text(updated, encoding="utf-8")
    print("Configured separate Android package: pk.com.bluemarketing.bluepos_app.dev")


def configure_debug_manifest() -> None:
    if not DEBUG_MANIFEST.is_file():
        raise SystemExit(
            "Missing android/app/src/debug/AndroidManifest.xml: "
            "run flutter create first."
        )

    ET.register_namespace("android", ANDROID_NS)
    ET.register_namespace("tools", TOOLS_NS)
    tree = ET.parse(
        DEBUG_MANIFEST,
        parser=ET.XMLParser(target=ET.TreeBuilder(insert_comments=True)),
    )
    root = tree.getroot()
    if root.tag != "manifest":
        raise SystemExit("Unexpected debug manifest root. No manifest changes made.")

    application = root.find("application")
    if application is None:
        application = ET.SubElement(root, "application")

    label_key = f"{{{ANDROID_NS}}}label"
    replace_key = f"{{{TOOLS_NS}}}replace"
    current_replace = application.get(replace_key, "")
    replace_parts = [value.strip() for value in current_replace.split(",") if value.strip()]
    if "android:label" not in replace_parts:
        replace_parts.append("android:label")

    needs_write = (
        application.get(label_key) != "BluePOS Dev"
        or application.get(replace_key) != ",".join(replace_parts)
    )
    if needs_write:
        application.set(label_key, "BluePOS Dev")
        application.set(replace_key, ",".join(replace_parts))
        ET.indent(tree, space="    ")
        tree.write(DEBUG_MANIFEST, encoding="utf-8", xml_declaration=True)
        print("Configured Android debug launcher label: BluePOS Dev")
    else:
        print("BluePOS Dev launcher label already configured.")


if __name__ == "__main__":
    # Fail fast on absent generated files before changing either of them.
    if not GRADLE.is_file() or not DEBUG_MANIFEST.is_file():
        raise SystemExit(
            "Android platform is missing. From D:\\BluePOSApp run:\n"
            "flutter create --platforms=android --org pk.com.bluemarketing "
            "--project-name bluepos_app ."
        )
    configure_windows_kotlin_cache()
    configure_gradle()
    configure_debug_manifest()
    print("BluePOS Dev is ready. Run: flutter run -d d2b1f972 --debug")
