#!/usr/bin/env python3
"""
excel_to_json.py

Convert Belgian tide Excel files (one sheet per station/year) to JSON files consumable by the app.

Input: Excel file like 'Oostende2025_mTAW.xlsx' that contains a table with columns Date, Time, Height, Type (or similar).
Output: JSON array with entries: { "date": "YYYY-MM-DD", "time": "HH:MM", "height": Float, "type": "high|low" }

Usage (optional):
  python3 excel_to_json.py path/to/Oostende2025_mTAW.xlsx --station oostende --year 2025 --out ./GeneratedJSON

Notes:
- This script is provided as a helper; run it on your Mac, then copy the generated JSON into the app's Documents folder on Simulator or Device.
- If column names differ, adjust COLUMN_MAP.
"""

import argparse
import json
import os
import re
from datetime import datetime

try:
    import pandas as pd
except Exception as e:
    raise SystemExit("pandas is required: pip install pandas openpyxl")

COLUMN_MAP = {
    # Possible variants -> normalized key
    "date": ["date", "datum", "day", "dag"],
    "time": ["time", "uur", "tijd", "tijdstip"],
    "height": ["height", "mTAW", "m taw", "hoogte", "waterstand"],
    "type": ["type", "tide", "soort", "hoog/laag", "opmerking"],
}

# Simple classifier if the file doesn't contain a type column
# If a 'Type' is present with values like 'HW', 'LW', 'High', 'Low', we will map those.
TYPE_MAP = {
    "hw": "high",
    "lw": "low",
    "high": "high",
    "low": "low",
    "hoog": "high",
    "laag": "low",
}

TIME_RE = re.compile(r"^(\d{1,2}):(\d{2})$")
DATE_FORMATS = ["%Y-%m-%d", "%d/%m/%Y", "%d-%m-%Y", "%m/%d/%Y", "%d.%m.%Y"]


def normalize_columns(cols):
    norm = {}
    for c in cols:
        lc = str(c).strip().lower()
        for key, variants in COLUMN_MAP.items():
            if any(lc == v for v in variants):
                norm[key] = c
                break
    return norm


def parse_date(value):
    if isinstance(value, (int, float)):
        # Excel serial date; let pandas handle if present
        try:
            return pd.to_datetime(value, unit="D", origin="1899-12-30").date()
        except Exception:
            pass
    if isinstance(value, datetime):
        return value.date()
    s = str(value).strip()
    for fmt in DATE_FORMATS:
        try:
            return datetime.strptime(s, fmt).date()
        except Exception:
            continue
    # Fallback: let pandas try
    try:
        return pd.to_datetime(s).date()
    except Exception:
        return None


def parse_time(value):
    if isinstance(value, datetime):
        return value.strftime("%H:%M")
    s = str(value).strip()
    m = TIME_RE.match(s)
    if m:
        h, mm = m.groups()
        return f"{int(h):02d}:{int(mm):02d}"
    # Try pandas
    try:
        t = pd.to_datetime(s)
        return t.strftime("%H:%M")
    except Exception:
        return None


def map_type(value, height=None):
    if value is None or (isinstance(value, float) and pd.isna(value)):
        # Infer from relative height if needed
        if height is not None:
            try:
                h = float(height)
                return "high" if h >= 2.0 else "low"
            except Exception:
                return "low"
        return "low"
    s = str(value).strip().lower()
    s = s.replace(" ", "")
    return TYPE_MAP.get(s, "high" if (height and float(height) >= 2.0) else "low")


def excel_to_json(xlsx_path, station, year, out_dir):
    df = pd.read_excel(xlsx_path)
    cols = normalize_columns(df.columns)

    if not {"date", "time", "height"}.issubset(cols.keys()):
        raise SystemExit(
            f"Couldn't find required columns in {xlsx_path}. Found mapping: {cols}. Please adjust COLUMN_MAP."
        )

    date_col = cols["date"]
    time_col = cols["time"]
    height_col = cols["height"]
    type_col = cols.get("type")

    records = []
    for _, row in df.iterrows():
        d = parse_date(row[date_col])
        t = parse_time(row[time_col])
        if not d or not t:
            continue
        try:
            h = float(str(row[height_col]).replace(",", "."))
        except Exception:
            continue
        ty = map_type(row[type_col] if type_col in df.columns else None, height=h)
        records.append({
            "date": d.strftime("%Y-%m-%d"),
            "time": t,
            "height": round(h, 2),
            "type": ty,
        })

    os.makedirs(out_dir, exist_ok=True)
    out_name = f"{station}_{year}.json"
    out_path = os.path.join(out_dir, out_name)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(records, f, ensure_ascii=False, indent=2)
    return out_path


def main():
    p = argparse.ArgumentParser()
    p.add_argument("xlsx", help="Path to Excel file, e.g., Oostende2025_mTAW.xlsx")
    p.add_argument("--station", required=True, help="Station id: antwerpen|blankenberge|nieuwpoort|oostende|zeebrugge")
    p.add_argument("--year", type=int, required=True, help="Year, e.g., 2025")
    p.add_argument("--out", default="./GeneratedJSON", help="Output directory for JSON")
    args = p.parse_args()

    out = excel_to_json(args.xlsx, args.station, args.year, args.out)
    print(out)


if __name__ == "__main__":
    main()
