"""NEW manifest contract tests. No original packaging tests are imported or run.

Tests use mocked Git records and disposable local files, not a live repository.
"""
import importlib.util
import json
import zipfile
from pathlib import Path
import tempfile
import plistlib
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).with_name("package_source.py")
spec = importlib.util.spec_from_file_location("packaging_manifest_candidate", SCRIPT)
packager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packager)


def record(name, mode="100644", stage="0"):
    return f"{mode} {'0' * 40} {stage}\t{name}\0".encode("utf-8")


class ManifestContractTests(unittest.TestCase):
    def selected(self, records):
        with patch.object(packager.subprocess, "check_output", return_value=records):
            return packager.selected_index_paths()

    def test_unresolved_selected_entry_is_rejected(self):
        with self.assertRaisesRegex(SystemExit, "unresolved"):
            self.selected(record("Sources/Pending.swift", stage="2"))

    def test_selected_gitlink_is_rejected_from_index_metadata(self):
        with self.assertRaisesRegex(SystemExit, "non-regular indexed"):
            self.selected(record("Sources/Dependency", mode="160000"))

    def test_indexed_symlink_is_rejected_even_before_filesystem_check(self):
        with self.assertRaisesRegex(SystemExit, "non-regular indexed"):
            self.selected(record("Sources/Linked.swift", mode="120000"))

    def test_regular_modes_and_embedded_tab_filename_are_preserved(self):
        self.assertEqual(self.selected(record("script/tool.sh", mode="100755") +
                                       record("Sources/a\tb.swift")),
                         ["Sources/a\tb.swift", "script/tool.sh"])

    def test_excluded_gitlink_does_not_become_a_release_dependency(self):
        self.assertEqual(self.selected(record("private/dependency", mode="160000")), [])

    def test_versioned_current_payload_keeps_reload_and_release_description(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            names = sorted(packager.REQUIRED)
            for name in names:
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("Synthetic release fixture\n", encoding="utf-8")
            (root / "Resources/Info.plist").write_bytes(
                plistlib.dumps({"CFBundleShortVersionString": "0.1.2"}))
            current_description = "# Fixture\n## Downloads and development builds\nPublished app and local development builds are separate.\n"
            (root / "README.md").write_text(current_description, encoding="utf-8")
            reload_text = "# Reload inputs\nCurrent version workflow fixture.\n"
            (root / "docs/RELOAD_INPUTS.md").write_text(reload_text, encoding="utf-8")
            with patch.multiple(packager, ROOT=root, DIST=root / "dist"), \
                 patch.object(packager.subprocess, "check_output",
                              return_value=b"".join(record(name) for name in names)):
                packager.main()
            base = root / "dist/EntitlementDiff-0.1.2-Source"
            self.assertEqual((base / "README.md").read_text(), current_description)
            self.assertEqual((base / "docs/RELOAD_INPUTS.md").read_text(), reload_text)
            receipt = json.loads(Path(str(base) + ".receipt.json").read_text())
            self.assertEqual(receipt["version"], "0.1.2")
            with zipfile.ZipFile(str(base) + ".zip") as archive:
                self.assertEqual(archive.read("EntitlementDiff/docs/RELOAD_INPUTS.md").decode(), reload_text)
            self.assertFalse((root / "evidence").exists())

    def test_untracked_acceptance_checklist_is_not_silently_omitted(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            # The file exists but is untracked. Source selection must fail before staging.
            checklist = root / "docs/MACOS_ACCEPTANCE.md"
            checklist.parent.mkdir()
            checklist.write_text("Fixture checklist\n", encoding="utf-8")
            metadata = root / "Resources/Info.plist"
            metadata.parent.mkdir()
            metadata.write_bytes(plistlib.dumps({"CFBundleShortVersionString": "0.1.2"}))
            names = sorted(packager.REQUIRED - {"docs/MACOS_ACCEPTANCE.md"})
            with patch.multiple(packager, ROOT=root, DIST=root / "dist"), \
                 patch.object(packager, "selected_index_paths", return_value=names):
                with self.assertRaisesRegex(SystemExit, "Missing tracked.*MACOS_ACCEPTANCE"):
                    packager.main()
                self.assertFalse((root / "dist").exists())


if __name__ == "__main__":
    unittest.main()
