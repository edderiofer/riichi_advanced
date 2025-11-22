# Wright-Patterson Mah Jongg (2022)
This documentation file contains the rules of Wright-Patterson Mah Jongg (NMJL-style), as might be implemented in an online client like Riichi Advanced. Some rules for real-life play may be found in the official rulebook published by the Wright-Patterson Spouses' Club, with purchase details [here](https://wrightpattersonosc.org/mah-jongg.html).

Like [American Mah-Jongg (NMJL-style)](american.md), Wright-Patterson is a game of yakuman-hunting. However, Wright-Patterson Mah-Jongg is a much closer descendant of Chinese Classical.

---
## TL;DR summary for Wright-Patterson Mah Jongg players:

Here are differences between Riichi Advanced and real life/other mahjong clients:

- Riichi Advanced will not let you draw a tile when you shouldn't, or discard a tile when you shouldn't. If you ever have more or fewer tiles than you're supposed to, that's a bug, and you should report it on the [Issues page](https://github.com/EpicOrange/riichi_advanced/issues) or in the Discord.
- Riichi Advanced will not let you make an incorrect exposure (i.e. one that isn't a Chow/Pung/Kong) or Mah Jongg in error. It will, however, let you make exposures that would make your hand unwinnable.
- Riichi Advanced requires you to name what kind of exposure you're calling for (Chow/Pung/Kong).
- Once you have made an exposure, Riichi Advanced will not let you edit the tiles in that exposure.
- Riichi Advanced will not require you to name your discards.
- Discards in Riichi Advanced are arranged in order in front of each player. (It's **Riichi** Advanced, so everything is a Riichi variant.)
- Riichi Advanced will keep the Window of Opportunity for calling a discard open until each player who can call it decides whether to call it or pass.
- There are [some] buttons in the bottom left of the interface, used for automatic actions. See the **Auto-buttons in Riichi Advanced** section for more. <<TODO: add this section after you've implemented this variant>>
- Other differences listed in the "TODOS" section below:

---
## TODOS:

- Implement a way for a player to look at a blind-pass after they have selected which tiles to blind-pass.
- implement the rest of the game lol
- check anything that says <<TODO: check this>>

---
## Fundamentals

This ruleset assumes that you have read [base.md](base.md).

## Setup

The wall for Wright-Patterson consists of the 1-9 character tiles (Craks), 1-9 circle tiles (Dots), 1-9 bamboo tiles (Bams), the four wind tiles, the three dragon tiles, the four flower tiles, and the four season tiles.

Players each start with 10000 points.

During the setup phase, two dice are rolled by the dealer. Then, two more dice are rolled by the player whose seat is that number, and added to the first roll. Counting from the anticlockwise end of that player's wall (continuing onto the next wall if necessary) determines where the wall is broken. The wind of the player with the broken wall is now the Prevailing Wind. (If the two rolls total 18, the prevailing wind is that of the original player, not the player to their left.)

At the beginning of each round, you must declare all flowers/seasons in your hand before making any discards. This happens in an initial go-around before the first discard. If nobody declares any flowers, each player puts 50 points into the Flower Pot. The Flower Pot is collected by the first player who declares a flower after the end of the Charleston; it carries over between rounds.

If a player declares all four flowers or all four seasons, they are instantly paid 500 points by each other player. Those flowers/seasons are then immediately discarded, the flower replacement draw is made, and that player then discards a tile if applicable. (Note that East, who normally pays and receives double, does not do so here.)

## Charleston

After flowers are declared from the starting hand, players go through three rounds of passing tiles:
  - First pass: Each player passes three tiles from their hand to the player to their right.
  - Second pass: Each player passes three tiles from their hand to the player opposite.
  - Third pass: Each player passes three tiles from their hand to the player to their left. Optionally, a player may opt to Blind Pass.

Blind Pass: When a player blind-passes some tiles, they pass fewer than three tiles from their hand, and make up the rest of the three tiles to be passed with tiles that are about to be passed to them.
  - For instance, if a player opts to blind-pass a tile during the third pass, they may pass only two tiles from their hand to pass to their left, and a third tile to pass to their left, randomly chosen from the tiles about to be passed to them by the player to their right.
  - Players may look at all the tiles they are blind-passing, but only after they have passed them. <<TODO: implement this somehow.>>
  - In Riichi Advanced, East always passes first. (The official rulebook does not specify what is to happen when multiple people wish to blind-pass.)
  - Players may only draw tiles passed to them after they have passed three tiles themselves.
  - If everyone wishes to blind-pass a nonzero number of tiles, no pass occurs.

(NOTE: Unlike American Mah-Jongg: There are only three rounds of passes instead of seven. Players may see what tiles they have chosen to blind-pass. East may not declare Mah Jongg before the Charleston starts. If everyone wants to blind-pass, the entire pass is forfeited rather than players using the IOU protocol.)

## Gameplay

To win, you must achieve one of the ninety-two hands listed in the official rulebook. About half of these hands do not fit the "four sets and a pair" paradigm.

Chow and Mixed Chow may be declared, but this prohibits the player from winning with any hand other than a "Jewel Hand". (In particular, Mixed Chows may only be used in hand #36 "Gemstones".)

Open Kongs are placed with three tiles face-down and one face-up. Concealed Kongs are initially placed with four tiles face-down; if that player has a Pung of a suited tile, two of the tiles of that Concealed Kong are turned face-up. Added Kongs are placed with all four tiles face-up. Unlike other variants, declaring a concealed Kong opens your hand.

Robbing a Kong is allowed. However, the robbed player completes their Added Kong and must then discard a tile (which cannot be used by anyone).

Competing calls on the same discarded tile are resolved by priority; Mah Jongg takes priority over Kong/Pung/Chow/Mixed Chow, the latter four of which have the same priority; ties are resolved by the player next in turn order.

Upon drawing from the dead wall (also called the "Flower Wall"), the last tile of the live wall does not move into the dead wall. If the dead wall is ever empty, players continue drawing replacement tiles from the dead end of the live wall instead. The game ends when someone declares Mah Jongg, or after the last discard has been made and nobody wants it for any reason. In particular, players may still call for Mixed Chow/Chow/Pung/Kong on the last discard.

(NOTE: There is no official rule for what should happen if the dead wall is empty and the last tile is a flower. For Riichi Advanced, the player must declare the flower, draw zero tiles, and then discard a tile.)

## Game End

If a player declares Mah Jongg, they are paid the value of their hand by each player. Afterwards, the other three players each score their hand (see below), and each player pays each higher-scoring player the difference between their two hands' scores, up to the limit of 500 points. East always pays and receives double at the end of each round, and their limit is also doubled (to 1000 points).

If East wins immediately after the Charleston, or any player wins off East's first discard, they are paid Triple Limit.

If the round ends with nobody declaring Mah Jongg, each player puts 50 points into the Wall Pot. The Wall Pot carries over between rounds, and is collected by the next player who declares Mah Jongg. Hands are not scored.

Dealership passes only if someone other than East wins.

## Scoring For Non-Winner Hands

The scoring for non-winner hands in Wright-Patterson resembles Chinese Classical, or below-mangan scoring in Riichi.

First, count the number of points for each of the following groups of tiles:

* Pung of 2-8 tiles: 4 points each
* Pung of terminals/honors: 8 points each
* Kong of 2-8 tiles: 16 points each
* Kong of terminals/honors: 32 points each

* Pair of dragons, seat wind, or prevailing wind: 2 points each
* Flower not in a bouquet: 4 points each
* Any other tiles (e.g. Chows, mixed Chows, singles, pairs of other tiles): 0 points

For Pungs and Kongs, this point amount is halved if the Pung/Kong is open (formed via call). Note that a Concealed Kong is not considered open, and that concealed triplets and undeclared Kongs are all considered Concealed Pungs, even if a player is Ready for a hand that would group these tiles differently.

(A pair that is both seat wind and prevailing wind scores 4 points.)

If a hand totals 2 points at this stage, it instead scores 0.

Next, count the number of doubles (indented doubles do not stack):

* Own/Prevailing Flower, not in a bouquet: 1 double each
* Triplet of dragons, seat wind, or prevailing wind: 1 double each
* Little Three Dragons: 3 doubles
  - Big Three Dragons: 4 doubles
* Half-Flush: 1 double
  - Full Flush: 3 doubles
* Terminals and Honours: 1 double
  - All Honors: 3 doubles (does not stack with Half-Flush)
  - All Terminals: 3 doubles
* Three Concealed Pungs: 1 double
  - Four Concealed Pungs: 2 doubles
* Ready on Limit Hand: 1 double
  - Ready on Double Limit Hand: 2 doubles
    - Ready on Triple Limit Hand: 3 doubles
   
For the purposes of counting Three Concealed Pungs and Four Concealed Pungs, open Kongs count as Concealed Pungs.
   
Doubling the points that many times, then rounding up or down to the nearest 10, yields the score of that hand. (Note that East's double payment and double receipt, as well as limits, do not apply to the score of the hand, but to the payments, computed by the differences between scores.)

## Ending the game

On Riichi Advanced, the game ends after dealership has passed eight times. Any money left in the Flower or Wall Pots is split evenly between players. <<TODO: check this>>

## Yaku list

The list of yaku in Wright-Patterson Mah Jongg is not listed here. Sorry, we don't want to get copyright-struck.
