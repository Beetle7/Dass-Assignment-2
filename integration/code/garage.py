"""
garage.py - Parts catalog and purchasing system.
Provides a stock of parts that can be bought with cash from inventory.
Parts are categorized by which car slot they fit into.
"""
from . import state
from . import inventory

# Garage catalog: {part_name: {"slot": str, "price": float, "stat_boost": int, "description": str}}
CATALOG = {
    # Engine parts
    "V6 Turbo Engine":      {"slot": "engine",     "price": 3000, "stat_boost": 20, "description": "Mid-range turbo engine"},
    "V8 Supercharger":      {"slot": "engine",     "price": 6000, "stat_boost": 40, "description": "High-power supercharged V8"},
    "Electric Motor":       {"slot": "engine",     "price": 4500, "stat_boost": 30, "description": "Silent and quick electric motor"},
    # Tire parts
    "Street Tires":         {"slot": "tires",      "price": 800,  "stat_boost": 5,  "description": "Basic street-legal tires"},
    "Racing Slicks":        {"slot": "tires",      "price": 2000, "stat_boost": 15, "description": "Smooth tires for max grip on dry track"},
    "Off-Road Tires":       {"slot": "tires",      "price": 1500, "stat_boost": 10, "description": "Rugged tires for rough terrain"},
    # NOS parts
    "NOS Stage 1":          {"slot": "nos",        "price": 1200, "stat_boost": 10, "description": "Basic nitrous oxide kit"},
    "NOS Stage 3":          {"slot": "nos",        "price": 3500, "stat_boost": 25, "description": "Full nitrous system with purge"},
    # Suspension parts
    "Sport Suspension":     {"slot": "suspension", "price": 1000, "stat_boost": 8,  "description": "Lowered sport suspension"},
    "Rally Suspension":     {"slot": "suspension", "price": 2500, "stat_boost": 18, "description": "Heavy-duty rally lift kit"},
}


def list_parts():
    """Return the full catalog as a dict."""
    return dict(CATALOG)


def get_part_info(part_name):
    """Get info for a specific part. Returns None if not in catalog."""
    return CATALOG.get(part_name)


def buy_part(part_name):
    """
    Buy a part from the garage. Deducts cash from inventory and adds the
    part to spare_parts inventory.
    """
    if part_name not in CATALOG:
        raise ValueError(f"Part '{part_name}' is not in the garage catalog.")
    part = CATALOG[part_name]
    price = part["price"]

    # Deduct cash (raises ValueError if insufficient)
    inventory.deduct_cash(price)

    # Add part to spare_parts
    inventory.add_spare_part(part_name, 1)
    return True


def get_parts_for_slot(slot):
    """Return all catalog parts that fit a given slot."""
    return {name: info for name, info in CATALOG.items() if info["slot"] == slot}
