from __future__ import annotations

import argparse
import configparser
import os
from pathlib import Path
from typing import Iterable

import psycopg
from psycopg.rows import dict_row


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CONFIG = PROJECT_ROOT / "config" / "postgres.ini"
EXAMPLE_CONFIG = PROJECT_ROOT / "config" / "postgres.example.ini"
SQL_DIR = PROJECT_ROOT / "sql"


def load_config(config_path: Path) -> dict[str, str]:
    parser = configparser.ConfigParser()
    source = config_path if config_path.exists() else EXAMPLE_CONFIG
    parser.read(source, encoding="utf-8")

    if "postgresql" not in parser:
        raise SystemExit(f"Missing [postgresql] section in {source}")

    values = dict(parser["postgresql"])
    env_overrides = {
        "host": "PGHOST",
        "port": "PGPORT",
        "database": "PGDATABASE",
        "user": "PGUSER",
        "password": "PGPASSWORD",
        "sslmode": "PGSSLMODE",
    }
    for key, env_name in env_overrides.items():
        if os.getenv(env_name):
            values[key] = os.environ[env_name]

    required = ["host", "port", "database", "user", "password"]
    missing = [key for key in required if not values.get(key)]
    if missing:
        raise SystemExit(f"Missing PostgreSQL settings: {', '.join(missing)}")

    return values


def connect(config_path: Path) -> psycopg.Connection:
    values = load_config(config_path)
    return psycopg.connect(
        host=values["host"],
        port=int(values["port"]),
        dbname=values["database"],
        user=values["user"],
        password=values["password"],
        sslmode=values.get("sslmode", "prefer"),
        row_factory=dict_row,
    )


def read_sql(name: str) -> str:
    path = SQL_DIR / name
    if not path.exists():
        raise SystemExit(f"SQL file not found: {path}")
    return path.read_text(encoding="utf-8")


def execute_file(conn: psycopg.Connection, name: str) -> None:
    with conn.cursor() as cur:
        cur.execute(read_sql(name))
    conn.commit()
    print(f"Applied {name}")


def init_database(args: argparse.Namespace) -> None:
    with connect(args.config) as conn:
        execute_file(conn, "01_schema.sql")


def seed_database(args: argparse.Namespace) -> None:
    with connect(args.config) as conn:
        execute_file(conn, "01_schema.sql")
        execute_file(conn, "02_seed_data.sql")


def format_table(rows: list[dict[str, object]]) -> str:
    if not rows:
        return "(no rows)"

    columns = list(rows[0].keys())
    widths = {
        column: max(len(column), *(len(str(row[column])) for row in rows))
        for column in columns
    }
    header = " | ".join(column.ljust(widths[column]) for column in columns)
    divider = "-+-".join("-" * widths[column] for column in columns)
    body = [
        " | ".join(str(row[column]).ljust(widths[column]) for column in columns)
        for row in rows
    ]
    return "\n".join([header, divider, *body])


def available_queries() -> list[Path]:
    return sorted(SQL_DIR.glob("query_*.sql"))


def run_query_file(conn: psycopg.Connection, path: Path) -> None:
    with conn.cursor() as cur:
        cur.execute(path.read_text(encoding="utf-8"))
        rows = cur.fetchall()
    print(f"\n{path.name}")
    print(format_table(rows))


def query_database(args: argparse.Namespace) -> None:
    queries = available_queries()
    if args.name != "all":
        selected = [
            path for path in queries if path.stem == args.name or path.name == args.name
        ]
        if not selected:
            names = ", ".join(path.stem for path in queries)
            raise SystemExit(f"Unknown query '{args.name}'. Available: {names}")
        queries = selected

    with connect(args.config) as conn:
        for path in queries:
            run_query_file(conn, path)


def check_config(args: argparse.Namespace) -> None:
    values = load_config(args.config)
    masked = {**values, "password": "***"}
    print("Loaded PostgreSQL configuration:")
    for key in ["host", "port", "database", "user", "password", "sslmode"]:
        print(f"- {key}: {masked.get(key, '')}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Set up and query a PostgreSQL FOCUS demonstration database."
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG,
        help="Path to PostgreSQL INI config. Defaults to config/postgres.ini.",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    check = subparsers.add_parser("check-config", help="Validate config loading.")
    check.set_defaults(func=check_config)

    init = subparsers.add_parser("init-db", help="Create the FOCUS schema and table.")
    init.set_defaults(func=init_database)

    seed = subparsers.add_parser("seed", help="Create schema and load demo rows.")
    seed.set_defaults(func=seed_database)

    query = subparsers.add_parser("query", help="Run one or all sample queries.")
    query.add_argument(
        "name",
        nargs="?",
        default="all",
        help="Query stem, file name, or 'all'. Example: query_01_daily_cost_by_provider",
    )
    query.set_defaults(func=query_database)

    return parser


def main(argv: Iterable[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
