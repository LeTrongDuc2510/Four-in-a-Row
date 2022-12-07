
# Author: Duc Trong Le

           ###############################################################
           ### 			BITMAP SETTINGS			       ###	
           ###							       ###
           ###	Unit Width in pixels: 1 			       ###
           ###	Unit Heigh in Pixels: 1				       ###
           ###	Display Width in Pixels: 512			       ###
           ###	Display Height in Pixels: 512  			       ###
           ###	Base address for display 0x10010000 (static data)      ###
           ###							       ###	
           ###############################################################


.data
	frameBuffer: .space 0x100000
	blue:        .word 0x004158ab
	red:         .word 0x00d5423f
	yellow:      .word 0x00ead700
	white:	     .word 0x00f4f4f4
	n:	     .word 56 #length of each square
	ver_margin:  .word 53
	hori_margin: .word 18
	dist:        .word 14
	
	arr1:	     .space 168  # store data of the first player
	arr2: 	     .space 168  # store data of the second player
	
	space:       .asciiz " "
	endl:	     .asciiz "\n"
	str1:        .asciiz "\nPlayer 1's turn: " 
	str2:        .asciiz "\nPlayer 2's turn: "
	str3: 	     .asciiz "Input 9 to undo\n"
	str4: 	     .asciiz "Please seclect the color for the first player\nto begin (1 of red and 0 for yellow) : "
	str5:        .asciiz "Game over !"
	str6:        .asciiz "Player 1 wins !\n"
	str7:        .asciiz "Player 2 wins !\n"
	str8:	     .asciiz "Press 'Enter' to continue;'u' to undo?"
	str9:	     .asciiz "Choose the color to begin (0 for yellow and 1 for red): "
	str10:       .asciiz "Player 1's turns of undo left: "
	str11:       .asciiz "Player 2's turns of undo left: "
	str12:       .asciiz "Player 1's mistakes: "
	str13:       .asciiz "Player 2's mistakes: "
	str14:       .asciiz "Invalid move !\n"
	str15:       .asciiz "Draw ! \nGame over !"
	str16:       .asciiz "Player 1 go first !\n"
	str17:       .asciiz "Player 2 go first !\n"
	
	intro1:	     .asciiz "                                                     Welcome to 4 IN A ROW\n"
	intro2:	     .asciiz "This is a 2-player game in a 7x6 grid.\n"
	intro3:	     .asciiz "Each turn a player puts a piece of his/her color inside a column and it reaches the lowest available spot.\n"
	intro4:	     .asciiz "The one who can put 4 pieces of the same color in a row horizontally, vertically or diagonally wins.\n"
	intro5:	     .asciiz "Each player has 3 times to undo their move (before the opponent's turn).\n"
	decor1:      .asciiz "--------------------------------------------------------------------------------------------------------------\n"
	law1:	     .asciiz "How to play:\nInput a number in the range 0-6 to drop your pieces.\n"
	law2:	     .asciiz "At the end of your turn, hit 'Enter' to continue, else press 'u' to undo.\n"

.text
main: 	
	#### PRINT OUT SOME INTODUCTION ####
	la $a0, intro1
	li $v0,4
	syscall
	la $a0, intro2
	syscall
	la $a0, intro3
	syscall
	la $a0, intro4
	syscall
	la $a0, intro5
	syscall
	la $a0, decor1 
	syscall
	#----------------------------------#
	### PRINT OUT SOME RULES ####
	la $a0, law1
	syscall
	la $a0, law2
	syscall
	la $a0, decor1 
	syscall
	#----------------------------------#

####### DRAW THE BEGIN MAP #########
	la $t0, frameBuffer 		# load the frameBuffer address
	li $t1, 262144 			# total 512*512 pixels
	lw $t2, blue 			# load blue color
L1:	
	sw $t2, 0($t0)
	addi $t0, $t0, 4 		# move to the next position of the framBuffer array
	addi $t1, $t1, -1 		# decrement the number of total pixels
	bne $t1, $zero, L1 		# repeat till the number of total pixels bcomes zero

	li $t0, 0
L2:
	li $t1, 0
L3:
	lw $a3, white 			# choose color
	jal Draw_square
	addi $t1, $t1, 1
	bne $t1, 6, L3
	# end inner loops, jump to outer loops
	addi $t0, $t0, 1
	bne $t0, 7, L2
	
##### SET ALL THE CELLS TO EMPTY (SET TO 0) #####

		# state 0: empty cell
		# state 1: has value
		# state -1: non-empty but can't insert
		
	li $t0, 0
L4:
	sw $zero, arr1($t0) 
	sw $zero, arr2($t0) 
	addi $t0, $t0, 4
	bne $t0, 168, L4

##### LET PLAYER CHOOSE THE CELLS #########
	
	li $s0, 0 			# s0 store the totals moves of both players 
	li $s2, 4 			# numbers undo times of first player (a1 = 0)
	li $s3, 4 			# number undo times of second player (a1 = 1)
	# s4 used to check condition
	li $s5, 3 			# number mistakes of first player (a1 = 0)
	li $s6, 3 			# number mistakes of second player (a1 = 1)
					
	jal Random_player		# random to select the begginers

	# select color
	la $a0, str9
	li $v0, 4
	syscall
	li $v0,5	 		# choose begin color
	syscall
	jal Check_color 		# if v0 == 1 choose red , v0 == 0 choose yellow
	
while:
	beq $s0, 60, exit  		# number of moves , please set again
	mul $s4, $s3, $s2 		# check if any players out of undo turns
	beqz $s4, exit
	mul $s4, $s5, $s6 		# check if any players the valid check has reach 3 times
	beqz $s4, exit
	jal Print_turn
	
	li $v0,5 			# let players input
	syscall
	move $a2, $v0 			# save the input in a2
	
	# check invalid input
	slti $s4, $a2, 0
	beq $s4, 1, L10
	sgt $s4, $a2, 6
	beq $s4, 1, L10

	jal Update_array
	move $t0, $a2 			# the y coordinate return move to $t0
	li $t1, 5
	sub $t1, $t1, $v0 		# need to sub cause the lowest level is 5
	slti $s4, $t1, 0
	beq $s4, 1, L10 		# handle full column but still input in
	jal Draw_square
	
	move $s1, $a2 			# save the move to do the undo
	la $a0, str8
	li $v0, 4
	syscall
	li $v0, 12
	syscall
	beq $v0, 'u', L7 		# check undo happens here

	jal Check_win_ver_1		# check if players_1 has won vertical
	beq $v1, 1, exit1
	
	jal Check_win_ver_2		# check if players_2 has won vertical
	beq $v1, 1, exit2
	
	jal Check_win_hori_1		# check if players_1 has won horizontal
	beq $v1, 1, exit1
	
	jal Check_win_hori_2 		# check if players_2 has won horizontal
	beq $v1, 1, exit2

	jal Check_win_diag_up_1 	# check if players_1 has won up diagonal
	beq $v1, 1, exit1
	
	jal Check_win_diag_up_2 	# check if players_2 has won up diagonal
	beq $v1, 1, exit2
	
	jal Check_win_diag_down_1	# check if players_1 has won down diagonal
	beq $v1, 1, exit1
	
	jal Check_win_diag_down_2	# check if players_2 has won down diagonal
	beq $v1, 1, exit2
	
	# check Draw
	jal Check_draw
	beq $v1,1, Draw_exit
	addi $s0, $s0, 1
	jal Update_turn
	jal Toggle_color
	la $a0, endl
	li $v0, 4
	syscall
	j while
	
L7:     # handling undo
	move $a2, $s1 			# store the undo to $a2
	move $s4, $a3 			# store the color
	jal Undo
	beqz $a1, L9 			#if a1 == 0 branch
	addi $s3, $s3, -1 		# reduced number of undo turns of player 2
	addi $s0, $s0, 1
	move $a3, $s4 			# load back the color
	# perfrom endline
	la $a0, endl
	li $v0, 4
	syscall
	j while
L9:	# handling undo
	addi $s2, $s2, -1 		# reduced number of undo turns of player 1
	addi $s0, $s0, 1
	move $a3, $s4 			# load back the color
	# perfrom endline
	la $a0, endl
	li $v0, 4
	syscall
	j while
	
L10:	# handle invalid
	la $a0, str14
	li $v0, 4
	syscall
	beqz $a1 , L11 			# if player 1 turn
	# handle player 2 mistake
	addi $s6, $s6, -1
	addi $s0, $s0, 1
	j while
L11: 	# handle player 1 mistake 
	addi $s5, $s5, -1
	addi $s0, $s0, 1
	j while
	
exit:
	beq $a1, 1, exit1 		# if player 2 turn
	# else player 1 turn 
	la $a0, str7 			# print out plyer 2 wins
	li $v0, 4
	syscall
	# print game over
	la $a0, str5
	li $v0, 4
	syscall
	# terminate program
	li $v0, 10
	syscall
	
exit1:  # if player 1 wins
	la $a0, str6
	li $v0, 4
	syscall
	# print game over
	la $a0, str5
	li $v0, 4
	syscall
	# terminate program
	li $v0, 10
	syscall
	
exit2:  # if player 2 wins
	la $a0, str7
	li $v0, 4
	syscall
	# print game over 
	la $a0, str5
	li $v0, 4
	syscall
	# terminate program
	li $v0, 10
	syscall

Draw_exit: # if draw
	la $a0, str15
	li $v0, 4
	syscall
	# terminate program
	li $v0, 10
	syscall
### RANDOMW CHOSE PLAYER ###
Random_player:
	li $a1, 2              		# set the upper bound
	li $v0, 42             		# choose the service random
	syscall
	move $a1, $a0          		# store random number for the begin player to a1
	beq $a1, 0, Player1 
	la $a0, str17          		# if randome number is 1 print out player 2 go first
	li $v0, 4
	syscall
	jr $ra
	
Player1:                       		# if randome number is 0 print out player 1 go first
	la $a0, str16
	li $v0, 4
	syscall
	jr $ra

### FUNCTION TO UPDATE THE ARRAY #### and also return the (x,y) coordinate to update
Update_array:	
	# a1 to check to update array arr1 or arr2
	# a2 is the number just input 
	li $t3 ,1 			# store the number one need to change
	li $t4 ,-1 			# store the number one need to change
	li $t5 ,0 			# to return the y coordinate
	mul $t0, $a2, 4
	beq $a1, 1, while2 		# if a1 == 1 branch to update arr 2

while1:	
	lw $t1, arr1($t0)
	beqz $t1, L5 			# if equal zero insert
	addi $t0, $t0, 28
	addi $t5, $t5, 1
	j while1
L5: 	
	sw $t3, arr1($t0)		# change that position in arr1 to 1
	sw $t4, arr2($t0) 		# change that position in arr2 to -1
	move $v0, $t5
	jr $ra

while2:	
	lw $t1, arr2($t0)
	beqz $t1, L6 			# if equal zero insert
	addi $t0, $t0, 28
	addi $t5, $t5, 1
	j while2
L6: 	
	sw $t3, arr2($t0) 		# change that position in arr2 to 1
	sw $t4, arr1($t0) 		# change that position in arr1 to -1
	move $v0, $t5
	jr $ra
	

#### UPDATE PLAYER TURN #####
Update_turn: #take a1 as the value to toggle
	beq $a1, 1, Toggle # if a1 == 1 branch to toggle
	li $a1, 1          # set a1 to 1
	jr $ra

Toggle: li $a1, 0      # set a1 to 0
	jr $ra
	
	
###Print Player Turn ####
Print_turn:
	beq $a1, 1, Turn_2 # if a1 == 1 player 2's turn
	# print how many undo turns left
	la $a0, str10
	li $v0, 4
	syscall
	move $a0, $s2
	addi $a0, $a0, -1 # minus 1 due to the original set is 4
	li $v0, 1
	syscall
	la $a0, endl
	li $v0, 4
	syscall
	
	# print how many mistakes
	la $a0, str12
	li $v0, 4
	syscall
	li $a0, 3
	sub $a0, $a0, $s5 # 3 - s5 (because we count mistake backwards)
	li $v0, 1
	syscall
	
	# print the input line
	la $a0, str1
	li $v0, 4
	syscall
	jr $ra
Turn_2:
	# print how many undo turns left
	la $a0, str11
	li $v0, 4
	syscall
	move $a0, $s3
	addi $a0, $a0, -1 # minus 1 due to the original set is 4
	li $v0, 1
	syscall
	la $a0, endl
	li $v0, 4
	syscall	
	
	# print how many mistakes
	la $a0, str13
	li $v0, 4
	syscall
	li $a0, 3
	sub $a0, $a0, $s6 # 3 - s5 (because we count mistake backwards)
	li $v0, 1
	syscall
	
	# print the input line	
	la $a0, str2
	li $v0, 4
	syscall
	jr $ra
### CHECK COLOR ###
Check_color:
	beq $v0, 1, To_red
	beq $v0, 0, To_yellow	
	
### Toggle color ###
Toggle_color:
	lw $t0, yellow
	lw $t1, red
	beq $a3, $t1, To_yellow
	beq $a3, $t0, To_red
To_yellow:
	lw $a3, yellow
	jr $ra
To_red: 
	lw $a3, red
	jr $ra

#### UNDO ####

Undo:  # take $a2 as the previous step
	li $t1, 7
	sub $t1, $t1, $a2 # traverse the array backwards
	mul $t0, $t1, 4
	li $t1, 168
	sub $t0, $t1, $t0
	li $t1, 0     # coordinate for y
	
while3:	
	lw $t2, arr1($t0)
	bnez $t2, L8
	addi $t0, $t0, -28
	addi $t1, $t1, 1
	j while3
L8: 	
	sw $zero, arr1($t0) # change that position in arr1 to 0
	sw $zero, arr2($t0) # change that position in arr2 to 0
	# draw again the square
	move $t0, $a2
	lw $a3, white
	move $a2, $ra # save the current return address
	jal Draw_square
	move $ra, $a2
	jr $ra

### CHECK WIN VERTICAL PLAYER 1####
# free to use t0 to t9
Check_win_ver_1:
	li $t1, 0 #loops seven columns
	li $t0, 0 
	li $t5, 0 # how many time to perform per column
while_verti_1:
	beq $t5, 3, return_ver_1
	li $t1, 0

while_verti_1.2:
	#li $t2, 0 # count up if cell equals 1
	beq $t1, 7, T5
	lw $t3, arr1($t0)
	beq $t3, 1, T1 # if arr[i][j] == 1
	# if arr[i][j] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_1.2
	
T1:	# check a[i][j+1] == 1
	addi $t4, $t0, 28
	lw $t3, arr1($t4)
	beq $t3, 1, T2
	# if arr[i][j+1] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_1.2
	
T2:	# check a[i][j+2] == 1
	addi $t4, $t4, 28
	lw $t3, arr1($t4)
	beq $t3, 1, T3
	# if arr[i][j+2] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_1.2
	
T3:	# check a[i][j+3] == 1
	addi $t4, $t4, 28
	lw $t3, arr1($t4)
	beq $t3, 1, T4
	# if arr[i][j+3] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_1.2
T4:     #if reach T4, means player 1 wins the game
	li $v1, 1
	jr $ra
T5:
	addi $t5, $t5, 1
	j while_verti_1
return_ver_1:
	li $v1, 0
	jr $ra

### CHECK WIN VERTICAL PLAYER 2 ####
# free to use t0 to t9

Check_win_ver_2:

	li $t0, 0
	li $t1, 0
	li $t5, 0 # how many time to perform per column
while_verti_2:
	beq $t5, 3, return_ver_2
	li $t1, 0
while_verti_2.2:
	#li $t2, 0 # count up if cell equals 1
	beq $t1, 7, A5
	lw $t3, arr2($t0)
	beq $t3, 1, A1 # if arr[i][j] == 1
	# if arr[i][j] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_2.2
	
A1:	# check a[i][j+1] == 1
	addi $t4, $t0, 28
	lw $t3, arr2($t4)
	beq $t3, 1, A2
	# if arr[i][j+1] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_2.2
	
A2:	# check a[i][j+2] == 1
	addi $t4, $t4, 28
	lw $t3, arr2($t4)
	beq $t3, 1, A3
	# if arr[i][j+2] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_2.2
	
A3:	# check a[i][j+3] == 1
	addi $t4, $t4, 28
	lw $t3, arr2($t4)
	beq $t3, 1, A4
	# if arr[i][j+3] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_2.2

A4:     #if reach A4, means players 2 wins the game
	li $v1, 1
	jr $ra
A5:
	addi $t5, $t5, 1
	j while_verti_2
return_ver_2:
	li $v1, 0
	jr $ra
#### CHECK WIN HORIZONTAL PLAYER 1####
Check_win_hori_1:
	li $t0, 0 # loop 4 columns
	li $t1, -12 # add for address
	li $t4, 0 # loop 6 rows
while_hori_1:
	beq $t4, 6, return_hori_1  #loop seven times
	li $t0, 0 # loop 4 columns
	addi $t1, $t1, 12 # advance to the next row
	
while_hori_1.2:
	beq $t0, 4, B5
	lw $t2, arr1($t1) #take the value of the cell
	beq $t2, 1, B1 #if a[i][j]==1
	addi $t0, $t0, 1
	addi $t1, $t1, 4
	j while_hori_1.2
	
B1:	addi $t3, $t1, 4 #advance to the next address
	lw $t2, arr1($t3) # take the value of the cell
	beq $t2, 1, B2 #if a[i+1][j]==1
	# else keep looping	
	addi $t0, $t0, 1
	addi $t1, $t1, 4
	j while_hori_1.2

B2:	
	addi $t3, $t3, 4 # advance to the next address
	lw $t2, arr1($t3) # take the value of the cell
	beq $t2, 1, B3 #if a[i+2][j]==1
	# else keep looping	
	addi $t0, $t0, 1
	addi $t1, $t1, 4
	j while_hori_1.2
	
B3: 	addi $t3, $t3, 4 # advance to the next address
	lw $t2, arr1($t3) # take the value of the cell
	beq $t2, 1, B4 #if a[i+3][j]==1
	# else keep looping	
	addi $t0, $t0, 1
	addi $t1, $t1, 4
	j while_hori_1.2
B4:	
	li $v1, 1
	jr $ra
B5:
	addi $t4, $t4, 1
	j while_hori_1
return_hori_1:
	li $v1, 0
	jr $ra
	

#### CHECK WIN HORIZONTAL PLAYER 2####
Check_win_hori_2:
	li $t0, 0 # loop 4 columns
	li $t1, -12 # add for address
	li $t4, 0 # loop 6 rows
	
while_hori_2:
	beq $t4, 6, return_hori_2  #loop seven times
	li $t0, 0 # loop 4 columns
	addi $t1, $t1, 12 # advance to the next row
	
while_hori_2.2:
	beq $t0, 4, C5
	lw $t2, arr2($t1) #take the value of the cell
	beq $t2, 1, C1 #if a[i][j]==1
	addi $t0, $t0, 1
	addi $t1, $t1, 4
	j while_hori_2.2
	
C1:	
	addi $t3, $t1, 4 #advance to the next address
	lw $t2, arr2($t3) # take the value of the cell
	beq $t2, 1, C2 #if a[i+1][j]==1
	# else keep looping	
	addi $t0, $t0, 1
	addi $t1, $t1, 4
	j while_hori_2.2

C2:	
	addi $t3, $t3, 4 # advance to the next address
	lw $t2, arr2($t3) # take the value of the cell
	beq $t2, 1, C3 #if a[i+2][j]==1
	# else keep looping	
	addi $t0, $t0, 1
	addi $t1, $t1, 4
	j while_hori_2.2
	
C3: 	
	addi $t3, $t3, 4 # advance to the next address
	lw $t2, arr2($t3) # take the value of the cell
	beq $t2, 1, C4 #if a[i+3][j]==1
	# else keep looping	
	addi $t0, $t0, 1
	addi $t1, $t1, 4
	j while_hori_2.2
C4:	
	li $v1, 1
	jr $ra
C5:
	addi $t4, $t4, 1
	j while_hori_2
	
return_hori_2:
	li $v1, 0
	jr $ra

#### CHECK UP DIAGONAL FOR PLAYER 1 ###
Check_win_diag_up_1:
	li $t0, 0
	li $t1, -12 #  to load address
	li $t4, 0

while_diag_up_1:
	beq $t4, 3, return_diag_up_1  #loop 3 rows
	li $t0, 0 # loop 4 columns
	addi $t1, $t1, 12 # advance to the next row
	
while_diag_up_1.2:
	beq $t0, 4, D5
	lw $t2, arr1($t1) # take the value of the cell
	beq $t2, 1, D1 # if a[i][j]==1
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_up_1.2
D1:	
	addi $t3, $t1, 32 #advance to the next address
	lw $t2, arr1($t3) # take the value of the cell
	beq $t2, 1, D2 #if a[i+1][j]==1
	# else keep looping	
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_up_1.2

D2:	
	addi $t3, $t3, 32 # advance to the next address
	lw $t2, arr1($t3) # take the value of the cell
	beq $t2, 1, D3 #if a[i+2][j]==1
	# else keep looping	
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_up_1.2
	
D3: 	
	addi $t3, $t3, 32 # advance to the next address
	lw $t2, arr1($t3) # take the value of the cell
	beq $t2, 1, D4 #if a[i+3][j]==1
	# else keep looping	
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_up_1.2
D4:	
	li $v1, 1
	jr $ra
D5:
	addi $t4, $t4, 1
	j while_diag_up_1
	
return_diag_up_1:
	li $v1, 0
	jr $ra

#### CHECK UP DIAGONAL FOR PLAYER 2 ###
Check_win_diag_up_2:
	li $t0, 0
	li $t1, -12 #  to load address
	li $t4, 0

while_diag_up_2:
	beq $t4, 3, return_diag_up_2  #loop 3 rows
	li $t0, 0 # loop 4 columns
	addi $t1, $t1, 12 # advance to the next row
	
while_diag_up_2.2:
	beq $t0, 4, E5
	lw $t2, arr2($t1) # take the value of the cell
	beq $t2, 1, E1 # if a[i][j]==1
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_up_2.2
E1:	
	addi $t3, $t1, 32 #advance to the next address
	lw $t2, arr2($t3) # take the value of the cell
	beq $t2, 1, E2 #if a[i+1][j]==1
	# else keep looping	
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_up_2.2

E2:	
	addi $t3, $t3, 32 # advance to the next address
	lw $t2, arr2($t3) # take the value of the cell
	beq $t2, 1, E3 #if a[i+2][j]==1
	# else keep looping	
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_up_2.2
	
E3: 	
	addi $t3, $t3, 32 # advance to the next address
	lw $t2, arr2($t3) # take the value of the cell
	beq $t2, 1, E4 #if a[i+3][j]==1
	# else keep looping	
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_up_2.2
E4:	
	li $v1, 1
	jr $ra
E5:
	addi $t4, $t4, 1
	j while_diag_up_2
	
return_diag_up_2:
	li $v1, 0
	jr $ra

#### CHECK DOWN DIAGONAL FOR PLAYER 1 ###
Check_win_diag_down_1:
	li $t0, 0
	li $t1, 0 #  to load address
	li $t4, 0

while_diag_down_1:
	beq $t4, 3, return_diag_down_1  #loop 3 rows
	li $t0, 0 # loop 4 columns
	addi $t1, $t1, 12 # advance to the next row
	
while_diag_down_1.2:
	beq $t0, 4, F5
	lw $t2, arr1($t1) # take the value of the cell
	beq $t2, 1, F1 # if a[i][j]==1
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_down_1.2
F1:	
	addi $t3, $t1, 24 #advance to the next address
	lw $t2, arr1($t3) # take the value of the cell
	beq $t2, 1, F2 #if a[i+1][j]==1
	# else keep looping	
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_down_1.2

F2:	
	addi $t3, $t3, 24 # advance to the next address
	lw $t2, arr1($t3) # take the value of the cell
	beq $t2, 1, F3 #if a[i+2][j]==1
	# else keep looping	
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_down_1.2
	
F3: 	
	addi $t3, $t3, 24 # advance to the next address
	lw $t2, arr1($t3) # take the value of the cell
	beq $t2, 1, F4 #if a[i+3][j]==1
	# else keep looping	
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_down_1.2
F4:	
	li $v1, 1
	jr $ra
F5:
	addi $t4, $t4, 1
	j while_diag_down_1
	
return_diag_down_1:
	li $v1, 0
	jr $ra

#### CHECK DOWN DIAGONAL FOR PLAYER 2 ###
Check_win_diag_down_2:
	li $t0, 0
	li $t1, 0 #  to load address
	li $t4, 0

while_diag_down_2:
	beq $t4, 3, return_diag_down_2  #loop 3 rows
	li $t0, 0 # loop 4 columns
	addi $t1, $t1, 12 # advance to the next row
	
while_diag_down_2.2:
	beq $t0, 4, H5
	lw $t2, arr2($t1) # take the value of the cell
	beq $t2, 1, H1 # if a[i][j]==1
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_down_2.2
H1:	
	addi $t3, $t1, 24 #advance to the next address
	lw $t2, arr2($t3) # take the value of the cell
	beq $t2, 1, H2 #if a[i-1][j+1]==1
	# else keep looping	
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_down_2.2

H2:	
	addi $t3, $t3, 24 # advance to the next address
	lw $t2, arr2($t3) # take the value of the cell
	beq $t2, 1, H3 #if a[i-2][j+2]==1
	# else keep looping	
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_down_2.2
	
H3: 	
	addi $t3, $t3, 24 # advance to the next address
	lw $t2, arr2($t3) # take the value of the cell
	beq $t2, 1, H4 #if a[i-3][j+3]==1
	# else keep looping	
	addi, $t0, $t0, 1
	addi $t1, $t1, 4
	j while_diag_down_2.2
H4:	
	li $v1, 1
	jr $ra
H5:
	addi $t4, $t4, 1
	j while_diag_down_2
	
return_diag_down_2:
	li $v1, 0
	jr $ra

### CHECK DRAW ###
Check_draw:
	li $t0, 0
Draw:	
	lw $t3, arr1($t0)
	beq $t3, 0, G1 # if there are a cell equal zero break (the array still not full)
	addi $t0, $t0, 4
	bne $t0, 168, Draw
	# if can loop through all the array means 42 cells of the array if full (return true)
	li $v1, 1
	jr $ra
G1:
	li $v1, 0
	jr $ra


#### DRAW THE SQUARE FUNCTION ####
Draw_square: # t0: x from 0 -> 6
	     # t1: y from 0 -> 5
	     # a3 to choose color
	# load all the needed constants
	lw $t2, n
	lw $t3, dist
	add $t3, $t3, $t2  # n + dist
	srl $t2, $t2, 1    # t2 = n/2
	lw $t4, hori_margin
	lw $t5, ver_margin
	
	# calculate x center
	mul $t6, $t0, $t3
	add $t6, $t6 ,$t4
	add $t6, $t6, $t2  # t6 store x center
	
	# calculate y center
	mul $t7, $t1, $t3
	add $t7, $t7, $t5
	add $t7, $t7, $t2  # t7 store y center
	
	lw $t2, n          # load edge to t3
	srl $t2, $t2, 1    # take n/2
	sub $t3, $t6, $t2
	sll $t3, $t3, 2    # take offset of x
	sub $t4, $t7, $t2
	sll $t4, $t4, 11   # take offset of y
	add $t3, $t3, $t4  # total offset of x and y
	la $t4, frameBuffer
	add $t3, $t3, $t4  # begining pixels
	lw $t5, n
top_row:
	lw $t4, n          # number of columns
	move $t6, $t3
top_col:
	sw $a3, 0($t3)
	addi $t3, $t3, 4
	addi $t4, $t4, -1
	bnez $t4, top_col
	move $t3, $t6
	addi $t3, $t3, 2048 #start a new line
	addi $t5, $t5, -1
	bnez $t5, top_row
	jr $ra
	