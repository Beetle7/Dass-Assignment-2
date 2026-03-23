"""
mission_planning.py - Assign missions and verify required crew roles are available.
"""
from . import state
from . import crew_management

# Default role requirements per mission type
MISSION_ROLES = {
    "delivery": ["driver"],
    "rescue": ["driver", "mechanic"],
    "repair": ["mechanic"],
    "recon": ["strategist"],
    "heist": ["driver", "strategist", "mechanic"],
}


def create_mission(mission_id, mission_type):
    """Create a mission of a given type."""
    mission_type = mission_type.lower()
    if mission_id in state.missions:
        raise ValueError(f"Mission '{mission_id}' already exists.")
    if mission_type not in MISSION_ROLES:
        raise ValueError(f"Unknown mission type '{mission_type}'. Choose from: {', '.join(MISSION_ROLES.keys())}")

    required = MISSION_ROLES[mission_type]
    state.missions[mission_id] = {
        "type": mission_type,
        "status": "pending",
        "required_roles": list(required),
        "assigned_crew": [],
    }
    return True


def start_mission(mission_id):
    """
    Start a mission. Checks that all required roles have at least one crew
    member available. Auto-assigns crew members to the mission.
    """
    if mission_id not in state.missions:
        raise ValueError(f"Mission '{mission_id}' does not exist.")
    mission = state.missions[mission_id]
    if mission["status"] != "pending":
        raise ValueError(f"Mission '{mission_id}' is not pending.")

    assigned = []
    for role in mission["required_roles"]:
        available = crew_management.get_members_with_role(role)
        # Filter out crew already assigned to this mission
        available = [m for m in available if m not in assigned]
        if not available:
            raise ValueError(
                f"Cannot start mission: no available crew member with role '{role}'."
            )
        assigned.append(available[0])

    mission["assigned_crew"] = assigned
    mission["status"] = "active"
    return True


def complete_mission(mission_id):
    """Mark a mission as completed."""
    if mission_id not in state.missions:
        raise ValueError(f"Mission '{mission_id}' does not exist.")
    mission = state.missions[mission_id]
    if mission["status"] != "active":
        raise ValueError(f"Mission '{mission_id}' is not active.")
    mission["status"] = "completed"
    return True


def get_mission(mission_id):
    """Get mission info."""
    return state.missions.get(mission_id)


def list_missions():
    """Return all mission IDs."""
    return list(state.missions.keys())
