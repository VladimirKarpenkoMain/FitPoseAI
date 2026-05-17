import importlib.util
from pathlib import Path


ALEMBIC_VERSION_NUM_LENGTH = 32


def _load_migration(path: Path):
    spec = importlib.util.spec_from_file_location(path.stem, path)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_alembic_revision_ids_fit_default_version_table() -> None:
    versions_dir = (
        Path(__file__).resolve().parents[1] / "app" / "migrations" / "versions"
    )

    for migration_path in versions_dir.glob("*.py"):
        migration = _load_migration(migration_path)

        assert len(migration.revision) <= ALEMBIC_VERSION_NUM_LENGTH
