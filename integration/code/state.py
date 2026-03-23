"""
state.py - Shared in-memory data structures for the StreetRace Manager.
All modules read/write from these global stores.
"""

# Crew registry: {name: {"roles": set(), "skills": {role: int}}}
crew = {}

# Inventory
cars = {}          # {car_name: {"speed": int, "condition": "ok"|"damaged", "slots": {slot: part_name|None}}}
spare_parts = {}   # {part_name: count}
tools = {}         # {tool_name: count}
cash = 0.0

# Races: {race_id: {"name": str, "status": "open"|"started"|"finished", "entries": [(driver, car)], "results": []}}
races = {}

# Missions: {mission_id: {"type": str, "status": "pending"|"active"|"completed", "required_roles": [str], "assigned_crew": [str]}}
missions = {}

# Rankings: {driver_name: {"wins": int, "races": int, "earnings": float}}
rankings = {}

# Car slot types available
CAR_SLOTS = ["engine", "tires", "nos", "suspension"]


def reset():
    """Reset all state. Useful for testing."""
    global crew, cars, spare_parts, tools, cash, races, missions, rankings
    crew = {}
    cars = {}
    spare_parts = {}
    tools = {}
    cash = 0.0
    races = {}
    missions = {}
    rankings = {}
