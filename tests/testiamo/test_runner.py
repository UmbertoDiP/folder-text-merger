# -*- coding: utf-8 -*-
"""
FolderTextMerger - Automated Test Suite
========================================

This test suite validates the compiled EXE with a comprehensive battery of tests.

Test Categories:
- Basic Execution: Can the EXE start and process files?
- Logging Verification: Are debug logs created properly?
- Edge Cases: Empty folders, read-only files, large files, etc.

Structure: Class-based approach for easy expansion.
"""

import os
import sys
import subprocess
import tempfile
import shutil
from pathlib import Path
from datetime import datetime
from typing import List, Tuple

# Force UTF-8 output for Windows console
if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())
    sys.stderr = codecs.getwriter("utf-8")(sys.stderr.detach())


class Colors:
    """ANSI color codes for terminal output"""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'


# ASCII-safe symbols
CHECK = "[OK]"
CROSS = "[FAIL]"


class TestApp:
    """Main test harness for FolderTextMerger"""

    def __init__(self, exe_path: Path):
        self.exe_path = exe_path
        self.test_root = Path(tempfile.gettempdir()) / "FolderTextMerger_Tests"
        self.results: List[Tuple[str, bool, str]] = []
        self.setup_test_environment()

    def setup_test_environment(self):
        """Create test directory structure"""
        # Clean up any previous test runs
        if self.test_root.exists():
            shutil.rmtree(self.test_root)

        self.test_root.mkdir(parents=True, exist_ok=True)
        print(f"{Colors.OKCYAN}Test environment created: {self.test_root}{Colors.ENDC}")

    def create_test_files(self, subdirs: List[str], files_per_dir: int = 3) -> Path:
        """Create dummy test files in multiple directories"""
        test_dir = self.test_root / f"test_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        test_dir.mkdir(parents=True, exist_ok=True)

        for subdir in subdirs:
            subdir_path = test_dir / subdir
            subdir_path.mkdir(parents=True, exist_ok=True)

            for i in range(files_per_dir):
                file_path = subdir_path / f"file_{i}.txt"
                file_path.write_text(
                    f"Test content in {subdir}/file_{i}.txt\n"
                    f"Created at: {datetime.now()}\n"
                    f"Line 3\nLine 4\nLine 5\n",
                    encoding="utf-8"
                )

        return test_dir

    def run_exe(self, args: List[str], timeout: int = 30) -> Tuple[int, str, str]:
        """
        Execute the EXE with given arguments.
        Returns: (return_code, stdout, stderr)
        """
        cmd = [str(self.exe_path)] + args

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=self.test_root
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "Process timed out"
        except Exception as e:
            return -1, "", str(e)

    def check_debug_log(self) -> Tuple[bool, str]:
        """Check if debug log was created and contains expected entries"""
        temp_dir = Path(tempfile.gettempdir())
        log_file = temp_dir / "FolderTextMerger_Debug.log"

        if not log_file.exists():
            return False, f"Debug log not found at {log_file}"

        try:
            content = log_file.read_text(encoding="utf-8")

            # Check for critical bootstrap markers
            required_markers = [
                "BOOTSTRAP LOGGING INITIALIZED",
                "Python version:",
                "Platform:",
                "Executable:",
            ]

            missing = [m for m in required_markers if m not in content]

            if missing:
                return False, f"Missing log markers: {missing}"

            return True, f"Debug log valid ({len(content)} bytes)"
        except Exception as e:
            return False, f"Error reading log: {e}"

    def check_crash_log(self) -> Tuple[bool, str]:
        """Check if crash log exists (should NOT exist for successful runs)"""
        temp_dir = Path(tempfile.gettempdir())
        crash_log = temp_dir / "FolderTextMerger_CRASH.log"

        if crash_log.exists():
            content = crash_log.read_text(encoding="utf-8")
            return False, f"CRASH LOG FOUND:\n{content}"

        return True, "No crash log (good)"

    def test_basic_execution(self):
        """Test 1: Basic execution with simple test files"""
        print(f"\n{Colors.BOLD}Test 1: Basic Execution{Colors.ENDC}")

        # Create test structure
        test_dir = self.create_test_files(["folder1", "folder2"])

        # Run EXE
        return_code, stdout, stderr = self.run_exe([str(test_dir)])

        # Check results
        success = return_code == 0
        output_files = list(test_dir.glob("output-*.txt"))

        if success and output_files:
            message = f"Success: Output created at {output_files[0]}"
            self.results.append(("Basic Execution", True, message))
            print(f"{Colors.OKGREEN}{CHECK} {message}{Colors.ENDC}")
        else:
            message = f"Failed: RC={return_code}, Output files: {len(output_files)}"
            self.results.append(("Basic Execution", False, message))
            print(f"{Colors.FAIL}{CROSS} {message}{Colors.ENDC}")
            print(f"  stdout: {stdout}")
            print(f"  stderr: {stderr}")

    def test_logging_verification(self):
        """Test 2: Verify debug logging works"""
        print(f"\n{Colors.BOLD}Test 2: Logging Verification{Colors.ENDC}")

        log_ok, log_msg = self.check_debug_log()
        crash_ok, crash_msg = self.check_crash_log()

        if log_ok and crash_ok:
            message = f"Logging OK: {log_msg}"
            self.results.append(("Logging Verification", True, message))
            print(f"{Colors.OKGREEN}{CHECK} {message}{Colors.ENDC}")
        else:
            message = f"Logging Issues: {log_msg} | {crash_msg}"
            self.results.append(("Logging Verification", False, message))
            print(f"{Colors.FAIL}{CROSS} {message}{Colors.ENDC}")

    def test_empty_folder(self):
        """Test 3: Handle empty folders gracefully"""
        print(f"\n{Colors.BOLD}Test 3: Empty Folder Handling{Colors.ENDC}")

        empty_dir = self.test_root / "empty_test"
        empty_dir.mkdir(parents=True, exist_ok=True)

        return_code, stdout, stderr = self.run_exe([str(empty_dir)])

        # Should exit with "no files found" error (exit code 2)
        expected_exit_code = 2
        success = return_code == expected_exit_code

        if success:
            message = f"Correctly handled empty folder (exit code {expected_exit_code})"
            self.results.append(("Empty Folder", True, message))
            print(f"{Colors.OKGREEN}{CHECK} {message}{Colors.ENDC}")
        else:
            message = f"Unexpected behavior: RC={return_code} (expected {expected_exit_code})"
            self.results.append(("Empty Folder", False, message))
            print(f"{Colors.FAIL}{CROSS} {message}{Colors.ENDC}")

    def test_single_file(self):
        """Test 4: Process a single file directly"""
        print(f"\n{Colors.BOLD}Test 4: Single File Processing{Colors.ENDC}")

        single_file = self.test_root / "single.txt"
        single_file.write_text("Single file test content", encoding="utf-8")

        return_code, stdout, stderr = self.run_exe([str(single_file)])

        success = return_code == 0
        output_files = list(self.test_root.glob("output-*.txt"))

        if success and output_files:
            message = f"Single file processed: {output_files[0].name}"
            self.results.append(("Single File", True, message))
            print(f"{Colors.OKGREEN}{CHECK} {message}{Colors.ENDC}")
        else:
            message = f"Failed: RC={return_code}"
            self.results.append(("Single File", False, message))
            print(f"{Colors.FAIL}{CROSS} {message}{Colors.ENDC}")

    def test_custom_output_path(self):
        """Test 5: Custom output path (-o argument)"""
        print(f"\n{Colors.BOLD}Test 5: Custom Output Path{Colors.ENDC}")

        test_dir = self.create_test_files(["custom_test"])
        custom_output = self.test_root / "my_custom_output.txt"

        return_code, stdout, stderr = self.run_exe([
            str(test_dir),
            "-o",
            str(custom_output)
        ])

        success = return_code == 0 and custom_output.exists()

        if success:
            message = f"Custom output created: {custom_output.name}"
            self.results.append(("Custom Output", True, message))
            print(f"{Colors.OKGREEN}{CHECK} {message}{Colors.ENDC}")
        else:
            message = f"Failed: RC={return_code}, File exists: {custom_output.exists()}"
            self.results.append(("Custom Output", False, message))
            print(f"{Colors.FAIL}{CROSS} {message}{Colors.ENDC}")

    def test_pe_header_integrity(self):
        """Test 6: Verify PE header is valid (Windows EXE structure)"""
        print(f"\n{Colors.BOLD}Test 6: PE Header Integrity{Colors.ENDC}")

        try:
            with open(self.exe_path, "rb") as f:
                header = f.read(2)

            # Check for MZ header (DOS stub)
            if header == b"MZ":
                message = "PE header valid (MZ signature found)"
                self.results.append(("PE Header", True, message))
                print(f"{Colors.OKGREEN}{CHECK} {message}{Colors.ENDC}")
            else:
                message = f"Invalid PE header: {header.hex()}"
                self.results.append(("PE Header", False, message))
                print(f"{Colors.FAIL}{CROSS} {message}{Colors.ENDC}")
        except Exception as e:
            message = f"Error checking PE header: {e}"
            self.results.append(("PE Header", False, message))
            print(f"{Colors.FAIL}{CROSS} {message}{Colors.ENDC}")

    def print_summary(self):
        """Print test results summary"""
        print(f"\n{Colors.HEADER}{'='*60}{Colors.ENDC}")
        print(f"{Colors.BOLD}TEST SUMMARY{Colors.ENDC}")
        print(f"{Colors.HEADER}{'='*60}{Colors.ENDC}\n")

        passed = sum(1 for _, success, _ in self.results if success)
        failed = len(self.results) - passed

        for test_name, success, message in self.results:
            status = f"{Colors.OKGREEN}PASS{Colors.ENDC}" if success else f"{Colors.FAIL}FAIL{Colors.ENDC}"
            print(f"[{status}] {test_name}: {message}")

        print(f"\n{Colors.HEADER}{'='*60}{Colors.ENDC}")
        print(f"{Colors.BOLD}Total: {len(self.results)} | Passed: {passed} | Failed: {failed}{Colors.ENDC}")
        print(f"{Colors.HEADER}{'='*60}{Colors.ENDC}\n")

        # Show debug log location
        temp_dir = Path(tempfile.gettempdir())
        debug_log = temp_dir / "FolderTextMerger_Debug.log"
        if debug_log.exists():
            print(f"{Colors.OKCYAN}Debug log available at:{Colors.ENDC}")
            print(f"  {debug_log}")
            print(f"  Size: {debug_log.stat().st_size} bytes\n")

        return failed == 0

    def run_all_tests(self):
        """Execute all test cases"""
        print(f"{Colors.HEADER}{'='*60}{Colors.ENDC}")
        print(f"{Colors.BOLD}FolderTextMerger - Automated Test Suite{Colors.ENDC}")
        print(f"{Colors.HEADER}{'='*60}{Colors.ENDC}")
        print(f"EXE Path: {self.exe_path}")
        print(f"EXE Size: {self.exe_path.stat().st_size / (1024*1024):.2f} MB")
        print(f"Test Root: {self.test_root}")

        # Run all tests
        self.test_pe_header_integrity()
        self.test_basic_execution()
        self.test_logging_verification()
        self.test_empty_folder()
        self.test_single_file()
        self.test_custom_output_path()

        # Print summary
        all_passed = self.print_summary()

        # Cleanup
        print(f"{Colors.OKCYAN}Cleaning up test files...{Colors.ENDC}")
        shutil.rmtree(self.test_root)

        return all_passed


def main():
    """Main entry point for test runner"""
    # Find the EXE
    script_dir = Path(__file__).parent.parent
    exe_path = script_dir / "dist" / "FolderTextMerger.exe"

    if not exe_path.exists():
        print(f"{Colors.FAIL}ERROR: EXE not found at {exe_path}{Colors.ENDC}")
        sys.exit(1)

    # Run tests
    test_app = TestApp(exe_path)
    all_passed = test_app.run_all_tests()

    # Exit with appropriate code
    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()
