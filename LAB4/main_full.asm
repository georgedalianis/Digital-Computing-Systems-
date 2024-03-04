# s1 -> Address of request message
# s2 -> Address of the final message
# s3 -> Contains character '@' == 0x40
# s4 -> Contains number 4
# s5 -> Contains character '0'
# s6 -> Contains character '9'
# s7 -> Contains character 'z'
# s8 -> Contains characters 'a'/'Z'


.data
    buffer:     .space 100
    edited:     .space 100
    message:    .asciiz "\nEnter your Character: "
    finalMessage: .asciiz "\nThe given characters are:\n"

.text
main:
    
    jal init

    la $a0, buffer  # Argument 1 -> string address
    li $a1, 100     # Argument 2 -> string length (== 100)
    jal get_string
    # Catch return value in $v0 and put it as the third argument in the next function

    la $a0, buffer  # Arfument 1 -> string address input
    la $a1, edited  # Argument 2 -> string address output
    move $a2, $v0   # Argument 3 -> string length (The number of input characters we entered)
    jal process_string

    la $a0, edited  # Argument 1 -> string address output
    jal output_string

    li $v0, 10
    syscall

init:
    la $s1, message
    la $s2, finalMessage
    li $s3, 0x40
    li $s4, 4
    li $s5, 0x30
    li $s6, 0x39
    li $s7, 0x7A
    li $s8, 0x61

    jr $ra

# Arguments are stringn address in a0 and length in a1
get_string:
    move $t0, $a0   # Move from input register to temp register (string address)
    move $t1, $a1   # Same ... (string length == 100)

    # Count up to 100 characters (limit of string buffer)
    li $t2, 0   # Counting variable (up to 100)
    li $t4, 0   # Temp saving register for input characters
    li $t5, 0   # Counting variable (up to 4) for notifying memory write...
    li $t6, 4   # 4
    
    # Repeat until t2 == t1
    loop:
        addi $t2, 1     # Add 1 to t2 (counting register...)

        # Read character...
        li $v0, 4
        move $a0, $s1
        syscall
        li $v0, 12
        syscall

        # Input character is in register v0
        move $t3, $v0               # Copy character from v0 to t3 to process it...
        beq $t3, $s3, exit_loop     # If the input character is s3 (== '@') go to exit loop...
        beq $t2, $t1, exit_loop     # If the counting variable t2 is t1 (== 100) then there is no more space left and go to exit loop...

        # Otherwise
        or $t4, $t4, $t3            # Save character into t4
        addi $t5, 1                 # Increase counting variable by 1.

        # If 4 bytes are read, then write to memory...
        
        beq $t5, $t6, write_to_memory   # If 4 bytes are read, then write to memory the whole word.

        sll $t4, $t4, 8			        # $t4 = $t4 << 8
        j loop                          # Else repeat...

        write_to_memory:
            sw $t4, 0($t0)  # Write all 4 bytes using a single store word.
            addi $t0, 4     # Move to the next destination addres in memory.
            li $t4, 0       # Reset register t4 to 0
            li $t5, 0       # Reset counting register t5 to 0

        j loop              # Repeat...

    exit_loop:
        li $t6, 0
        bne $t5, $zero, final_memory_write          # If there is at least one byte left in the temp register t4, then write it down in the memory...
        addi $v0, $t2, -1                           # Return the number of bytes we read
        jr $ra                                      # Else exit function
        

        final_memory_write:
            srl $t4, $t4, 8			                # $t4 = $t4 >> 8        (undo from earlier...)
            sw $t4, 0($t0)                          # Write all 4 bytes using a single store word.

        addi $v0, $t2, -1                           # Return the number of bytes we read
        jr $ra                                      # Exit function...

# Arguments are input string address in a0, edited string address in a1 and string length in a2
process_string:

    move $t0, $a0
    move $t1, $a1
    move $t2, $a2
    
    li $t4, 0                   # This counts the number of bytes that we have read. (max 100)
    li $t7, 0                   # The number of valid characters we have read (max 4 -- then write to memory and reset)
    li $t8, 0                   # The temp register used to store the 4 bytes that will be written to memory

    generic_loop:
        # Load 4 bytes at a time using load word...
        lw $t3, 0($t0)

        li $t6, 1               # Mask counting variable (max 4)

        inner_mask_loop:
            lui $t5, 0xFF00
            and $t5, $t5, $t3
            srl $t5, $t5, 24

            process_character:

                blt $t5, $s5, discard       # If the character is less than 0x30 (aka char '0') then discard it
                blt $t5, $s3, check_below   # If the character is less than 0x40 (aka char '@') check if its grater than '9'
                
                bgt $t5, $s7, discard       # If the character is more than 0x7A (aka char 'z') then discard it

                li $s8, 0x61
                blt $t5, $s8, check_above   # If the character is less than 0x61 (aka char 'a') check if its grater than 'Z'
                j save_character
                
            discard:

            beq $t6, $s4, exit_inner_mask_loop
            addi $t6, 1
            sll $t3, $t3, 8
            j inner_mask_loop

        exit_inner_mask_loop:

        addi $t4, 4                             # Increase the number of bytes we have read by 4...
        bge $t4, $t2, exit_generic_loop         # If the number of bytes is >= than the string lenth (= 100) exit
        addi $t0, 4                             # Move to the next 4 bytes (string address)
        j generic_loop                          # Else repeat

    exit_generic_loop:

        bne $t7, $zero, final_edited_memory_write
        la $t5, edited
        sub $v0, $t1, $t5
        add $v0, $v0, $t7
        sub $v1, $t2, $v0
        jr $ra

        final_edited_memory_write:
            # Reuse already used tmep registers, since this is gonna be the last time...
            # Information is stored in register t8 and it needs to be stored in the memory. Hoever, we need to shift the data on the register to the right

            addi $t5, $zero, 3
            sub $t5, $t5, $t7

            shift_while:
                beq $t5, $zero, exit_shift_while
                srl $t8, $t8, 8
                addi $t5, $t5, -1
                j shift_while
                
            exit_shift_while:

            sw $t8, 0($t1)

    la $t5, edited
    sub $v0, $t1, $t5
    add $v0, $v0, $t7
    sub $v1, $t2, $v0

    jr $ra

# Argument is the output string address
output_string:
    move $t0, $a0       # Copy argument to a temp register
    move $a0, $s2
    li $v0, 4
    syscall

    move $a0, $t0
    li $v0, 4
    syscall

    jr $ra

check_above:
    li $s8, 0x5A
    bgt $t5, $s8, discard   # If the character is grater than 'Z' then discard it, else save it
    j save_character

check_below:
    bgt $t5, $s6, discard   # If the character is grater than '9' then discard it, else save it
    j save_character

save_character:

    addi $t7, 1
    sll $t5, $t5, 24
    or $t8, $t8, $t5        # Write t5 byte to t8

    beq $t7, $s4, save_to_memory_and_reset
    continue_saving_character:
    srl $t8, $t8, 8
    j discard


save_to_memory_and_reset:

    sw $t8, 0($t1)
    move $t8, $zero # Reset t8
    li $t7, 0       # Reset counter
    addi $t1, 4     # Go to the next 4 bytes
    j discard