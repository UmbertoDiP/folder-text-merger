import os
import sys
import shutil
import locale
import argparse
import logging
import tempfile
from logging.handlers import TimedRotatingFileHandler
from datetime import datetime
from pathlib import Path
from typing import Iterable, List, Set, Optional

# =========================
# Metadati applicazione
# =========================

APP_NAME = "Folder2Text"
VERSION = "1.0.9"
COPYRIGHT = "Copyright (c) 2026 Folder2Text. All rights reserved."

# =========================
# Costanti tecniche
# =========================

DEFAULT_MAX_FILE_SIZE_MB = 10
TEXT_DETECTION_THRESHOLD = 0.85
BINARY_SAMPLE_SIZE = 8192
LOG_RETENTION_DAYS = 30  # Keep logs for 30 days, then auto-delete
DEV_MODE = False  # Set to True for detailed file processing logs

EXIT_OK = 0
EXIT_NO_ARGUMENTS = 1
EXIT_NO_FILES = 2
EXIT_RUNTIME_ERROR = 3

EXCLUDED_DIRECTORIES: Set[str] = {
    ".git",
    ".svn",
    ".hg",
    "node_modules",
    "__pycache__",
    ".venv",
    "venv",
    "env",
    "dist",
    "build",
    "out",
}

SUPPORTED_EXTENSIONS: Set[str] = {
    ".txt", ".log", ".md", ".rst", ".adoc", ".asciidoc",
    ".xml", ".xsd", ".xsl", ".xslt", ".html", ".htm", ".svg",
    ".json", ".jsonc", ".json5", ".yaml", ".yml", ".csv", ".tsv",
    ".properties", ".ini", ".cfg", ".conf", ".toml",
    ".py", ".pyw",
    ".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx",
    ".java", ".c", ".h", ".cpp", ".hpp",
    ".cs", ".go", ".rs", ".kt", ".kts",
    ".swift", ".dart", ".php", ".rb",
    ".scala", ".groovy",
    ".sh", ".bash", ".bat", ".cmd", ".ps1",
    ".sql",
    ".tex", ".latex", ".bib",
    ".diff", ".patch",
    ".rtf",
}

SUPPORTED_FILENAMES: Set[str] = {
    "dockerfile",
    ".env",
    ".env.example",
    ".gitignore",
    ".gitattributes",
    "pom.xml",
    "gradle.build",
}

LABELS = {
    "en": "Merged text export created",
    "it": "Export di testo unificato creato",
}

# =========================
# BOOTSTRAP LOGGING (CRITICO)
# =========================

def bootstrap_logging() -> None:
    """
    Inizializza il logging MINIMALE prima di qualunque altra operazione.
    Deve funzionare anche se argparse o altre parti falliscono.
    BRUTE FORCE: Log to TEMP directory with immediate flush.
    """
    try:
        # Use TEMP directory for guaranteed write access
        temp_dir = Path(tempfile.gettempdir())
        log_file = temp_dir / "Folder2Text_Debug.log"

        # Create file handler with immediate flush
        file_handler = logging.FileHandler(log_file, encoding="utf-8", mode="a")
        file_handler.flush()  # Force immediate write

        logging.basicConfig(
            level=logging.DEBUG,
            format="%(asctime)s - PID:%(process)d - %(levelname)s - %(funcName)s:%(lineno)d - %(message)s",
            handlers=[file_handler],
            force=True
        )

        # Log everything about the environment
        logging.debug("="*80)
        logging.debug("BOOTSTRAP LOGGING INITIALIZED - Folder2Text %s", VERSION)
        logging.debug("Python version: %s", sys.version)
        logging.debug("Platform: %s", sys.platform)
        logging.debug("Executable: %s", sys.executable)
        logging.debug("Frozen (compiled): %s", getattr(sys, 'frozen', False))
        logging.debug("Log file: %s", log_file)
        logging.debug("Working directory: %s", os.getcwd())
        logging.debug("TEMP directory: %s", temp_dir)
        logging.debug("="*80)

    except Exception as e:
        # Last resort: write to a basic file without logging module
        try:
            fallback_log = Path(tempfile.gettempdir()) / "Folder2Text_FALLBACK.log"
            with open(fallback_log, "a") as f:
                f.write(f"\n{datetime.now()} - CRITICAL: Bootstrap logging failed: {e}\n")
                f.write(f"Traceback: {str(e)}\n")
        except:
            pass  # Ultima difesa: il logging non deve MAI impedire l'avvio

bootstrap_logging()

# =========================
# Utility lingua
# =========================

def detect_language() -> str:
    """Rileva la lingua per i messaggi utente."""
    try:
        locale_code, _ = locale.getlocale()
        if not locale_code:
            return "en"
        return locale_code.split("_", 1)[0].lower()
    except Exception:
        return "en"

LANG = detect_language()
FINAL_MESSAGE = LABELS.get(LANG, LABELS["en"])

# =========================
# Logging completo (override)
# =========================

def configure_logging(verbose: bool) -> None:
    """Configura logging completo con rotazione giornaliera."""
    log_dir = Path(os.environ.get("LOCALAPPDATA", tempfile.gettempdir())) / APP_NAME / "logs"
    log_dir.mkdir(parents=True, exist_ok=True)
    log_file = log_dir / "debug.log"

    log_level = logging.DEBUG if verbose else logging.INFO
    formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")

    file_handler = TimedRotatingFileHandler(
        log_file,
        when="D",
        interval=1,
        backupCount=LOG_RETENTION_DAYS,
        encoding="utf-8",
    )
    file_handler.setFormatter(formatter)

    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.setLevel(log_level)
    root_logger.addHandler(file_handler)
    root_logger.addHandler(console_handler)

    logging.debug("Full logging configured at: %s", log_file)

# =========================
# Utility file system
# =========================

def sanitize_argument(argument: str) -> str:
    if not argument:
        return ""
    cleaned = argument.strip().strip('"').strip("'")
    if cleaned.startswith(">"):
        cleaned = cleaned[1:]
    return cleaned.strip()

def is_supported_file(path: Path) -> bool:
    # Exclude previous output files generated by this app
    if path.name.startswith("output-") and path.suffix.lower() == ".txt":
        return False

    return (
        path.name.lower() in SUPPORTED_FILENAMES
        or path.suffix.lower() in SUPPORTED_EXTENSIONS
    )

def is_probably_text_file(path: Path) -> bool:
    try:
        with open(path, "rb") as file:
            sample = file.read(BINARY_SAMPLE_SIZE)
            if not sample:
                return True
            printable = sum(
                byte in (9, 10, 13) or 32 <= byte <= 126
                for byte in sample
            )
            ratio = printable / len(sample)
            return ratio >= TEXT_DETECTION_THRESHOLD
    except Exception:
        return False

def read_text_safely(path: Path) -> Optional[str]:
    for encoding in ("utf-8", "utf-8-sig", "utf-16", "cp1252", "latin-1"):
        try:
            with open(path, "r", encoding=encoding) as file:
                return file.read()
        except Exception:
            continue
    return None

def expand_input_paths(arguments: Iterable[str]) -> List[Path]:
    collected_files: Set[Path] = set()

    for argument in arguments:
        sanitized = sanitize_argument(argument)
        if not sanitized:
            continue

        path = Path(sanitized).expanduser().resolve()

        if not path.exists():
            logging.debug("Path not found: %s", path)
            continue

        if path.is_file():
            collected_files.add(path)
            continue

        if path.is_dir():
            for root, directories, filenames in os.walk(path):
                directories[:] = [
                    directory
                    for directory in directories
                    if directory not in EXCLUDED_DIRECTORIES
                ]
                for filename in filenames:
                    collected_files.add(Path(root) / filename)

    return sorted(collected_files)

# =========================
# Main logic
# =========================

def main() -> None:
    parser = argparse.ArgumentParser(
        prog=APP_NAME,
        description="Merge multiple text files into a single output file",
    )
    parser.add_argument("paths", nargs="+", help="Input files or directories")
    parser.add_argument("-o", "--output", type=Path, help="Output file path")
    parser.add_argument(
        "--max-size-mb",
        type=int,
        default=DEFAULT_MAX_FILE_SIZE_MB,
        help="Maximum file size in MB",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        default=True,
        help="Enable verbose logging",
    )

    args = parser.parse_args()

    configure_logging(args.verbose)
    logging.debug("Arguments received: %s", args.paths)

    selected_files = expand_input_paths(args.paths)

    if not selected_files:
        logging.error("No valid text files found in provided paths")
        logging.debug("Searched paths: %s", args.paths)
        logging.debug("Total paths provided: %d", len(args.paths))
        print(f"\nERROR: No valid text files found in the specified location(s).")
        print(f"Searched: {', '.join(str(p) for p in args.paths)}")
        sys.exit(EXIT_NO_FILES)

    # Determine base directory for relative paths (where files are located)
    if len(selected_files) > 1:
        base_directory = Path(os.path.commonpath(selected_files))
    else:
        base_directory = selected_files[0].parent

    # Determine output directory: always use parent of base_directory
    # This ensures output is created one level up from where user clicked
    if args.output:
        output_file = args.output.resolve()
        output_directory = output_file.parent
    else:
        # Get the first argument path (what user clicked on)
        first_arg_path = Path(args.paths[0]).resolve()

        # If user clicked on a directory, use its parent for output
        # If user clicked on a file, use its parent's parent for output
        if first_arg_path.is_dir():
            output_directory = first_arg_path.parent
            folder_name = first_arg_path.name
        else:
            output_directory = first_arg_path.parent.parent
            folder_name = first_arg_path.parent.name

        output_file = output_directory / f"output-{folder_name}-{datetime.now().strftime('%Y%m%d-%H%M%S')}.txt"

    logging.debug("Output will be created in: %s", output_directory)
    logging.debug("Output file: %s", output_file)

    max_size_bytes = args.max_size_mb * 1024 * 1024

    # Track files for summary
    included_files: List[Path] = []
    excluded_files: List[tuple[Path, str]] = []  # (path, reason)

    with tempfile.NamedTemporaryFile(
        mode="w",
        encoding="utf-8",
        delete=False,
        suffix=".tmp",
    ) as temporary_file:
        temporary_path = Path(temporary_file.name)

        for file_path in selected_files:
            try:
                relative_name = (
                    str(file_path.relative_to(base_directory))
                    if file_path.is_relative_to(base_directory)
                    else file_path.name
                )

                if not is_supported_file(file_path):
                    # Always log when skipping output-*.txt files (important for user visibility)
                    if file_path.name.startswith("output-") and file_path.suffix.lower() == ".txt":
                        logging.info("Skipped previous output file: %s", relative_name)
                        excluded_files.append((file_path, "Previous output file"))
                    else:
                        excluded_files.append((file_path, "Unsupported file type"))
                        if DEV_MODE:
                            logging.debug("Skipped unsupported file: %s", relative_name)
                    continue

                if file_path.stat().st_size > max_size_bytes:
                    excluded_files.append((file_path, f"File too large (>{args.max_size_mb}MB)"))
                    if DEV_MODE:
                        logging.debug("Skipped oversized file: %s", relative_name)
                    continue

                if not is_probably_text_file(file_path):
                    excluded_files.append((file_path, "Binary file detected"))
                    if DEV_MODE:
                        logging.debug("Skipped binary-like file: %s", relative_name)
                    continue

                content = read_text_safely(file_path)
                if content is None:
                    excluded_files.append((file_path, "Encoding not supported"))
                    if DEV_MODE:
                        logging.debug("Unreadable file: %s", relative_name)
                    continue

                temporary_file.write(f"\n=== {relative_name} ===\n")
                temporary_file.write(content.rstrip())
                temporary_file.write("\n")

                included_files.append(file_path)

                if DEV_MODE:
                    logging.debug("Merged file: %s", relative_name)

            except Exception as exception:
                excluded_files.append((file_path, f"Error: {exception}"))
                logging.error(
                    "Error processing file %s: %s",
                    file_path,
                    exception,
                    exc_info=True,
                )

        # Write summary at end of file
        temporary_file.write("\n\n")
        temporary_file.write("="*80 + "\n")
        temporary_file.write("EXTRACTION SUMMARY\n")
        temporary_file.write("="*80 + "\n\n")

        # Application info
        temporary_file.write(f"Generated by: {APP_NAME} v{VERSION}\n")
        temporary_file.write(f"{COPYRIGHT}\n")
        temporary_file.write(f"Extraction date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        temporary_file.write(f"Base directory: {base_directory}\n")
        temporary_file.write(f"Output file: {output_file}\n")
        temporary_file.write("\n")

        # Statistics
        total_files = len(selected_files)
        total_included = len(included_files)
        total_excluded = len(excluded_files)

        temporary_file.write(f"Files scanned: {total_files}\n")
        temporary_file.write(f"Files included: {total_included}\n")
        temporary_file.write(f"Files excluded: {total_excluded}\n")
        temporary_file.write(f"Verification: {total_included} + {total_excluded} = {total_included + total_excluded} ")

        if total_included + total_excluded == total_files:
            temporary_file.write("✓ OK\n")
        else:
            temporary_file.write(f"✗ MISMATCH (expected {total_files})\n")

        temporary_file.write("\n")

        # Included files with absolute paths
        if included_files:
            temporary_file.write(f"\n--- INCLUDED FILES ({total_included}) ---\n\n")
            for idx, file_path in enumerate(included_files, 1):
                temporary_file.write(f"{idx:4}. {file_path}\n")

        # Excluded files with reasons
        if excluded_files:
            temporary_file.write(f"\n--- EXCLUDED FILES ({total_excluded}) ---\n\n")
            for idx, (file_path, reason) in enumerate(excluded_files, 1):
                temporary_file.write(f"{idx:4}. {file_path}\n")
                temporary_file.write(f"      Reason: {reason}\n")

        temporary_file.write("\n")
        temporary_file.write("="*80 + "\n")
        temporary_file.write("END OF EXTRACTION SUMMARY\n")
        temporary_file.write("="*80 + "\n")

    # Use shutil.move instead of os.replace to support cross-drive moves
    shutil.move(temporary_path, output_file)

    # Log completion with summary (no console output in windowed mode)
    logging.info("Process completed successfully: %s", output_file)
    logging.info("Total files scanned: %d", total_files)
    logging.info("Files included: %d", total_included)
    logging.info("Files excluded: %d", total_excluded)
    logging.info("Output size: %.2f MB", output_file.stat().st_size / (1024*1024))
    logging.info("Output location: %s", output_file.parent)

    # Show Windows notification (with full error logging)
    # Note: win10toast is optional and may have internal issues on some systems
    try:
        import warnings
        with warnings.catch_warnings(record=True) as warning_list:
            warnings.simplefilter("always")
            from win10toast import ToastNotifier
            toaster = ToastNotifier()
            toaster.show_toast(
                "Folder2Text",
                f"Merged {total_included} files successfully!\n{output_file.name}",
                duration=5,
                threaded=False, # Non-threaded to capture all exceptions
                icon_path=None  # Explicitly disable icon lookup to prevent PyInstaller crash
            )

            # Log any warnings from win10toast
            if warning_list:
                for warning_item in warning_list:
                    logging.debug("win10toast warning: %s - %s",
                                 warning_item.category.__name__,
                                 warning_item.message)

        logging.debug("Windows notification completed (may have shown)")
    except ImportError as import_err:
        logging.warning("win10toast library not available: %s", import_err)
        logging.debug("Notification skipped - library missing (non-critical)")
    except Exception as notify_err:
        import traceback
        logging.warning("Windows notification failed (non-critical): %s", notify_err)
        logging.debug("Notification exception type: %s", type(notify_err).__name__)
        logging.debug("Notification exception traceback:\n%s", traceback.format_exc())

    # Exit silently (no console pause needed in windowed mode)
    logging.debug("Application completed - exiting silently")
    sys.exit(EXIT_OK)

# =========================
# Entry point
# =========================

if __name__ == "__main__":
    try:
        logging.debug("MAIN ENTRY POINT: Starting application")
        logging.debug("Arguments received: %s", sys.argv)
        logging.debug("Python version: %s", sys.version)
        logging.debug("Platform: %s", sys.platform)
        main()
        logging.debug("MAIN COMPLETED: Application finished successfully")
    except SystemExit as sys_exit:
        exit_code = sys_exit.code if sys_exit.code is not None else 0
        logging.debug("System exit called with code: %s", exit_code)
        if exit_code != 0:
            logging.warning("Application exited with non-zero code: %s", exit_code)
        raise
    except Exception as fatal_exception:
        import traceback
        logging.critical("="*80)
        logging.critical("FATAL ERROR CAUGHT IN MAIN")
        logging.critical("Exception type: %s", type(fatal_exception).__name__)
        logging.critical("Exception message: %s", fatal_exception)
        logging.critical("Full traceback:")
        logging.critical(traceback.format_exc())
        logging.critical("="*80)

        # Also write to fallback log
        try:
            fallback_log = Path(tempfile.gettempdir()) / "Folder2Text_CRASH.log"
            with open(fallback_log, "w") as f:
                f.write(f"CRASH REPORT - {datetime.now()}\n")
                f.write(f"Exception: {type(fatal_exception).__name__}\n")
                f.write(f"Message: {fatal_exception}\n")
                f.write(f"\nFull Traceback:\n{traceback.format_exc()}\n")
                f.write(f"\nArguments: {sys.argv}\n")
                f.write(f"Python: {sys.version}\n")
                f.write(f"Executable: {sys.executable}\n")
        except:
            pass

        sys.exit(EXIT_RUNTIME_ERROR)