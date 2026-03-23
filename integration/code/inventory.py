"""
inventory.py - Track cars, spare parts, tools, and cash balance.
"""
from . import state


# ---- Cash ----

def get_cash():
    """Return current cash balance."""
    return state.cash


def add_cash(amount):
    """Add money to the crew's balance."""
    if amount <= 0:
        raise ValueError("Amount must be positive.")
    state.cash += amount
    return state.cash


def deduct_cash(amount):
    """Deduct money from balance. Fails if insufficient funds."""
    if amount <= 0:
        raise ValueError("Amount must be positive.")
    if amount > state.cash:
        raise ValueError(f"Insufficient funds. Have {state.cash}, need {amount}.")
    state.cash -= amount
    return state.cash


# ---- Cars ----

def add_car(name, speed=100):
    """Add a car to inventory with a base speed and empty upgrade slots."""
    if not name or not name.strip():
        raise ValueError("Car name cannot be empty.")
    name = name.strip()
    if name in state.cars:
        raise ValueError(f"Car '{name}' already exists.")
    state.cars[name] = {
        "speed": speed,
        "condition": "ok",
        "slots": {slot: None for slot in state.CAR_SLOTS},
    }
    return True


def get_car(name):
    """Get a car's info dict, or None if not found."""
    return state.cars.get(name)


def list_cars():
    """Return list of all car names."""
    return list(state.cars.keys())


def set_car_condition(name, condition):
    """Set car condition to 'ok' or 'damaged'."""
    if name not in state.cars:
        raise ValueError(f"Car '{name}' not found.")
    if condition not in ("ok", "damaged"):
        raise ValueError("Condition must be 'ok' or 'damaged'.")
    state.cars[name]["condition"] = condition
    return True


def remove_car(name):
    """Remove a car from inventory."""
    if name not in state.cars:
        raise ValueError(f"Car '{name}' not found.")
    del state.cars[name]
    return True


# ---- Spare Parts ----

def add_spare_part(name, qty=1):
    """Add spare parts to inventory."""
    if qty <= 0:
        raise ValueError("Quantity must be positive.")
    state.spare_parts[name] = state.spare_parts.get(name, 0) + qty
    return state.spare_parts[name]


def use_spare_part(name, qty=1):
    """Use spare parts from inventory."""
    current = state.spare_parts.get(name, 0)
    if current < qty:
        raise ValueError(f"Not enough '{name}'. Have {current}, need {qty}.")
    state.spare_parts[name] -= qty
    if state.spare_parts[name] == 0:
        del state.spare_parts[name]
    return True


# ---- Tools ----

def add_tool(name, qty=1):
    """Add tools to inventory."""
    if qty <= 0:
        raise ValueError("Quantity must be positive.")
    state.tools[name] = state.tools.get(name, 0) + qty
    return state.tools[name]
