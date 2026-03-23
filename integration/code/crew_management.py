"""
crew_management.py - Manage roles and skill levels for registered crew members.
"""
from . import state

VALID_ROLES = {"driver", "mechanic", "strategist"}


def assign_role(name, role, skill_level=1):
    """Assign a role to a registered crew member with a skill level (1-10)."""
    if name not in state.crew:
        raise ValueError(f"'{name}' is not registered. Register them first.")
    role = role.lower()
    if role not in VALID_ROLES:
        raise ValueError(f"Invalid role '{role}'. Choose from: {', '.join(sorted(VALID_ROLES))}")
    if skill_level < 1 or skill_level > 10:
        raise ValueError("Skill level must be between 1 and 10.")
    state.crew[name]["roles"].add(role)
    state.crew[name]["skills"][role] = skill_level
    return True


def remove_role(name, role):
    """Remove a role from a crew member."""
    if name not in state.crew:
        raise ValueError(f"'{name}' is not registered.")
    role = role.lower()
    if role not in state.crew[name]["roles"]:
        raise ValueError(f"'{name}' does not have the role '{role}'.")
    state.crew[name]["roles"].discard(role)
    del state.crew[name]["skills"][role]
    return True


def get_members_with_role(role):
    """Return list of member names who have a given role."""
    role = role.lower()
    return [name for name, info in state.crew.items() if role in info["roles"]]


def get_skill(name, role):
    """Get the skill level for a member's role."""
    if name not in state.crew:
        raise ValueError(f"'{name}' is not registered.")
    role = role.lower()
    return state.crew[name]["skills"].get(role, 0)


def update_skill(name, role, new_level):
    """Update the skill level for an existing role."""
    if name not in state.crew:
        raise ValueError(f"'{name}' is not registered.")
    role = role.lower()
    if role not in state.crew[name]["roles"]:
        raise ValueError(f"'{name}' does not have the role '{role}'.")
    if new_level < 1 or new_level > 10:
        raise ValueError("Skill level must be between 1 and 10.")
    state.crew[name]["skills"][role] = new_level
    return True
