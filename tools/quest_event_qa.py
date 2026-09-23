#!/usr/bin/env python3
"""Honour War quest and world-event content contract."""
from pathlib import Path
import json, re, sys

ROOT=Path(__file__).resolve().parents[1]
data_path=ROOT/"data/honour_war_quests_events.json"
if not data_path.is_file():
    raise SystemExit("QUEST_EVENT_QA_FAIL: missing data/honour_war_quests_events.json")

data=json.loads(data_path.read_text(encoding="utf-8"))
quests=data.get("quests",[])
events=data.get("world_events",[])

if data.get("quest_count") != 12 or len(quests) != 12:
    raise SystemExit("QUEST_EVENT_QA_FAIL: expected exactly 12 quests")
if data.get("world_event_count") != 6 or len(events) != 6:
    raise SystemExit("QUEST_EVENT_QA_FAIL: expected exactly 6 world events")
if sorted(q.get("id") for q in quests) != list(range(1,13)):
    raise SystemExit("QUEST_EVENT_QA_FAIL: quest IDs must be 1..12")
if len({q.get("title") for q in quests}) != 12:
    raise SystemExit("QUEST_EVENT_QA_FAIL: quest titles must be unique")
if len({e.get("title") for e in events}) != 6:
    raise SystemExit("QUEST_EVENT_QA_FAIL: event titles must be unique")

species={"Any","Poring","Goblin","Wolf","Skeleton","Orc","Mantis","Golem","Dragon"}
for q in quests:
    if int(q.get("goal",0)) <= 0:
        raise SystemExit(f"QUEST_EVENT_QA_FAIL: invalid quest goal {q.get('id')}")
    if not 1 <= int(q.get("required_level",0)) <= 300:
        raise SystemExit(f"QUEST_EVENT_QA_FAIL: invalid quest level {q.get('id')}")
    if q.get("target") not in species:
        raise SystemExit(f"QUEST_EVENT_QA_FAIL: invalid quest target {q.get('id')}")

for e in events:
    if int(e.get("duration_seconds",0)) != 180:
        raise SystemExit(f"QUEST_EVENT_QA_FAIL: event duration must be 180 ({e.get('id')})")

quest_cpp=(ROOT/"Source/HonourWar/HonourWarQuestComponent.cpp").read_text(encoding="utf-8")
game_state=(ROOT/"Source/HonourWar/HonourWarGameState.cpp").read_text(encoding="utf-8")
game_state_h=(ROOT/"Source/HonourWar/HonourWarGameState.h").read_text(encoding="utf-8")
combat=(ROOT/"Source/HonourWar/HonourWarCombatComponent.cpp").read_text(encoding="utf-8")
character=(ROOT/"Source/HonourWar/HonourWarCharacter.cpp").read_text(encoding="utf-8")
hud=(ROOT/"Source/HonourWar/HonourWarHUDWidget.cpp").read_text(encoding="utf-8")

for q in quests:
    if q["title"] not in quest_cpp:
        raise SystemExit(f"QUEST_EVENT_QA_FAIL: quest missing from runtime {q['id']}")
for title in [e["title"] for e in events]:
    if title not in game_state:
        raise SystemExit(f"QUEST_EVENT_QA_FAIL: event missing from GameState {title}")

required_fragments = [
    (game_state_h,"GetEventSecondsRemaining"),
    (game_state_h,"GetWorldEventDamageMultiplier"),
    (game_state,"WorldEventDuration"),
    (game_state,"ActiveWorldEventId = (ActiveWorldEventId + 1)"),
    (combat,"GetWorldEventXpMultiplier"),
    (combat,"GetWorldEventZenyMultiplier"),
    (combat,"GetWorldEventHonourMultiplier"),
    (combat,"GetWorldEventSpRegenMultiplier"),
    (combat,"GetWorldEventDamageMultiplier"),
    (character,"RecordMonsterDefeat(MonsterLevel"),
    (character,"SetQuestState(Save->QuestId"),
    (hud,"BuildWorldEventPanel"),
    (hud,"BuildSkillBar"),
    (hud,"GetActiveWorldEventTitle"),
]
for source, frag in required_fragments:
    if frag not in source:
        raise SystemExit(f"QUEST_EVENT_QA_FAIL: missing runtime integration {frag}")

print("QUEST_EVENT_QA_PASS: 12 quests + 6 rotating world events are registered and integrated.")
