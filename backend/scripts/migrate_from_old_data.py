"""Migrate shops, products, expenses, and uploads from backend/OLD_DATA."""

from __future__ import annotations

import json
import re
import shutil
import sqlite3
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent
OLD_DATA_DIR = BACKEND_DIR / "OLD_DATA"
OLD_DB_PATH = OLD_DATA_DIR / "azaly_trade.db"
OLD_UPLOADS_DIR = OLD_DATA_DIR / "uploads"
NEW_DB_PATH = BACKEND_DIR / "azaly_trade.db"
NEW_UPLOADS_DIR = BACKEND_DIR / "uploads"

SUPPLIER_SHARE_PERCENT = 10.0


def parse_amount_value(raw_value: str) -> float | None:
    normalized = re.sub(r"[^0-9.,]", "", (raw_value or "").strip()).replace(",", ".")

    if not normalized:
        return None

    if not re.fullmatch(r"[0-9]+(?:\.[0-9]+)?", normalized):
        return None

    return float(normalized)


def calculate_product_pricing(
    amount: str,
    quantity: int,
    supplier_share_percent: float = SUPPLIER_SHARE_PERCENT,
) -> tuple[float, float, float]:
    unit_price = parse_amount_value(amount)
    if unit_price is None:
        return supplier_share_percent, 0.0, 0.0

    safe_quantity = max(1, int(quantity or 1))
    gross_total = unit_price * safe_quantity
    supplier_share_amount = gross_total * (supplier_share_percent / 100.0)
    supplier_share_per_unit = supplier_share_amount / safe_quantity
    unit_price_with_share = unit_price + supplier_share_per_unit
    return supplier_share_percent, supplier_share_amount, unit_price_with_share


def load_json(value: object, fallback):
    if value in (None, ""):
        return fallback

    if isinstance(value, (list, dict)):
        return value

    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return fallback


def copy_uploads() -> tuple[int, int]:
    NEW_UPLOADS_DIR.mkdir(parents=True, exist_ok=True)
    copied = 0
    skipped = 0

    if not OLD_UPLOADS_DIR.exists():
        return copied, skipped

    for source_path in OLD_UPLOADS_DIR.iterdir():
        if not source_path.is_file():
            continue

        destination_path = NEW_UPLOADS_DIR / source_path.name
        if destination_path.exists():
            skipped += 1
            continue

        shutil.copy2(source_path, destination_path)
        copied += 1

    return copied, skipped


def update_sqlite_sequence(connection: sqlite3.Connection, table_name: str) -> None:
    sequence_table_exists = connection.execute(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'sqlite_sequence'"
    ).fetchone()

    if not sequence_table_exists:
        return

    max_id = connection.execute(
        f"SELECT COALESCE(MAX(id), 0) FROM {table_name}"
    ).fetchone()[0]
    connection.execute(
        "INSERT OR REPLACE INTO sqlite_sequence(name, seq) VALUES (?, ?)",
        (table_name, max_id),
    )


def migrate_database() -> dict[str, int]:
    if not OLD_DB_PATH.exists():
        raise FileNotFoundError(f"Old database not found: {OLD_DB_PATH}")

    backup_path = NEW_DB_PATH.with_suffix(".db.pre-migrate.bak")
    shutil.copy2(NEW_DB_PATH, backup_path)

    old_connection = sqlite3.connect(OLD_DB_PATH)
    old_connection.row_factory = sqlite3.Row
    new_connection = sqlite3.connect(NEW_DB_PATH)

    try:
        new_connection.execute("PRAGMA foreign_keys = OFF")
        new_connection.execute("DELETE FROM products")
        new_connection.execute("DELETE FROM shops")
        new_connection.execute("DELETE FROM expenses")

        shop_rows = old_connection.execute(
            """
            SELECT
                id, name, photo, location, latitude, longitude, description,
                storefront_items, storefront_images, storefront_image,
                business_card_image, seller_wechat, seller_wechat_link, created_at
            FROM shops
            ORDER BY id
            """
        ).fetchall()

        for row in shop_rows:
            new_connection.execute(
                """
                INSERT INTO shops (
                    id, name, photo, location, latitude, longitude, description,
                    storefront_items, storefront_images, storefront_image,
                    business_card_image, seller_wechat, seller_wechat_link, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    row["id"],
                    row["name"] or "",
                    row["photo"] or "",
                    row["location"] or "",
                    row["latitude"],
                    row["longitude"],
                    row["description"] or "",
                    json.dumps(load_json(row["storefront_items"], []), ensure_ascii=False),
                    json.dumps(load_json(row["storefront_images"], []), ensure_ascii=False),
                    row["storefront_image"] or "",
                    row["business_card_image"] or "",
                    row["seller_wechat"] or "",
                    row["seller_wechat_link"] or "",
                    row["created_at"],
                ),
            )

        product_rows = old_connection.execute(
            """
            SELECT
                id, shop_id, images, article, amount, quantity, color, material,
                size, measurements, status, is_favorite, created_at
            FROM products
            ORDER BY id
            """
        ).fetchall()

        for row in product_rows:
            share_percent, share_amount, unit_price_with_share = calculate_product_pricing(
                row["amount"] or "",
                row["quantity"] or 1,
            )
            new_connection.execute(
                """
                INSERT INTO products (
                    id, shop_id, images, article, amount, quantity,
                    supplier_share_percent, supplier_share_amount, unit_price_with_share,
                    color, material, size, measurements, status, is_favorite, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    row["id"],
                    row["shop_id"],
                    json.dumps(load_json(row["images"], []), ensure_ascii=False),
                    row["article"] or "",
                    row["amount"] or "",
                    max(1, int(row["quantity"] or 1)),
                    share_percent,
                    share_amount,
                    unit_price_with_share,
                    row["color"] or "",
                    row["material"] or "",
                    row["size"] or "",
                    row["measurements"] or "",
                    row["status"] or "new",
                    int(bool(row["is_favorite"])),
                    row["created_at"],
                ),
            )

        expense_rows = old_connection.execute(
            """
            SELECT id, title, amount, note, created_at
            FROM expenses
            ORDER BY id
            """
        ).fetchall()

        for row in expense_rows:
            new_connection.execute(
                """
                INSERT INTO expenses (id, title, amount, note, created_at)
                VALUES (?, ?, ?, ?, ?)
                """,
                (
                    row["id"],
                    row["title"] or "",
                    row["amount"] or "",
                    row["note"] or "",
                    row["created_at"],
                ),
            )

        profile_row = old_connection.execute(
            "SELECT name FROM profiles WHERE id = 1"
        ).fetchone()
        if profile_row and profile_row["name"]:
            new_connection.execute(
                "UPDATE profiles SET name = ? WHERE id = 1",
                (profile_row["name"],),
            )

        for table_name in ("shops", "products", "expenses"):
            update_sqlite_sequence(new_connection, table_name)

        new_connection.commit()
    finally:
        old_connection.close()
        new_connection.close()

    return {
        "shops": len(shop_rows),
        "products": len(product_rows),
        "expenses": len(expense_rows),
    }


def main() -> None:
    copied, skipped = copy_uploads()
    counts = migrate_database()

    print("Migration complete.")
    print(f"  uploads copied: {copied}")
    print(f"  uploads skipped (already existed): {skipped}")
    print(f"  shops: {counts['shops']}")
    print(f"  products: {counts['products']}")
    print(f"  expenses: {counts['expenses']}")
    print(f"  database backup: {NEW_DB_PATH.with_suffix('.db.pre-migrate.bak')}")


if __name__ == "__main__":
    main()
