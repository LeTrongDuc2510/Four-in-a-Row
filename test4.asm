.data
	frameBuffer: .space 0x80000 #512 wide x 256 high pixels
	m: .word 80
	n: .word 40
	yellow: .word 0x00FFFF00
.text
main: 	
	## clear the display in yellow
	la $t0, frameBuffer #load the frameBuffer address
	li $t1, 131072 #save 512 * 256 pixels 0x20000 = 131072
	lw $t2, yellow #load yellow color
L1:	sw $t2, 0($t0)
	addi $t0, $t0, 4 # move to the next position of the framBuffer array
	addi $t1, $t1, -1 #decrement the number of total pixels
	bne $t1, $zero, L1 #repeat till the number of total pixels bcomes zero
	##draw a cross
	##it centers it on the display
	li $a0, 0x000000FF #load blue color
	lw $a1, m #load size m
	lw $a2, n #load size n
	li $t0, 256 # load x center
	li $t1, 128 # load y center
	#check if m is even
	move $t2, $a1 #load m in t2
	andi $t2, $t2, 1 #check the lowest bit if it is one (if one means m is odd)
	beq $t2, $zero, skipm # branch to skipm if even
	addi $a1, $a1, 1 #add a1 by one a1 = m + 1 and is even
skipm:  
	#check n is even
	move $t2, $a2 # load n in t2
	andi $t2, $t2, 1 #check the lowest bit if it is one
	beq $t2, $zero, skipn #branch to skipn if even
	addi $a2, $a2, 1 #add a2 by one a2 = n + 1 and is even
skipn: 
	srl $t2, $a2, 1 #calculate n/2 and store in t2
##draw top bar
	sub $t3, $t1, $t2 #calculate y center - n/2
	sub $t3, $t3, $a1 # calculate top position = y center - n/2 - m
	bltz $t3, exit #if negative we can't draw
	sll $t3, $t3, 11 #multiply by 4*512 to get offset in y
	
	sub $t4,$t0, $t2 #calculate x center - n/2
	sll $t4, $t4, 2 #multiply by 4 to get offset in x
	
	add $t3, $t3, $t4 #add offset in x and y 
	la $t4, frameBuffer #load the address of frameBuffer
	add $t3, $t3, $t4 #get positon of the first pixel in row
	move $t4, $a1 # we will dram m rows
top_row:
	move $t5, $a2 #we will draw n columns
	move $t6, $t3 #save curent row start position
top_col:
	sw $a0, 0($t3) #put pixel in curent position
	addi $t3, $t3, 4 #go to the next pixel
	addi $t5, $t5, -1 #decrement the numbers of columns to draw
	bnez $t5, top_col #repeat till the number of columns is zero
	move $t3, $t6 # get the start of the row
	add $t3, $t3, 2048 #advance to next row
	addi $t4, $t4, -1 #deceremt number of rows to draw
	bnez $t4, top_row #repeat while number of rows is not zero
	
##draw bottom bar
	add $t3, $t1, $t2 #calculate the ycenter + n/2
	sll $t3, $t3, 11 #get offset in for y
	
	sub $t4, $t0, $t2 #calculate x center - n/2
	sll $t4, $t4, 2 #get offset for x
	
	add $t3, $t3, $t4 #add offset x and y
	la $t4, frameBuffer
	add $t3, $t3, $t4 #get to the first pixel position
	move $t4, $a1 #we will draw m rows
bot_row:	
	move $t5, $a2 #draw n columns
	move $t6, $t3 # save the position
bot_col:
	sw $a0, 0($t3)
	addi $t3, $t3, 4
	addi $t5, $t5, -1 #decrease the number of colums
	bnez $t5, bot_col
	move $t3, $t6
	addi $t3, $t3, 2048 # add to go to the start at next row
	addi $t4, $t4 ,-1
	bnez $t4, bot_row
	
##draw right bar
	add $t3, $t0, $t2 # add x center with n/2
	sll $t3, $t3, 2 # get offset of x
	sub $t4, $t1, $t2 #y cen - n/2
	sll $t4, $t4, 11
	add $t3, $t3, $t4 # add offet of x and y
	la $t4, frameBuffer
	add $t3, $t3, $t4 #position of the first pixel
	move $t5, $a2 #number of rows
right_row:
	#move $t6, $t3 # save the position at the begining each line
	move $t4, $a1 #number of columns
right_col:
	sw $a0, 0($t3)
	addi $t3, $t3, 4
	addi $t4, $t4, -1
	bnez $t4, right_col
	#move $t3, $t6
	addi $t3,$t3, 1728
	addi $t5, $t5, -1
	bnez $t5, right_row
	
	
	
	
	
		 
		 	 
		 	 	 
		 	 	 	 
exit: 	
	li $v0,10
	syscall	 
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
