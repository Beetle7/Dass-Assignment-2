"""
registration.py - Register new crew members into the system.
"""
from . import state


def register_member(name):
    """Register a new crew member by name. Returns True on success."""
    if not name or not name.strip():
        raise ValueError("Name cannot be empty.")
    name = name.strip()
    if name in state.crew:
        raise ValueError(f"'{name}' is already registered.")
    state.crew[name] = {"roles": set(), "skills": {}}
    return True


def get_member(name):
    """Get a member's info dict, or None if not found."""
    return state.crew.get(name)


def list_members():
    """Return list of all registered member names."""
    return list(state.crew.keys())


def remove_member(name):
    """Remove a member from the registry."""
    if name not in state.crew:
        raise ValueError(f"'{name}' is not registered.")
    del state.crew[name]
    return True
