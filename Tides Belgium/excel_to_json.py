#!/usr/bin/env python3
"""
Excel to JSON Converter for Tides Belgium App

This script converts the Excel tide data files to JSON format
that can be easily parsed by the iOS app.

Usage:
    python3 excel_to_json.py

Requirements:
    pip install pandas openpyxl
"""

import pandas as pd
import json
import os
from datetime import datetime
import sys

def convert_excel_to_json(excel_file_path, output_json_path):
    """Convert Excel file to JSON format"""
    try:
        # Read Excel file
        df = pd.read_excel(excel_file_path)
        
        # Print column names to understand structure
        print(f"Columns in {excel_file_path}: {df.columns.tolist()}")
        
        # Expected column patterns (adjust based on actual Excel structure)
        date_columns = [col for col in df.columns if 'datum' in col.lower() or 'date' in col.lower()]
        time_columns = [col for col in df.columns if 'tijd' in col.lower() or 'time' in col.lower()]
        height_columns = [col for col in df.columns if 'hoogte' in col.lower() or 'height' in col.lower() or 'taw' in col.lower()]
        
        print(f"Date columns: {date_columns}")
        print(f"Time columns: {time_columns}")  
        print(f"Height columns: {height_columns}")
        
        # Convert to JSON-friendly format
        tide_data = []
        
        for index, row in df.iterrows():
            # Skip header rows or empty rows
            if pd.isna(row.iloc[0]) or str(row.iloc[0]).lower() in ['datum', 'date']:
                continue
                
            try:
                # Extract date, time, and height (adjust column indices based on actual Excel structure)
                date_val = row.iloc[0] if len(df.columns) > 0 else None
                time_val = row.iloc[1] if len(df.columns) > 1 else None
                height_val = row.iloc[2] if len(df.columns) > 2 else None
                
                # Convert to proper formats
                if pd.notna(date_val) and pd.notna(time_val) and pd.notna(height_val):
                    # Handle different date formats
                    if isinstance(date_val, datetime):
                        date_str = date_val.strftime("%Y-%m-%d")
                    else:
                        date_str = str(date_val)
                    
                    # Handle time format
                    if isinstance(time_val, str):
                        time_str = time_val
                    else:
                        time_str = str(time_val)
                    
                    # Handle height
                    try:
                        height = float(str(height_val).replace(',', '.').replace('m', ''))
                        
                        # Determine tide type based on height
                        tide_type = "high" if height > 2.0 else "low"
                        
                        tide_entry = {
                            "date": date_str,
                            "time": time_str,
                            "height": height,
                            "type": tide_type
                        }
                        
                        tide_data.append(tide_entry)
                        
                    except (ValueError, TypeError):
                        continue
                        
            except Exception as e:
                print(f"Error processing row {index}: {e}")
                continue
        
        # Save as JSON
        with open(output_json_path, 'w', encoding='utf-8') as f:
            json.dump(tide_data, f, indent=2, ensure_ascii=False)
        
        print(f"Converted {len(tide_data)} tide entries to {output_json_path}")
        return True
        
    except Exception as e:
        print(f"Error converting {excel_file_path}: {e}")
        return False

def main():
    """Main conversion process"""
    # Define Excel files and their corresponding stations
    excel_files = {
        "xlsx-getijtabellen-taw-2025/Antwerpen2025_mTAW.xlsx": "antwerpen_2025.json",
        "xlsx-getijtabellen-taw-2025/Blankenberge2025_mTAW.xlsx": "blankenberge_2025.json",
        "xlsx-getijtabellen-taw-2025/Nieuwpoort2025_mTAW.xlsx": "nieuwpoort_2025.json",
        "xlsx-getijtabellen-taw-2025/Oostende2025_mTAW.xlsx": "oostende_2025.json",
        "xlsx-getijtabellen-taw-2025/Zeebrugge2025_mTAW.xlsx": "zeebrugge_2025.json",
        
        "xlsx-getijtabellen-taw-2026/Antwerpen_2026_mTAW.xlsx": "antwerpen_2026.json",
        "xlsx-getijtabellen-taw-2026/Blankenberge_2026_mTAW.xlsx": "blankenberge_2026.json",
        "xlsx-getijtabellen-taw-2026/Nieuwpoort_2026_mTAW.xlsx": "nieuwpoort_2026.json",
        "xlsx-getijtabellen-taw-2026/Oostende_2026_mTAW.xlsx": "oostende_2026.json",
        "xlsx-getijtabellen-taw-2026/Zeebrugge_2026_mTAW.xlsx": "zeebrugge_2026.json"
    }
    
    # Create output directory
    output_dir = "json-tide-data"
    os.makedirs(output_dir, exist_ok=True)
    
    success_count = 0
    for excel_file, json_file in excel_files.items():
        if os.path.exists(excel_file):
            output_path = os.path.join(output_dir, json_file)
            if convert_excel_to_json(excel_file, output_path):
                success_count += 1
        else:
            print(f"Excel file not found: {excel_file}")
    
    print(f"\nConversion complete! Successfully converted {success_count}/{len(excel_files)} files.")
    print(f"JSON files saved in: {output_dir}/")
    print("\nNext steps:")
    print("1. Copy the JSON files to your Xcode project")
    print("2. Update ExcelTideParser.swift to read JSON instead of Excel")
    print("3. Make sure to add the JSON files to the Xcode target")

if __name__ == "__main__":
    # Check if required libraries are installed
    try:
        import pandas
        import openpyxl
    except ImportError:
        print("Error: Required libraries not found.")
        print("Please install them with: pip install pandas openpyxl")
        sys.exit(1)
    
    main()
