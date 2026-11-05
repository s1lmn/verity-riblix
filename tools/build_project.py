"""Build the complete game or explicitly marked Studio animation preview.

Includes deterministic source fingerprint to distinguish old Studio places.
No source tree, static World artifacts or existing places are rewritten.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
from xml.etree import ElementTree as ET
from zipfile import ZIP_DEFLATED, ZipFile

ROOT = Path(__file__).resolve().parents[1]


def build(rojo, preview=False, candidate=False):
    if preview and candidate:
        raise ValueError("Release candidates must use the canonical project")
    version_source = (ROOT / "src/shared/ProjectVersion.luau").read_text(encoding="utf-8")
    expected_map = re.search(r'Map\s*=\s*"([^"]+)"', version_source).group(1)
    world_source = (ROOT / "src/world/WorldBuilder.luau").read_text(encoding="utf-8")
    assert f'local VERSION = "{expected_map}"' in world_source, "World/Shared version mismatch"
    digest = hashlib.sha256()
    digest.update(b"studio-preview-v1" if preview else b"complete-game-v1")
    inputs = [*ROOT.glob("src/**/*.luau"), ROOT / "default.project.json", Path(__file__).resolve(),
              ROOT / "assets/verity-ten-textured/Verity_FaceTemplates.rbxmx",
              ROOT / "assets/verity-elemental/all-levels/Verity_All_100_Models.rbxmx"]
    if preview:
        inputs.extend(ROOT.glob("tests/*.luau"))
    for path in sorted(inputs):
        digest.update(path.relative_to(ROOT).as_posix().encode())
        digest.update(path.read_bytes().replace(b"\r\n", b"\n"))
    revision = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, check=True,
                              capture_output=True, text=True).stdout.strip()
    dirty = bool(subprocess.run(["git", "status", "--porcelain"], cwd=ROOT, check=True,
                                capture_output=True, text=True).stdout.strip())
    if candidate and dirty:
        raise ValueError("Commit changes before packaging a release candidate")
    info = {"schema": 1, "map": expected_map, "fingerprint": digest.hexdigest(),
            "sourceCommit": revision, "dirty": dirty, "preview": preview}
    generated = ROOT / "builds/generated"
    generated.mkdir(parents=True, exist_ok=True)
    info_path = generated / ("PreviewBuildInfo.luau" if preview else "BuildInfo.luau")
    fields = ",".join(f"{key}={json.dumps(value)}" for key, value in info.items())
    info_path.write_text("return {" + fields + "}\n", encoding="utf-8")
    project = json.loads((ROOT / "default.project.json").read_text(encoding="utf-8"))
    project["name"] = "VerityAnimationsPreview" if preview else "VerityGrowingSimulator"
    tree = project["tree"]
    tree["ReplicatedStorage"]["BuildInfo"] = {"$path": str(info_path)}
    if preview:
        tree["ReplicatedStorage"]["AnimationEditHarness"] = {"$path": "tests/AnimationEditHarness.luau"}
        tree["ReplicatedStorage"]["AnimationPreviewHarness"] = {"$path": "tests/AnimationPreviewHarness.luau"}
        tree["ServerScriptService"]["AnimationPreview"] = {"$path": "tests/AnimationPreview.server.luau"}
        tree["StarterPlayer"]["StarterPlayerScripts"]["AnimationPreview"] = {"$path": "tests/AnimationPreview.client.luau"}

    def absolute_paths(node):
        if not isinstance(node, dict):
            return
        for key, value in node.items():
            if key == "$path":
                node[key] = str((ROOT / value).resolve())
            else:
                absolute_paths(value)
    absolute_paths(tree)
    config = generated / ("preview.project.json" if preview else "complete.project.json")
    config.write_text(json.dumps(project, ensure_ascii=False, indent=2), encoding="utf-8")
    output = ROOT / "builds" / ("VerityAnimations-preview.rbxlx" if preview else "VerityGrowingSimulator.rbxlx")
    subprocess.run([str(Path(rojo).resolve()), "build", str(config), "-o", str(output)], cwd=ROOT, check=True)
    root = ET.parse(output).getroot()
    names = [p.text for p in root.findall(".//Properties/string[@name='Name']")]
    assert ("AnimationPreview" in names) == preview
    assert "VerityVisualController" in names and "ProjectVersion" in names
    assert "InteriorTransitionController" not in names and "InteriorTemplates" not in names
    if not preview:
        script_names = [item.findtext("Properties/string[@name='Name']")
                        for item in root.iter("Item") if item.get("class") == "Script"]
        if script_names != ["ServerBootstrap"]:
            raise ValueError(f"Expected one canonical server script, found {script_names}")
    info["placeSha256"] = hashlib.sha256(output.read_bytes()).hexdigest()
    manifest = output.with_suffix(".version.json")
    manifest.write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")
    if candidate:
        package = ROOT / "builds" / "release-candidates" / f"VERITY-{revision[:7]}.zip"
        package.parent.mkdir(parents=True, exist_ok=True)
        with ZipFile(package, "w", compression=ZIP_DEFLATED) as archive:
            archive.write(output, "VERITY-Latest.rbxlx")
            archive.write(manifest, "VERITY-Latest.version.json")
            for name in ("RELEASE_READINESS.md", "STORE_LISTING.md"):
                archive.write(ROOT / "docs" / name, name)
        print(f"Release candidate packaged: {package.name}")
    print(f"Complete project build verified: {output.name} / {expected_map} / {info['fingerprint'][:12]}")
    return output


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--rojo", required=True)
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--candidate", action="store_true", help="Package a clean committed game build")
    args = parser.parse_args()
    build(args.rojo, args.preview, args.candidate)
