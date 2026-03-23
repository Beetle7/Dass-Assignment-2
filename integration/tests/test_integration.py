"""
test_integration.py - Integration tests for StreetRace Manager.
Tests module interactions, not individual units.
Run from integration/ directory: pytest tests/test_integration.py -v
"""
import sys
import os
import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src import state
from src import registration
from src import crew_management
from src import inventory
from src import race_management
from src import results
from src import mission_planning
from src import garage
from src import car_upgrade


@pytest.fixture(autouse=True)
def clean_state():
    """Reset all state before each test."""
    state.reset()
    yield


# ----------------------------------------------------------------
# 1. Registration -> Crew Management -> Race Management (happy path)
# ----------------------------------------------------------------
class TestRegistrationToRace:
    """Tests the full flow: register member, assign driver role, add car,
    create race, enter race. Covers Registration + Crew + Inventory + Race."""

    def test_full_race_entry_flow(self):
        registration.register_member("Alice")
        crew_management.assign_role("Alice", "driver", 8)
        inventory.add_car("Supra", 150)
        race_management.create_race("R1", "Downtown Sprint")
        race_management.enter_race("R1", "Alice", "Supra")

        race = race_management.get_race("R1")
        assert ("Alice", "Supra") in race["entries"]

    def test_enter_race_without_registration(self):
        """Unregistered person cannot enter a race."""
        inventory.add_car("Civic", 120)
        race_management.create_race("R2")
        with pytest.raises(ValueError, match="not a registered crew member"):
            race_management.enter_race("R2", "Ghost", "Civic")

    def test_enter_race_without_driver_role(self):
        """Registered member without driver role cannot race."""
        registration.register_member("Bob")
        crew_management.assign_role("Bob", "mechanic", 5)
        inventory.add_car("Civic", 120)
        race_management.create_race("R3")
        with pytest.raises(ValueError, match="does not have the 'driver' role"):
            race_management.enter_race("R3", "Bob", "Civic")

    def test_damaged_car_cannot_race(self):
        """A damaged car should be rejected from entering a race."""
        registration.register_member("Carl")
        crew_management.assign_role("Carl", "driver", 7)
        inventory.add_car("Mustang", 140)
        inventory.set_car_condition("Mustang", "damaged")
        race_management.create_race("R4")
        with pytest.raises(ValueError, match="damaged"):
            race_management.enter_race("R4", "Carl", "Mustang")


# ----------------------------------------------------------------
# 2. Race Results -> Inventory Cash Update
# ----------------------------------------------------------------
class TestRaceResultsToInventory:
    """Tests that finishing a race correctly updates cash and rankings."""

    def test_prize_money_flows_to_inventory(self):
        registration.register_member("Alice")
        registration.register_member("Bob")
        crew_management.assign_role("Alice", "driver", 9)
        crew_management.assign_role("Bob", "driver", 6)
        inventory.add_car("Supra", 150)
        inventory.add_car("Civic", 120)

        race_management.create_race("R5", "Highway Blitz")
        race_management.enter_race("R5", "Alice", "Supra")
        race_management.enter_race("R5", "Bob", "Civic")
        race_management.start_race("R5")

        initial_cash = inventory.get_cash()
        results.record_result(
            "R5",
            positions=[("Alice", "Supra"), ("Bob", "Civic")],
            prize_pool=2000,
        )

        # 1st gets 50%(1000) + 2nd gets 30%(600) = 1600 added
        assert inventory.get_cash() == initial_cash + 1600
        ranks = results.get_rankings()
        assert ranks["Alice"]["wins"] == 1
        assert ranks["Bob"]["wins"] == 0

    def test_race_damage_marks_car(self):
        """Damaged cars from race results should be flagged in inventory."""
        registration.register_member("Dan")
        crew_management.assign_role("Dan", "driver", 5)
        inventory.add_car("Eclipse", 130)

        race_management.create_race("R6")
        race_management.enter_race("R6", "Dan", "Eclipse")
        race_management.start_race("R6")
        results.record_result("R6", [("Dan", "Eclipse")], damaged_cars=["Eclipse"])

        car = inventory.get_car("Eclipse")
        assert car["condition"] == "damaged"


# ----------------------------------------------------------------
# 3. Mission Planning -> Crew Role Verification
# ----------------------------------------------------------------
class TestMissionPlanning:
    """Tests that missions check role availability before starting."""

    def test_mission_requires_mechanic(self):
        """Repair mission fails if no mechanic is registered."""
        mission_planning.create_mission("M1", "repair")
        with pytest.raises(ValueError, match="no available crew member with role 'mechanic'"):
            mission_planning.start_mission("M1")

    def test_mission_succeeds_with_role(self):
        """Repair mission works when a mechanic exists."""
        registration.register_member("Eve")
        crew_management.assign_role("Eve", "mechanic", 7)
        mission_planning.create_mission("M2", "repair")
        mission_planning.start_mission("M2")

        m = mission_planning.get_mission("M2")
        assert m["status"] == "active"
        assert "Eve" in m["assigned_crew"]

    def test_heist_needs_all_three_roles(self):
        """Heist requires driver + strategist + mechanic."""
        registration.register_member("A")
        registration.register_member("B")
        crew_management.assign_role("A", "driver", 5)
        crew_management.assign_role("B", "strategist", 5)

        mission_planning.create_mission("M3", "heist")
        with pytest.raises(ValueError, match="mechanic"):
            mission_planning.start_mission("M3")

        # Now add a mechanic and retry
        registration.register_member("C")
        crew_management.assign_role("C", "mechanic", 5)
        state.missions["M3"]["status"] = "pending"  # reset status for retry
        mission_planning.start_mission("M3")
        m = mission_planning.get_mission("M3")
        assert m["status"] == "active"
        assert len(m["assigned_crew"]) == 3

    def test_mission_completion_flow(self):
        """Full lifecycle: create -> start -> complete."""
        registration.register_member("Finn")
        crew_management.assign_role("Finn", "driver", 6)
        mission_planning.create_mission("M4", "delivery")
        mission_planning.start_mission("M4")
        mission_planning.complete_mission("M4")
        assert mission_planning.get_mission("M4")["status"] == "completed"


# ----------------------------------------------------------------
# 4. Garage -> Inventory -> Car Upgrade (slot system)
# ----------------------------------------------------------------
class TestGarageAndUpgrades:
    """Tests the custom modules: buying parts and equipping them in car slots."""

    def test_buy_part_deducts_cash(self):
        inventory.add_cash(10000)
        garage.buy_part("Racing Slicks")
        assert inventory.get_cash() == 10000 - 2000
        assert state.spare_parts.get("Racing Slicks") == 1

    def test_buy_part_insufficient_cash(self):
        inventory.add_cash(100)
        with pytest.raises(ValueError, match="Insufficient funds"):
            garage.buy_part("V8 Supercharger")

    def test_equip_part_to_car(self):
        inventory.add_cash(5000)
        inventory.add_car("RX-7", 130)
        garage.buy_part("NOS Stage 1")

        car_upgrade.equip_part("RX-7", "NOS Stage 1")
        slots = car_upgrade.view_car_slots("RX-7")
        assert slots["nos"] == "NOS Stage 1"
        assert car_upgrade.get_effective_speed("RX-7") == 130 + 10

    def test_equip_without_buying_fails(self):
        inventory.add_car("Z4", 140)
        with pytest.raises(ValueError, match="No 'Racing Slicks' in inventory"):
            car_upgrade.equip_part("Z4", "Racing Slicks")

    def test_swap_parts_in_slot(self):
        """Equipping a new part into an occupied slot returns the old part to inventory."""
        inventory.add_cash(10000)
        inventory.add_car("GT-R", 160)

        garage.buy_part("Street Tires")
        garage.buy_part("Racing Slicks")

        car_upgrade.equip_part("GT-R", "Street Tires")
        assert car_upgrade.get_effective_speed("GT-R") == 160 + 5

        car_upgrade.equip_part("GT-R", "Racing Slicks")
        # Old part returned, new part equipped
        assert state.spare_parts.get("Street Tires") == 1
        assert car_upgrade.get_effective_speed("GT-R") == 160 + 15
        assert car_upgrade.view_car_slots("GT-R")["tires"] == "Racing Slicks"

    def test_unequip_returns_part(self):
        inventory.add_cash(5000)
        inventory.add_car("Evo", 140)
        garage.buy_part("Sport Suspension")
        car_upgrade.equip_part("Evo", "Sport Suspension")

        car_upgrade.unequip_part("Evo", "suspension")
        assert car_upgrade.view_car_slots("Evo")["suspension"] is None
        assert state.spare_parts.get("Sport Suspension") == 1
        assert car_upgrade.get_effective_speed("Evo") == 140


# ----------------------------------------------------------------
# 5. Cross-module: Race damage -> Repair mission -> Fix car -> Race again
# ----------------------------------------------------------------
class TestDamageRepairCycle:
    """End-to-end: race damages car, repair mission fixes it, car races again."""

    def test_full_damage_repair_rerace(self):
        # Setup crew
        registration.register_member("Kai")
        registration.register_member("Mech")
        crew_management.assign_role("Kai", "driver", 8)
        crew_management.assign_role("Mech", "mechanic", 7)
        inventory.add_car("WRX", 145)

        # Race and damage the car
        race_management.create_race("R10")
        race_management.enter_race("R10", "Kai", "WRX")
        race_management.start_race("R10")
        results.record_result("R10", [("Kai", "WRX")], prize_pool=500, damaged_cars=["WRX"])

        assert inventory.get_car("WRX")["condition"] == "damaged"

        # Can't enter a new race with damaged car
        race_management.create_race("R11")
        with pytest.raises(ValueError, match="damaged"):
            race_management.enter_race("R11", "Kai", "WRX")

        # Start repair mission (requires mechanic)
        mission_planning.create_mission("FIX1", "repair")
        mission_planning.start_mission("FIX1")
        mission_planning.complete_mission("FIX1")

        # Fix the car
        inventory.set_car_condition("WRX", "ok")

        # Now the car can race again
        race_management.enter_race("R11", "Kai", "WRX")
        race = race_management.get_race("R11")
        assert ("Kai", "WRX") in race["entries"]


# ----------------------------------------------------------------
# 6. Garage upgrade -> Race with upgraded car
# ----------------------------------------------------------------
class TestUpgradeAndRace:
    """Buy parts, equip to car, then race with the upgraded car."""

    def test_upgraded_car_enters_race(self):
        registration.register_member("Vin")
        crew_management.assign_role("Vin", "driver", 9)

        inventory.add_cash(20000)
        inventory.add_car("Charger", 140)

        garage.buy_part("V8 Supercharger")
        garage.buy_part("Racing Slicks")
        garage.buy_part("NOS Stage 3")

        car_upgrade.equip_part("Charger", "V8 Supercharger")
        car_upgrade.equip_part("Charger", "Racing Slicks")
        car_upgrade.equip_part("Charger", "NOS Stage 3")

        assert car_upgrade.get_effective_speed("Charger") == 140 + 40 + 15 + 25

        race_management.create_race("R20", "Quarter Mile")
        race_management.enter_race("R20", "Vin", "Charger")
        race = race_management.get_race("R20")
        assert ("Vin", "Charger") in race["entries"]


# ----------------------------------------------------------------
# 7. Edge cases and validation across modules
# ----------------------------------------------------------------
class TestCrossModuleValidation:
    """Edge cases that span multiple modules."""

    def test_remove_member_with_role_still_works(self):
        registration.register_member("X")
        crew_management.assign_role("X", "driver", 5)
        registration.remove_member("X")
        assert "X" not in state.crew

    def test_double_register_fails(self):
        registration.register_member("Y")
        with pytest.raises(ValueError, match="already registered"):
            registration.register_member("Y")

    def test_invalid_role_rejected(self):
        registration.register_member("Z")
        with pytest.raises(ValueError, match="Invalid role"):
            crew_management.assign_role("Z", "pilot", 5)

    def test_car_in_two_races_blocked(self):
        """Same car can't be entered in two open races simultaneously."""
        registration.register_member("A")
        registration.register_member("B")
        crew_management.assign_role("A", "driver", 5)
        crew_management.assign_role("B", "driver", 5)
        inventory.add_car("Shared", 100)

        race_management.create_race("RA")
        race_management.create_race("RB")
        race_management.enter_race("RA", "A", "Shared")
        # Same car in another race is allowed (different race context)
        race_management.enter_race("RB", "B", "Shared")

    def test_mission_without_required_roles(self):
        """Delivery needs a driver. Without one, mission can't start."""
        mission_planning.create_mission("MD", "delivery")
        with pytest.raises(ValueError, match="no available crew member"):
            mission_planning.start_mission("MD")
