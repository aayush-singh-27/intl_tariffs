import pandas as pd
import numpy as np
import os

DATA_DIR = "../data"
MITCHELL_DIR = os.path.join(DATA_DIR, "mitchell")
OUTPUT_PATH = os.path.join(DATA_DIR, "panel.csv")

COUNTRIES = {
    "GBR": {"csv": "uk.csv", "tamar_sheet": "GBR", "has_ip": True},
    "FRA": {"csv": "france.csv", "tamar_sheet": "FRA", "has_ip": True},
    "DEU": {"csv": "germany.csv", "tamar_sheet": "DEU", "has_ip": True},
    "ITA": {"csv": "italy.csv", "tamar_sheet": "ITA", "has_ip": True},
    "NLD": {"csv": "netherlands.csv", "tamar_sheet": "NLD", "has_ip": True},
    "JPN": {"csv": "japan.csv", "tamar_sheet": "JPN", "has_ip": False},
    "BEL": {"csv": "belgium.csv", "tamar_sheet": "BEL", "has_ip": True},
    "PRT": {"csv": "portugal.csv", "tamar_sheet": "PRT", "has_ip": True},
    "CHE": {"csv": "switzerland.csv", "tamar_sheet": "CHE", "has_ip": True},
    "ESP": {"csv": "spain.csv", "tamar_sheet": "ESP", "has_ip": True},
    "ARG": {"csv": "argentina.csv", "tamar_sheet": None, "has_ip": False},
    "BRA": {"csv": "brazil.csv", "tamar_sheet": "BRA", "has_ip": False},
    "MEX": {"csv": "mexico.csv", "tamar_sheet": "MEX", "has_ip": False},
}

TARGET_ISO3 = list(COUNTRIES.keys())

IP_COUNTRY_MAP = {
    "United Kingdom": "GBR",
    "France": "FRA",
    "Germany": "DEU",
    "Italy": "ITA",
    "Netherlands": "NLD",
    "Belgium": "BEL",
    "Portugal": "PRT",
    "Switzerland": "CHE",
    "Spain": "ESP",
}


def unit_multiplier_to_millions(unit_str):
    """Return multiplier to convert a given unit to millions of local currency."""
    if pd.isna(unit_str):
        return np.nan
    u = unit_str.lower().strip()
    if "million million" in u or "trillion" in u:
        return 1_000_000.0
    elif "thousand million" in u or "billion" in u:
        return 1_000.0
    elif "million" in u:
        return 1.0
    elif "thousand" in u:
        return 0.001
    else:
        return 1.0


def extract_currency_name(unit_str):
    """Extract base currency name, stripping scale prefixes."""
    if pd.isna(unit_str):
        return None
    u = unit_str.lower().strip()
    for prefix in ["million million ", "thousand million ", "trillion ",
                   "billion ", "million ", "thousand "]:
        if u.startswith(prefix):
            u = u[len(prefix):]
            break
    return u


def units_compatible(trade_unit, revenue_unit):
    """Check if trade and revenue units refer to the same currency denomination."""
    t = extract_currency_name(trade_unit)
    r = extract_currency_name(revenue_unit)
    if t is None or r is None:
        return False
    return t == r


def load_mitchell(iso3, info):
    print(f"  Loading Mitchell: {info['csv']}")
    path = os.path.join(MITCHELL_DIR, info["csv"])
    df = pd.read_csv(path)

    df["trade_mult"] = df["trade_unit"].apply(unit_multiplier_to_millions)
    df["rev_mult"] = df["revenue_unit"].apply(unit_multiplier_to_millions)

    df["imports_harmonized"] = df["imports"] * df["trade_mult"]
    df["exports_harmonized"] = df["exports"] * df["trade_mult"]
    df["customs_revenue_harmonized"] = df["customs_revenue"] * df["rev_mult"]

    # Mark rows where trade and revenue units refer to different currencies
    # (e.g., "new francs" vs "francs", or local currency vs USD)
    df["units_ok"] = df.apply(
        lambda row: units_compatible(row["trade_unit"], row["revenue_unit"]), axis=1
    )
    df.loc[~df["units_ok"], "customs_revenue_harmonized"] = np.nan

    # For countries where trade switches to USD (ARG, BRA), also mark as incompatible
    if iso3 in ("ARG", "BRA"):
        usd_mask = df["trade_unit"].str.contains("US dollar", case=False, na=False)
        df.loc[usd_mask, "customs_revenue_harmonized"] = np.nan

    # Compute Mitchell tariff rate
    df["tau_mitchell"] = np.where(
        (df["imports_harmonized"] > 0) & df["customs_revenue_harmonized"].notna(),
        100.0 * df["customs_revenue_harmonized"] / df["imports_harmonized"],
        np.nan,
    )

    result = df[["year", "unemployment_rate_pct", "imports_harmonized",
                 "exports_harmonized", "customs_revenue_harmonized", "tau_mitchell"]].copy()
    result.columns = ["year", "unemployment_rate_pct", "imports", "exports",
                      "customs_revenue", "tau_mitchell"]
    result["iso3"] = iso3
    return result


def load_tamar():
    print("Loading Tamar tariff rates...")
    tamar_path = os.path.join(DATA_DIR, "foreign_tariff_rates_final.xlsx")
    frames = []
    for iso3, info in COUNTRIES.items():
        sheet = info["tamar_sheet"]
        if sheet is None:
            continue
        col_name = f"tau_{iso3.lower()}_own"
        df = pd.read_excel(tamar_path, sheet_name=sheet, header=1)
        if col_name in df.columns:
            sub = df[["year", col_name]].dropna(subset=["year"]).copy()
            sub["year"] = sub["year"].astype(int)
            sub = sub.rename(columns={col_name: "tau_tamar"})
            sub["iso3"] = iso3
            frames.append(sub[["iso3", "year", "tau_tamar"]])
        else:
            print(f"    Warning: column {col_name} not found in sheet {sheet}")
    return pd.concat(frames, ignore_index=True)


def load_gmd():
    gmd_path = os.path.join(DATA_DIR, "GMD.xlsx")

    print("Loading GMD deflator sheet...")
    deflator = pd.read_excel(gmd_path, sheet_name="deflator", engine="openpyxl")
    deflator = deflator[deflator["ISO3"].isin(TARGET_ISO3)].copy()
    deflator["year"] = deflator["year"].astype(int)
    deflator = deflator[["ISO3", "year", "deflator", "rGDP"]].rename(
        columns={"ISO3": "iso3", "deflator": "gdp_deflator", "rGDP": "rgdp"}
    )

    print("Loading GMD unemployment sheet...")
    unemp = pd.read_excel(gmd_path, sheet_name="unemp", engine="openpyxl")
    unemp = unemp[unemp["ISO3"].isin(TARGET_ISO3)].copy()
    unemp["year"] = unemp["year"].astype(int)
    unemp = unemp[["ISO3", "year", "unemp"]].rename(
        columns={"ISO3": "iso3", "unemp": "unemp_gmd"}
    )

    return deflator, unemp


def load_industrial_production():
    print("Loading industrial production data...")
    ip_path = os.path.join(MITCHELL_DIR, "industrial_production_index_europe.csv")
    df = pd.read_csv(ip_path)
    df["iso3"] = df["Country"].map(IP_COUNTRY_MAP)
    df = df.dropna(subset=["iso3"])
    df = df.rename(columns={"Year": "year", "Index_Value": "ind_prod", "Base": "ind_prod_base"})
    df = df.sort_values(["iso3", "year", "ind_prod_base"])
    df = df.drop_duplicates(subset=["iso3", "year"], keep="last")
    return df[["iso3", "year", "ind_prod", "ind_prod_base"]]


def main():
    print("=" * 60)
    print("Building international panel dataset")
    print("=" * 60)

    # Load Mitchell data for all countries
    print("\n--- Mitchell data ---")
    mitchell_frames = []
    for iso3, info in COUNTRIES.items():
        mitchell_frames.append(load_mitchell(iso3, info))
    mitchell = pd.concat(mitchell_frames, ignore_index=True)

    # Load Tamar tariff rates
    print("\n--- Tamar tariff rates ---")
    tamar = load_tamar()

    # Load GMD
    print("\n--- GMD data ---")
    gmd_deflator, gmd_unemp = load_gmd()

    # Load industrial production
    print("\n--- Industrial production ---")
    ip = load_industrial_production()

    # Merge everything
    print("\n--- Merging ---")
    panel = mitchell.copy()

    # Merge Tamar tariff
    panel = panel.merge(tamar, on=["iso3", "year"], how="left")

    # Merge GMD deflator and rGDP
    panel = panel.merge(gmd_deflator, on=["iso3", "year"], how="left")

    # Merge GMD unemployment (for filling)
    panel = panel.merge(gmd_unemp, on=["iso3", "year"], how="left")

    # Fill Mitchell unemployment with GMD where missing
    panel["unemployment_rate_pct"] = panel["unemployment_rate_pct"].fillna(panel["unemp_gmd"])
    panel = panel.drop(columns=["unemp_gmd"])

    # Merge industrial production
    panel = panel.merge(ip, on=["iso3", "year"], how="left")

    # Select and order final columns
    panel = panel[["iso3", "year", "tau_tamar", "tau_mitchell", "rgdp", "gdp_deflator",
                   "unemployment_rate_pct", "imports", "exports", "customs_revenue",
                   "ind_prod", "ind_prod_base"]]

    panel = panel.sort_values(["iso3", "year"]).reset_index(drop=True)

    # Save
    panel.to_csv(OUTPUT_PATH, index=False)
    print(f"\nPanel saved to: {OUTPUT_PATH}")

    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"Countries: {sorted(panel['iso3'].unique().tolist())}")
    print(f"Total observations: {len(panel)}")
    for iso3 in sorted(panel["iso3"].unique()):
        sub = panel[panel["iso3"] == iso3]
        yr_min, yr_max = sub["year"].min(), sub["year"].max()
        print(f"  {iso3}: {yr_min}-{yr_max} ({len(sub)} obs)")

    print("\nNon-missing counts per variable:")
    for col in ["tau_tamar", "tau_mitchell", "rgdp", "gdp_deflator",
                "unemployment_rate_pct", "imports", "exports", "customs_revenue",
                "ind_prod"]:
        n = panel[col].notna().sum()
        print(f"  {col}: {n}")


if __name__ == "__main__":
    main()

panel = pd.read_csv(r'../data/panel.csv')
