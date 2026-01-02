# Pussers Bones (aka Australian Navy Rules Mahjong)

This ruleset assumes that you have read [base.md](base.md). Unlike the official rules as written by Frank "Choco" Munday, this rules doc uses the standard "civvy" names for things (in alignment with all the other mahjong variants we feature). A translation table between Civvy Names and Pussers Names is given at the end of this document.

(If you are an active member of the Australian Navy, you may find that these rules are different from how you've been playing on Navy ships. We welcome all reports of incongruencies via the Issues page or the Discord.)

## TL;DR summary for Pussers Bones players:

Here are differences between Riichi Advanced and real life/other mahjong clients:

- Riichi Advanced will not let you draw a tile when you shouldn't, or discard a tile when you shouldn't. If you ever have more or fewer tiles than you're supposed to, that's a bug, and you should report it on the [Issues page](https://github.com/EpicOrange/riichi_advanced/issues) or in the Discord.
- Riichi Advanced will not let you win in error.
- Riichi Advanced requires you to name what kind of exposure you're calling for (Pung/Kong).
- Once you have made an exposure, Riichi Advanced will not let you edit the tiles in that exposure, even if you have not yet discarded.
- Riichi Advanced will not require you to name your discards.
- Discards in Riichi Advanced are arranged in order in front of each player. (It's **Riichi** Advanced, so everything is a Riichi variant.)
- Riichi Advanced will keep the Window of Opportunity for calling a discard open until each player who can call it decides whether to call it or pass.
- Multiple players calling on the same tile are resolved by turn order from the discarder.
- East (Eddie) doesn't get to pick where to break the wall; instead, the location of the break is determined by die roll as in Riichi. There is no penalty if East breaks into their own wall during the initial deal.
- The game ends after two rounds (eight dealership passes).
- Multiple claims on the same tile are resolved by turn order.
- There are <<TODO: NUMBER>> buttons in the bottom left of the interface, used for automatic actions. See the **Auto-buttons in Riichi Advanced** section for more.
- Other differences listed in the "TODOS" section below:

---
## TODOS:

- Await rules clarifications.
- Implement the variant lol
- Implement additional mods (e.g. Pussers Names, Shit Tie Up (aka Chombo)).

---

## Fundamentals

The wall for Pussers Bones consists of the 1-9 character tiles, 1-9 circle tiles, 1-9 bamboo tiles, the four wind tiles, the three dragon tiles, the four flower tiles, and the four season tiles.

To win, you must achieve one of the following:
  - Four sets and a pair (as usual) <<TODO: check if these must all be one suit plus honours>>
  - One of each terminal/honor tile, plus one extra (aka Thirteen Orphans, or "Moon")
  - 1~9 of a given suit, plus one of each wind, plus one extra wind (aka "Lizard"; if the extra wind is the player's seat wind, it's a "Big Lizard"; else it's a "Little Lizard").

and your hand must ALSO score at least 50 points. (See the Scoring section below.)

Note that sequences are not considered to be sets.

Declaring a Kong is mandatory, whether it is a Concealed, Added, or Open Kong.

When calling a tile for an exposure, the call is "Yes!". When declaring a win, the call is "Do Bone!".

There is no concept of a Prevailing Wind.

## Scoring

Like Chinese Classical, Pussers Bones is based off the "points and doubles" scoring system.

Points:
* Pung of 2-8 tiles: 4 points each
* Pung of terminals/honors: 8 points each
* Kong of 2-8 tiles: 16 points each
* Kong of terminals/honors: 32 points each

* Pair of dragons or seat wind: 2 points each
* Flower: 4 points each
* Any other tiles (e.g. Chows, mixed Chows, singles, pairs of other tiles): 0 points
* Winning: 20 points

For Pungs and Kongs, this point amount is halved if the Pung/Kong is open (formed via call).

Doubles (indented doubles do not stack):
- Being East: 1 double
- Triplet of dragons or seat wind: 1 double each
- Seat flower/season: 1 double each
- Winning by drawing the last tile or from a flower/kong replacement: 1 double
- Full Flush: 3 doubles <<TODO: check whether there exists a Half Flush double.>>
- Concealed Hand: 3 doubles

Hands with fixed scores:
- Majors (aka All Terminals And Honours): 3000
- 1s and 9s (aka All Terminals): 5000
- Winds and Dragons (aka All Honours): 5000
- Little Lizard: 2000
- Big Lizard: 3000
- Moon (aka Thirteen Orphans): 5000

Bonus points:
* One set of flowers: 2000 <<TODO: check when these are awarded>>
* Two sets of flowers: 5000
* First Flower (if there are no flowers on the initial deal): 1000 (awarded immediately)

Double the number of points in the winning hand, as many times as the winning hand has doubles. Round to the nearest 100. Each other player pays the winner this amount. Each other player then pays additional bonus points to the winner.

Unlike Chinese Classical, non-winners' hands are not scored.

## Ending the game

If the last tile of the wall is a flower, <<TODO: figure out how to resolve this>>

If the game ends in a draw, nobody's hands are scored.

Dealership passes if someone other than the dealer wins.

On Riichi Advanced, the game ends after two rounds (eight dealership passes).

---
## (WIP) Pussers Names

Civvy Name | Pussers Name
---|---
tile | bone
Numbered tiles | Minor Bones
Honours | Major Bones
Flowers | Pretties
East | Eddie / Eat Me
South | Sammy / Suck Me
West | Wally / Wank Me
North | Normie / Gnaw Me
White | Blanket
Green | Cabbage / Green Bone
Red | Blood
Characters (suit) | Ricks
Circles (suit) | Balls
Bamboos (suit) | Sticks
pair | Double-Up
triplet | Pair
kong | All-of


## Acknowledgements

This document would not have been possible without the copious help of Frank "Choco" Munday of [Hot Rod Handbooks](https://hotrodhandbooks.com.au/). In lieu of donating to us, please donate to him.
