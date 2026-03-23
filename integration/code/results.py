"""
results.py - Record race outcomes, update rankings, handle prize money.
"""
from . import state
from . import inventory


def record_result(race_id, positions, prize_pool=1000, damaged_cars=None):
    """
    Record results for a finished race.

    positions: list of (driver_name, car_name) in finishing order (1st, 2nd, ...)
    prize_pool: total prize money to distribute
    damaged_cars: list of car names damaged during the race (optional)
    """
    if race_id not in state.races:
        raise ValueError(f"Race '{race_id}' does not exist.")
    race = state.races[race_id]
    if race["status"] != "started":
        raise ValueError(f"Race '{race_id}' has not been started.")

    race["results"] = positions
    race["status"] = "finished"

    # Award prize money: 1st gets 50%, 2nd gets 30%, 3rd gets 20%
    splits = [0.50, 0.30, 0.20]
    for i, (driver, car) in enumerate(positions):
        # Init ranking if needed
        if driver not in state.rankings:
            state.rankings[driver] = {"wins": 0, "races": 0, "earnings": 0.0}
        state.rankings[driver]["races"] += 1

        if i == 0:
            state.rankings[driver]["wins"] += 1

        if i < len(splits):
            prize = prize_pool * splits[i]
            state.rankings[driver]["earnings"] += prize
            inventory.add_cash(prize)

    # Mark damaged cars
    if damaged_cars:
        for car_name in damaged_cars:
            if car_name in state.cars:
                inventory.set_car_condition(car_name, "damaged")

    return True


def get_rankings():
    """Return the rankings dict."""
    return dict(state.rankings)


def get_race_results(race_id):
    """Return results for a specific race."""
    if race_id not in state.races:
        raise ValueError(f"Race '{race_id}' does not exist.")
    return state.races[race_id].get("results", [])
