"""
car_upgrade.py - Slot-based car upgrade system.
Cars have slots (engine, tires, nos, suspension) where parts can be equipped
and swapped. Parts come from the spare_parts inventory (bought via garage module).
"""
from . import state
from . import inventory
from . import garage


def equip_part(car_name, part_name):
    """
    Equip a part into the matching slot on a car.
    - Part must exist in spare_parts inventory.
    - Part slot must match a valid car slot.
    - If a part is already in that slot, it gets unequipped first (returned to inventory).
    """
    car = inventory.get_car(car_name)
    if car is None:
        raise ValueError(f"Car '{car_name}' not found.")

    part_info = garage.get_part_info(part_name)
    if part_info is None:
        raise ValueError(f"Part '{part_name}' is not a recognized part.")

    slot = part_info["slot"]

    # Check part is in inventory
    if state.spare_parts.get(part_name, 0) < 1:
        raise ValueError(f"No '{part_name}' in inventory. Buy it from the garage first.")

    # If slot already has a part, unequip it first
    current_part = car["slots"].get(slot)
    if current_part is not None:
        old_info = garage.get_part_info(current_part)
        if old_info:
            car["speed"] -= old_info["stat_boost"]
        inventory.add_spare_part(current_part, 1)

    # Equip the new part
    inventory.use_spare_part(part_name, 1)
    car["slots"][slot] = part_name
    car["speed"] += part_info["stat_boost"]

    return True


def unequip_part(car_name, slot):
    """
    Remove the part from a car's slot and return it to inventory.
    """
    car = inventory.get_car(car_name)
    if car is None:
        raise ValueError(f"Car '{car_name}' not found.")
    if slot not in state.CAR_SLOTS:
        raise ValueError(f"Invalid slot '{slot}'. Choose from: {', '.join(state.CAR_SLOTS)}")

    current_part = car["slots"].get(slot)
    if current_part is None:
        raise ValueError(f"No part equipped in '{slot}' slot of '{car_name}'.")

    # Return part to inventory
    part_info = garage.get_part_info(current_part)
    if part_info:
        car["speed"] -= part_info["stat_boost"]
    inventory.add_spare_part(current_part, 1)
    car["slots"][slot] = None

    return True


def view_car_slots(car_name):
    """Return the slot layout for a car."""
    car = inventory.get_car(car_name)
    if car is None:
        raise ValueError(f"Car '{car_name}' not found.")
    return dict(car["slots"])


def get_effective_speed(car_name):
    """Return the car's current speed including all equipped parts."""
    car = inventory.get_car(car_name)
    if car is None:
        raise ValueError(f"Car '{car_name}' not found.")
    return car["speed"]
