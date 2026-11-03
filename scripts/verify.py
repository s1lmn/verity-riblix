"""Compile, test, simulate and build Core without launching Studio or publishing."""
from pathlib import Path
import argparse
import subprocess
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def run(*args):
    subprocess.run(list(map(str, args)), cwd=ROOT, check=True)


def check_build(path):
    tree = ET.parse(path)
    actual = {}
    for item in tree.iter("Item"):
        if item.attrib.get("class") not in ("ModuleScript", "Script", "LocalScript"):
            continue
        props = item.find("Properties")
        name = props.find("string[@name='Name']").text
        source = props.find("*[@name='Source']").text or ""
        assert name not in actual, f"Duplicate script name in build: {name}"
        actual[name] = source.replace("\r\n", "\n")
    expected = {}
    for source in (ROOT / "src").rglob("*.luau"):
        if source.name in {"MapBootstrap.server.luau", "CompanionBootstrap.server.luau",
                           "VerityCompanion.client.luau", "VerityLevelPreview.client.luau"}:
            continue  # Standalone preview scripts are mapped only in companion-preview.project.json.
        name = source.stem.removesuffix(".server").removesuffix(".client")
        expected[name] = source.read_text(encoding="utf-8").replace("\r\n", "\n")
    assert expected == actual, "Built scripts differ from source or unexpected scripts present"
    print(f"PASS Rojo roundtrip: {len(expected)} exact script sources")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau", required=True)
    parser.add_argument("--compiler", required=True)
    parser.add_argument("--rojo", required=True)
    args = parser.parse_args()
    files = [p.relative_to(ROOT).as_posix() for base in ("src", "tests", "scripts")
             for p in sorted((ROOT / base).rglob("*.luau"))]
    run(args.compiler, "--null", *files)
    run(sys.executable, "scripts/run_tests.py", "--luau", args.luau)
    run(sys.executable, "scripts/simulate_balance.py")
    (ROOT / "build").mkdir(exist_ok=True)
    run(args.rojo, "build", "default.project.json", "-o", "build/VERITY-Final.rbxlx")
    check_build(ROOT / "build/VERITY-Final.rbxlx")


if __name__ == "__main__":
    main()
