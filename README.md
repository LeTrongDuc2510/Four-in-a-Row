# Four-in-a-Row-Assembly
This project use the MARS version 4.5

Four in a row is a pretty classic game.
This is a 2-player game in a 7x6 grid.
Each turn a player puts a piece of his/her color inside a column and it will fall until reaches the lowest available spot.
The one who can put 4 pieces of the same color in a row horizontally, vertically or diagonally wins.
Each player has 3 times to undo their move (before the opponent's turn).

## How to play:
Input a number in the range 0-6 to drop your pieces.
At the end of your turn, hit 'Enter' to continue, else press 'u' to undo.

### Bit Map setting
Unit width in Pixels     : 1
Unit height in Pixels    : 1
Display width in Pixels  : 512
Display height in Pixels : 512
Base address for display : 0x10010000 (static data)


![alt text](https://https://github.com/LeTrongDuc2510/Four-in-a-Row/blob/main/display/bit-map-1.png?raw=true)
