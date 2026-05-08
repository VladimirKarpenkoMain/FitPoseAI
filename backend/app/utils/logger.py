import sys
from pathlib import Path

from loguru import logger

logger.remove()

LOGS_DIR = Path("logs")
LOGS_DIR.mkdir(exist_ok=True)

LOG_FORMAT = (
    "<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | "
    "<level>{level: <8}</level> | "
    "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
    "<level>{message}</level>"
)

logger.add(
    sys.stdout,
    format=LOG_FORMAT,
    level="DEBUG",
    colorize=True,
    backtrace=True,
    diagnose=True,
)


def _add_file_sink(path: Path, *, level: str, retention: str) -> None:
    try:
        logger.add(
            path,
            format=LOG_FORMAT,
            level=level,
            rotation="10 MB",
            retention=retention,
            compression="zip",
            backtrace=True,
            diagnose=True,
        )
    except OSError:
        # Test environments may not permit writing into the configured logs directory.
        pass


_add_file_sink(LOGS_DIR / "app.log", level="INFO", retention="7 days")
_add_file_sink(LOGS_DIR / "errors.log", level="ERROR", retention="30 days")

__all__ = ["logger"]
