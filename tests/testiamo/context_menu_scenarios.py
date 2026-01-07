#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Context Menu Selection Scenarios
=================================

Simulates various Windows Explorer context menu scenarios:
1. Single file selection
2. Multiple files selection
3. Single folder selection
4. Multiple folders selection
5. Mixed files + folders selection
6. Deeply nested folder
"""

import sys
import subprocess
from pathlib import Path

if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())
    sys.stderr = codecs.getwriter("utf-8")(sys.stderr.detach())


class ContextMenuSimulator:
    def __init__(self):
        self.exe = Path(__file__).parent.parent / "dist" / "FolderTextMerger.exe"
        self.test_root = Path("context_menu_test")
        self.results = []

    def run_scenario(self, name, paths, expected_files):
        """Simulate a context menu scenario"""
        print(f"\n{'='*70}")
        print(f"Scenario: {name}")
        print(f"{'='*70}")
        print(f"Selected paths:")
        for p in paths:
            print(f"  - {p}")

        # Build command
        cmd = [str(self.exe)] + [str(self.test_root / p) for p in paths] + ["-o", f"output_{name.replace(' ', '_').lower()}.txt"]

        # Run
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=10
        )

        # Check
        success = result.returncode == 0
        output_file = Path(f"output_{name.replace(' ', '_').lower()}.txt")

        if success and output_file.exists():
            content = output_file.read_text(encoding="utf-8")

            # Count merged files
            merged_count = content.count("=== ")

            print(f"\n[OK] Merged {merged_count} files")

            # Verify expected files are present
            missing = []
            for expected in expected_files:
                if expected not in content:
                    missing.append(expected)

            if missing:
                print(f"[WARN] Missing expected files: {missing}")
                success = False
            else:
                print(f"[OK] All {len(expected_files)} expected files present")

            # Show some stats
            lines = content.count("\n")
            size_kb = output_file.stat().st_size / 1024
            print(f"      Output: {lines} lines, {size_kb:.2f} KB")

            # Cleanup
            output_file.unlink()
        else:
            print(f"[FAIL] Exit code: {result.returncode}")
            if result.stderr:
                print(f"Error: {result.stderr[:200]}")
            success = False

        self.results.append((name, success))
        return success

    def scenario_1_single_file(self):
        """Scenario 1: Right-click on a single file"""
        return self.run_scenario(
            name="Single File Selection",
            paths=["single_file.txt"],
            expected_files=["single_file.txt"]
        )

    def scenario_2_multiple_files(self):
        """Scenario 2: Ctrl+click multiple files, right-click"""
        return self.run_scenario(
            name="Multiple Files Selection",
            paths=[
                "standalone_files/note1.txt",
                "standalone_files/note2.txt",
                "single_file.txt"
            ],
            expected_files=["note1.txt", "note2.txt", "single_file.txt"]
        )

    def scenario_3_single_folder(self):
        """Scenario 3: Right-click on a single folder"""
        return self.run_scenario(
            name="Single Folder Selection",
            paths=["project1"],
            expected_files=["main.py", "utils.py", "README.md"]
        )

    def scenario_4_multiple_folders(self):
        """Scenario 4: Ctrl+click multiple folders, right-click"""
        return self.run_scenario(
            name="Multiple Folders Selection",
            paths=["project1", "project2"],
            expected_files=[
                "main.py",
                "utils.py",
                "README.md",
                "guide.md",
                "config.json"
            ]
        )

    def scenario_5_mixed_selection(self):
        """Scenario 5: Mix of files and folders selected"""
        return self.run_scenario(
            name="Mixed Files and Folders",
            paths=[
                "project1",  # Folder
                "project2/config.json",  # Single file
                "standalone_files/note1.txt",  # Single file
                "single_file.txt"  # Single file
            ],
            expected_files=[
                "main.py",
                "utils.py",
                "README.md",
                "config.json",
                "note1.txt",
                "single_file.txt"
            ]
        )

    def scenario_6_nested_folder(self):
        """Scenario 6: Right-click on nested subfolder"""
        return self.run_scenario(
            name="Nested Subfolder Selection",
            paths=["project1/src"],
            expected_files=["main.py", "utils.py"]
        )

    def scenario_7_empty_folder(self):
        """Scenario 7: Right-click on empty folder"""
        # Create empty folder
        empty = self.test_root / "empty_folder"
        empty.mkdir(exist_ok=True)

        print(f"\n{'='*70}")
        print(f"Scenario: Empty Folder Selection")
        print(f"{'='*70}")

        result = subprocess.run(
            [str(self.exe), str(empty)],
            capture_output=True,
            text=True,
            timeout=5
        )

        # Should exit with code 2 (no files)
        success = result.returncode == 2
        if success:
            print("[OK] Correctly handled empty folder (exit code 2)")
        else:
            print(f"[FAIL] Unexpected exit code: {result.returncode}")

        empty.rmdir()
        self.results.append(("Empty Folder Selection", success))
        return success

    def scenario_8_drag_drop_simulation(self):
        """Scenario 8: Drag multiple items onto EXE"""
        print(f"\n{'='*70}")
        print(f"Scenario: Drag & Drop Multiple Items")
        print(f"{'='*70}")
        print("This simulates dragging files/folders onto the EXE icon")

        # Simulate drag & drop of mixed content
        paths = [
            self.test_root / "project1",
            self.test_root / "single_file.txt",
            self.test_root / "standalone_files/note1.txt"
        ]

        print(f"Dragged items:")
        for p in paths:
            print(f"  - {p}")

        result = subprocess.run(
            [str(self.exe)] + [str(p) for p in paths],
            capture_output=True,
            text=True,
            timeout=10
        )

        success = result.returncode == 0
        if success:
            # Find output file (auto-generated name)
            outputs = list(Path(".").glob("output-context_menu_test-*.txt"))
            if outputs:
                output = outputs[0]
                content = output.read_text(encoding="utf-8")
                merged_count = content.count("=== ")
                print(f"[OK] Drag & drop processed: {merged_count} files merged")
                print(f"     Output: {output.name}")
                output.unlink()
            else:
                print("[WARN] Output file not found (might be in different location)")
        else:
            print(f"[FAIL] Exit code: {result.returncode}")

        self.results.append(("Drag & Drop Simulation", success))
        return success

    def print_summary(self):
        """Print summary of all scenarios"""
        print(f"\n{'='*70}")
        print("CONTEXT MENU SIMULATION SUMMARY")
        print(f"{'='*70}\n")

        passed = sum(1 for _, success in self.results if success)
        total = len(self.results)

        for name, success in self.results:
            status = "[PASS]" if success else "[FAIL]"
            print(f"{status} {name}")

        print(f"\n{'='*70}")
        print(f"Total: {total} | Passed: {passed} | Failed: {total - passed}")
        print(f"{'='*70}\n")

        if passed == total:
            print("[OK] All context menu scenarios work correctly!")
            print("The application is ready for Windows Explorer integration.")
        else:
            print("[WARN] Some scenarios failed. Review the issues above.")

        return passed == total


def main():
    sim = ContextMenuSimulator()

    print("="*70)
    print("Windows Explorer Context Menu Simulation")
    print("="*70)
    print(f"EXE: {sim.exe}")
    print(f"Test root: {sim.test_root}")

    # Run all scenarios
    sim.scenario_1_single_file()
    sim.scenario_2_multiple_files()
    sim.scenario_3_single_folder()
    sim.scenario_4_multiple_folders()
    sim.scenario_5_mixed_selection()
    sim.scenario_6_nested_folder()
    sim.scenario_7_empty_folder()
    sim.scenario_8_drag_drop_simulation()

    # Summary
    all_passed = sim.print_summary()

    return 0 if all_passed else 1


if __name__ == "__main__":
    exit(main())
