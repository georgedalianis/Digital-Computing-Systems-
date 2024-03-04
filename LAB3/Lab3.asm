data
    buffer:     .space 100 #desmeuei stin mnimi 100 bytes 
    message:    .asciiz "Enter your Character:\n"
    finalMessage: .asciiz "\nThe given characters are:\n"
    changeL:    .asciiz "\n"

.text
main:
    li $t0, 0            # i topiki petabliti pou einai ston prosorino kataxoriti pernei timi = 0
    la $s0, buffer       # fortonei tin dieu8insi tou  buffer ston kataxwriti s0

inputLoop:
    li $v0, 4             # print message
    la $a0, message
    syscall

    li $v0, 12            # diabasma xaraktira
    syscall

    beq $v0, 64, printResult   # #if(strK[j]!='@'){} kai pigenei stin "sinartisi" printR se periptwsei pou to dosmeno string einai '@', ston kataxwriti v0 apothikeuontai oi xaraktires apo ton xristi

    sb $v0, 0($s0)        # apothikeuei to bytee tou kataxoriti
    addi $s0, $s0, 1      # auxanei to j kata 1
		

    li $v0, 4             # print allagi grammis
    la $a0, changeL
    syscall

    j inputLoop          # teleiwnei to loop

printResult:
    li $v0, 4             # print changel
    la $a0, changeL
    syscall

    li $v0, 4             # print  finalMessage
    la $a0, finalMessage
    syscall

    li $v0, 4             # #ektipwnei olo to buffer xrisimopoioume ton kataxwriti v0 kathws ekei mpainoun ta chars tou xristi, einai to apotelesma ths sunartisis tou inputLoop
    la $a0, buffer
    syscall

    li $v0, 10            # termatismos programmatos
    syscall