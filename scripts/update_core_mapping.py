"""Refresh Core file mappings while preserving World/UI nodes in each Rojo project."""
from pathlib import Path
import json

root = Path(__file__).resolve().parents[1]
core = {"$className": "Folder"}
for source in sorted((root / "src/server").glob("*.luau")):
    if source.name == "MapBootstrap.server.luau":
        continue
    name = source.name.removesuffix(".server.luau").removesuffix(".luau")
    core[name] = {"$path": source.relative_to(root).as_posix()}
for name in ("default.project.json", "smoke.project.json"):
    path = root / name
    data = json.loads(path.read_text(encoding="utf-8"))
    data["tree"]["ServerScriptService"]["Core"] = core
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8", newline="\n")
    print("Updated", name, "Core scripts:", len(core) - 1)
