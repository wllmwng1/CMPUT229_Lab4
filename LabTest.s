.data
tile:
	.asciiz "█"
marked:
	.asciiz "●"
has0:
	.asciiz " "
has1:
	.asciiz "1"
has2:
	.asciiz "2"
has3:
	.asciiz "3"
has4:
	.asciiz "4"
has5:
	.asciiz "5"
has6:
	.asciiz "6"
has7:
	.asciiz "7"
has8:
	.asciiz "8"
bomb:
	.asciiz "∅"
gameBoard:
	.align 2
	.space 800
gameRows:
	.space 4
gameCols:
	.space 4

.text
getTile:
    addi $sp $sp -4
    sw $ra 0($sp)

    la $t0 gameBoard    #load address of gameBoard
    la $t1 gameCols     #load address of gameCols
    lw $t1 0($t1)       #load gameCols
    mul $t1 $t1 $a0     #multiply gameCols by row of tile
    add $t1 $t1 $a1     #add col of tile to t1
    add $t0 $t0 $t1     #add t1 to address of gameBoard
    lb $t1 0($t0)       #load byte from gameBoard[f(row,column)]
    andi $t2 $t1 0x2
    beqz $t2 revealed
    andi $t2 $t1 0x4
    bnez $t2 mark
    la $v0 tile
    li $v1 0x1
    jr $ra

    mark:
        la $v0 marked
        li $v1 0x1
        lw $ra 0($sp)
        addi $sp $sp 4
        jr $ra

    revealed:
        jal hasBomb
        bnez $v0 revealedBomb
        addi $a0 $a0 -1
        addi $a1 $a1 -1
        li $t3 0
        addi $t4 $a0 3
        addi $t5 $a1 3
        checkBombLoopCol:
            checkBombLoopRow:
                jal hasBomb
                beqz $v0 skipBomb
                addi $t3 $t3 1
                skipBomb:
                    addi $a0 $a0 1
                    bne $a0 $t4 checkBombLoopRow
                addi $a0 $a0 -3
            addi $a1 $a1 1
            bne $a1 $t5 checkBombLoopCol
        la $v0 has0
        sll $t3 $t3 1
        add $v0 $v0 $t3
        li $v1 0x0
        lw $ra 0($sp)
        addi $sp $sp 4
        jr $ra

    revealedBomb:
        la $v0 bomb
        li $v1 0x0
        lw $ra 0($sp)
        addi $sp $sp 4
        jr $ra

hasBomb:
    la $t0 gameBoard    #load address of gameBoard
    la $t1 gameCols     #load address of gameCols
    lw $t1 0($t1)       #load gameCols
    mul $t1 $t1 $a0     #multiply gameCols by row of tile
    add $t1 $t1 $a1     #add col of tile to t1
    add $t0 $t0 $t1     #add t1 to address of gameBoard
    lb $t1 0($t0)       #load byte from gameBoard[f(row,column)]
    andi $t1 $t1 0x1    #mask first bit of byte
    move $v0 $t1        #move result to v0
    jr $ra              #return to address

setBomb:
    la $t0 gameBoard    #load address of gameBoard
    la $t1 gameCols     #load address of gameCols
    lw $t1 0($t1)       #load gameCols
    mul $t1 $t1 $a0     #multiply gameCols by row of tile
    add $t1 $t1 $a1     #add col of tile to t1
    add $t0 $t0 $t1     #add t1 to address of gameBoard
    li $t1 0x3          #get 000...0011 into t1
    sb $t1 0($t0)       #save 11 into gameBoard[(f(row,column))]
    jr $ra              #return to address

printTile:
    jal getTile
    move $a1 $a0
    move $a2 $a1
    move $a0 $v0
    jal printString
    jr $ra

main:
    li $t0 5
    la $t1 gameCols
    sw $t0 0($t1)
    li $a0 1
    li $a1 1
    jal getTile
    move $a0 $v0
    li $v0 4
    syscall
    la $t9 has0