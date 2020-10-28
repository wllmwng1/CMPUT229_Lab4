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

.data
#gameBoard representation
#a - nothing
#b - marked
#c - revealed
#d - bomb presence

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
    lw $t0 gameCols     #load gameCols to t0
    mul $t0 $a0 $t0     #t0 -> a0 * t0
    add $t0 $t0 $a1     #t0 -> t0 + a1
    la $t1 gameBoard    #load address of gameBoard to t1
    add $t1 $t1 $t0     #t1 -> t1 + t0
    lb $t0 0($t1)       #load gameBoard[tile] to t0

    ori $t0 $t0 0x3     #put bomb and unrevealed indicator to t0
    sb $t0 0($t1)       #store t0 to gameBoard[tile]
    jr $ra              #goto return address

#---------------------------------------------------------------
# The function finds the liveliness of registers 4-25 ($a0 - $t9)
# through every function call given in the argument. The argument
# is a set of MIPS base instructions, with no pseudocode. It stops
# once it reaches the sentinel value 0xffffffff.
#
# Inputs:
#
#	a0: beginning address of the instructions being read
# allLiveRegs: an array of live registers for a function call
# liveRegs: the current function call's live registers
# deadStack: the stack of dead registers in a function call
#
# Register Usage:
# s0: stores the beginning address
# s1: stores the result index
# s2: stores the address of allLiveRegs
# s3: stores the address of liveRegs
# s4: stores the address of deadStack
# s5: stores the current address of instruction
# t0: used to get the instruction, and a constant
# t1: used to get conditions
# a1: used for gatherLiveRegs function
#
# Returns:
# v0: the address of the beginning of allLiveRegs, which has
#     the liveliness of the registers for each function call,
#     which ends with a sentinel value 0xffffffff
#
#---------------------------------------------------------------
printTile:
    #finish this forth
    #calls printString to printTile
    addi $sp $sp -12
    sw $ra 0($sp)
    sw $a0 4($sp)
    sw $a1 8($sp)
    jal getTile
    move $a2 $a1
    move $a1 $a0
    #start here

    move $a0 $v0
    jal printString
    lw $ra 0($sp)
    lw $a0 4($sp)
    lw $a1 8($sp)
    addi $sp $sp 12
    jr $ra

#---------------------------------------------------------------
# The function finds the liveliness of registers 4-25 ($a0 - $t9)
# through every function call given in the argument. The argument
# is a set of MIPS base instructions, with no pseudocode. It stops
# once it reaches the sentinel value 0xffffffff.
#
# Inputs:
#
#	a0: beginning address of the instructions being read
# allLiveRegs: an array of live registers for a function call
# liveRegs: the current function call's live registers
# deadStack: the stack of dead registers in a function call
#
# Register Usage:
# s0: stores the beginning address
# s1: stores the result index
# s2: stores the address of allLiveRegs
# s3: stores the address of liveRegs
# s4: stores the address of deadStack
# s5: stores the current address of instruction
# t0: used to get the instruction, and a constant
# t1: used to get conditions
# a1: used for gatherLiveRegs function
#
# Returns:
# v0: the address of the beginning of allLiveRegs, which has
#     the liveliness of the registers for each function call,
#     which ends with a sentinel value 0xffffffff
#
#---------------------------------------------------------------
main:
    addi $sp $sp -8
    sw $ra 0($sp)
    sw $s0 4($sp)

    lw $t1 gameRows
    lw $t2 gameCols
    mul $t1 $t1 $t2
    sw $t1 totalTiles

    #init Cursor
    jal updateCursor
    
    mfc0 $t0 $12
    ori $t0 $t0 0x8801
    mtc0 $t0 $12
    lw $t0 totalBombs
    li $t1 888
    mul $t2 $t0 $t1
    lw $t1 totalTiles
    sub $t1 $t1 $t0
    div $t2 $t1
    mflo $t0
    li $t1 5
    sub $t2 $t0 $t1
    bgez $t2 firstMax
        move $s0 $t1
        j calcMax
    firstMax:
        move $s0 $t0
    calcMax:
    li $t0 999
    sub $t1 $t0 $s0
    bgez $t1 firstMin
        move $s0 $t0
    firstMin:
    li $t1 100
    div $s0 $t1
    mflo $t0
    mfhi $s0
    la $t1 timer
    sb $t0 0($t1)
    li $t2 10
    div $s0 $t2
    mflo $t0
    mfhi $s0
    sb $t0 1($t1)
    sb $s0 2($t1)
    lw $t0 keyboardControl
    lw $t1 0($t0)
    ori $t1 $t1 0x2
    sw $t1 0($t0)
    #tell what needs to be updated
    li $s0 0x1
    #then enter loop
    mainLoop:
        #update timer
        andi $t0 $s0 0x1
        bnez $t0 changeTimer
        #update Cursor
        andi $t0 $s0 0x2
        bnez $t0 changeCursor
        #update marked
        andi $t0 $s0 0x4
        beqz $t0 changeMarkedSkip
            lw $t0 GameStatus
            andi $t0 $t0 0x1
            bnez $t0 changeMarkedEndGame
            lw $a0 cursorRow
            lw $a1 cursorCol
            jal changeMarked
            changeMarkedEndGame:
            addi $s0 $s0 -4
        changeMarkedSkip:
        #update revealed
        andi $t0 $s0 0x8
        beqz $t0 changeRevealedSkip
            lw $t0 GameStatus
            andi $t0 $t0 0x1
            bnez $t0 changeRevealedEndGame
            lw $a0 cursorRow
            lw $a1 cursorCol
            jal changeRevealed
            changeRevealedEndGame:
            addi $s0 $s0 -8
        changeRevealedSkip:
        #check if won/lost
        andi $t0 $s0 0x10
        bnez $t0 changeWin
        andi $t0 $s0 0x20
        bnez $t0 changeLose
        andi $t0 $s0 0x40
        bnez $t0 changeQuit
        andi $t0 $s0 0x80
        bnez $t0 changeRestart
        j mainLoop
    
    lw $ra 0($sp)
    lw $s0 4($sp)
    addi $sp $sp 8
    jr $ra

    changeTimer:
        la $s1 timer
        li $a2 0
        li $s2 3
        timerLoop:
           lb $t1 0($s1)
            sll $t1 $t1 1
            la $a0 timerchar
            add $a0 $a0 $t1
            lb $t1 0($a0)
            lw $a1 gameRows
            jal printString
            addi $a2 $a2 1
            addi $s1 $s1 1
            bne $a2 $s2 timerLoop
        addi $s0 $s0 -1
        j mainLoop

    changeCursor:
        jal updateCursor
        addi $s0 $s0 -2
        j mainLoop



    changeWin:
        la $a0 gameWon
        lw $a1 gameRows
        li $a2 0
        jal printString
        lw $t0 GameStatus
        addi $t0 $t0 0x1
        sw $t0 GameStatus
        addi $s0 $s0 -16
        j mainLoop

    changeLose:
        la $a0 gameLost
        lw $a1 gameRows
        li $a2 0
        jal printString
        lw $t0 GameStatus
        addi $t0 $t0 0x1
        sw $t0 GameStatus
        addi $s0 $s0 -32
        j mainLoop

    changeQuit:
        lw $ra 0($sp)
        lw $s0 4($sp)
        addi $sp $sp 8
        li $v0 0
        jr $ra

    changeRestart:
        li $t0 0
        sb $t0 GameStatus

        mfc0 $t0 $12
        srl $t1 $t0 16
        sll $t1 $t1 16
        andi $t1 $t1 0x77fe
        sll $t2 $t0 16
        srl $t2 $t2 16
        add $t2 $t2 $t1
        mtc0 $t2 $12

        lw $ra 0($sp)
        lw $s0 4($sp)
        addi $sp $sp 8
        li $v0 1
        jr $ra

#---------------------------------------------------------------
# The function finds the liveliness of registers 4-25 ($a0 - $t9)
# through every function call given in the argument. The argument
# is a set of MIPS base instructions, with no pseudocode. It stops
# once it reaches the sentinel value 0xffffffff.
#
# Inputs:
#
#	a0: beginning address of the instructions being read
# allLiveRegs: an array of live registers for a function call
# liveRegs: the current function call's live registers
# deadStack: the stack of dead registers in a function call
#
# Register Usage:
# s0: stores the beginning address
# s1: stores the result index
# s2: stores the address of allLiveRegs
# s3: stores the address of liveRegs
# s4: stores the address of deadStack
# s5: stores the current address of instruction
# t0: used to get the instruction, and a constant
# t1: used to get conditions
# a1: used for gatherLiveRegs function
#
# Returns:
# v0: the address of the beginning of allLiveRegs, which has
#     the liveliness of the registers for each function call,
#     which ends with a sentinel value 0xffffffff
#
#---------------------------------------------------------------        
changeMarked:
    addi $sp $sp -4
    sw $ra 0($sp)

    lw $t0 gameCols
    mul $t0 $a0 $t0
    add $t0 $t0 $a1
    la $t1 gameBoard
    add $t1 $t1 $t0
    lb $t0 0($t1)

    andi $t2 $t0 0x2
    beqz $t2 changeMarkedEnd
    andi $t2 $t0 0x4
    beqz $t2 makeMark
        addi $t0 $t0 -4
        sb $t0 0($t1)
        j changeMarkedEnd
    makeMark:
        addi $t0 $t0 4
        sb $t0 0($t1)
    changeMarkedEnd:
    jal updateCursor
    lw $ra 0($sp)
    addi $sp $sp 4
    jr $ra

#---------------------------------------------------------------
# The function finds the liveliness of registers 4-25 ($a0 - $t9)
# through every function call given in the argument. The argument
# is a set of MIPS base instructions, with no pseudocode. It stops
# once it reaches the sentinel value 0xffffffff.
#
# Inputs:
#
#	a0: beginning address of the instructions being read
# allLiveRegs: an array of live registers for a function call
# liveRegs: the current function call's live registers
# deadStack: the stack of dead registers in a function call
#
# Register Usage:
# s0: stores the beginning address
# s1: stores the result index
# s2: stores the address of allLiveRegs
# s3: stores the address of liveRegs
# s4: stores the address of deadStack
# s5: stores the current address of instruction
# t0: used to get the instruction, and a constant
# t1: used to get conditions
# a1: used for gatherLiveRegs function
#
# Returns:
# v0: the address of the beginning of allLiveRegs, which has
#     the liveliness of the registers for each function call,
#     which ends with a sentinel value 0xffffffff
#
#---------------------------------------------------------------
changeRevealed:
    #this is a recursive function
    #Arguments
    #a0 - row
    #a1 - column
    addi $sp $sp -16
    sw $ra 0($sp)
    sw $s1 4($sp)
    sw $a0 8($sp)
    sw $a1 12($sp)

    lw $t0 gameCols
    mul $t0 $a0 $t0
    add $t0 $t0 $a1
    la $t1 gameBoard
    add $t1 $t1 $t0
    lb $t0 0($t1)

    #check for marked
    andi $t2 $t0 0x4
    bnez $t2 endChangeRevealed
    #check for revealed
    andi $t2 $t0 0x2
    beqz $t2 endChangeRevealed
        addi $t0 $t0 -2
        sb $t0 0($t1)
        jal printTile
        jal getTile
        la $t0 bomb
        beq $t0 $v0 explodeBomb
        lw $t0 totalTiles
        addi $t0 $t0 -1
        lw $t1 totalBombs
        beq $t0 $t1 winGame
        sw $t0 totalTiles
        la $t0 has0
        bne $t0 $v0 endChangeRevealed
            move $s1 $a0
            addi $a0 $s1 1
            lw $t0 gameRows
            bne $t0 $a0 lastRow
                addi $a0 $t0 -1
            lastRow:
            jal changeRevealed
            move $a0 $s1

            move $s1 $a1
            addi $a1 $s1 1
            lw $t0 gameCols
            bne $t0 $a1 lastCol
                addi $a1 $t0 -1
            lastCol:
            jal changeRevealed
            addi $a1 $s1 -1
            bgez $a1 firstCol
                li $a1 0
            firstCol:
            jal changeRevealed
            move $a1 $s1

            move $s1 $a0
            addi $a0 $s1 -1
            bgez $a0 firstRow
                li $a0 0
            firstRow:
            jal changeRevealed

            j endChangeRevealed

        explodeBomb:
            addi $s0 $s0 0x20
            mfc0 $a0 $9
            li $a0 0
            mtc0 $a0 $11

            j endChangeRevealed
        
        winGame:
            addi $s0 $s0 0x10
            mfc0 $a0 $9
            li $a0 0
            mtc0 $a0 $11

    endChangeRevealed:
    lw $ra 0($sp)
    lw $s1 4($sp)
    lw $a0 8($sp)
    lw $a1 12($sp)
    addi $sp $sp 16
    jr $ra

#---------------------------------------------------------------
# The function finds the liveliness of registers 4-25 ($a0 - $t9)
# through every function call given in the argument. The argument
# is a set of MIPS base instructions, with no pseudocode. It stops
# once it reaches the sentinel value 0xffffffff.
#
# Inputs:
#
#	a0: beginning address of the instructions being read
# allLiveRegs: an array of live registers for a function call
# liveRegs: the current function call's live registers
# deadStack: the stack of dead registers in a function call
#
# Register Usage:
# s0: stores the beginning address
# s1: stores the result index
# s2: stores the address of allLiveRegs
# s3: stores the address of liveRegs
# s4: stores the address of deadStack
# s5: stores the current address of instruction
# t0: used to get the instruction, and a constant
# t1: used to get conditions
# a1: used for gatherLiveRegs function
#
# Returns:
# v0: the address of the beginning of allLiveRegs, which has
#     the liveliness of the registers for each function call,
#     which ends with a sentinel value 0xffffffff
#
#---------------------------------------------------------------    
prepareBoard:
    #finish this third, optional
    la $t0 gameBoard
    li $t1 0
    li $t2 800
    prepareLoop:
        lb $t3 0($t0)
        ori $t3 $t3 0x2
        sb $t3 0($t0)
        addi $t1 $t1 1
        beq $t1 $t2 prepareExit
        addi $t0 $t0 1
        j prepareLoop
    prepareExit:
    jr $ra

.kdata
save0:
    .word 0
save1:
    .word 0
regs:
    .space 40
nl:
    .asciiz "\n"
.ktext 0x80000180
#---------------------------------------------------------------
# The function finds the liveliness of registers 4-25 ($a0 - $t9)
# through every function call given in the argument. The argument
# is a set of MIPS base instructions, with no pseudocode. It stops
# once it reaches the sentinel value 0xffffffff.
#
# Inputs:
#
#	a0: beginning address of the instructions being read
# allLiveRegs: an array of live registers for a function call
# liveRegs: the current function call's live registers
# deadStack: the stack of dead registers in a function call
#
# Register Usage:
# s0: stores the beginning address
# s1: stores the result index
# s2: stores the address of allLiveRegs
# s3: stores the address of liveRegs
# s4: stores the address of deadStack
# s5: stores the current address of instruction
# t0: used to get the instruction, and a constant
# t1: used to get conditions
# a1: used for gatherLiveRegs function
#
# Returns:
# v0: the address of the beginning of allLiveRegs, which has
#     the liveliness of the registers for each function call,
#     which ends with a sentinel value 0xffffffff
#
#---------------------------------------------------------------
    sw $a0 save0
    sw $a1 save1
    
    mfc0 $k0,$13
    srl $a0 $k0 15
    andi $a0 $a0 0x1
    bnez $a0 timerInterupt
    srl $a0 $k0 11
    andi $a0 $a0 0x1
    bnez $a0 keyboardInterupt
    endKeyboardInterupt:

    endException:
    li $13 0
    mfc0 $a0 $12
    ori $a0 $a0 0x8801
    mtc0 $a0 $12
    lw $a0 save0
    lw $a1 save1
    eret

    timerInterupt:
        la $k1 timer
        addi $k1 $k1 2
        timerExceptionLoop:
            lb $a0 0($k1)
            bnez $a0 timerExceptionSkip
                la $a1 timer
                beq $k1 $a1 timerDone
                li $a0 9
                sb $a0 0($k1)
                addi $k1 $k1 -1
                j timerExceptionLoop
            timerExceptionSkip:
            addi $a0 $a0 -1
            sb $a0 0($k1)

        ori $s0 $s0 1
        mfc0 $a0 $9
        addi $a0 $a0 100
        mtc0 $a0 $11
        j endException

        timerDone:
            ori $s0 $s0 0x20
            mfc0 $a0 $9
            li $a0 0
            mtc0 $a0 $11
            j endException
    
    keyboardInterupt:  
        lw  $k0, keyboardData
        lw  $a0, 0($k0)

        li $a1 0x35
        beq $a0 $a1 pressReveal
        li $a1 0x37
        beq $a0 $a1 pressMarked
        li $a1 0x38

        beq $a0 $a1 pressUp
        li $a1 0x32
        beq $a0 $a1 pressDown
        li $a1 0x34
        beq $a0 $a1 pressLeft
        li $a1 0x36
        beq $a0 $a1 pressRight
        li $a1 0x71
        beq $a0 $a1 pressQuit
        li $a1 0x72
        beq $a0 $a1 pressRestart
        j endKeyboardInterupt

        pressReveal:
            lw $k0 GameStatus
            andi $k0 $k0 0x2
            bnez $k0 continueReveal
                mfc0 $a0 $9
                addi $a0 $a0 100
                mtc0 $a0 $11
                ori $k0 $k0 0x2
                sw $k0 GameStatus
            continueReveal:
            addi $s0 $s0 0x8
            j endKeyboardInterupt

        pressMarked:
            lw $k0 GameStatus
            andi $k0 $k0 0x2
            bnez $k0 continueMarked
                mfc0 $a0 $9
                addi $a0 $a0 100
                mtc0 $a0 $11
                ori $k0 $k0 0x2
                sw $k0 GameStatus
            continueMarked:
            addi $s0 $s0 0x4
            j endKeyboardInterupt
        
        pressQuit:
            addi $s0 $s0 0x40
            j endKeyboardInterupt

        pressRestart:
            addi $s0 $s0 0x80
            j endKeyboardInterupt

        pressUp:
            lw $a0 newCursorRow
            addi $a0 $a0 -1
            bgez $a0 moveUp
                li $a0 0
            moveUp:
            sw $a0 newCursorRow
            addi $s0 $s0 0x2
            j endKeyboardInterupt
        
        pressDown:
            lw $a0 newCursorRow
            addi $a0 $a0 1
            lw $a1 gameRows
            bne $a0 $a1 moveDown
                addi $a0 $a0 -1
            moveDown:
            sw $a0 newCursorRow
            addi $s0 $s0 0x2
            j endKeyboardInterupt
        
        pressLeft:
            lw $a0 newCursorCol
            addi $a0 $a0 -1
            bgez $a0 moveLeft
                li $a0 0
            moveLeft:
            sw $a0 newCursorCol
            addi $s0 $s0 0x2
            j endKeyboardInterupt
        
        pressRight:
            lw $a0 newCursorCol
            addi $a0 $a0 1
            lw $a1 gameCols
            bne $a0 $a1 moveRight
                addi $a0 $a0 -1
            moveRight:
            sw $a0 newCursorCol
            addi $s0 $s0 0x2
            j endKeyboardInterupt

        j endKeyboardInterupt
