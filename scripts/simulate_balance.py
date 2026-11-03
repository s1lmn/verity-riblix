"""Deterministic economy simulation; prices/boost are calibrated, never claimed as playtests."""
from pathlib import Path
import argparse
import json
import math
import re

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "src/shared/EconomyConfig.luau"


def rounded(n):
    return math.floor(n + 0.5)


def simulate(costs, mode="active", multiplier=1.0, boost_seconds=14400):
    level, swipe, cash, seconds = 1, 0, 0.0, 0
    milestones, gaps, last_purchase, swipe_spend = {}, [], 0, 0
    passive = [rounded(5 * 1.16 ** i) for i in range(100)]
    swipe_income = [rounded(2 * 1.35 ** i) + i for i in range(41)]
    swipe_cost = [rounded(30 * 1.5 ** i) for i in range(40)]
    # A one-minute route includes explicit travel/interaction time with phone closed.
    # Active: 45 swipes + 3 tasks/min. Moderate: 10 swipes + 3 tasks/2 min.
    duty = {"passive": 0, "moderate": 10 / 120, "active": 45 / 60}[mode]
    while level < 100 and seconds < 7 * 86400:
        seconds += 1
        boost = multiplier if seconds <= boost_seconds else 1
        cash += passive[level - 1] * boost
        phase = seconds % (120 if mode == "moderate" else 60)
        if mode == "active" and phase < 45:
            cash += swipe_income[swipe] * boost  # 1/sec respects the 0.75s cooldown.
        elif mode == "moderate" and phase < 20 and phase % 2 == 0:
            cash += swipe_income[swipe] * boost
        if mode != "passive":
            route_start = 45 if mode == "active" else 90
            # Five seconds between points, including travel; platform hold >=1s.
            task_reward = {route_start + 1: 20, route_start + 6: 40, route_start + 11: 25}.get(phase, 0)
            cash += task_reward * boost
        # Explicit policy: buy Swipe Power when its incremental payback is <=30min;
        # only one purchase per simulated second; no hidden free upgrades.
        if duty and swipe < 40 and cash >= swipe_cost[swipe]:
            marginal_rate = (swipe_income[swipe + 1] - swipe_income[swipe]) * duty * boost
            if marginal_rate > 0 and swipe_cost[swipe] / marginal_rate <= 1800:
                cash -= swipe_cost[swipe]
                swipe_spend += swipe_cost[swipe]
                swipe += 1
        if cash >= costs[level - 1]:
            cash -= costs[level - 1]
            level += 1
            gaps.append(seconds - last_purchase)
            last_purchase = seconds
            if level in (10, 25, 50, 75, 100):
                milestones[str(level)] = seconds
    return {"mode": mode, "multiplier": multiplier, "boostSeconds": boost_seconds,
            "completed": level == 100, "seconds": seconds, "hours": round(seconds / 3600, 4),
            "milestonesSeconds": milestones, "maxPurchaseGapSeconds": max(gaps, default=0),
            "swipeUpgradeLevel": swipe, "swipeUpgradeSpend": swipe_spend}


def costs_for(factor):
    early = [50, 100, 180, 300, 500, 800, 1200, 1800, 2600]
    return early + [rounded(rounded(5 * 1.16 ** (level - 1)) * factor
                            * (0.35 + 0.65 * ((level - 9) / 90) ** 0.6))
                    for level in range(10, 100)]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--calibrate", action="store_true")
    args = parser.parse_args()
    content = CONFIG.read_text(encoding="utf-8")
    if args.calibrate:
        low, high = 300, 3000
        for _ in range(16):
            factor = (low + high) / 2
            if simulate(costs_for(factor))["seconds"] < 24 * 3600:
                low = factor
            else:
                high = factor
        costs = costs_for((low + high) / 2)
        low, high = 1, 20
        for _ in range(16):
            boost = (low + high) / 2
            if simulate(costs, multiplier=boost)["seconds"] > 3.75 * 3600:
                low = boost
            else:
                high = boost
        boost = round((low + high) / 2, 4)
        table = "\nEconomyConfig.LevelCost = table.freeze({\n"
        for offset in range(0, 99, 9):
            table += "\t" + ", ".join(map(str, costs[offset:offset + 9])) + ",\n"
        table += "})\n"
        content = re.sub(r"(?s)(-- BEGIN LEVEL COSTS).*?(-- END LEVEL COSTS)",
                         lambda match: match[1] + table + match[2], content)
        content = re.sub(r"Multiplier = [\d.]+", f"Multiplier = {boost}", content)
        CONFIG.write_text(content, encoding="utf-8")
    else:
        body = content.split("-- BEGIN LEVEL COSTS")[1].split("-- END LEVEL COSTS")[0]
        costs = [int(n) for n in re.findall(r"\b\d+\b", body)]
        boost = float(re.search(r"Multiplier = ([\d.]+)", content)[1])
    assert len(costs) == 99
    runs = [simulate(costs, mode) for mode in ("passive", "moderate", "active")]
    runs.append(simulate(costs, multiplier=boost))
    assert all(run["completed"] for run in runs)
    assert 20 <= runs[2]["hours"] <= 30
    assert 3.5 <= runs[3]["hours"] <= 4
    report = {"kind": "deterministic simulation; not observed player behaviour", "timeStepSeconds": 1,
              "boostRules": {"multiplier": boost, "durationSeconds": 14400, "stacking": "extend duration; multiplier does not stack"},
              "policy": "45 swipes/min + one 15s task route/min; Swipe Power ROI <=1800s; all upgrades paid", "runs": runs}
    output = ROOT / "docs/balance-simulation.json"
    output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    for run in runs:
        print(run)


if __name__ == "__main__":
    main()
