"""
race_management.py - Create races and enter drivers + cars.
"""
from . import state
from . import crew_management
from . import inventory


def create_race(race_id, name="Street Race"):
    """Create a new race with the given ID."""
    if race_id in state.races:
        raise ValueError(f"Race '{race_id}' already exists.")
    state.races[race_id] = {
        "name": name,
        "status": "open",
        "entries": [],
        "results": [],
    }
    return True


def enter_race(race_id, driver_name, car_name):
    """Enter a driver+car into a race. Validates driver role and car condition."""
    if race_id not in state.races:
        raise ValueError(f"Race '{race_id}' does not exist.")
    race = state.races[race_id]
    if race["status"] != "open":
        raise ValueError(f"Race '{race_id}' is not open for entries.")

    # Driver must be registered
    if driver_name not in state.crew:
        raise ValueError(f"'{driver_name}' is not a registered crew member.")

    # Driver must have 'driver' role
    if "driver" not in state.crew[driver_name]["roles"]:
        raise ValueError(f"'{driver_name}' does not have the 'driver' role.")

    # Car must exist
    car = inventory.get_car(car_name)
    if car is None:
        raise ValueError(f"Car '{car_name}' not found in inventory.")

    # Car must not be damaged
    if car["condition"] == "damaged":
        raise ValueError(f"Car '{car_name}' is damaged and cannot race.")

    # Check for duplicate entries
    for d, c in race["entries"]:
        if d == driver_name:
            raise ValueError(f"'{driver_name}' is already entered in this race.")
        if c == car_name:
            raise ValueError(f"Car '{car_name}' is already entered in this race.")

    race["entries"].append((driver_name, car_name))
    return True


def start_race(race_id):
    """Mark a race as started."""
    if race_id not in state.races:
        raise ValueError(f"Race '{race_id}' does not exist.")
    race = state.races[race_id]
    if race["status"] != "open":
        raise ValueError(f"Race '{race_id}' is not open.")
    if len(race["entries"]) < 1:
        raise ValueError("Need at least 1 entry to start a race.")
    race["status"] = "started"
    return True


def get_race(race_id):
    """Get race info."""
    return state.races.get(race_id)


def list_races():
    """Return all race IDs."""
    return list(state.races.keys())
