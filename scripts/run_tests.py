"""Run actual Luau modules under the standalone Luau VM with injected Roblox boundaries."""
from pathlib import Path
import argparse
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau", required=True)
    args = parser.parse_args()
    sources = sorted((ROOT / "src").rglob("*.luau"))
    tests = sorted((ROOT / "tests").glob("*Tests.luau"))
    build = ROOT / "build"
    build.mkdir(exist_ok=True)
    chunks = ["local factories, cache = {}, {}\n"]
    for path in sources + sorted((ROOT / "tests").glob("*.luau")):
        if path.name.endswith(".server.luau"):
            continue
        key = path.relative_to(ROOT).as_posix().removesuffix(".luau")
        chunks.append(f'factories["{key}"] = function(require, script, game, warn)\n{path.read_text(encoding="utf-8")}\nend\n')
    chunks.append(r'''
local function node(path)
    return setmetatable({Path = path}, {__index = function(self, key)
        if key == "Parent" then return node(string.match(self.Path, "^(.*)/[^/]+$")) end
        if key == "WaitForChild" then return function(_, name) return node(self.Path .. "/" .. name) end end
        return node(self.Path .. "/" .. key)
    end})
end
local fakeGame = {}
function fakeGame:GetService(name)
    assert(name == "ReplicatedStorage", "Unexpected engine dependency: " .. name)
    return setmetatable({}, {__index = function(_, key)
        if key == "WaitForChild" then return function(_, child) assert(child == "Shared"); return node("src/shared") end end
        if key == "Shared" then return node("src/shared") end
        error("Unexpected ReplicatedStorage field " .. key)
    end})
end
local loadModule
loadModule = function(ref)
    local key = if type(ref) == "string" then ref else ref.Path
    if cache[key] ~= nil then return cache[key] end
    assert(factories[key], "Module not found: " .. key)
    cache[key] = factories[key](loadModule, node(key), fakeGame, function(...) print("WARN", ...) end)
    return cache[key]
end
local total = 0
local function check(condition, message)
    total += 1
    assert(condition, message or "Assertion failed")
end
''')
    for path in tests:
        key = path.relative_to(ROOT).as_posix().removesuffix(".luau")
        chunks.append(f'loadModule("{key}")(loadModule, check)\nprint("PASS {path.name}")\n')
    chunks.append('print("PASS " .. total .. " assertions")\n')
    bundle = build / "test_bundle.luau"
    bundle.write_text("\n".join(chunks), encoding="utf-8")
    return subprocess.run([args.luau, "build/test_bundle.luau"], cwd=ROOT).returncode


if __name__ == "__main__":
    sys.exit(main())
