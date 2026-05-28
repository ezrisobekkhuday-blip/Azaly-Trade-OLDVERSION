"""Migrate shops, products, expenses, batches, and uploads from backend/OLD_DATA."""

from __future__ import annotations

import json
import re
import shutil
import sqlite3
from collections import defaultdict
from datetime import datetime
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent.parent
OLD_DATA_DIR = BACKEND_DIR / "OLD_DATA"
OLD_DB_PATH = OLD_DATA_DIR / "azaly_trade.db"
OLD_UPLOADS_DIR = OLD_DATA_DIR / "uploads"
NEW_DB_PATH = BACKEND_DIR / "azaly_trade.db"
NEW_UPLOADS_DIR = BACKEND_DIR / "uploads"

SUPPLIER_SHARE_PERCENT = 10.0
DEFAULT_USD_TO_CNY = 6.8
DEFAULT_USD_TO_UZS = 12200.0

ORDER_BATCH_NAMES = {
    "заказ товар",
    "заказ",
}


def parse_amount_value(raw_value: str) -> float | None:
    normalized = re.sub(r"[^0-9.,]", "", (raw_value or "").strip()).replace(",", ".")

    if not normalized:
        return None

    if not re.fullmatch(r"[0-9]+(?:\.[0-9]+)?", normalized):
        return None

    return float(normalized)


def normalize_expense_currency(value: str | None) -> str:
    normalized = (value or "CNY").strip().upper()
    if normalized in {"CNY", "USD", "UZS"}:
        return normalized
    return "CNY"


def calculate_expense_amounts(
    amount_raw: str,
    currency: str,
    usd_to_cny_rate: float,
    usd_to_uzs_rate: float,
) -> tuple[float, float, float]:
    amount_value = parse_amount_value(amount_raw) or 0.0
    safe_usd_to_cny = max(0.0, float(usd_to_cny_rate))
    safe_usd_to_uzs = max(0.0, float(usd_to_uzs_rate))
    normalized_currency = normalize_expense_currency(currency)

    if normalized_currency == "USD":
        amount_usd = amount_value
        amount_cny = amount_usd * safe_usd_to_cny
        amount_uzs = amount_usd * safe_usd_to_uzs
    elif normalized_currency == "UZS":
        amount_uzs = amount_value
        amount_usd = amount_uzs / safe_usd_to_uzs if safe_usd_to_uzs > 0 else 0.0
        amount_cny = amount_usd * safe_usd_to_cny
    else:
        amount_cny = amount_value
        amount_usd = amount_cny / safe_usd_to_cny if safe_usd_to_cny > 0 else 0.0
        amount_uzs = amount_usd * safe_usd_to_uzs

    return amount_cny, amount_usd, amount_uzs


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


def convert_cny_to_usd_uzs(
    amount_cny: float,
    usd_to_cny_rate: float,
    usd_to_uzs_rate: float,
) -> tuple[float, float]:
    safe_usd_to_cny = usd_to_cny_rate if usd_to_cny_rate > 0 else 0.0
    safe_usd_to_uzs = usd_to_uzs_rate if usd_to_uzs_rate > 0 else 0.0
    amount_usd = amount_cny / safe_usd_to_cny if safe_usd_to_cny > 0 else 0.0
    amount_uzs = amount_usd * safe_usd_to_uzs
    return amount_usd, amount_uzs


def load_json(value: object, fallback):
    if value in (None, ""):
        return fallback

    if isinstance(value, (list, dict)):
        return value

    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return fallback


def read_batch_name(arrival_summary_json: object) -> str:
    payload = load_json(arrival_summary_json, {})
    if not isinstance(payload, dict):
        return ""
    return str(payload.get("batch_name") or "").strip()


def is_order_batch(batch_name: str) -> bool:
    return batch_name.strip().casefold() in ORDER_BATCH_NAMES


def resolve_expense_amount(row: sqlite3.Row) -> str:
    input_amount = str(row["input_amount"] or "").strip()
    if input_amount:
        return input_amount
    return str(row["amount"] or "").strip()


def resolve_expense_currency(row: sqlite3.Row) -> str:
    return normalize_expense_currency(row["input_currency"])


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

    if NEW_DB_PATH.exists():
        backup_path = NEW_DB_PATH.with_suffix(".db.pre-migrate.bak")
        shutil.copy2(NEW_DB_PATH, backup_path)

    old_connection = sqlite3.connect(OLD_DB_PATH)
    old_connection.row_factory = sqlite3.Row
    new_connection = sqlite3.connect(NEW_DB_PATH)

    try:
        new_connection.execute("PRAGMA foreign_keys = OFF")
        new_connection.execute("DELETE FROM products")
        new_connection.execute("DELETE FROM batches")
        new_connection.execute("DELETE FROM expenses")
        new_connection.execute("DELETE FROM shops")

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
                size, measurements, status, is_favorite, created_at, arrival_summary_json
            FROM products
            ORDER BY id
            """
        ).fetchall()

        batch_created_at: dict[str, str] = {}
        batch_names: set[str] = set()

        for row in product_rows:
            batch_name = read_batch_name(row["arrival_summary_json"])
            if not batch_name:
                continue

            batch_names.add(batch_name)
            created_at = str(row["created_at"] or "")
            previous = batch_created_at.get(batch_name)
            if previous is None or created_at < previous:
                batch_created_at[batch_name] = created_at

        batch_id_by_name: dict[str, int] = {}
        for batch_name in sorted(batch_names, key=lambda value: batch_created_at.get(value, "")):
            cursor = new_connection.execute(
                """
                INSERT INTO batches (name, note, created_at)
                VALUES (?, ?, ?)
                """,
                (
                    batch_name,
                    "",
                    batch_created_at.get(batch_name)
                    or datetime.utcnow().isoformat(sep=" ", timespec="seconds"),
                ),
            )
            batch_id_by_name[batch_name] = int(cursor.lastrowid)

        products_in_batch = 0
        order_products = 0

        for row in product_rows:
            share_percent, share_amount, unit_price_with_share = calculate_product_pricing(
                row["amount"] or "",
                row["quantity"] or 1,
            )
            batch_name = read_batch_name(row["arrival_summary_json"])
            batch_id = batch_id_by_name.get(batch_name)
            batch_item_type = "order" if batch_name and is_order_batch(batch_name) else "regular"

            if batch_id is not None:
                products_in_batch += 1
                if batch_item_type == "order":
                    order_products += 1

            final_cny = unit_price_with_share
            final_usd, final_uzs = convert_cny_to_usd_uzs(
                final_cny,
                DEFAULT_USD_TO_CNY,
                DEFAULT_USD_TO_UZS,
            )

            new_connection.execute(
                """
                INSERT INTO products (
                    id, shop_id, batch_id, batch_item_type, images, article, amount, quantity,
                    supplier_share_percent, supplier_share_amount, unit_price_with_share,
                    allocated_expense_per_unit_cny, final_unit_cost_cny, final_unit_cost_usd,
                    final_unit_cost_uzs, usd_to_cny_rate, usd_to_uzs_rate,
                    color, material, size, measurements, status, is_favorite, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    row["id"],
                    row["shop_id"],
                    batch_id,
                    batch_item_type,
                    json.dumps(load_json(row["images"], []), ensure_ascii=False),
                    row["article"] or "",
                    row["amount"] or "",
                    max(1, int(row["quantity"] or 1)),
                    share_percent,
                    share_amount,
                    unit_price_with_share,
                    0.0,
                    final_cny,
                    final_usd,
                    final_uzs,
                    DEFAULT_USD_TO_CNY,
                    DEFAULT_USD_TO_UZS,
                    row["color"] or "",
                    row["material"] or "",
                    row["size"] or "",
                    row["measurements"] or "",
                    row["status"] or "new",
                    int(bool(row["is_favorite"])),
                    row["created_at"],
                ),
            )

        profile_row = old_connection.execute(
            "SELECT name FROM profiles WHERE id = 1"
        ).fetchone()
        profile_name = (
            profile_row["name"].strip()
            if profile_row and profile_row["name"]
            else "Azaly Trade"
        )
        new_connection.execute(
            """
            UPDATE profiles
            SET name = ?, usd_to_cny = ?, usd_to_uzs = ?
            WHERE id = 1
            """,
            (profile_name, DEFAULT_USD_TO_CNY, DEFAULT_USD_TO_UZS),
        )

        expense_rows = old_connection.execute(
            """
            SELECT
                id, title, amount, note, created_at,
                input_amount, input_currency
            FROM expenses
            ORDER BY id
            """
        ).fetchall()

        for row in expense_rows:
            expense_currency = resolve_expense_currency(row)
            expense_amount = resolve_expense_amount(row)
            amount_cny, amount_usd, amount_uzs = calculate_expense_amounts(
                expense_amount,
                expense_currency,
                DEFAULT_USD_TO_CNY,
                DEFAULT_USD_TO_UZS,
            )
            new_connection.execute(
                """
                INSERT INTO expenses (
                    id, title, accounting_type, accounting_channel, currency,
                    amount, amount_cny, amount_usd, amount_uzs,
                    usd_to_cny_rate, usd_to_uzs_rate, note, batch_id, created_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    row["id"],
                    row["title"] or "",
                    "not_selected",
                    "not_selected",
                    expense_currency,
                    expense_amount,
                    amount_cny,
                    amount_usd,
                    amount_uzs,
                    DEFAULT_USD_TO_CNY,
                    DEFAULT_USD_TO_UZS,
                    row["note"] or "",
                    None,
                    row["created_at"],
                ),
            )

        for table_name in ("shops", "products", "batches", "expenses"):
            update_sqlite_sequence(new_connection, table_name)

        new_connection.commit()
    finally:
        old_connection.close()
        new_connection.close()

    return {
        "shops": len(shop_rows),
        "products": len(product_rows),
        "products_in_batch": products_in_batch,
        "order_products": order_products,
        "batches": len(batch_names),
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
    print(f"  products in batches: {counts['products_in_batch']}")
    print(f"  order products: {counts['order_products']}")
    print(f"  batches: {counts['batches']}")
    print(f"  expenses: {counts['expenses']}")
    print(f"  default rates: 1 USD = {DEFAULT_USD_TO_CNY} CNY, 1 USD = {DEFAULT_USD_TO_UZS} UZS")
    if NEW_DB_PATH.exists():
        print(f"  database backup: {NEW_DB_PATH.with_suffix('.db.pre-migrate.bak')}")


if __name__ == "__main__":
    main()
