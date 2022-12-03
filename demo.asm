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
	str1:        .asciiz "Player 1's turn \nPlease input from 0 to 6: " 
	str2:        .asciiz "Player 2's turn \nPlease input from 0 to 6: "
	str3: 	     .asciiz "Input 9 to undo\n"
	str4: 	     .asciiz "Please seclect the color for the first player\nto begin (1 of red and 0 for yellow) : "
	str5:        .asciiz "Game over !"
	str6:        .asciiz "Player 1 wins !"
	str7:        .asciiz "Player 2 wins !"
	
	test: 	     .asciiz "Please seclect the player to begin : "
.text
main: 	
####### DRAW THE BEGIN MAP #########
	la $t0, frameBuffer #load the frameBuffer address
	li $t1, 262144 # total 512*512 pixels
	lw $t2, blue #load blue color
L1:	
	sw $t2, 0($t0)
	addi $t0, $t0, 4 # move to the next position of the framBuffer array
	addi $t1, $t1, -1 #decrement the number of total pixels
	bne $t1, $zero, L1 #repeat till the number of total pixels bcomes zero

	li $t0, 0
L2:
	li $t1, 0
L3:
	lw $a0, white #choose color
	jal Draw_square
	addi $t1, $t1, 1
	bne $t1, 6, L3
	#end inner loops, jump to outer loops
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
	
	li $s0, 0 #s0 store the totals moves of both players 
	li $s2, 4 # numbers undo times of first player (a1 = 0)
	li $s3, 4 # number undo times of second player (a1 = 1)
	
	# select the begginers
	la $a0, test # print the string
	li $v0 ,4
	syscall
	li $v0,5 # choose begin player
	syscall
	move $a1, $v0
	li $v0,1
	sub $a1, $v0, $a1
	

while:
	beq $s0, 42, exit  ####### number of moves , please set again
	mul $s4, $s3, $s2
	beqz $s4, exit
	jal Update_turn
	
	li $v0,5 # let players input
	syscall
	move $a2, $v0 # set the input parameter
	beq $a2, 9, L7 	# check condition happens here
	jal Update_array
	move $t0, $a2 # the y coordinate return move to $t0
	li $t1, 5
	sub $t1, $t1, $v0 # need to sub cause the lowest level is 5
	jal Draw_square
	# check if players_1 has won vertical
	jal Check_win_ver_1
	beq $v1, 1, exit1
	# check if players_2 has won vertical
	jal Check_win_ver_2
	beq $v1, 1, exit2
	
	move $s1, $a2 # save the move to do the undo
	addi $s0, $s0, 1
	j while
L7:
	move $a2, $s1 # store the undo to $a2
	jal Undo
	beqz $a1, L9 #if a1 == 0 branch
	addi $s3, $s3, -1 # reduced number of undo turns
	addi $s0, $s0, 1
	j while
L9:
	addi $s2, $s2, -1 # reduced number of undo turns
	addi $s0, $s0, 1
	j while
	
	
exit:

	la $a0, str5
	li $v0, 4
	syscall
	# terminate program
	li $v0, 10
	syscall
	
exit1:
	la $a0, str6
	li $v0, 4
	syscall
	# terminate program
	li $v0, 10
	syscall
	
exit2:
	la $a0, str7
	li $v0, 4
	syscall
	# terminate program
	li $v0, 10
	syscall


### FUNCTION TO UPDATE THE ARRAY #### and also return the (x,y) coordinate to update
Update_array:	
	# a1 to check to update array arr1 or arr2
	# a2 is the number just input 
	li $t3 ,1 # store the number one need to change
	li $t4 ,-1 # store the number one need to change
	li $t5 ,0 #to return the y coordinate
	mul $t0, $a2, 4
	beq $a1, 1, while2 # if a1 == 1 branch to update arr 2

while1:	
	lw $t1, arr1($t0)
	beqz $t1, L5
	addi $t0, $t0, 28
	addi $t5, $t5, 1
	j while1
L5: 	
	sw $t3, arr1($t0) # change that position in arr1 to 1
	sw $t4, arr2($t0) # change that position in arr2 to -1
	move $v0, $t5
	jr $ra
	
while2:	
	lw $t1, arr2($t0)
	beqz $t1, L6
	addi $t0, $t0, 28
	addi $t5, $t5, 1
	j while2
L6: 	
	sw $t3, arr2($t0) # change that position in arr2 to 1
	sw $t4, arr1($t0) # change that position in arr1 to -1
	move $v0, $t5
	jr $ra
	
#### UPDATE PLAYER TURN #####
Update_turn: #take a1 as the value to toggle
	beq $a1, 1, Toggle # if a1 == 1 branch to toggle
	li $a1, 1          # set a1 to 1
	la $a0, str1
	li $v0, 4
	syscall
	lw $a0, red	   # set again the color to red
	jr $ra

Toggle: li $a1, 0      # set a1 to 0
	la $a0, str2
	li $v0, 4
	syscall
	lw $a0, yellow     # set again the color to yellow
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
	lw $a0, white
	move $a2, $ra # save the current return address
	jal Draw_square
	move $ra, $a2
	jr $ra

### CHECK WIN VERTICAL PLYER 1####
# free to use t0 to t9

Check_win_ver_1:
	li $t0, 0
	li $t1, 0
while_verti_1:
	#li $t2, 0 # count up if cell equals 1
	beq $t1, 7, T5
	lw $t3, arr1($t0)
	beq $t3, 1, T1 # if arr[i][j] == 1
	# if arr[i][j] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_1
	
T1:	# check a[i][j+1] == 1
	#addi $t2, $t2, 1 # count ++
	addi $t4, $t0, 28
	lw $t3, arr1($t4)
	beq $t3, 1, T2
	# if arr[i][j+1] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_1
	
T2:	# check a[i][j+2] == 1
	#addi $t2, $t2, 1 # count ++
	addi $t4, $t4, 28
	lw $t3, arr1($t4)
	beq $t3, 1, T3
	# if arr[i][j+2] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_1
	
T3:	# check a[i][j+3] == 1
	#addi $t2, $t2, 1 # count ++
	addi $t4, $t4, 28
	lw $t3, arr1($t4)
	beq $t3, 1, T4
	# if arr[i][j+3] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_1

T4:     #if reach T4, means someone wins the game
	li $v1, 1
	jr $ra
T5:
	li $v1, 0
	jr $ra

### CHECK WIN VERTICAL PLYER 2 ####
# free to use t0 to t9

Check_win_ver_2:

	li $t0, 0
	li $t1, 0
while_verti_2:
	#li $t2, 0 # count up if cell equals 1
	beq $t1, 7, A5
	lw $t3, arr2($t0)
	beq $t3, 1, A1 # if arr[i][j] == 1
	# if arr[i][j] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_2
	
A1:	# check a[i][j+1] == 1
	#addi $t2, $t2, 1 # count ++
	addi $t4, $t0, 28
	lw $t3, arr2($t4)
	beq $t3, 1, A2
	# if arr[i][j+1] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_2
	
A2:	# check a[i][j+2] == 1
	#addi $t2, $t2, 1 # count ++
	addi $t4, $t4, 28
	lw $t3, arr2($t4)
	beq $t3, 1, A3
	# if arr[i][j+2] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_2
	
A3:	# check a[i][j+3] == 1
	#addi $t2, $t2, 1 # count ++
	addi $t4, $t4, 28
	lw $t3, arr2($t4)
	beq $t3, 1, A4
	# if arr[i][j+3] not equals 1 advance to the next cells
	addi $t0, $t0, 4 # advance to the next address
	addi $t1, $t1, 1 # count up the cells (cause check for 0 to 6)
	j while_verti_2

A4:     #if reach A4, means players 2 wins the game
	li $v1, 1
	jr $ra
A5:
	li $v1, 0
	jr $ra


#### DRAW THE SQUARE FUNCTION ####
Draw_square: # t0: x from 0 -> 6
	     # t1: y from 0 -> 5
	     # a0 to choose color
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
	sw $a0, 0($t3)
	addi $t3, $t3, 4
	addi $t4, $t4, -1
	bnez $t4, top_col
	move $t3, $t6
	addi $t3, $t3, 2048 #start a new line
	addi $t5, $t5, -1
	bnez $t5, top_row
	jr $ra
	
	
	
	
	
	
	
	
	
	
	 
	
	
	
