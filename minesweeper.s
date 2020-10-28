# The following format is required for all submissions in CMPUT 229
#
# The following copyright notice does not apply to this file
# It is included here because it should be included in all
# solutions submitted by students.
#
#----------------------------------------------------------------
#
# CMPUT 229 Student Submission License
# Version 1.0
# Copyright 2017 <student name>
#
# Redistribution is forbidden in all circumstances. Use of this software
# without explicit authorization from the author is prohibited.
#
# This software was produced as a solution for an assignment in the course
# CMPUT 229 - Computer Organization and Architecture I at the University of
# Alberta, Canada. This solution is confidential and remains confidential
# after it is submitted for grading.
#
# Copying any part of this solution without including this copyright notice
# is illegal.
#
# If any portion of this software is included in a solution submitted for
# grading at an educational institution, the submitter will be subject to
# the sanctions for plagiarism at that institution.
#
# If this software is found in any public website or public repository, the
# person finding it is kindly requested to immediately report, including
# the URL or other repository locating information, to the following email
# address:
#
#          cmput229@ualberta.ca
#
#---------------------------------------------------------------
# Assignment:           4
# Due Date:             November 15, 2017
# Name:                 William Wong
# Unix ID:              wwong1
# Lecture Section:      A1
# Instructor:           Jose Amaral
# Lab Section:          D09 (Friday 1400 - 1650)
# Teaching Assistant:   Unknown
#---------------------------------------------------------------



#---------------------------------------------------------------
#			NOTES
# gameBoard tile representation
#  - this is how the tiles are stored in gameBoard
#	- bit 2: marked indicator
#	- bit 1: revealed indicator
#	- bit 0: bomb indicator
#
#
# GameStatus representation
#  - this is how the status of the game was represented
#	- bit 1: timerStart; if the timer started or not
#	- bit 0: gameEnded; if the game ended or not
#
#
# main function s0 representation
#  - the main function uses s0 to store its various indicators,
#	which other functions might use as well.
#	- bit 7: restart indicator; used if restart is required
#	- bit 6: quit indicator; used if quit is required
#	- bit 5: lose indicator; used when user loses
#	- bit 4: win indicator; used when user wins
#	- bit 3: reveal indicator; used when user reveals tile
#	- bit 2: mark indicator; used when user marks tile
#	- bit 1: cursor indicator; used when cursor is moved
#	- bit 0: timer indicator; used when timer needs update
#
#		END OF NOTES
#---------------------------------------------------------------


.data
#Characters used for the timer
timerchar:
    .asciiz "0","1","2","3","4","5","6","7","8","9"

#The timer
timer:
    .byte 1,2,0

#Total tiles of the game
totalTiles:
    .space 4

#Used to see if the game has ended
GameStatus:
    .byte 0

#Address of keyboardControl
keyboardControl:
    .word 0xffff0000

#Address of keyboardData
keyboardData:
    .word 0xffff0004

.text
#---------------------------------------------------------------
# The function finds the character used to represent the tile.
# It checks the tile in gameBoard and sees if it is a bomb. If
# it is not a bomb, then it checks the surrounding tiles and
# sees if they have bombs to find out how many bombs surrounding
# the tile.
#
# Inputs:
# a0: row of tile to find
# a1: column of tile to find
# gameRows: memory of number of rows in game
# gameCols: memory of number of columns in game
# gameBoard: memory of the tiles in the game and its indicators
#
# Register Usage:
# s0: amount of rows needed to find surronding tiles
# s1: amount of columns needed to find surronding tiles
# s2: amount of bombs surronding tile
# s3: amounr needed to decrement when finding surronding tiles
# t0: used for various instructions
# t1: used for various instructions
# a0: used to store row of tiles
# a1: used to store columns of tiles
# v0: stores value of function hasBomb which is called here
#
# Returns:
# v0: Returns the address of the character used to represent
#       the tile
#
#---------------------------------------------------------------
getTile:
    addi $sp $sp -28    #increment stack pointer
    sw $a0 0($sp)       #store a0 into stack
    sw $a1 4($sp)       #store a1 into stack
    sw $s0 8($sp)       #store s0 into stack
    sw $s1 12($sp)      #store s1 into stack
    sw $s2 16($sp)      #store s2 into stack
    sw $s3 20($sp)      #store s3 into stack
    sw $ra 24($sp)      #store ra into stack

    #get tile
    lw $t0 gameCols     #load gameCols to t0
    mul $t0 $a0 $t0     #t0 -> a0 * gameCols
    add $t0 $t0 $a1     #t0 -> t0 + a1
    la $t1 gameBoard    #load address of gameBoard to t1
    add $t1 $t1 $t0     #add t1 to address of gameBoard
    lb $t0 0($t1)       #load tile of row and column

    #check if flaged, unrevealed, or bombed
    andi $t1 $t0 0x4        #mask flaged indicator
    bne $t1 $0 flaged       #if flaged goto flaged
    andi $t1 $t0 0x2        #mask revealed indicator
    bne $t1 $0 unrevealed   #if not revealed goto unrevealed
    andi $t1 $t0 0x1        #mask bombed indicator
    bne $t1 $0 bombed       #if bombed goto bombed

    #this is when it is revealed and not a bomb
    #finds out how many bombs are surronding it
    li $s3 -3           #put 3 into s3
    addi $a0 $a0 -1     #a0 -> a0 - 1
    bgez $a0 zeroRow    #if a0 >= 0 goto zeroRow
        li $a0 0        #a0 -> 0
        li $s0 2        #s0 -> 2
        li $s3 -2       #s3 -> -2
        j doneRow       #jump to doneRow
    zeroRow:
    addi $s0 $a0 3      #s0 -> a0 + 3
    lw $t0 gameRows     #load gameRows to t0
    sub $t0 $t0 $s0     #t0 -> t0 - s0
    bgez $t0 doneRow    #if t0 >= 0 goto doneRow
        lw $s0 gameRows #load gameRows to s0
        li $s3 -2       #s3 -> -2
    doneRow:
    addi $a1 $a1 -1     #a1 -> a1 - 1
    bgez $a1 zeroCol    #if a1 >= 0 goto zeroCol
        li $a1 0        #a1 -> 0
        li $s1 2        #s2 -> 2
        j doneCol       #goto doneCol
    zeroCol:
    addi $s1 $a1 3      #s1 -> a1 + 3
    lw $t0 gameCols     #load gameCols to t0
    sub $t0 $t0 $s1     #t0 -> t0 - s1
    bgez $t0 doneCol    #if t0 >= 0 goto doneCol
        lw $s1 gameCols #load gameCols to s1
    doneCol:

    #getting character of tile if not bomb, mark, or unrevealed
    la $s2 has0                         #load address of has0 to s2
    checkBombLoop:
        jal hasBomb                     #call function hasBomb
        beq $v0 $0 hasNoBomb            #if result = 0 goto hasNoBomb
            addi $s2 $s2 2              #s2 -> s2 + 2
        hasNoBomb:
        addi $a0 $a0 1                  #a0 -> a0 + 1
        bne $a0 $s0 checkBombLoop       #if a0 != s0 goto checkBombLoop
            add $a0 $a0 $s3             #a0 -> a0 + s3
            addi $a1 $a1 1              #a1 -> a1 + 1
            bne $a1 $s1 checkBombLoop   #if a1 = s1 goto checkBombLoop
                move $v0 $s2            #move s2 to v0
                j endGetTile            #goto endGetTile

    #getting flagged character
    flaged:
        la $v0 marked   #load address of marked to v0
        j endGetTile    #goto endGetTile
    #getting unrevealed character
    unrevealed:
        la $v0 tile     #load address of tile to v0
        j endGetTile    #goto endGetTile
    #getting bombed character
    bombed:
        la $v0 bomb     #load address of bomb to v0
        j endGetTile    #goto endGetTile
    
    #end of function, finishing
    endGetTile:
        lw $a0 0($sp)   #load a0 from stack
        lw $a1 4($sp)   #load a1 from stack
        lw $s0 8($sp)   #load s0 from stack
        lw $s1 12($sp)  #load s1 from stack
        lw $s2 16($sp)  #load s2 from stack
        lw $s3 20($sp)  #load s3 from stack
        lw $ra 24($sp)  #load ra from stack
        addi $sp $sp 28 #decrement stack pointer
        jr $ra          #goto return address

#---------------------------------------------------------------
# The function finds out if the tile in the argument has a bomb
# or not.
#
# Inputs:
# a0: row of tile
# a1: column of tile
#
# Register Usage:
# t0: used to find index of tile
# t1: used to store gameBoard[tile]
# gameRows: memory of number of rows in game
# gameCols: memory of number of columns in game
#
# Returns:
# v0: 1 if there is a bomb, 0 if not
#
#---------------------------------------------------------------
hasBomb:
    #get tile
    lw $t0 gameCols     #t0 -> gameCols
    mul $t0 $a0 $t0     #t0 -> a0 * t0
    add $t0 $t0 $a1     #t0 -> t0 + a1
    la $t1 gameBoard    #load address of gameBoard to t1
    add $t1 $t1 $t0     #t1 -> t1 + t0
    lb $t1 0($t1)       #load gameBoard[tile] to t1
    
    #checks if this is a bomb
    andi $t1 $t1 0x1    #mask bomb indicator
    beq $t1 $0 noBomb   #if t1 = 0 goto noBomb
    li $v0 1            #v0 -> 1
    jr $ra              #goto return address

    noBomb:
        li $v0 0    #v0 -> 0
        jr $ra      #goto return address   

#---------------------------------------------------------------
# The function puts a bomb into the tile in the argument.
#
# Inputs:
# a0: row of tile to set
# a1: column of tile to set
# gameCols: memory of number of columns in game
# gameBoard: memory of tiles in game with their indicators
#
# Register Usage:
# t0: used to get tile index
# t1: used to store address of gameBoard
#
# Returns:
# N/A: sets the tile in argument to have a unrevealed bomb.
#
#---------------------------------------------------------------
setBomb:
    #get the tile from memory
    lw $t0 gameCols     #load gameCols to t0
    mul $t0 $a0 $t0     #t0 -> a0 * t0
    add $t0 $t0 $a1     #t0 -> t0 + a1
    la $t1 gameBoard    #load address of gameBoard to t1
    add $t1 $t1 $t0     #t1 -> t1 + t0
    lb $t0 0($t1)       #load gameBoard[tile] to t0

    #add the required indicators
    ori $t0 $t0 0x3     #put bomb and unrevealed indicator to t0
    sb $t0 0($t1)       #store t0 to gameBoard[tile]
    jr $ra              #goto return address

#---------------------------------------------------------------
# The function prints the tile specified in the argument and 
# puts it in the appropriate place.
#
# Inputs:
# a0: row of tile
# a1: column of tile
#
# Register Usage:
# a0: used to store arguments for getTile and printString
# a1: used to store arguments for getTile and printString
# a2: used to store arguments for getTile and printString
# v0: store the values of functions that are called
#
# Returns:
# N/A: prints the tile at the row and column specified in the
# 	argument.
#
#---------------------------------------------------------------
printTile:
    addi $sp $sp -12    #increment stack pointer
    sw $ra 0($sp)	    #store ra into stack
    sw $a0 4($sp)	    #store a0 into stack
    sw $a1 8($sp)	    #store a1 into stack

    #print the right character
    jal getTile		#call function getTile
    move $a2 $a1	#move a1 to a2
    move $a1 $a0	#move a0 to a1
    move $a0 $v0	#move v0 to a0
    jal printString	#call function printString

    lw $ra 0($sp)	#load ra from stack
    lw $a0 4($sp)	#load a0 from stack
    lw $a1 8($sp)	#load a1 from stack
    addi $sp $sp 12	#increment stack pointer
    jr $ra		    #goto return address

#---------------------------------------------------------------
# The function is where it handles the minesweeper game. This
# function loops around, handling various changes in the game
# until the user quits or restarts the game, in which case it
# ends and produces a value which tells other functions whether
# to end or make a new game.
#
# Inputs:
# gameRows: memory of number of rows in the game
# gameCols: memory of number of columns in the game
# gameBoard: memory of tiles in the game
# totalTiles: memory of number of tiles in the game
# totalBombs: memory of number of bombs in the game
# timer: memory of the timer
# keyboardControl: memory of address of keyboardControl
#
# Register Usage:
# t0: used for various purposes
# t1: used for various purposes
# t2: used for various purposes
# s0: used to store indicators, see Notes in top of script
# s1: used to store variables after call functions
# s2: used to store variables after call functions
# a0: used for arguments in various functions
# a1: used for arguments in various functions
# a2: used for arguments in various functions
# 12: used for interrupt handling
#
#
# Returns:
# v0: returns 1 if the user wants to restart, 0 if the user
# 	wants to quit.
#
#---------------------------------------------------------------
main:
    addi $sp $sp -16	#increment stack pointer
    sw $ra 0($sp)	    #store ra into stack
    sw $s0 4($sp)	    #store s0 into stack
    sw $s1 8($sp)	    #store s1 into stack
    sw $s2 12($sp)	    #store s2 into stack

    #get total tiles in game
    lw $t1 gameRows	    #load gameRows into t1
    lw $t2 gameCols 	#load gameCols into t2
    mul $t1 $t1 $t2	    #t1 -> t1*t2
    sw $t1 totalTiles	#store t1 to totalTiles

    #init Cursor
    jal updateCursor	#call updateCursor
    
    #enable interruptions
    mfc0 $t0 $12	    #move 12 to t0
    ori $t0 $t0 0x8801	#add bits 15,11, and 0 to t0
    mtc0 $t0 $12	    #move t0 to 12

    #calculate the timer for the game
    lw $t0 totalBombs	#load totalBombs to t0
    li $t1 888		    #t1 -> 888
    mul $t2 $t0 $t1	    #t2 -> t0*t1
    lw $t1 totalTiles	#load totalTiles to t1
    sub $t1 $t1 $t0     #t1 -> t1 - t0
    div $t2 $t1		    #t2/t1
    mflo $t0		    #move quotient to t0
    li $t1 5		    #t1 -> 5
    sub $t2 $t0 $t1	    #t2 -> t0 - t1
    bgez $t2 firstMax	#if t2 >= 0 goto firstMax
        move $s0 $t1	#move t1 to s0
        j calcMax	    #goto calcMax
    firstMax:
        move $s0 $t0	#move t0 to s0
    calcMax:
    li $t0 999		    #t0 -> 999
    sub $t1 $t0 $s0	    #t1 -> t0 - s0
    bgez $t1 firstMin	#if t1 >= 0 goto firstMin
        move $s0 $t0	#s0 -> t0
    firstMin:
    li $t1 100		#t1 -> 100
    div $s0 $t1		#s0/t1
    mflo $t0		#move quotient to t0
    mfhi $s0		#move remainder to s0
    la $t1 timer	#load address of timer to t1
    sb $t0 0($t1)	#store t0 to timer
    li $t2 10		#t2 -> 10
    div $s0 $t2		#s0/t2
    mflo $t0		#move quotient to t0
    mfhi $s0		#move remainder to s0
    sb $t0 1($t1)	#store t0 to timer[1]
    sb $s0 2($t1)	#store s0 to timer[2]
    li $s0 0x1	    #updateTimer indicator

    #enable keyboard interuptions
    lw $t0 keyboardControl	#load keyboardControl to t0
    lw $t1 0($t0)		    #load information of keyboardControl to t1
    ori $t1 $t1 0x2		    #add keyboard inturruption
    sw $t1 0($t0)		    #store t1 to keyboardControl

    #Loop of the game
    mainLoop:
        #update timer
        andi $t0 $s0 0x1	    #mask s0 for timer indicator
        bnez $t0 changeTimer	#if t0 != 0 goto changeTimer

        #update Cursor
        andi $t0 $s0 0x2	    #mask s0 for cursor indicator
        bnez $t0 changeCursor	#if t0 != 0 goto changeCursor

        #update marked
        andi $t0 $s0 0x4			        #mask s0 for mask indicator
        beqz $t0 changeMarkedSkip		    #if t0 = 0 goto changeMarkedSkip
            lw $t0 GameStatus			    #load GameStatus to t0
            andi $t0 $t0 0x1			    #mask t0 for endGame indicator
            bnez $t0 changeMarkedEndGame	#if t0 != 0 goto changeMarkedEndGame
            lw $a0 cursorRow			    #load cursorRow to a0
            lw $a1 cursorCol			    #load cursorCol to a1
            jal changeMarked			    #call changeMarked
            changeMarkedEndGame:		
            addi $s0 $s0 -4			        #remove marked indicator
        changeMarkedSkip:

        #update revealed
        andi $t0 $s0 0x8			        #mask s0 for revealed indicator
        beqz $t0 changeRevealedSkip		    #if t0 = 0 goto changeRevealedSkip
            lw $t0 GameStatus			    #load GameStatus to t0
            andi $t0 $t0 0x1			    #mask t0 for endGame indicator
            bnez $t0 changeRevealedEndGame	#if t0 != 0 goto changeRevealedEndGame
            lw $a0 cursorRow			    #load cursorRow to a0
            lw $a1 cursorCol			    #load cursorCol to a1
            jal changeRevealed			    #call changeRevealed
            changeRevealedEndGame:
            addi $s0 $s0 -8			        #remove revealed indicator
        changeRevealedSkip:

        #check if won/lost
        andi $t0 $s0 0x10	#mask s0 for won indicator
        bnez $t0 changeWin	#if t0 != 0 goto changeWin
        andi $t0 $s0 0x20	#mask s0 for lose indicator
        bnez $t0 changeLose	#if t0 !=0 goto changeLose

	#check if quit
        andi $t0 $s0 0x40	#mask s0 for quit indicator
        bnez $t0 changeQuit	#if t0 != 0 goto changeQuit

	#check if restart
        andi $t0 $s0 0x80	    #mask s0 for restart indicator
        bnez $t0 changeRestart	#if t0 != 0 goto changeRestart

        j mainLoop	#goto mainLoop

    #changes the timer for display
    changeTimer:
        la $s1 timer	#load address of timer to s1
        li $a2 0	    #a2 -> 0
        li $s2 3	    #s2 -> 3

        timerLoop:
            lb $t1 0($s1)		    #load timer[index] to t1
            sll $t1 $t1 1		    #t1 << 1
            la $a0 timerchar	    #load timerchar address to a0
            add $a0 $a0 $t1		    #a0 -> a0 + t1
            lb $t1 0($a0)		    #load timerchar[index] to t1
            lw $a1 gameRows		    #load gameRows to a1
            jal printString		    #call printString
            addi $a2 $a2 1		    #a2 -> a2 + 1
            addi $s1 $s1 1		    #s1 -> s1 + 1
            bne $a2 $s2 timerLoop	#if a2 != s2 goto timerLoop
        addi $s0 $s0 -1			    #remove timer indicator
        j mainLoop			        #goto mainLoop

    #changes the cursor
    changeCursor:
        jal updateCursor	#call updateCursor
        addi $s0 $s0 -2		#remove cursor indicator
        j mainLoop		    #goto mainLoop

    #changes the timer to You WIN!
    changeWin:
        la $a0 gameWon		#load gameWon address to a0
        lw $a1 gameRows		#load gameRows to a1
        li $a2 0		    #a2 -> 0
        jal printString		#call printString
        lw $t0 GameStatus	#load GameStatus to t0
        addi $t0 $t0 0x1	#add endGame indicator
        sw $t0 GameStatus	#store t0 to GameStatus
        addi $s0 $s0 -16	#remove win indicator
        j mainLoop		    #goto mainLoop

    #changes the timer to You LOSE!
    changeLose:
        la $a0 gameLost		#load gameLost address to a0
        lw $a1 gameRows		#load gameRows to a1
        li $a2 0		    #a2 -> 0
        jal printString		#call printString
        lw $t0 GameStatus	#load GameStatus to t0
        addi $t0 $t0 0x1	#add endGame indicator
        sw $t0 GameStatus	#store t0 to gameStatus
        addi $s0 $s0 -32	#remove lose indicator
        j mainLoop		    #goto mainLoop

    #quits the mainLoop and returns 0
    changeQuit:
        lw $ra 0($sp)	#load ra from stack
        lw $s0 4($sp)	#load s0 from stack
	    lw $s1 8($sp)	#load s1 from stack
	    lw $s2 12($sp)	#load s2 from stack
        addi $sp $sp 16	#decrement stack pointer
        li $v0 0	    #v0 -> 0
        jr $ra		    #goto return address

    #restarts the game, exiting mainLoop and returning 1
    changeRestart:
        li $t0 0		    #t0 -> 0
        sb $t0 GameStatus	#store t0 to GameStatus

        mfc0 $t0 $12		#move Status register to t0
        srl $t1 $t0 16		#t0 >> 16
        sll $t1 $t1 16		#t0 << 16
        andi $t1 $t1 0x77fe	#mask away bits 15, 11, and 0
        sll $t2 $t0 16		#t2 << 16
        srl $t2 $t2 16		#t2 >> 16
        add $t2 $t2 $t1		#t2 -> t2 + t1
        mtc0 $t2 $12		#move t2 to Status Register

        lw $ra 0($sp)	#load ra from stack
        lw $s0 4($sp)	#load s0 from stack
	    lw $s1 8($sp)	#load s1 from stack
	    lw $s2 12($sp)	#load s2 from stack
        addi $sp $sp 16	#decrement stack pointer
        li $v0 1        #v0 -> 1
        jr $ra          #goto return address

#---------------------------------------------------------------
# The function makes a tile in gameBoard marked. First it checks
# if the tile is not revealed yet. If it is revealed, do nothing,
# otherwise turn the marked indicator on or off based on its
# previous state. It then updates the tile to show the action.
#
# Inputs:
# a0: row of tile
# a1: column of tile
# gameCols: the amount of columns in the game, stored in memory
# gameBoard: the tiles in the game and its indicators, stored in
# 		memory
#
# Register Usage:
# t0: used to store the tile indicator information
# t1: used to store the address of gameBoard[tile]
# t2: used to check the tile
# 
#
# Returns:
# N/A: makes the tile specified in the argument marked if it was
# 	not marked, and vice versa.
#
#---------------------------------------------------------------        
changeMarked:
    addi $sp $sp -4	#increment stack pointer
    sw $ra 0($sp)	#store ra into stack

    #get tile
    lw $t0 gameCols	    #load gameCols into t0
    mul $t0 $a0 $t0	    #t0 -> t0*a0
    add $t0 $t0 $a1	    #t0 -> t0*a1
    la $t1 gameBoard	#load address of gameBoard to t1
    add $t1 $t1 $t0	    #t1 -> t1 + t0
    lb $t0 0($t1)	    #load gameBoard[tile] to t0

    #make marked/unmarked based on tile
    andi $t2 $t0 0x2		    #mask unrevealed indicator
    beqz $t2 changeMarkedEnd	#if unrevealed goto changeMarkedEnd
    andi $t2 $t0 0x4		    #mask marked indicator
    beqz $t2 makeMark		    #if marked indicator off goto makeMark
        addi $t0 $t0 -4		    #remove marked indicator
        sb $t0 0($t1)		    #store t0 to gameBoard[tile]
        j changeMarkedEnd	    #goto changeMarkedEnd
    makeMark:
        addi $t0 $t0 4		    #add marked indicator
        sb $t0 0($t1)		    #store t0 to gameBoard[tile]
    changeMarkedEnd:
    jal updateCursor		    #update the cursor

    lw $ra 0($sp)	#load ra from stack
    addi $sp $sp 4	#decrement stack pointer
    jr $ra		    #goto return address

#---------------------------------------------------------------
# The function reveals the tile in the argument. If it is
# already revealed, do nothing. If it is not revealed, make it
# revealed and check if it has a bomb. If it does have a bomb,
# it will activate the lose indicator. It also checks if the
# tile is marked. If it is marked, no nothing. Once it is
# revealed and there is no bomb, it checks if the tiles
# surrounding it also do not have bombs using the function
# getTile. If this is true, it also checks the tiles touching
# the original tiles edge, using recursion. It then updates
# gameBoard according to the changes.
#
# Inputs:
# a0: row of tile
# a1: column of tile
# gameCols: memory of number of columns in the game
# gameBoard: memory of tiles of the game and its indicators
# totalTiles: memory of number of tiles in the game
# totalBombs: memory of number of bombs in the game
#
# Register Usage:
# t0: used to check the tile
# t1: used to check the tile
# t2: used to check conditions
# s0: used for game indicators
# s1: used to store either a0 or a1
# a0: used for arguments of functions
# a1: used for arguments of functions
# v0: used to store values from functions
# 9: for the timer in coprocessor
# 11: for the timer in coprocessor
#
# Returns:
# N/A: reveals the tile specified in the argument. May reveal
# 	more than one tile.
#
#---------------------------------------------------------------
changeRevealed:
    addi $sp $sp -16	#increment stack pointer
    sw $ra 0($sp)	    #store ra into stack
    sw $s1 4($sp)	    #store s1 into stack
    sw $a0 8($sp)	    #store a0 into stack
    sw $a1 12($sp)	    #store a1 into stack

    #get tile
    lw $t0 gameCols	    #load gameCols to t0
    mul $t0 $a0 $t0	    #t0 -> t0*a0
    add $t0 $t0 $a1	    #t0 -> t0 + a1
    la $t1 gameBoard	#load address of gameBoard to t1
    add $t1 $t1 $t0	    #t1 -> t1 + t0
    lb $t0 0($t1)	    #load gameBoard[tile] to t0

    #check the tile
    andi $t2 $t0 0x4			        #check if marked
    bnez $t2 endChangeRevealed	        #if t2 != 0 goto endChangeRevealed
    andi $t2 $t0 0x2			        #check if revealed using t2
    beqz $t2 endChangeRevealed	        #if t2 = 0 goto endChangeRevealed
        addi $t0 $t0 -2			        #remove unrevealed indicator
        sb $t0 0($t1)			        #store t0 in gameBoard[tile]
        jal printTile			        #call function printTile
        jal getTile			            #call function getTile
        la $t0 bomb			            #load bomb address at t0
        beq $t0 $v0 explodeBomb	        #if t0 = v0 goto explodeBomb
        lw $t0 totalTiles		        #load totalTiles to t0
        addi $t0 $t0 -1			        #t0 -> t0 - 1
        lw $t1 totalBombs		        #load totalBombs at t1
        beq $t0 $t1 winGame		        #if t0 = t1 goto winGame
        sw $t0 totalTiles		        #store t0 to totalTiles
        la $t0 has0			            #load address of has0 to t0
        bne $t0 $v0 endChangeRevealed	#if t0 = v0 goto endChangeRevealed
            move $s1 $a0		        #move a0 to s1
            addi $a0 $s1 1		        #a0 -> s1 + 1
            lw $t0 gameRows		        #load gameRows to t0
            bne $t0 $a0 lastRow		    #if t0 != a0 goto LastRow
                addi $a0 $t0 -1		    #a0 -> t0 - 1
            lastRow:
            jal changeRevealed		    #recursive call changeRevealed
            move $a0 $s1		        #move s1 to a0

            move $s1 $a1		    #move a1 to s1
            addi $a1 $s1 1		    #a1 -> s1 + 1
            lw $t0 gameCols		    #load gameCols to t0
            bne $t0 $a1 lastCol		#if t0 != a1 goto lastCol
                addi $a1 $t0 -1		#a1 -> t0 - 1
            lastCol:	
            jal changeRevealed		#recursive call changeRevealed
            addi $a1 $s1 -1		    #a1 -> s1 - 1
            bgez $a1 firstCol		#if a1 >= 0 goto firstCol
                li $a1 0		    #a1 -> 0
            firstCol:		
            jal changeRevealed		#recursive call changeRevealed
            move $a1 $s1		    #a1 -> s1

            move $s1 $a0		#s1 -> a0
            addi $a0 $s1 -1		#a0 -> s1 -1
            bgez $a0 firstRow	#if a0 >= 0 goto firstRow
                li $a0 0		#a0 -> 0
            firstRow:		
            jal changeRevealed	#recursive call changeRevealed

            j endChangeRevealed	#goto endChangeRevealed

 	#do this when you reveal a bomb
        explodeBomb:
            addi $s0 $s0 0x20	#indicate that the player lost
            mfc0 $a0 $9			#a0 -> $9
            li $a0 0			#a0 -> 0
            mtc0 $a0 $11		#11 -> a0

            j endChangeRevealed	#goto endChangeRevealed
        
	#do this when the player wins the game
        winGame:
            addi $s0 $s0 0x10	#indicate that the player won
            mfc0 $a0 $9		    #a0 -> 9
            li $a0 0		    #a0 -> 0
            mtc0 $a0 $11	    #11 -> a0

    endChangeRevealed:
    lw $ra 0($sp)	#load ra from stack
    lw $s1 4($sp)	#load s1 from stack
    lw $a0 8($sp)	#load a0 from stack
    lw $a1 12($sp)	#load a1 from stack
    addi $sp $sp 16	#decrement stack pointer
    jr $ra		    #goto return address

#---------------------------------------------------------------
# The function sets the board to have all the tiles be unrevealed.
# This function is called in the beginning of a game.
#
# Inputs:
# gameBoard: an array of tiles with indicators of the state of the
# 		tile.
#
# Register Usage:
# t0: stores the address of gameBoard and its elements
# t1: stores the current index
# t2: stores the maximum index
# t3: stores the values of the tiles
#
# Returns:
# N/A: makes all the tiles in gameBoard unrevealed
#
#---------------------------------------------------------------    
prepareBoard:
    la $t0 gameBoard	#load gameBoard address to t0
    li $t1 0		    #load 0 to t1
    li $t2 800		    #load 800 to t2

    prepareLoop:
        lb $t3 0($t0)		    #load gameBoard[tile] to t3
        ori $t3 $t3 0x2		    #add unrevealed indicator
        sb $t3 0($t0)		    #save t3 to gameBoard[tile]
        addi $t1 $t1 1		    #t1 -> t1 + 1
        beq $t1 $t2 prepareExit	#if t1 = t2 goto prepareExit
        addi $t0 $t0 1		    #t0 -> t0 + 1
        j prepareLoop
    prepareExit:
    jr $ra			            #goto return address



.kdata
save0:
    .word 0
save1:
    .word 0

.ktext 0x80000180
#---------------------------------------------------------------
# The exception handler here handles timer interuptions and
# keyboard interruptions, then raises the appropriate
# indicator for the main function to handle changes
#
# Inputs:
# 13(Cause Register): used to find things out
# newCursorRow: used to update the cursor
# newCursorCol: used to update the cursor
# GameStatus: used to find the status of the game
# timer: used to measure time
# keyboardData: used to see the input from the keyboard
#
# Register Usage:
# k0: used for various purposes
# k1: used for various purposes
# a0: used for various purposes
# a1: used for various purposes
# 12(Status register): used to update which interuptions are
#   needed
# 13(Cause register): used to find which interuption was it
#
# Returns:
# N/A: updates GameStatus, $12, timer, or the indicators
#       depending on the interuption.
#
#---------------------------------------------------------------
    sw $a0 save0	#store a0 to save0
    sw $a1 save1	#store a1 to save1
    
    #check which interrupt is activated
    mfc0 $k0,$13		        #move Cause registers to k0
    srl $a0 $k0 15		        #a0 -> k0 >> 15
    andi $a0 $a0 0x1		    #mask bit 15
    bnez $a0 timerInterupt	    #if a0 != 0 goto timerInterrupt
    srl $a0 $k0 11		        #a0 -> k0 >> 11
    andi $a0 $a0 0x1		    #mask bit 11
    bnez $a0 keyboardInterupt	#if a0 != 0 goto keyboardInterrupt
    endKeyboardInterupt:

    #reset and start next exception
    endException:
    li $13 0		    #clear Cause register
    mfc0 $a0 $12	    #move Status register to a0
    ori $a0 $a0 0x8801	#add appropriate interruptions
    mtc0 $a0 $12	    #move a0 to Status register
    lw $a0 save0	    #load a0 from save0
    lw $a1 save1	    #load a1 from save1
    eret		        #goto return address error

    #decrement the timer
    timerInterupt:
        la $k1 timer				        #load address of timer to k1
        addi $k1 $k1 2				        #k1 -> k1 + 2
        timerExceptionLoop:			
            lb $a0 0($k1)			        #load timer[index] to a0
            bnez $a0 timerExceptionSkip		#if a0 != 0 goto timerExceptionSkip
                la $a1 timer			    #load address of timer to a1
                beq $k1 $a1 timerDone		#if k1 = a1 goto timerDone
                li $a0 9			        #a0 -> 9
                sb $a0 0($k1)			    #store a0 to timer[index]
                addi $k1 $k1 -1			    #k1 -> k1 - 1
                j timerExceptionLoop		#goto timerExceptionLoop
            timerExceptionSkip:
            addi $a0 $a0 -1			        #a0 -> a0 - 1
            sb $a0 0($k1)			        #store a0 to timer[index]

   	#reset timer inturuption
        ori $s0 $s0 1		#add timer indicator
        mfc0 $a0 $9		    #move 9 register to a0
        addi $a0 $a0 100	#a0 -> a0 + 100
        mtc0 $a0 $11		#move a0 to 9 register
        j endException		#goto endException

	#lose game if timer reaches 0
        timerDone:
            ori $s0 $s0 0x20	#add lose indicator
            mfc0 $a0 $9		    #move 9 register to a0
            li $a0 0		    #a0 -> 0
            mtc0 $a0 $11	    #move a0 to 9 register
            j endException	    #goto endException
    
    #check which key was pressed
    keyboardInterupt:
        lw  $k0, keyboardData	#load keyboardData address to k0
        lw  $a0, 0($k0)		    #load keyboardData to a0

        li $a1 0x35			        #a1 -> hex of “5”
        beq $a0 $a1 pressReveal		#if a0 = a1 goto pressReveal
        li $a1 0x37			        #a1 -> hex of “7”
        beq $a0 $a1 pressMarked 	#if a0 = a1 goto pressMarked

        li $a1 0x38			        #a1 -> hex of “8”
        beq $a0 $a1 pressUp		    #if a0 = a1 goto pressUp
        li $a1 0x32			        #a1 -> hex of “2”
        beq $a0 $a1 pressDown		#if a0 = a1 goto pressDown
        li $a1 0x34			        #a1 -> hex of “4”
        beq $a0 $a1 pressLeft		#if a0 = a1 goto pressLeft
        li $a1 0x36			        #a1 -> hex of “6”
        beq $a0 $a1 pressRight		#if a0 = a1 goto pressRight
        li $a1 0x71			        #a1 -> hex of “q”
        beq $a0 $a1 pressQuit		#if a0 = a1 goto pressQuit
        li $a1 0x72			        #a1 -> hex of “r”
        beq $a0 $a1 pressRestart	#if a0 = a1 goto pressRestart
        j endKeyboardInterupt		#goto endKeyboardInterupt

	#revealed is pressed
        pressReveal:
            lw $k0 GameStatus		#load GameStatus to k0
            andi $k0 $k0 0x2		#mask timerStart indicator
            bnez $k0 continueReveal	#if k0 != 0 goto continueReveal
                mfc0 $a0 $9		    #move 9 register to a0
                addi $a0 $a0 100	#a0 -> a0 + 100
                mtc0 $a0 $11		#move a0 to 11 register
                ori $k0 $k0 0x2	    #add timerStart indicator
                sw $k0 GameStatus	#load k0 to GameStatus
            continueReveal:
            addi $s0 $s0 0x8		#add revealed indicator
            j endKeyboardInterupt	#goto endKeyboardInterupt

	#marked is pressed
        pressMarked:
            lw $k0 GameStatus		#load GameStatus to k0
            andi $k0 $k0 0x2		#mask timerStart indicator
            bnez $k0 continueMarked	#if k0 != 0 goto continueKeyBoard
                mfc0 $a0 $9		    #move 9 register to a0
                addi $a0 $a0 100	#a0 -> a0 + 100
                mtc0 $a0 $11		#move a0 to 11 register
                ori $k0 $k0 0x2	    #add timerStart register
                sw $k0 GameStatus	#load k0 to GameStatus
            continueMarked:
            addi $s0 $s0 0x4		#add masked indicator
            j endKeyboardInterupt	#goto endKeyboardInterupt
        
	#quit is pressed
        pressQuit:
            addi $s0 $s0 0x40		#add quit indicator
            j endKeyboardInterupt	#goto endKeyboardInterupt

	#restart is pressed
        pressRestart:
            addi $s0 $s0 0x80		#add restart indicator
            j endKeyboardInterupt	#goto endKeyboardInterupt

	#up is pressed
        pressUp:
            lw $a0 newCursorRow		#load newCursorRow to a0
            addi $a0 $a0 -1		    #a0 -> a0 - 1
            bgez $a0 moveUp		    #if a0 >= 0 goto moveUp
                li $a0 0		    #a0 -> 0
            moveUp:		
            sw $a0 newCursorRow 	#store a0 into newCursorRow
            addi $s0 $s0 0x2		#add cursor indicator
            j endKeyboardInterupt	#goto endKeyboardInterupt
        
	#down is pressed
        pressDown:
            lw $a0 newCursorRow		#load newCursorRow to a0
            addi $a0 $a0 1		    #a0 -> a0 + 1
            lw $a1 gameRows		    #load gameRows to a1
            bne $a0 $a1 moveDown	#if a0 != a1 goto moveDown
                addi $a0 $a0 -1		#a0 -> a0 - 1
            moveDown:
            sw $a0 newCursorRow		#store a0 into newCursorRow
            addi $s0 $s0 0x2		#add cursor indicator
            j endKeyboardInterupt	#goto endKeyboardInterupt
        
	#left is pressed
        pressLeft:
            lw $a0 newCursorCol		#load newCursorCol
            addi $a0 $a0 -1		    #a0 -> a0 - 1
            bgez $a0 moveLeft		#if a0 >= 0 goto moveLeft
                li $a0 0		    #a0 -> 0
            moveLeft:		
            sw $a0 newCursorCol		#store a0 into newCursorCol
            addi $s0 $s0 0x2		#add cursor indicator
            j endKeyboardInterupt	#goto endKeyboardInterupt
        
	#right is pressed
        pressRight:
            lw $a0 newCursorCol		#load newCursorCol
            addi $a0 $a0 1		    #a0 -> a0 + 1
            lw $a1 gameCols		    #load gameCols to a1
            bne $a0 $a1 moveRight	#if a0 != a1 goto moveRight
                addi $a0 $a0 -1		#a0 -> a0 - 1
            moveRight:
            sw $a0 newCursorCol		#store a0 to newCursorCol
            addi $s0 $s0 0x2		#add cursor indicator
            j endKeyboardInterupt	#goto endKeyboardInterupt

        j endKeyboardInterupt	    #goto endKeyboardInterupt
