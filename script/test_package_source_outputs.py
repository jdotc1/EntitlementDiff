"""New failure-cleanup checks; accepted manifest tests are intentionally not rerun."""
import importlib.util
import json
from pathlib import Path
import plistlib
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('package_source_outputs', Path(__file__).with_name('package_source.py'))
packager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packager)

class OutputCleanupTests(unittest.TestCase):
    def fixture(self, root):
        names = sorted(packager.REQUIRED)
        for name in names:
            path = root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('Synthetic fixture\n')
        (root / 'Resources/Info.plist').write_bytes(plistlib.dumps({'CFBundleShortVersionString':'9.4.7'}))
        return names

    def test_scan_failure_removes_only_new_outputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve(); names = self.fixture(root)
            (root / 'README.md').write_text('-----BEGIN ' + 'PRIVATE KEY-----')
            dist = root / 'dist'; dist.mkdir(); previous = dist / 'previous.zip'; previous.write_bytes(b'preserve')
            with patch.multiple(packager, ROOT=root, DIST=dist), patch.object(packager, 'selected_index_paths', return_value=names):
                with self.assertRaisesRegex(SystemExit, 'Publication scan'):
                    packager.main()
            self.assertEqual(list(dist.iterdir()), [previous])
            self.assertEqual(previous.read_bytes(), b'preserve')

    def test_existing_versioned_receipt_refuses_without_mutation(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve(); names = self.fixture(root)
            dist = root / 'dist'; dist.mkdir()
            receipt = dist / 'EntitlementDiff-9.4.7-Source.receipt.json'; receipt.write_text('accepted receipt')
            with patch.multiple(packager, ROOT=root, DIST=dist), patch.object(packager, 'selected_index_paths', return_value=names):
                with self.assertRaisesRegex(SystemExit, 'already exists'):
                    packager.main()
            self.assertEqual(receipt.read_text(), 'accepted receipt')
            self.assertEqual(list(dist.iterdir()), [receipt])

    def test_partial_zip_failure_cleans_new_zip_and_tree(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve(); names = self.fixture(root); dist = root / 'dist'
            with patch.multiple(packager, ROOT=root, DIST=dist), patch.object(packager, 'selected_index_paths', return_value=names), patch.object(packager.zipfile.ZipFile, 'write', side_effect=OSError('synthetic write failure')):
                with self.assertRaisesRegex(OSError, 'synthetic write failure'):
                    packager.main()
            self.assertEqual(list(dist.iterdir()), [])

if __name__ == '__main__':
    unittest.main()
