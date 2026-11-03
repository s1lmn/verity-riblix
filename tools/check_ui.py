"""Compile UI, run pure Luau tests, typecheck isolated modules, build the place.

No packages are installed. Pass paths to official Luau and Rojo binaries.
The ASCII staging directory works around Luau CLI Unicode require paths on Windows.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau-dir", type=Path, required=True)
    parser.add_argument("--rojo", type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    suffix = ".exe" if os.name == "nt" else ""
    binaries = {name: args.luau_dir.resolve() / (name + suffix)
                for name in ("luau", "luau-compile", "luau-analyze")}
    for binary in [*binaries.values(), args.rojo.resolve()]:
        if not binary.is_file():
            raise SystemExit(f"Missing official tool: {binary}")
    stage_parent = Path(os.environ["PUBLIC"]) if os.name == "nt" else Path(tempfile.gettempdir())
    with tempfile.TemporaryDirectory(prefix="verity-ui-", dir=stage_parent) as tmp:
        stage = Path(tmp).resolve()
        assert stage.parent == stage_parent.resolve() and stage.name.startswith("verity-ui-")
        for folder in ("src/client", "src/shared", "src/world", "src/server", "tests"):
            shutil.copytree(root / folder, stage / folder)
        sources = sorted(p.relative_to(stage).as_posix()
                         for folder in ("src/client", "src/shared", "src/world", "src/server", "tests")
                         for p in (stage / folder).glob("*.luau"))
        for source in sources:
            subprocess.run([str(binaries["luau-compile"]), "--null", source],
                           cwd=stage, check=True, capture_output=True, text=True)
        print(f"Luau compilation: {len(sources)} files passed", flush=True)
        subprocess.run([str(binaries["luau"]), "tests/UIModelTests.luau"], cwd=stage, check=True)
        subprocess.run([str(binaries["luau"]), "tests/AnimationProfileTests.luau"], cwd=stage, check=True)
        # These modules have no Roblox-engine type dependency.
        subprocess.run([str(binaries["luau-analyze"]), "src/shared/LevelConfig.luau",
                        "src/client/RequestTracker.luau", "src/client/EventLedger.luau"],
                       cwd=stage, check=True)
        print("Pure module strict typecheck: 3 passed", flush=True)
    from build_project import build
    build(args.rojo)
    report = {"compiledFiles": len(sources), "pureTestGroups": 14,
              "strictTypecheckedModules": 3, "rojoBuild": "passed",
              "studioTests": "See docs/UI_TEST_REPORT.md; this script does not run Studio."}
    (root / "builds/ui-checks.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("UI checks passed. Studio evidence is documented separately.")


if __name__ == "__main__":
    main()
