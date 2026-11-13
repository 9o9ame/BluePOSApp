#!/usr/bin/env python3
"""Verify the BluePOS mobile mockup ZIP or extracted design directory.

Read-only. Verifies the numbered 92-screen manifest, actual PNG bytes/dimensions,
SHA-256 and duplicates. Provisional design slots are reported, not approved.
"""
import argparse
import csv
import hashlib
import io
from pathlib import Path, PurePosixPath
import struct
import sys
import zipfile

ROOT = 'BluePOS_Mobile_Design_Approval_Pack'
MANIFEST = 'SCREEN_MANIFEST.csv'
REQUIRED = {'screen', 'screen_title', 'module', 'image_file', 'original_source',
            'status', 'dimensions', 'sha256'}
PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'


def validate(source: Path, *, require_unique: bool = False) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    if source.is_file() and zipfile.is_zipfile(source):
        with zipfile.ZipFile(source) as zf:
            names = set(zf.namelist())
            prefix = f'{ROOT}/' if f'{ROOT}/{MANIFEST}' in names else ''
            manifest_path = prefix + MANIFEST
            if manifest_path not in names:
                return [f'Missing {MANIFEST} in ZIP'], []
            def load(rel: str) -> bytes:
                name = prefix + rel
                if name not in names:
                    raise FileNotFoundError(name)
                info = zf.getinfo(name)
                if info.file_size > 20 * 1024 * 1024:
                    raise ValueError(f'Image exceeds 20 MiB safety cap: {name}')
                return zf.read(info)
            return _validate_bytes(zf.read(manifest_path), load, require_unique)
    if source.is_dir():
        root = source / ROOT if (source / ROOT / MANIFEST).is_file() else source
        manifest = root / MANIFEST
        if not manifest.is_file():
            return [f'Missing {MANIFEST} in {root}'], []
        def load(rel: str) -> bytes:
            path = root.joinpath(*PurePosixPath(rel).parts)
            if path.stat().st_size > 20 * 1024 * 1024:
                raise ValueError(f'Image exceeds 20 MiB safety cap: {path}')
            return path.read_bytes()
        return _validate_bytes(manifest.read_bytes(), load, require_unique)
    return [f'Expected an existing ZIP file or directory: {source}'], []


def _validate_bytes(manifest: bytes, load, require_unique: bool) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []
    try:
        reader = csv.DictReader(io.StringIO(manifest.decode('utf-8-sig')))
        if not reader.fieldnames or not REQUIRED.issubset(reader.fieldnames):
            return [f'Manifest missing required columns: {sorted(REQUIRED - set(reader.fieldnames or []))}'], []
        rows = list(reader)
    except (UnicodeError, csv.Error) as ex:
        return [f'Invalid manifest: {ex}'], []
    expected = {f'{i:02}' for i in range(1, 93)}
    present = [row.get('screen', '') for row in rows]
    if len(rows) != 92:
        errors.append(f'Expected 92 manifest rows, found {len(rows)}')
    if len(set(present)) != len(present):
        errors.append('Duplicate screen numbers detected')
    if set(present) != expected:
        errors.append(f'Missing IDs: {sorted(expected - set(present))}; unexpected IDs: {sorted(set(present) - expected)}')
    if present != sorted(present):
        errors.append('Manifest rows must be ordered from 01 to 92')

    seen_hashes: dict[str, str] = {}
    for row in rows:
        num = row.get('screen', '?')
        rel = row.get('image_file', '')
        path = PurePosixPath(rel)
        if (path.is_absolute() or '..' in path.parts or len(path.parts) != 2
                or path.parts[0] != 'screens' or path.suffix.lower() != '.png'
                or not path.name.startswith(num + '_')):
            errors.append(f'{num}: unsafe or incorrectly numbered PNG path {rel!r}')
            continue
        try:
            binary = load(rel)
            if len(binary) < 24 or not binary.startswith(PNG_SIGNATURE) or binary[12:16] != b'IHDR':
                errors.append(f'{num}: invalid PNG header: {rel}')
                continue
            width, height = struct.unpack('>II', binary[16:24])
            actual_dimensions = f'{width}x{height}'
            if row.get('dimensions') != actual_dimensions:
                errors.append(f'{num}: dimension mismatch ({row.get("dimensions")} vs {actual_dimensions})')
            digest = hashlib.sha256(binary).hexdigest()
            if row.get('sha256', '').lower() != digest:
                errors.append(f'{num}: SHA256 mismatch: {rel}')
            if digest in seen_hashes:
                warnings.append(f'{num}: identical to screen {seen_hashes[digest]} ({rel})')
            else:
                seen_hashes[digest] = num
            if 'PROVISIONAL' in row.get('status', '').upper() or 'DUPLICATE' in row.get('status', '').upper():
                warnings.append(f'{num}: provisional/unapproved mockup ({row.get("status")})')
        except (OSError, KeyError, ValueError, zipfile.BadZipFile) as ex:
            errors.append(f'{num}: unreadable PNG {rel}: {ex}')

    if require_unique and any('identical to screen' in x or 'provisional/unapproved' in x for x in warnings):
        errors.append('Final-approval mode requires 92 unique, non-provisional screens')
    return errors, warnings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('path', type=Path, help='Mockup ZIP or extracted directory')
    parser.add_argument('--require-unique', action='store_true',
                        help='Fail if any repeated or provisional mockup remains')
    args = parser.parse_args()
    errors, warnings = validate(args.path, require_unique=args.require_unique)
    for warning in warnings:
        print(f'WARNING: {warning}')
    for error in errors:
        print(f'ERROR: {error}', file=sys.stderr)
    print(f'Mockup verification: {"FAILED" if errors else "PASS"} '
          f'({len(errors)} errors, {len(warnings)} warnings)')
    return 1 if errors else 0


if __name__ == '__main__':
    raise SystemExit(main())
