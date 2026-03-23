# Phase 1: Code Quality Analysis

Pylint was run on each file iteratively and the warnings were fixed one at a time. Below are the changes made in each iteration.

## Iteration 1: Added docstrings to bank.py and removed unused import

Pylint flagged a missing module docstring (C0114), a missing class docstring (C0115), and an unused import for the math module (W0611). Added docstrings at the module and class level, and removed the unused import math line since no math functions are actually used in the file.

## Iteration 2: Added docstring and fixed long lines in cards.py

The file was missing a module docstring (C0114) and had several lines that were too long (C0301) because the card dictionaries were all written on single wide lines. Added a docstring at the top and reformatted the dictionary entries by placing the action and value keys on the line below description.

## Iteration 3: Added module docstring to config.py

Only warning was a missing module docstring (C0114). Added a short docstring at the top explaining the file contains game constants.

## Iteration 4: Added docstring, removed unused import, and fixed doubles_streak init in dice.py

Three warnings were fixed. The module docstring was missing (C0114). The BOARD_SIZE import from moneypoly.config was unused (W0611) so it was removed. The doubles_streak attribute was being defined in reset() rather than __init__ which triggered W0201, so it was added directly to __init__.

## Iteration 5: Added docstring, removed unused imports, and fixed warnings in player.py

Added a module docstring (C0114). Removed the unused sys import (W0611). Added a pylint disable comment for the too-many-instance-attributes warning (R0902) since a player naturally needs to track name, balance, position, properties, jail status and so on. Removed the old_position variable that was assigned but never used (W0612). Added the missing final newline (C0304).

## Iteration 6: Fixed module docstrings, syntax, and comparison warnings across board.py, game.py, property.py, ui.py

Several warnings were fixed across multiple files in this iteration. Module and class docstrings were added wherever missing (C0114, C0115). In board.py the comparison prop.is_mortgaged == True was changed to prop.is_mortgaged is True as recommended by pylint (C0121). In game.py the unnecessary parentheses around not expressions were removed (C0325), the f-string that had no interpolation was changed to a plain string (W1309), an elif after a break was restructured (R1723), and the unused os and GO_TO_JAIL_POSITION imports were removed (W0611). The final newline was also missing in game.py and player.py (C0304) and was added. In property.py the unnecessary else after a return was removed (R1705). In ui.py the bare except clause was changed to except ValueError (W0702).

## Iteration 7: Suppressed complex logic warnings and import-error false positives

Some warnings could not be fixed by restructuring the code without making it harder to read. The too-many-instance-attributes warning (R0902) in Game and Property is appropriate since these classes need to represent the full state of the game and a property tile. The too-many-branches warning (R0912) in _apply_card is justified since the method handles each card action type in a separate branch. The too-many-arguments and too-many-positional-arguments warnings (R0913, R0917) in Property.__init__ cannot be reduced without losing meaningful constructor parameters. All of these were suppressed with inline pylint disable comments. The import-error warnings (E0401) across all files are false positives because pylint cannot resolve the moneypoly package when running on individual files without the package on PYTHONPATH, so these were suppressed with a disable comment at the top of each file.

# Phase 2: White Box Test Cases

Tests were written in whitebox/tests/test_moneypoly.py to cover every module in the codebase. For each module the tests cover the main success path, boundary values, and every branch condition. Running the tests found 7 logical errors in the code, which are described below along with the fixes.

## Error 1: all_owned_by used any() instead of all() in property.py

The bug was in all_owned_by() on line 86 of property.py. It used any(p.owner == player ...) which returns True as soon as the player owns even a single property in the group. This meant rent was doubled from the moment a player bought their first property in a group. The fix was to change any() to all().

Tests that caught this: test_all_owned_by_partial, test_all_owned_by_split, test_rent_single_owner_no_double

## Error 2: move() only gave Go salary when landing on Go, not when passing it

The bug was in move() in player.py. The condition was if self.position == 0 which only fires when a player lands exactly on position 0 after the modulo. The fix was to check whether the raw move (before modulo) is at least BOARD_SIZE, which means the player wrapped around.

Test that caught this: test_move_pass_go_gives_salary

## Error 3: buy_property used <= instead of < when checking affordability in game.py

The bug was on line 143 of game.py: if player.balance <= prop.price. This blocked the purchase even when balance exactly equals price. The fix was to change <= to <.

Test that caught this: test_buy_exact_balance

## Error 4: pay_rent deducted from the renter but never credited the owner in game.py

The bug was in pay_rent() in game.py. The code called player.deduct_money(rent) but never called prop.owner.add_money(rent). The rent money was removed from the game and the property owner received nothing. The fix was to add the add_money call right after the deduction.

Test that caught this: test_rent_credited_to_owner

## Error 5: find_winner used min() instead of max() in game.py

The bug was on line 367 of game.py: return min(self.players, key=lambda p: p.net_worth()). This returned the player with the lowest net worth. The fix was to change min to max.

Test that caught this: test_find_winner_richest

## Error 6: dice.py rolled 1 to 5 instead of 1 to 6

The bug was in dice.py on lines 24 and 25: random.randint(1, 5) was used for both dice. The fix was to change both calls to random.randint(1, 6).

Test that caught this: test_roll_max_reachable

## Error 7: trade() never credits the seller in game.py

The bug is in trade() in game.py. The code calls buyer.deduct_money(cash_amount) and transfers ownership but never calls seller.add_money(cash_amount). The seller receives nothing for their property.

Test that documents this: test_seller_balance_increases
