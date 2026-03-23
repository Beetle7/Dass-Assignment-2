#!/usr/bin/env python3
"""
main.py - Interactive CLI for StreetRace Manager.
Run from the integration directory: python -m src.main
"""
import sys
import os

# Allow running from integration/ directory
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


def print_menu():
    print("\n===== StreetRace Manager =====")
    print(" 1. Register Crew Member")
    print(" 2. Assign Role to Member")
    print(" 3. List Crew")
    print(" 4. Add Car")
    print(" 5. List Cars")
    print(" 6. Add Cash")
    print(" 7. View Cash")
    print(" 8. Create Race")
    print(" 9. Enter Race")
    print("10. Start Race")
    print("11. Record Race Results")
    print("12. View Rankings")
    print("13. Create Mission")
    print("14. Start Mission")
    print("15. Complete Mission")
    print("16. Browse Garage Parts")
    print("17. Buy Part from Garage")
    print("18. Equip Part to Car")
    print("19. Unequip Part from Car")
    print("20. View Car Slots")
    print(" 0. Exit")
    print("==============================")


def safe_input(prompt):
    try:
        return input(prompt).strip()
    except (EOFError, KeyboardInterrupt):
        print()
        return ""


def main():
    print("Welcome to StreetRace Manager!")

    while True:
        print_menu()
        choice = safe_input("Choose an option: ")

        try:
            if choice == "1":
                name = safe_input("Enter crew member name: ")
                registration.register_member(name)
                print(f"Registered '{name}' successfully.")

            elif choice == "2":
                name = safe_input("Member name: ")
                role = safe_input("Role (driver/mechanic/strategist): ")
                skill = safe_input("Skill level (1-10): ")
                crew_management.assign_role(name, role, int(skill))
                print(f"Assigned '{role}' to '{name}' with skill {skill}.")

            elif choice == "3":
                members = registration.list_members()
                if not members:
                    print("No crew members registered.")
                for m in members:
                    info = registration.get_member(m)
                    roles = ", ".join(info["roles"]) if info["roles"] else "none"
                    print(f"  {m} - Roles: {roles}")

            elif choice == "4":
                name = safe_input("Car name: ")
                speed = safe_input("Base speed (default 100): ") or "100"
                inventory.add_car(name, int(speed))
                print(f"Added car '{name}' with speed {speed}.")

            elif choice == "5":
                cars = inventory.list_cars()
                if not cars:
                    print("No cars in inventory.")
                for c in cars:
                    info = inventory.get_car(c)
                    parts = [f"{s}={p}" for s, p in info["slots"].items() if p]
                    parts_str = ", ".join(parts) if parts else "stock"
                    print(f"  {c} - Speed: {info['speed']}, Condition: {info['condition']}, Parts: {parts_str}")

            elif choice == "6":
                amount = safe_input("Amount to add: ")
                inventory.add_cash(float(amount))
                print(f"Cash balance: {inventory.get_cash()}")

            elif choice == "7":
                print(f"Cash balance: {inventory.get_cash()}")

            elif choice == "8":
                rid = safe_input("Race ID: ")
                name = safe_input("Race name: ")
                race_management.create_race(rid, name)
                print(f"Race '{rid}' created.")

            elif choice == "9":
                rid = safe_input("Race ID: ")
                driver = safe_input("Driver name: ")
                car = safe_input("Car name: ")
                race_management.enter_race(rid, driver, car)
                print(f"Entered '{driver}' with '{car}' into race '{rid}'.")

            elif choice == "10":
                rid = safe_input("Race ID: ")
                race_management.start_race(rid)
                print(f"Race '{rid}' started!")

            elif choice == "11":
                rid = safe_input("Race ID: ")
                race = race_management.get_race(rid)
                if not race:
                    print("Race not found.")
                    continue
                print(f"Entries: {race['entries']}")
                positions = []
                for i in range(len(race["entries"])):
                    driver = safe_input(f"  Position {i+1} driver: ")
                    car = safe_input(f"  Position {i+1} car: ")
                    positions.append((driver, car))
                prize = safe_input("Prize pool (default 1000): ") or "1000"
                dmg = safe_input("Damaged cars (comma-separated, or blank): ")
                damaged = [c.strip() for c in dmg.split(",") if c.strip()] if dmg else None
                results.record_result(rid, positions, float(prize), damaged)
                print("Results recorded.")

            elif choice == "12":
                ranks = results.get_rankings()
                if not ranks:
                    print("No rankings yet.")
                for driver, info in ranks.items():
                    print(f"  {driver} - Wins: {info['wins']}, Races: {info['races']}, Earnings: {info['earnings']}")

            elif choice == "13":
                mid = safe_input("Mission ID: ")
                mtype = safe_input(f"Mission type ({', '.join(mission_planning.MISSION_ROLES.keys())}): ")
                mission_planning.create_mission(mid, mtype)
                print(f"Mission '{mid}' ({mtype}) created.")

            elif choice == "14":
                mid = safe_input("Mission ID: ")
                mission_planning.start_mission(mid)
                m = mission_planning.get_mission(mid)
                print(f"Mission '{mid}' started. Assigned crew: {m['assigned_crew']}")

            elif choice == "15":
                mid = safe_input("Mission ID: ")
                mission_planning.complete_mission(mid)
                print(f"Mission '{mid}' completed.")

            elif choice == "16":
                parts = garage.list_parts()
                for name, info in parts.items():
                    print(f"  [{info['slot']}] {name} - ${info['price']} (+{info['stat_boost']} speed) - {info['description']}")

            elif choice == "17":
                print("Cash:", inventory.get_cash())
                pname = safe_input("Part name (exact): ")
                garage.buy_part(pname)
                print(f"Bought '{pname}'. Remaining cash: {inventory.get_cash()}")

            elif choice == "18":
                car = safe_input("Car name: ")
                pname = safe_input("Part name to equip: ")
                car_upgrade.equip_part(car, pname)
                print(f"Equipped '{pname}' on '{car}'.")

            elif choice == "19":
                car = safe_input("Car name: ")
                slot = safe_input(f"Slot to clear ({', '.join(state.CAR_SLOTS)}): ")
                car_upgrade.unequip_part(car, slot)
                print(f"Unequipped part from '{slot}' slot of '{car}'.")

            elif choice == "20":
                car = safe_input("Car name: ")
                slots = car_upgrade.view_car_slots(car)
                for slot, part in slots.items():
                    print(f"  {slot}: {part if part else '(empty)'}")
                print(f"  Effective speed: {car_upgrade.get_effective_speed(car)}")

            elif choice == "0":
                print("Goodbye!")
                break

            else:
                print("Invalid option. Try again.")

        except ValueError as e:
            print(f"Error: {e}")
        except Exception as e:
            print(f"Unexpected error: {e}")


if __name__ == "__main__":
    main()
