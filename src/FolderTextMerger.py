import os
import sys
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

APP_NAME = "FolderTextMerger"
VERSION = "1.0.4"
COPYRIGHT = "Copyright (c) 2026 FolderTextMerger. All rights reserved."

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
        log_file = temp_dir / "FolderTextMerger_Debug.log"

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
        logging.debug("BOOTSTRAP LOGGING INITIALIZED - FolderTextMerger %s", VERSION)
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
            fallback_log = Path(tempfile.gettempdir()) / "FolderTextMerger_FALLBACK.log"
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
        logging.error("No valid files found")
        sys.exit(EXIT_NO_FILES)

    if len(selected_files) > 1:
        base_directory = Path(os.path.commonpath(selected_files))
    else:
        base_directory = selected_files[0].parent

    output_file = (
        args.output.resolve()
        if args.output
        else base_directory / f"output-{base_directory.name}-{datetime.now().strftime('%Y%m%d-%H%M%S')}.txt"
    )

    max_size_bytes = args.max_size_mb * 1024 * 1024

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
                    elif DEV_MODE:
                        logging.debug("Skipped unsupported file: %s", relative_name)
                    continue

                if file_path.stat().st_size > max_size_bytes:
                    if DEV_MODE:
                        logging.debug("Skipped oversized file: %s", relative_name)
                    continue

                if not is_probably_text_file(file_path):
                    if DEV_MODE:
                        logging.debug("Skipped binary-like file: %s", relative_name)
                    continue

                content = read_text_safely(file_path)
                if content is None:
                    if DEV_MODE:
                        logging.debug("Unreadable file: %s", relative_name)
                    continue

                temporary_file.write(f"\n=== {relative_name} ===\n")
                temporary_file.write(content.rstrip())
                temporary_file.write("\n")

                if DEV_MODE:
                    logging.debug("Merged file: %s", relative_name)

            except Exception as exception:
                logging.error(
                    "Error processing file %s: %s",
                    file_path,
                    exception,
                    exc_info=True,
                )

    os.replace(temporary_path, output_file)

    print(f"{FINAL_MESSAGE}: {output_file}")
    logging.info("Process completed successfully: %s", output_file)

    # Show Windows notification (silent mode)
    try:
        from win10toast import ToastNotifier
        toaster = ToastNotifier()
        toaster.show_toast(
            "FolderTextMerger",
            f"Merged {len(selected_files)} files successfully!\n{output_file.name}",
            duration=5,
            threaded=True
        )
    except:
        pass  # Silently fail if notification library not available

    sys.exit(EXIT_OK)

# =========================
# Entry point
# =========================

if __name__ == "__main__":
    try:
        logging.debug("MAIN ENTRY POINT: Starting application")
        logging.debug("Arguments received: %s", sys.argv)
        main()
        logging.debug("MAIN COMPLETED: Application finished successfully")
    except SystemExit as sys_exit:
        logging.debug("System exit called with code: %s", sys_exit.code)
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
            fallback_log = Path(tempfile.gettempdir()) / "FolderTextMerger_CRASH.log"
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
