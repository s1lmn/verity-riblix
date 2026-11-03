"""Run tests against actual server module text, without a duplicate implementation."""
from pathlib import Path
import argparse,subprocess
root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--luau',required=True);args=p.parse_args()
source=(root/'src/world/VerityCompanionService.luau').read_text()
runner=root/'builds/generated/CompanionServiceRunner.luau';runner.parent.mkdir(parents=True,exist_ok=True)
runner.write_text('local function loadService(game,Instance,task,require)\n'+source+'\nend\nrequire("../../tests/CompanionServiceTests")(loadService)\n')
subprocess.run([str(Path(args.luau).resolve()),str(runner)],cwd=root,check=True)
