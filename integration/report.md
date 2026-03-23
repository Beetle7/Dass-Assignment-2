# StreetRace Manager - Integration Testing Report

## System Overview

Command-line system for managing underground street races, crew, vehicles, and missions. Built as 8 independent modules that interact through a shared state layer.

### Modules

| Module | Description |
|--------|-------------|
| Registration | Registers crew members by name |
| Crew Management | Assigns roles (driver, mechanic, strategist) with skill levels 1-10 |
| Inventory | Tracks cars, spare parts, tools, and cash balance |
| Race Management | Creates races, validates and enters driver+car pairs |
| Results | Records race outcomes, distributes prize money, updates rankings |
| Mission Planning | Assigns missions with role-based crew requirement checks |
| **Garage** (custom) | Parts catalog with prices and stat boosts, purchasing system |
| **Car Upgrade** (custom) | Slot-based car modification — equip/swap parts into engine, tires, NOS, suspension slots |

### Custom Module Details

**Garage**: Provides a catalog of parts (e.g., V8 Supercharger, Racing Slicks, NOS Stage 3) each with a price, slot type, and speed boost. Buying a part deducts cash from Inventory and adds the part to spare_parts.

**Car Upgrade**: Cars have 4 upgrade slots: engine, tires, NOS, and suspension. Parts from the Garage can be equipped into matching slots. Swapping a part into an occupied slot automatically returns the old part to inventory. Unequipping returns the part and reverts the speed boost. This keeps loadouts flexible for different race/mission needs.

---

## Integration Test Cases

All tests run via: `cd integration && pytest tests/test_integration.py -v`

### Test Case 1: Full Race Entry Flow
- **Scenario**: Register a driver, assign role, add car, create race, enter race
- **Modules**: Registration → Crew Management → Inventory → Race Management
- **Expected**: Driver+car entry accepted
- **Actual**: Passed
- **Errors**: None

### Test Case 2: Unregistered Driver Enters Race
- **Scenario**: Try to enter a race with a name that was never registered
- **Modules**: Race Management ← Registration (missing)
- **Expected**: ValueError raised ("not a registered crew member")
- **Actual**: Passed
- **Errors**: None

### Test Case 3: Non-Driver Role Enters Race
- **Scenario**: Register member as mechanic, then try to enter a race
- **Modules**: Registration → Crew Management → Race Management
- **Expected**: ValueError raised ("does not have the 'driver' role")
- **Actual**: Passed
- **Errors**: None

### Test Case 4: Damaged Car Rejected From Race
- **Scenario**: Mark a car as damaged, then try to enter it in a race
- **Modules**: Inventory → Race Management
- **Expected**: ValueError raised ("damaged")
- **Actual**: Passed
- **Errors**: None

### Test Case 5: Prize Money Updates Inventory
- **Scenario**: Two drivers race, results recorded with $2000 prize pool
- **Modules**: Race Management → Results → Inventory
- **Expected**: Cash increases by $1600 (50%+30%), winner gets 1 win in rankings
- **Actual**: Passed
- **Errors**: None

### Test Case 6: Race Damage Flags Car
- **Scenario**: A car gets damaged during a race result
- **Modules**: Results → Inventory
- **Expected**: Car condition changes to "damaged"
- **Actual**: Passed
- **Errors**: None

### Test Case 7: Repair Mission Without Mechanic
- **Scenario**: Create a repair mission with no mechanic registered
- **Modules**: Mission Planning ← Crew Management (missing role)
- **Expected**: ValueError raised ("no available crew member with role 'mechanic'")
- **Actual**: Passed
- **Errors**: None

### Test Case 8: Repair Mission With Mechanic
- **Scenario**: Register a mechanic, then start a repair mission
- **Modules**: Registration → Crew Management → Mission Planning
- **Expected**: Mission starts, mechanic auto-assigned
- **Actual**: Passed
- **Errors**: None

### Test Case 9: Heist Needs All Three Roles
- **Scenario**: Create heist mission, first with 2 roles (fail), then add 3rd (success)
- **Modules**: Registration → Crew Management → Mission Planning
- **Expected**: Fails until all 3 roles available, then succeeds with 3 crew assigned
- **Actual**: Passed
- **Errors**: None

### Test Case 10: Mission Lifecycle
- **Scenario**: Create → Start → Complete a delivery mission
- **Modules**: Mission Planning (full lifecycle)
- **Expected**: Status transitions: pending → active → completed
- **Actual**: Passed
- **Errors**: None

### Test Case 11: Buy Part Deducts Cash
- **Scenario**: Buy Racing Slicks ($2000) from garage with $10000 balance
- **Modules**: Garage → Inventory
- **Expected**: Cash decreases to $8000, part appears in spare_parts
- **Actual**: Passed
- **Errors**: None

### Test Case 12: Buy Part With Insufficient Cash
- **Scenario**: Try to buy V8 Supercharger ($6000) with only $100
- **Modules**: Garage → Inventory
- **Expected**: ValueError raised ("Insufficient funds")
- **Actual**: Passed
- **Errors**: None

### Test Case 13: Equip Part to Car Slot
- **Scenario**: Buy NOS Stage 1, equip to car
- **Modules**: Garage → Inventory → Car Upgrade
- **Expected**: Part in NOS slot, speed increases by 10
- **Actual**: Passed
- **Errors**: None

### Test Case 14: Equip Without Buying Fails
- **Scenario**: Try to equip Racing Slicks without buying them first
- **Modules**: Car Upgrade ← Inventory (missing)
- **Expected**: ValueError raised
- **Actual**: Passed
- **Errors**: None

### Test Case 15: Swap Parts in Same Slot
- **Scenario**: Equip Street Tires, then swap with Racing Slicks
- **Modules**: Garage → Inventory → Car Upgrade
- **Expected**: Old tires returned to inventory, new tires equipped, speed adjusted
- **Actual**: Passed
- **Errors**: None

### Test Case 16: Unequip Returns Part
- **Scenario**: Equip Sport Suspension then unequip it
- **Modules**: Car Upgrade → Inventory
- **Expected**: Slot becomes empty, part back in inventory, speed reverts
- **Actual**: Passed
- **Errors**: None

### Test Case 17: Full Damage-Repair-Rerace Cycle
- **Scenario**: Race damages car → can't enter next race → repair mission → fix car → race again
- **Modules**: Race Management → Results → Inventory → Mission Planning → Race Management
- **Expected**: Complete cycle works end-to-end
- **Actual**: Passed
- **Errors**: None

### Test Case 18: Upgraded Car Enters Race
- **Scenario**: Buy and equip 3 parts, then enter race with upgraded car
- **Modules**: Garage → Inventory → Car Upgrade → Race Management
- **Expected**: Car with all upgrades enters race, effective speed = 140+40+15+25 = 220
- **Actual**: Passed
- **Errors**: None

### Test Case 19: Double Registration Blocked
- **Scenario**: Register same name twice
- **Modules**: Registration
- **Expected**: ValueError on second attempt
- **Actual**: Passed
- **Errors**: None

### Test Case 20: Invalid Role Rejected
- **Scenario**: Try to assign "pilot" role (not valid)
- **Modules**: Crew Management
- **Expected**: ValueError raised
- **Actual**: Passed
- **Errors**: None

### Test Case 21: Delivery Mission Without Driver
- **Scenario**: Create delivery mission with no drivers registered
- **Modules**: Mission Planning ← Crew Management
- **Expected**: ValueError raised
- **Actual**: Passed
- **Errors**: None

---

## Bugs Found and Fixed During Integration

### Bug 1: Part Swap Doesn't Subtract Old Speed Boost (Test Case 15)
- **Found in**: `car_upgrade.py` → `equip_part()`
- **Problem**: When swapping a part into an already-occupied slot, the old part was returned to inventory but its speed boost was never subtracted from the car. This caused speed to keep stacking.
- **Example**: Car at 160 speed → equip Street Tires (+5) = 165 → swap to Racing Slicks (+15) → expected 175, got 180 (old +5 never removed).
- **Fix**: Added `car["speed"] -= old_info["stat_boost"]` before adding the new part's boost during a swap.
- **Detected by**: `test_swap_parts_in_slot` assertion failure.

