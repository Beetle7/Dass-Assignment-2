"""
white-box tests for moneypoly.
covers all branches, edge cases, and key variable states.
run with: python -m pytest whitebox/tests/ -v
"""
import sys
import os
import pytest
from unittest.mock import patch

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "code"))

from moneypoly.bank import Bank
from moneypoly.config import (
    STARTING_BALANCE, BANK_STARTING_FUNDS, GO_SALARY,
    BOARD_SIZE, JAIL_POSITION, JAIL_FINE,
    INCOME_TAX_AMOUNT, LUXURY_TAX_AMOUNT,
)
from moneypoly.dice import Dice
from moneypoly.player import Player
from moneypoly.property import Property, PropertyGroup
from moneypoly.board import Board
from moneypoly.cards import CardDeck, CHANCE_CARDS, COMMUNITY_CHEST_CARDS
from moneypoly.game import Game


class TestBank:

    def setup_method(self):
        self.bank = Bank()

    def test_initial_balance(self):
        assert self.bank.get_balance() == BANK_STARTING_FUNDS

    def test_collect_positive(self):
        before = self.bank.get_balance()
        self.bank.collect(500)
        assert self.bank.get_balance() == before + 500

    def test_collect_zero(self):
        before = self.bank.get_balance()
        self.bank.collect(0)
        assert self.bank.get_balance() == before

    def test_collect_negative(self):
        # negative collect is used when paying out mortgage amounts
        before = self.bank.get_balance()
        self.bank.collect(-200)
        assert self.bank.get_balance() == before - 200

    def test_pay_out_normal(self):
        before = self.bank.get_balance()
        result = self.bank.pay_out(100)
        assert result == 100
        assert self.bank.get_balance() == before - 100

    def test_pay_out_zero(self):
        # amount <= 0 should return 0 and not change funds
        before = self.bank.get_balance()
        result = self.bank.pay_out(0)
        assert result == 0
        assert self.bank.get_balance() == before

    def test_pay_out_negative(self):
        result = self.bank.pay_out(-50)
        assert result == 0

    def test_pay_out_exceeds_funds(self):
        with pytest.raises(ValueError):
            self.bank.pay_out(BANK_STARTING_FUNDS + 1)

    def test_pay_out_exact_funds(self):
        # paying out exactly what the bank has should still work
        result = self.bank.pay_out(BANK_STARTING_FUNDS)
        assert result == BANK_STARTING_FUNDS
        assert self.bank.get_balance() == 0

    def test_give_loan_positive(self):
        player = Player("Alice")
        before = player.balance
        self.bank.give_loan(player, 300)
        assert player.balance == before + 300
        assert self.bank.loan_count() == 1
        assert self.bank.total_loans_issued() == 300

    def test_give_loan_zero(self):
        # zero amount should be ignored
        player = Player("Alice")
        before = player.balance
        self.bank.give_loan(player, 0)
        assert player.balance == before
        assert self.bank.loan_count() == 0

    def test_give_loan_negative(self):
        player = Player("Alice")
        self.bank.give_loan(player, -100)
        assert self.bank.loan_count() == 0

    def test_multiple_loans(self):
        p1 = Player("Alice")
        p2 = Player("Bob")
        self.bank.give_loan(p1, 100)
        self.bank.give_loan(p2, 200)
        assert self.bank.loan_count() == 2
        assert self.bank.total_loans_issued() == 300


class TestDice:

    def setup_method(self):
        self.dice = Dice()

    def test_initial_state(self):
        assert self.dice.die1 == 0
        assert self.dice.die2 == 0
        assert self.dice.doubles_streak == 0

    def test_roll_range(self):
        # each die must produce values 1 to 6
        for _ in range(200):
            self.dice.roll()
            assert 1 <= self.dice.die1 <= 6
            assert 1 <= self.dice.die2 <= 6

    def test_roll_max_reachable(self):
        # over many rolls the value 6 must appear at least once
        seen = set()
        for _ in range(500):
            self.dice.roll()
            seen.add(self.dice.die1)
            seen.add(self.dice.die2)
        assert 6 in seen, "die value 6 was never produced, dice range is likely 1-5"

    def test_roll_returns_total(self):
        total = self.dice.roll()
        assert total == self.dice.die1 + self.dice.die2

    def test_total_range(self):
        for _ in range(200):
            total = self.dice.roll()
            assert 2 <= total <= 12

    def test_doubles_detected(self):
        self.dice.die1 = 3
        self.dice.die2 = 3
        assert self.dice.is_doubles() is True

    def test_not_doubles(self):
        self.dice.die1 = 2
        self.dice.die2 = 4
        assert self.dice.is_doubles() is False

    def test_doubles_streak_increments(self):
        with patch("moneypoly.dice.random.randint", side_effect=[3, 3, 4, 4]):
            self.dice.roll()
            assert self.dice.doubles_streak == 1
            self.dice.roll()
            assert self.dice.doubles_streak == 2

    def test_doubles_streak_resets(self):
        self.dice.doubles_streak = 2
        with patch("moneypoly.dice.random.randint", side_effect=[2, 5]):
            self.dice.roll()
        assert self.dice.doubles_streak == 0

    def test_reset(self):
        self.dice.die1 = 5
        self.dice.die2 = 5
        self.dice.doubles_streak = 3
        self.dice.reset()
        assert self.dice.die1 == 0
        assert self.dice.die2 == 0
        assert self.dice.doubles_streak == 0

    def test_describe_shows_doubles(self):
        self.dice.die1 = 4
        self.dice.die2 = 4
        desc = self.dice.describe()
        assert "DOUBLES" in desc

    def test_describe_no_doubles(self):
        self.dice.die1 = 3
        self.dice.die2 = 5
        assert "DOUBLES" not in self.dice.describe()


class TestPlayer:

    def setup_method(self):
        self.player = Player("Alice")

    def test_initial_balance(self):
        assert self.player.balance == STARTING_BALANCE

    def test_initial_position(self):
        assert self.player.position == 0

    def test_initial_jail_state(self):
        assert self.player.in_jail is False
        assert self.player.jail_turns == 0

    def test_add_money_positive(self):
        self.player.add_money(500)
        assert self.player.balance == STARTING_BALANCE + 500

    def test_add_money_zero(self):
        self.player.add_money(0)
        assert self.player.balance == STARTING_BALANCE

    def test_add_money_negative_raises(self):
        with pytest.raises(ValueError):
            self.player.add_money(-100)

    def test_deduct_money_positive(self):
        self.player.deduct_money(200)
        assert self.player.balance == STARTING_BALANCE - 200

    def test_deduct_money_zero(self):
        self.player.deduct_money(0)
        assert self.player.balance == STARTING_BALANCE

    def test_deduct_money_negative_raises(self):
        with pytest.raises(ValueError):
            self.player.deduct_money(-50)

    def test_deduct_can_go_negative(self):
        # balance going below zero is allowed, bankruptcy is checked separately
        self.player.deduct_money(STARTING_BALANCE + 1)
        assert self.player.balance < 0

    def test_not_bankrupt(self):
        assert self.player.is_bankrupt() is False

    def test_bankrupt_at_zero(self):
        self.player.balance = 0
        assert self.player.is_bankrupt() is True

    def test_bankrupt_below_zero(self):
        self.player.balance = -1
        assert self.player.is_bankrupt() is True

    def test_move_basic(self):
        pos = self.player.move(5)
        assert pos == 5
        assert self.player.position == 5

    def test_move_wraps_around(self):
        self.player.position = 38
        pos = self.player.move(4)
        assert pos == 2

    def test_move_land_on_go_gives_salary(self):
        self.player.position = 38
        before = self.player.balance
        self.player.move(2)
        assert self.player.position == 0
        assert self.player.balance == before + GO_SALARY

    def test_move_pass_go_gives_salary(self):
        # moving from 38 by 4 lands on position 2, passing go on the way
        self.player.position = 38
        before = self.player.balance
        self.player.move(4)
        assert self.player.position == 2
        assert self.player.balance == before + GO_SALARY

    def test_go_to_jail(self):
        self.player.go_to_jail()
        assert self.player.position == JAIL_POSITION
        assert self.player.in_jail is True
        assert self.player.jail_turns == 0

    def test_add_property(self):
        prop = Property("Test", 1, 100, 10)
        self.player.add_property(prop)
        assert prop in self.player.properties
        assert self.player.count_properties() == 1

    def test_add_property_duplicate(self):
        prop = Property("Test", 1, 100, 10)
        self.player.add_property(prop)
        self.player.add_property(prop)
        assert self.player.count_properties() == 1

    def test_remove_property(self):
        prop = Property("Test", 1, 100, 10)
        self.player.add_property(prop)
        self.player.remove_property(prop)
        assert prop not in self.player.properties

    def test_remove_property_not_owned(self):
        # should not raise even if the player does not own the property
        prop = Property("Test", 1, 100, 10)
        self.player.remove_property(prop)

    def test_net_worth_equals_balance(self):
        assert self.player.net_worth() == self.player.balance


class TestProperty:

    def setup_method(self):
        self.group = PropertyGroup("Reds", "red")
        self.p1 = Property("Prop A", 1, 100, 10, self.group)
        self.p2 = Property("Prop B", 3, 100, 10, self.group)
        self.owner = Player("Alice")

    def test_rent_base(self):
        assert self.p1.get_rent() == 10

    def test_rent_mortgaged_is_zero(self):
        self.p1.is_mortgaged = True
        assert self.p1.get_rent() == 0

    def test_rent_single_owner_no_double(self):
        # owning only one property in the group should not double rent
        self.p1.owner = self.owner
        self.p2.owner = None
        assert self.p1.get_rent() == 10

    def test_rent_full_group_doubled(self):
        # owning all properties in the group should double rent
        self.p1.owner = self.owner
        self.p2.owner = self.owner
        assert self.p1.get_rent() == 20

    def test_rent_no_group(self):
        p = Property("Lone", 5, 200, 15)
        assert p.get_rent() == 15

    def test_mortgage_payout(self):
        payout = self.p1.mortgage()
        assert payout == 50
        assert self.p1.is_mortgaged is True

    def test_mortgage_already_mortgaged(self):
        self.p1.is_mortgaged = True
        assert self.p1.mortgage() == 0

    def test_unmortgage_cost(self):
        self.p1.is_mortgaged = True
        cost = self.p1.unmortgage()
        assert cost == int(50 * 1.1)
        assert self.p1.is_mortgaged is False

    def test_unmortgage_not_mortgaged(self):
        assert self.p1.unmortgage() == 0

    def test_available_unowned(self):
        assert self.p1.is_available() is True

    def test_not_available_owned(self):
        self.p1.owner = self.owner
        assert self.p1.is_available() is False

    def test_not_available_mortgaged(self):
        self.p1.is_mortgaged = True
        assert self.p1.is_available() is False


class TestPropertyGroup:

    def setup_method(self):
        self.group = PropertyGroup("Blues", "blue")
        self.p1 = Property("Prop A", 1, 100, 10, self.group)
        self.p2 = Property("Prop B", 3, 100, 10, self.group)
        self.alice = Player("Alice")
        self.bob = Player("Bob")

    def test_all_owned_by_none(self):
        assert self.group.all_owned_by(None) is False

    def test_all_owned_by_partial(self):
        # one of two properties owned should not count as full ownership
        self.p1.owner = self.alice
        self.p2.owner = None
        assert self.group.all_owned_by(self.alice) is False

    def test_all_owned_by_full(self):
        self.p1.owner = self.alice
        self.p2.owner = self.alice
        assert self.group.all_owned_by(self.alice) is True

    def test_all_owned_by_split(self):
        self.p1.owner = self.alice
        self.p2.owner = self.bob
        assert self.group.all_owned_by(self.alice) is False
        assert self.group.all_owned_by(self.bob) is False

    def test_size(self):
        assert self.group.size() == 2

    def test_get_owner_counts(self):
        self.p1.owner = self.alice
        self.p2.owner = self.alice
        counts = self.group.get_owner_counts()
        assert counts[self.alice] == 2


class TestBoard:

    def setup_method(self):
        self.board = Board()

    def test_get_property_at_valid(self):
        prop = self.board.get_property_at(1)
        assert prop is not None
        assert prop.name == "Mediterranean Avenue"

    def test_get_property_at_empty(self):
        assert self.board.get_property_at(0) is None

    def test_tile_type_go(self):
        assert self.board.get_tile_type(0) == "go"

    def test_tile_type_jail(self):
        assert self.board.get_tile_type(JAIL_POSITION) == "jail"

    def test_tile_type_go_to_jail(self):
        assert self.board.get_tile_type(30) == "go_to_jail"

    def test_tile_type_free_parking(self):
        assert self.board.get_tile_type(20) == "free_parking"

    def test_tile_type_income_tax(self):
        assert self.board.get_tile_type(4) == "income_tax"

    def test_tile_type_luxury_tax(self):
        assert self.board.get_tile_type(38) == "luxury_tax"

    def test_tile_type_chance(self):
        assert self.board.get_tile_type(7) == "chance"

    def test_tile_type_community_chest(self):
        assert self.board.get_tile_type(2) == "community_chest"

    def test_tile_type_railroad(self):
        assert self.board.get_tile_type(5) == "railroad"

    def test_tile_type_property(self):
        assert self.board.get_tile_type(1) == "property"

    def test_is_purchasable_unowned(self):
        assert self.board.is_purchasable(1) is True

    def test_is_purchasable_owned(self):
        prop = self.board.get_property_at(1)
        prop.owner = Player("Alice")
        assert self.board.is_purchasable(1) is False

    def test_is_purchasable_mortgaged(self):
        prop = self.board.get_property_at(1)
        prop.is_mortgaged = True
        assert self.board.is_purchasable(1) is False

    def test_is_purchasable_non_property(self):
        assert self.board.is_purchasable(0) is False

    def test_properties_owned_by(self):
        alice = Player("Alice")
        prop = self.board.get_property_at(1)
        prop.owner = alice
        owned = self.board.properties_owned_by(alice)
        assert prop in owned

    def test_all_unowned_initially(self):
        unowned = self.board.unowned_properties()
        assert len(unowned) == len(self.board.properties)


class TestCardDeck:

    def test_draw_returns_card(self):
        deck = CardDeck(CHANCE_CARDS)
        card = deck.draw()
        assert card is not None
        assert "description" in card
        assert "action" in card

    def test_draw_cycles(self):
        deck = CardDeck(CHANCE_CARDS)
        for _ in range(len(CHANCE_CARDS)):
            deck.draw()
        card = deck.draw()
        assert card == CHANCE_CARDS[0]

    def test_draw_empty_deck(self):
        deck = CardDeck([])
        assert deck.draw() is None

    def test_peek_does_not_advance(self):
        deck = CardDeck(CHANCE_CARDS)
        first = deck.peek()
        second = deck.peek()
        assert first == second

    def test_cards_remaining(self):
        deck = CardDeck(CHANCE_CARDS)
        total = len(CHANCE_CARDS)
        assert deck.cards_remaining() == total
        deck.draw()
        assert deck.cards_remaining() == total - 1

    def test_reshuffle_resets_index(self):
        deck = CardDeck(CHANCE_CARDS)
        deck.draw()
        deck.draw()
        deck.reshuffle()
        assert deck.index == 0


class TestGameBuyProperty:

    def setup_method(self):
        self.game = Game(["Alice", "Bob"])
        self.alice = self.game.players[0]
        self.prop = self.game.board.properties[0]

    def test_buy_success(self):
        self.alice.balance = 500
        result = self.game.buy_property(self.alice, self.prop)
        assert result is True
        assert self.prop.owner == self.alice

    def test_buy_exact_balance(self):
        # player with exactly the property price should be allowed to buy
        self.alice.balance = self.prop.price
        result = self.game.buy_property(self.alice, self.prop)
        assert result is True

    def test_buy_insufficient_funds(self):
        self.alice.balance = self.prop.price - 1
        result = self.game.buy_property(self.alice, self.prop)
        assert result is False
        assert self.prop.owner is None


class TestGamePayRent:

    def setup_method(self):
        self.game = Game(["Alice", "Bob"])
        self.alice = self.game.players[0]
        self.bob = self.game.players[1]
        self.prop = self.game.board.properties[0]
        self.prop.owner = self.bob

    def test_rent_deducted_from_renter(self):
        rent = self.prop.get_rent()
        before = self.alice.balance
        self.game.pay_rent(self.alice, self.prop)
        assert self.alice.balance == before - rent

    def test_rent_credited_to_owner(self):
        # the owner must actually receive the rent money
        rent = self.prop.get_rent()
        before = self.bob.balance
        self.game.pay_rent(self.alice, self.prop)
        assert self.bob.balance == before + rent

    def test_rent_mortgaged_property(self):
        # no money changes hands on a mortgaged property
        self.prop.is_mortgaged = True
        before_alice = self.alice.balance
        before_bob = self.bob.balance
        self.game.pay_rent(self.alice, self.prop)
        assert self.alice.balance == before_alice
        assert self.bob.balance == before_bob

    def test_rent_no_owner(self):
        self.prop.owner = None
        before = self.alice.balance
        self.game.pay_rent(self.alice, self.prop)
        assert self.alice.balance == before


class TestGameFindWinner:

    def test_richest_player_wins(self):
        game = Game(["Alice", "Bob"])
        game.players[0].balance = 500
        game.players[1].balance = 1500
        winner = game.find_winner()
        assert winner.name == "Bob"

    def test_no_players(self):
        game = Game(["Alice"])
        game.players.clear()
        assert game.find_winner() is None

    def test_single_player(self):
        game = Game(["Alice"])
        assert game.find_winner().name == "Alice"


class TestGameMortgage:

    def setup_method(self):
        self.game = Game(["Alice", "Bob"])
        self.alice = self.game.players[0]
        self.prop = self.game.board.properties[0]
        self.prop.owner = self.alice
        self.alice.add_property(self.prop)

    def test_mortgage_success(self):
        before = self.alice.balance
        payout = self.prop.mortgage_value
        result = self.game.mortgage_property(self.alice, self.prop)
        assert result is True
        assert self.alice.balance == before + payout
        assert self.prop.is_mortgaged is True

    def test_mortgage_not_owner(self):
        bob = self.game.players[1]
        result = self.game.mortgage_property(bob, self.prop)
        assert result is False

    def test_mortgage_already_mortgaged(self):
        self.prop.is_mortgaged = True
        result = self.game.mortgage_property(self.alice, self.prop)
        assert result is False

    def test_unmortgage_success(self):
        self.prop.is_mortgaged = True
        cost = int(self.prop.mortgage_value * 1.1)
        self.alice.balance = cost + 100
        before = self.alice.balance
        result = self.game.unmortgage_property(self.alice, self.prop)
        assert result is True
        assert self.alice.balance == before - cost
        assert self.prop.is_mortgaged is False

    def test_unmortgage_insufficient_funds(self):
        self.prop.is_mortgaged = True
        self.alice.balance = 1
        result = self.game.unmortgage_property(self.alice, self.prop)
        assert result is False

    def test_unmortgage_not_mortgaged(self):
        result = self.game.unmortgage_property(self.alice, self.prop)
        assert result is False


class TestGameTrade:

    def setup_method(self):
        self.game = Game(["Alice", "Bob"])
        self.alice = self.game.players[0]
        self.bob = self.game.players[1]
        self.prop = self.game.board.properties[0]
        self.prop.owner = self.alice
        self.alice.add_property(self.prop)

    def test_trade_success(self):
        self.bob.balance = 500
        result = self.game.trade(self.alice, self.bob, self.prop, 200)
        assert result is True
        assert self.prop.owner == self.bob
        assert self.prop in self.bob.properties
        assert self.prop not in self.alice.properties
        assert self.bob.balance == 300

    def test_trade_not_sellers_property(self):
        result = self.game.trade(self.bob, self.alice, self.prop, 0)
        assert result is False

    def test_trade_buyer_cant_afford(self):
        self.bob.balance = 10
        result = self.game.trade(self.alice, self.bob, self.prop, 100)
        assert result is False


class TestGameBankruptcy:

    def test_bankruptcy_removes_player(self):
        game = Game(["Alice", "Bob"])
        alice = game.players[0]
        alice.balance = -1
        game._check_bankruptcy(alice)
        assert alice not in game.players
        assert alice.is_eliminated is True

    def test_bankruptcy_releases_properties(self):
        game = Game(["Alice", "Bob"])
        alice = game.players[0]
        prop = game.board.properties[0]
        prop.owner = alice
        alice.add_property(prop)
        alice.balance = -1
        game._check_bankruptcy(alice)
        assert prop.owner is None
        assert prop.is_mortgaged is False

    def test_no_bankruptcy_with_money(self):
        game = Game(["Alice", "Bob"])
        alice = game.players[0]
        alice.balance = 100
        game._check_bankruptcy(alice)
        assert alice in game.players


class TestGameJailTurn:

    def setup_method(self):
        self.game = Game(["Alice", "Bob"])
        self.alice = self.game.players[0]
        self.alice.go_to_jail()

    def test_use_get_out_card(self):
        self.alice.get_out_of_jail_cards = 1
        with patch("moneypoly.ui.confirm", return_value=True):
            with patch.object(self.game.dice, "roll", return_value=6):
                with patch.object(self.game, "_move_and_resolve"):
                    self.game._handle_jail_turn(self.alice)
        assert self.alice.in_jail is False
        assert self.alice.get_out_of_jail_cards == 0

    def test_pay_fine_to_leave(self):
        self.alice.get_out_of_jail_cards = 0
        with patch("moneypoly.ui.confirm", return_value=True):
            with patch.object(self.game.dice, "roll", return_value=4):
                with patch.object(self.game, "_move_and_resolve"):
                    self.game._handle_jail_turn(self.alice)
        assert self.alice.in_jail is False

    def test_serve_turn_in_jail(self):
        self.alice.get_out_of_jail_cards = 0
        with patch("moneypoly.ui.confirm", return_value=False):
            self.game._handle_jail_turn(self.alice)
        assert self.alice.jail_turns == 1
        assert self.alice.in_jail is True

    def test_mandatory_release_after_3_turns(self):
        self.alice.get_out_of_jail_cards = 0
        self.alice.jail_turns = 2
        before = self.alice.balance
        with patch("moneypoly.ui.confirm", return_value=False):
            with patch.object(self.game.dice, "roll", return_value=4):
                with patch.object(self.game, "_move_and_resolve"):
                    self.game._handle_jail_turn(self.alice)
        assert self.alice.in_jail is False
        assert self.alice.balance == before - JAIL_FINE
