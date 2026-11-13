"""Focused offline unit tests for the mockup archive validator."""
import csv
import hashlib
import importlib.util
import io
from pathlib import Path
import struct
import tempfile
import unittest
import zipfile

MODULE = Path(__file__).resolve().parents[1] / 'tool' / 'verify_mobile_mockups.py'
spec = importlib.util.spec_from_file_location('verify_mobile_mockups', MODULE)
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


def png() -> bytes:
    return b'\x89PNG\r\n\x1a\n' + struct.pack('>I', 13) + b'IHDR' + struct.pack('>II', 1, 1) + b'\x08\x02\x00\x00\x00' + b'\x00\x00\x00\x00'


def make_archive(folder: Path, tamper: str = '') -> Path:
    result = folder / 'mockups.zip'
    data = png()
    with zipfile.ZipFile(result, 'w') as zf:
        output = io.StringIO()
        writer = csv.DictWriter(output, fieldnames=sorted(validator.REQUIRED))
        writer.writeheader()
        for i in range(1, 93):
            file = f'screens/{i:02}_Screen.png'
            writer.writerow({'screen': f'{i:02}', 'screen_title': f'Screen {i}',
                             'module': 'Test', 'image_file': file,
                             'original_source': 'generated.png',
                             'status': 'reference', 'dimensions': '1x1',
                             'sha256': 'bad' if tamper == 'checksum' and i == 5 else hashlib.sha256(data).hexdigest()})
            if not (tamper == 'missing' and i == 3):
                zf.writestr(f'{validator.ROOT}/{file}', data)
        zf.writestr(f'{validator.ROOT}/{validator.MANIFEST}', output.getvalue())
    return result


class MockupManifestTests(unittest.TestCase):
    def test_valid_numbered_files_pass_integrity_but_duplicates_warn(self):
        with tempfile.TemporaryDirectory() as temp:
            errors, warnings = validator.validate(make_archive(Path(temp)))
        self.assertEqual(errors, [])
        self.assertTrue(any('identical to screen' in w for w in warnings))

    def test_strict_approval_requires_distinct_images(self):
        with tempfile.TemporaryDirectory() as temp:
            errors, _ = validator.validate(make_archive(Path(temp)), require_unique=True)
        self.assertTrue(any('92 unique' in e for e in errors))

    def test_missing_image_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            errors, _ = validator.validate(make_archive(Path(temp), 'missing'))
        self.assertTrue(any('03: unreadable PNG' in e for e in errors))

    def test_hash_tampering_fails(self):
        with tempfile.TemporaryDirectory() as temp:
            errors, _ = validator.validate(make_archive(Path(temp), 'checksum'))
        self.assertTrue(any('05: SHA256 mismatch' in e for e in errors))


if __name__ == '__main__':
    unittest.main()
