#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Comprehensive Integration Test Suite
====================================

Tests all aspects of FolderTextMerger in real-world scenarios.
"""

import sys
import subprocess
import tempfile
import shutil
from pathlib import Path

# Force UTF-8 for Windows console
if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())
    sys.stderr = codecs.getwriter("utf-8")(sys.stderr.detach())


class ComprehensiveTest:
    def __init__(self):
        self.exe = Path(__file__).parent.parent / "dist" / "FolderTextMerger.exe"
        self.results = []

    def run_test(self, name, func):
        """Execute a test and record result"""
        print(f"\n{'='*60}")
        print(f"Test: {name}")
        print(f"{'='*60}")
        try:
            func()
            print(f"[OK] PASSED")
            self.results.append((name, True))
        except AssertionError as e:
            print(f"[FAIL] FAILED: {e}")
            self.results.append((name, False))
        except Exception as e:
            print(f"[ERROR] ERROR: {e}")
            self.results.append((name, False))

    def test_real_world_project(self):
        """Test with realistic project structure"""
        test_dir = Path("test_real_scenario")
        assert test_dir.exists(), "Test directory not found"

        result = subprocess.run(
            [str(self.exe), str(test_dir), "-o", "output_real.txt"],
            capture_output=True,
            text=True,
            timeout=10
        )

        assert result.returncode == 0, f"Exit code: {result.returncode}"
        assert Path("output_real.txt").exists(), "Output file not created"

        # Verify content
        content = Path("output_real.txt").read_text(encoding="utf-8")
        assert "readme.md" in content, "Markdown file not merged"
        assert "config.json" in content, "JSON file not merged"
        assert "script.py" in content, "Python file not merged"
        assert "notes.txt" in content, "Text file not merged"
        assert "日本語" in content, "Unicode not preserved"

        Path("output_real.txt").unlink()
        print("  - All file types merged correctly")
        print("  - Unicode characters preserved")

    def test_unicode_handling(self):
        """Test various unicode scenarios"""
        test_dir = Path("edge_cases/special_chars")

        result = subprocess.run(
            [str(self.exe), str(test_dir), "-o", "output_unicode.txt"],
            capture_output=True,
            text=True,
            timeout=10
        )

        assert result.returncode == 0, f"Exit code: {result.returncode}"

        content = Path("output_unicode.txt").read_text(encoding="utf-8")
        assert "café" in content, "Accented chars not preserved"
        assert "€" in content, "Currency symbols not preserved"
        assert "→" in content, "Arrows not preserved"
        assert "😀" in content, "Emoji not preserved"

        Path("output_unicode.txt").unlink()
        print("  - Accented characters: OK")
        print("  - Currency symbols: OK")
        print("  - Arrows: OK")
        print("  - Emoji: OK")

    def test_large_files(self):
        """Test performance with large files"""
        test_dir = Path("stress_test")

        # Clean up old outputs first
        for f in test_dir.glob("*.txt"):
            if f.name.startswith("stress_output") or f.name.startswith("output"):
                f.unlink()

        result = subprocess.run(
            [str(self.exe), str(test_dir), "-o", "output_stress.txt"],
            capture_output=True,
            text=True,
            timeout=30
        )

        assert result.returncode == 0, f"Exit code: {result.returncode}"

        output_file = Path("output_stress.txt")
        assert output_file.exists(), "Output not created"

        size_mb = output_file.stat().st_size / (1024 * 1024)
        # Expect ~815KB for 5 files (each ~163KB)
        assert size_mb < 1, f"Output too large: {size_mb:.2f} MB"

        output_file.unlink()
        print(f"  - Processed 5 large files successfully")
        print(f"  - Output size: {size_mb:.2f} MB")

    def test_size_limits(self):
        """Test file size filtering"""
        test_dir = Path("size_limit")

        # Test with default 10MB limit
        result = subprocess.run(
            [str(self.exe), str(test_dir), "-o", "output_default.txt"],
            capture_output=True,
            text=True,
            timeout=10
        )

        assert result.returncode == 0, f"Exit code: {result.returncode}"
        assert "Skipped oversized file" in result.stderr, "Large file not skipped"

        # Test with increased limit
        result = subprocess.run(
            [str(self.exe), str(test_dir), "--max-size-mb", "15", "-o", "output_15mb.txt"],
            capture_output=True,
            text=True,
            timeout=10
        )

        assert result.returncode == 0, f"Exit code: {result.returncode}"
        assert "Merged file: large_11mb.txt" in result.stderr, "Large file not merged with increased limit"

        Path("output_default.txt").unlink(missing_ok=True)
        Path("output_15mb.txt").unlink(missing_ok=True)
        print("  - Default 10MB limit: OK")
        print("  - Custom 15MB limit: OK")

    def test_error_handling(self):
        """Test error conditions"""
        # Test nonexistent path
        result = subprocess.run(
            [str(self.exe), "/nonexistent/path"],
            capture_output=True,
            text=True,
            timeout=5
        )

        assert result.returncode == 2, f"Expected exit code 2, got {result.returncode}"
        assert "No valid files found" in result.stderr, "Error message not shown"

        # Test empty directory
        empty_dir = Path("empty_test_dir")
        empty_dir.mkdir(exist_ok=True)

        result = subprocess.run(
            [str(self.exe), str(empty_dir)],
            capture_output=True,
            text=True,
            timeout=5
        )

        assert result.returncode == 2, f"Expected exit code 2, got {result.returncode}"

        empty_dir.rmdir()
        print("  - Nonexistent path: OK")
        print("  - Empty directory: OK")

    def test_cli_arguments(self):
        """Test command-line interface"""
        # Test --help
        result = subprocess.run(
            [str(self.exe), "--help"],
            capture_output=True,
            text=True,
            timeout=5
        )

        assert result.returncode == 0, f"Help exit code: {result.returncode}"
        assert "usage:" in result.stdout, "Help text not shown"
        assert "-o OUTPUT" in result.stdout, "Output option not documented"
        assert "--max-size-mb" in result.stdout, "Max size option not documented"

        print("  - --help: OK")
        print("  - All options documented: OK")

    def test_debug_logging(self):
        """Test that debug logs are created"""
        temp_dir = Path(tempfile.gettempdir())
        debug_log = temp_dir / "FolderTextMerger_Debug.log"

        # Run a simple command
        subprocess.run(
            [str(self.exe), "test_real_scenario", "-o", "output_log_test.txt"],
            capture_output=True,
            timeout=5
        )

        assert debug_log.exists(), "Debug log not created"

        content = debug_log.read_text(encoding="utf-8")
        assert "BOOTSTRAP LOGGING INITIALIZED" in content, "Bootstrap log missing"
        assert "Python version:" in content, "Python version not logged"
        assert "Frozen (compiled): True" in content, "Frozen state not logged"

        Path("output_log_test.txt").unlink(missing_ok=True)
        print(f"  - Debug log created: {debug_log}")
        print(f"  - Log size: {debug_log.stat().st_size} bytes")

    def print_summary(self):
        """Print final results"""
        print(f"\n{'='*60}")
        print("COMPREHENSIVE TEST SUMMARY")
        print(f"{'='*60}\n")

        passed = sum(1 for _, success in self.results if success)
        total = len(self.results)

        for name, success in self.results:
            status = "[PASS]" if success else "[FAIL]"
            print(f"{status} {name}")

        print(f"\n{'='*60}")
        print(f"Total: {total} | Passed: {passed} | Failed: {total - passed}")
        print(f"{'='*60}\n")

        return passed == total


def main():
    tester = ComprehensiveTest()

    print("Starting Comprehensive Integration Tests...")
    print(f"EXE: {tester.exe}")

    tester.run_test("Real-World Project Structure", tester.test_real_world_project)
    tester.run_test("Unicode Handling", tester.test_unicode_handling)
    tester.run_test("Large File Performance", tester.test_large_files)
    tester.run_test("File Size Limits", tester.test_size_limits)
    tester.run_test("Error Handling", tester.test_error_handling)
    tester.run_test("CLI Arguments", tester.test_cli_arguments)
    tester.run_test("Debug Logging", tester.test_debug_logging)

    all_passed = tester.print_summary()

    return 0 if all_passed else 1


if __name__ == "__main__":
    exit(main())
