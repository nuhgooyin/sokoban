# ADDITION INFORMATION
# There are two important modifications made to the base Sokoban game:
# 1. New multiplayer mode 
# 2. Improved random number generator
#
# These modifications can be found on the following lines:
# 1. Lines 113-561, which include:
#  sort_cummulative_standings, display_cummulative_standings, run_multiplayer_game, 
#  run_mod_singleplayer_game, check_finished_for_multiplayer functions.
#  And lines 712-780, which include: check_wall_hits_for_multiplayer function.
# 2. Lines 1909-1969 (improved_rand function)
#
# IMPLEMENTATION INFORMATION
# 1. The multiplayer mode was implemented using several additional functions as was mentioned above. 
# The "run_multiplayer_game" function works by taking in an input of how many players (through a0), and then
# loops through each player's turn by displaying whose turn it currently is, running a modified singleplayer game
# (using the "run_mod_singleplayer_game" function), storing the player's number of moves onto the allocated heap,
# resetting the game (by calling "reset_game1" function), sorting the cummulative standings, through "sort_cummulative_standings"
# function, and finally displaying the cummulative standings thus far using the "display_cummulative_standings" function.
#
# To put simply, the "run_multiplayer_game" function "bundles" functions used in singleplayer together in such a way that
# it becomes a alternative multiplayer mode.
#
# 2. The improved random functions works by taking in a value a0, and produces a number from 0 to a0 (exclusive)
# similar to how the original rand function works (on the surface anyway). The improved random function uses a 
# "mixed congruential method" as defined by the "Hull-Dobell" theorem, and thus is able to produce a random
# sequence with a period length of 2^31 
#
# In particular, parameters a, c, m, were picked in such a way so that this holds true.
# Each call to the improved_rand function will return the x0, x1, x3,...xn for the first, second,
# third and nth call respectively. Thus, the very first call to improved_rand will return x0 (the base case).
#
# The "seed" value is taken from the old rand function, thus, the very first call to improved_rand will return
# a value from the old rand, but subsequent calls will follow the LCG sequence mentioned above.
#
# **I WOULD HIGHLY RECOMMEND YOU OPEN THIS IN VSCODE OR A TEXT EDITOR WITH A SEARCH FUNCTION**
#

.data
character:  .byte 0,0
box:        .byte 0,0
target:     .byte 0,0
victory_msg: .string "\nCongratz! You have solved the puzzle!\n"
num_of_players: .string "\nEnter number of players:\n"
reset_game: .string "\nEnter 1 to reset the game, 0 to continue.\n"
penalty_game: .string "\nEnter 1 to reset the game, but note the number of moves will not reset, or 0 to continue.\n"
end_game: .string "\nEnter 1 to reset the game, 0 to end the game.\n"
curr_player_moves1: .string "\nYou took "
curr_player_moves2: .string " moves to complete the puzzle!\n"
curr_player: .string "\nIt is currently player "
curr_player2: .string "'s turn.\n"
cummulative_stand1: .string "\n          ~Scores~\n"
cummulative_stand2: .string "Player "
cummulative_stand3: .string ": "
cummulative_stand4: .string "\n"

og_char:    .byte 0,0
og_box:     .byte 0,0
og_target:  .byte 0,0

wall_hits:  .byte 0
char_moves: .byte 0

.globl main
.text

main:
    # Generate valid random locations for the character, box, and target.
    jal ra, generate_char_location   
    
    jal ra, generate_box_location

    jal ra, generate_target_location

    # Record the initial starting positions
    jal ra, record_og_pos
    
    # Illuminate LEDs for playable area
    jal ra, clear_screen
    jal ra, reilluminate

    # Ask how many players will be in the game
    li a7, 4
    la a0, num_of_players
    ecall
    call readInt

    addi t0, x0, 0
    addi t1, x0, 1

    beq a0, t1, run_a_singleplayer_game
    beq a0, t0, exit

    # Setup the heap to store player standings
    li gp, 536870912

    addi t2, x0, 8
    add t3, x0, a0
    mul a0, a0, t2
    add a0, gp, a0
	li a7, 214
	ecall

    # Error in setting up heap
    bne a0, t0, exit
    
    add a0, x0, t3

    j run_a_multiplayer_game

    run_a_singleplayer_game:
        jal ra, run_singleplayer_game
        j exit

    run_a_multiplayer_game:
        jal ra, run_multiplayer_game
        j exit
 
exit:
    li a7, 10
    ecall

# -- FUNCTIONS --

# Sort the cummulative standing for every player (given the number of players in a0)
sort_cummulative_standings:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw t4, 0(sp)
    addi sp, sp, -4
    sw t5, 0(sp)
    addi sp, sp, -4
    sw t6, 0(sp)
    
    # Initialize values
    add t1, a0, x0
    addi t1, t1, -1

    reset_val1:
        add t2, gp, x0
        add ra, x0, x0
        add s3, x0, x0

    while5:
        # Check if this is for only one player
        beq t1, x0, endloop11
        
        # Check if there has been a full pass
        beq t1, ra, endloop11
        
        # Check if reached end of stack
        beq t1, s3, reset_val1

        # Initialize values to compare
        lw t3, 0(t2)
        addi t2, t2, 4
        lw t4, 0(t2)
        addi t2, t2, 4

        lw t5, 0(t2)
        addi t2, t2, 4
        lw t6, 0(t2)
        addi t2, t2, -4

        # Compare the values
        bge t6, t4, case1
        blt t6, t4, case2

        # t4 =< t6
        case1:

            # Increment counter everytime a swap is not required
            addi ra, ra, 1

            j continue5

        # t4 > t6
        case2:

            # Reset the counter everytime a swap is required
            add ra, x0, x0

            # Swap the values
            addi t2, t2, -8
            sw t5, 0(t2)
            addi t2, t2, 4
            sw t6, 0(t2)
            addi t2, t2, 4
            sw t3, 0(t2)
            addi t2, t2, 4
            sw t4, 0(t2)
            addi t2, t2, -4

        continue5:
            addi s3, s3, 1
            j while5
    endloop11:

    lw t6, 0(sp)
    addi sp, sp, 4
    lw t5, 0(sp)
    addi sp, sp, 4
    lw t4, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra

# Display the cummulative standings for a multiplayer game (given # of players in a0)
display_cummulative_standings:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw a7, 0(sp)
    addi sp, sp, -4
    sw t4, 0(sp)

    add t2, x0, a0

    # Display the score header
    li a7, 4
    la a0, cummulative_stand1
    ecall

    add t1, x0, x0
    add t4, x0, gp

    # Loop through each players scores
    forloop7:
        beq t2, t1, endloop10

        # Display player's standing
        li a7, 4
        la a0, cummulative_stand2
        ecall

        # Access player number
        lw t3, 0(t4)
        addi t4, t4, 4

        li a7, 1
        mv a0, t3
        ecall

        li a7, 4
        la a0, cummulative_stand3
        ecall

        # Access player score
        lw t3, 0(t4)
        addi t4, t4, 4

        li a7, 1
        mv a0, t3
        ecall

        li a7, 4
        la a0, cummulative_stand4
        ecall

        addi t1, t1, 1

        j forloop7
    endloop10:

    lw t4, 0(sp)
    addi sp, sp, 4
    lw a7, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra

# Run a multiplayer game (takes in number of players through a0)
run_multiplayer_game:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw t4, 0(sp)
    addi sp, sp, -4
    sw s0, 0(sp)
    addi sp, sp, -4
    sw s1, 0(sp)

    addi t1, x0, 0
    add t2, x0, a0
    add s0, gp, x0

    # Loop through each players turn
    forloop6:
        beq t2, t1, endloop9

        # Indicate whose turn it currently is
        li a7, 4
        la a0, curr_player
        ecall

        li a7, 1
        addi t3, t1, 1
        mv a0, t3
        ecall

        li a7, 4
        la a0, curr_player2
        ecall

        addi t1, t1, 1

        jal ra, run_mod_singleplayer_game

        # Store the players number of moves in the heap
        sw t3, 0(s0)
        addi s0, s0, 4
        add t4, x0, x0
        la t4, char_moves
        lb s1, 0(t4)
        sw s1, 0(s0)
        addi s0, s0, 4

        # Reset the game
        jal ra, reset_game1

        add a0, t3, x0

        # Sort the cummulative standings
        jal ra, sort_cummulative_standings

        # Display the cummulative standings
        jal ra, display_cummulative_standings

        j forloop6
    endloop9:

    lw s1, 0(sp)
    addi sp, sp, 4
    lw s0, 0(sp)
    addi sp, sp, 4
    lw t4, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra


# Run a modified singleplayer game
run_mod_singleplayer_game:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw t4, 0(sp)
    addi sp, sp, -4
    sw t5, 0(sp)
    addi sp, sp, -4
    sw t6, 0(sp)
    addi sp, sp, -4
    sw t0, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw a3, 0(sp)

    addi t3, x0, 0
    addi t4, x0, 1
    addi t5, x0, 2
    addi t6, x0, 3

    main_movement_loop2:
        jal ra, clear_screen
        jal ra, reilluminate

        jal ra, check_finished_for_multiplayer
        addi a3, x0, 1
        beq a0, a3, end7

        jal ra, check_wall_hits_for_multiplayer
        jal ra, clean_call_pollDpad

        # Initialize player coords
        add t0, x0, x0
        la t0, character
        lb t1, 0(t0)
        addi t0, t0, 1
        lb t2, 0(t0)

        beq a0, t3, UP2
        beq a0, t4, DOWN2
        beq a0, t5, LEFT2
        beq a0, t6, RIGHT2

        UP2:
            addi t2, t2, -1
            add a0, x0, t1
            add a1, x0, t2
            addi a2, x0, 0

            jal ra, move_player

            j main_movement_loop2

        DOWN2:
            addi t2, t2, 1
            add a0, x0, t1
            add a1, x0, t2
            addi a2, x0, 1

            jal ra, move_player

            j main_movement_loop2

        LEFT2:
            addi t1, t1, -1
            add a0, x0, t1
            add a1, x0, t2
            addi a2, x0, 2

            jal ra, move_player

            j main_movement_loop2

        RIGHT2:
            addi t1, t1, 1
            add a0, x0, t1
            add a1, x0, t2
            addi a2, x0, 3

            jal ra, move_player

            j main_movement_loop2

    end7:

    lw a3, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4
    lw a1, 0(sp)
    addi sp, sp, 4
    lw t0, 0(sp)
    addi sp, sp, 4
    lw t6, 0(sp)
    addi sp, sp, 4
    lw t5, 0(sp)
    addi sp, sp, 4
    lw t4, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra


# Checks if box is on target, then end game (notifies next player turn with a0)
# (0 if not over, 1 if over)
check_finished_for_multiplayer:
    # Storing values of registers to use
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)
    addi sp, sp, -4
    sw a2, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)

    add a0, x0, x0
    la a0, box
    lb a1, 0(a0)
    addi a0, a0, 1
    lb a2, 0(a0)

    add a0, x0, x0
    la a0, target
    lb t2, 0(a0)
    addi a0, a0, 1
    lb t1, 0(a0)

    beq a1, t2, checkagain2

    j end6

    checkagain2:
        beq a2, t1, both_equal1

        j end6

    both_equal1:
        li a7, 4
        la a0, victory_msg
        ecall

        jal ra, display_moves

        addi a0, x0, 1
        j end8

    end6:
        addi a0, x0, 0

    end8:

    # Restoring values of used registers
    lw t2, 0(sp)
    addi sp, sp, 4
    lw a2, 0(sp)
    addi sp, sp, 4
    lw a1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4

    jr ra

# Display the number of moves currently
display_moves:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)

    li a7, 4
    la a0, curr_player_moves1
    ecall

    add t1, x0, x0
    la t1, char_moves
    lb t2, 0(t1)

    li a7, 1
    mv a0, t2
    ecall

    li a7, 4
    la a0, curr_player_moves2
    ecall

    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra

# Run a singleplayer game
run_singleplayer_game:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw t4, 0(sp)
    addi sp, sp, -4
    sw t5, 0(sp)
    addi sp, sp, -4
    sw t6, 0(sp)
    addi sp, sp, -4
    sw t0, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)
    addi sp, sp, -4
    sw a0, 0(sp)

    addi t3, x0, 0
    addi t4, x0, 1
    addi t5, x0, 2
    addi t6, x0, 3

    main_movement_loop:
        jal ra, clear_screen
        jal ra, reilluminate
        jal ra, check_finished
        jal ra, check_wall_hits
        jal ra, clean_call_pollDpad

        # Initialize player coords
        add t0, x0, x0
        la t0, character
        lb t1, 0(t0)
        addi t0, t0, 1
        lb t2, 0(t0)

        beq a0, t3, UP
        beq a0, t4, DOWN
        beq a0, t5, LEFT
        beq a0, t6, RIGHT

        UP:
            addi t2, t2, -1
            add a0, x0, t1
            add a1, x0, t2
            addi a2, x0, 0

            jal ra, move_player

            j main_movement_loop

        DOWN:
            addi t2, t2, 1
            add a0, x0, t1
            add a1, x0, t2
            addi a2, x0, 1

            jal ra, move_player

            j main_movement_loop

        LEFT:
            addi t1, t1, -1
            add a0, x0, t1
            add a1, x0, t2
            addi a2, x0, 2

            jal ra, move_player

            j main_movement_loop

        RIGHT:
            addi t1, t1, 1
            add a0, x0, t1
            add a1, x0, t2
            addi a2, x0, 3

            jal ra, move_player

            j main_movement_loop

    lw a0, 0(sp)
    addi sp, sp, 4
    lw a1, 0(sp)
    addi sp, sp, 4
    lw t0, 0(sp)
    addi sp, sp, 4
    lw t6, 0(sp)
    addi sp, sp, 4
    lw t5, 0(sp)
    addi sp, sp, 4
    lw t4, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra


# Check if wall hits are high enough, if they are ask the player if
# they want to "restart" the game
check_wall_hits_for_multiplayer:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw a0, 0(sp)

    # Initialize wall hits
    add t1, x0, x0
    la t1, wall_hits
    lb t2, 0(t1)

    addi t3, x0, 3

    beq t2, t3, ask_to_reset2

    j continue3

    ask_to_reset2:
        # Ask if they want to take a "penalty" and reset
        li a7, 4
        la a0, penalty_game
        ecall
        call readInt

        addi t1, x0, 1

        beq t1, a0, reset_game4

        j continue4

        reset_game4:
            add a0, x0, x0
            la a0, char_moves
            lb t3, 0(a0)
            call reset_game1

            sb t3, 0(a0)
            call clear_screen
            call reilluminate

        continue4:
            add t1, x0, x0
            la t1, wall_hits
            addi t2, x0, 0
            sb t2, 0(t1)

    continue3:

    lw a0, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra

# Check if wall hits are high enough, if they are ask the player if
# they want to reset the game
check_wall_hits:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw a0, 0(sp)

    # Initialize wall hits
    add t1, x0, x0
    la t1, wall_hits
    lb t2, 0(t1)

    addi t3, x0, 3

    beq t2, t3, ask_to_reset

    j continue1

    ask_to_reset:
        # Ask if they want to reset the game
        li a7, 4
        la a0, reset_game
        ecall
        call readInt

        addi t1, x0, 1

        beq t1, a0, reset_game3

        j continue2

        reset_game3:
            call reset_game1
            call clear_screen
            call reilluminate

        continue2:
            add t1, x0, x0
            la t1, wall_hits
            addi t2, x0, 0
            sb t2, 0(t1)

    continue1:

    lw a0, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra

# Record initial starting positions
record_og_pos:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)

    add t1, x0, x0
    la t1, character
    lb t2, 0(t1)
    addi t1, t1, 1
    lb t3, 0(t1)

    add t1, x0, x0
    la t1, og_char
    sb t2, 0(t1)
    addi t1, t1, 1
    sb t3, 0(t1)

    add t1, x0, x0
    la t1, box
    lb t2, 0(t1)
    addi t1, t1, 1
    lb t3, 0(t1)

    add t1, x0, x0
    la t1, og_box
    sb t2, 0(t1)
    addi t1, t1, 1
    sb t3, 0(t1)

    add t1, x0, x0
    la t1, target
    lb t2, 0(t1)
    addi t1, t1, 1
    lb t3, 0(t1)

    add t1, x0, x0
    la t1, og_target
    sb t2, 0(t1)
    addi t1, t1, 1
    sb t3, 0(t1)

    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra


# Reset the game to the initial starting conditions
# Precondition: initial starting pos. have been recorded already
reset_game1:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)

    add t1, x0, x0
    la t1, og_char
    lb t2, 0(t1)
    addi t1, t1, 1
    lb t3, 0(t1)

    add t1, x0, x0
    la t1, character
    sb t2, 0(t1)
    addi t1, t1, 1
    sb t3, 0(t1)

    add t1, x0, x0
    la t1, og_box
    lb t2, 0(t1)
    addi t1, t1, 1
    lb t3, 0(t1)

    add t1, x0, x0
    la t1, box
    sb t2, 0(t1)
    addi t1, t1, 1
    sb t3, 0(t1)

    add t1, x0, x0
    la t1, og_target
    lb t2, 0(t1)
    addi t1, t1, 1
    lb t3, 0(t1)

    add t1, x0, x0
    la t1, target
    sb t2, 0(t1)
    addi t1, t1, 1
    sb t3, 0(t1)

    add t1, x0, x0
    la t1, char_moves
    addi t2, x0, 0
    sb t2, 0(t1)

    add t1, x0, x0
    la t1, wall_hits
    addi t2, x0, 0
    sb t2, 0(t1)

    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra

# "Clean" call pollDpad
# (call pollDpad while restoring registers it uses to it's original val.)
clean_call_pollDpad:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)

    jal ra, pollDpad

    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra

# Clear the screen
clear_screen:
    # Storing values of registers to use
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)
    addi sp, sp, -4
    sw a2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw t4, 0(sp)
    addi sp, sp, -4
    sw t5, 0(sp)

    # Clear the LEDs
    addi t1, x0, 8
    addi t3, x0, 0
    addi a0, x0, 0
    addi a1, x0, 0
    addi a2, x0, 0
    forloop5:
        beq t3, t1, endloop5

        addi t4, x0, 0
        addi a1, x0, 0

        nestedforloop1:
            beq t4, t1, endnestedloop1

            jal ra, setLED

            addi a1, a1, 1

            addi t4, t4, 1

            j nestedforloop1

        endnestedloop1:

        jal ra, setLED

        addi a2, a2, 1

        addi t3, t3, 1
        
        j forloop5

    endloop5:

    # Restoring values of used registers
    lw t5, 0(sp)
    addi sp, sp, 4
    lw t4, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw a2, 0(sp)
    addi sp, sp, 4
    lw a1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4

    jr ra

# Given a player coord. in a0, a1 (x, y), and direction of movement a2,
# move the player if valid move, and handle box movement
move_player:
    # Storing values of registers to use
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t0, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)
    addi sp, sp, -4
    sw a2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw t4, 0(sp)
    addi sp, sp, -4
    sw t5, 0(sp)
    addi sp, sp, -4
    sw t6, 0(sp)

    addi t1, x0, 0
    addi t2, x0, 7

    # Check if player is going to be in a wall
    beq a0, t1, skip3
    beq a1, t2, skip3
    beq a0, t2, skip3
    beq a1, t1, skip3

    add t0, x0, x0
    la t0, wall_hits
    sb t1, 0(t0)

    # Check if player is going to be in a box
    add t1, x0, x0
    la t1, box
    lb t2, 0(t1)
    addi t1, t1, 1
    lb t6, 0(t1)
    addi t1, x0, 0
    addi t3, x0, 1
    addi t4, x0, 2
    addi t5, x0, 3

    box_handler:
        bne a0, t2, skip2
        bne a1, t6, skip2

        beq a2, t1, upbox
        beq a2, t3, downbox
        beq a2, t4, leftbox
        beq a2, t5, rightbox

        upbox:
            addi t6, t6, -1
            addi t3, x0, 0
            addi t4, x0, 7

            beq t6, t3, skip1
            beq t6, t4, skip1

            la t3, box
            addi t3, t3, 1
            sb t6, 0(t3)

            j skip2

        downbox:
            addi t6, t6, 1
            addi t3, x0, 0
            addi t4, x0, 7

            beq t6, t3, skip1
            beq t6, t4, skip1

            la t3, box
            addi t3, t3, 1
            sb t6, 0(t3)

            j skip2

        leftbox:
            addi t2, t2, -1
            addi t3, x0, 0
            addi t4, x0, 7

            beq t2, t3, skip1
            beq t2, t4, skip1

            la t3, box
            sb t2, 0(t3)

            j skip2

        rightbox: 
            addi t2, t2, 1
            addi t3, x0, 0
            addi t4, x0, 7

            beq t2, t3, skip1
            beq t2, t4, skip1

            la t3, box
            sb t2, 0(t3)

            j skip2

        skip2:

    # Update player coords
    add t0, x0, x0
    la t0, character
    sb a0, 0(t0)
    addi t0, t0, 1
    sb a1, 0(t0)

    add t0, x0, x0
    la t0, char_moves
    lb t1, 0(t0)
    addi t1, t1, 1
    sb t1, 0(t0)

    j skip1


    skip3:
        add t0, x0, x0
        la t0, wall_hits
        lb t1, 0(t0)
        addi t1, t1, 1
        sb t1, 0(t0)

    skip1:

    # Restoring values of used registers
    lw t6, 0(sp)
    addi sp, sp, 4
    lw t5, 0(sp)
    addi sp, sp, 4
    lw t4, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw a2, 0(sp)
    addi sp, sp, 4
    lw a1, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t0, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4

    jr ra

# Checks if box is on target, then end game
check_finished:
    # Storing values of registers to use
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)
    addi sp, sp, -4
    sw a2, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)

    add a0, x0, x0
    la a0, box
    lb a1, 0(a0)
    addi a0, a0, 1
    lb a2, 0(a0)

    add a0, x0, x0
    la a0, target
    lb t2, 0(a0)
    addi a0, a0, 1
    lb t1, 0(a0)

    beq a1, t2, checkagain1

    j end5

    checkagain1:
        beq a2, t1, both_equal

        j end5

    both_equal:
        li a7, 4
        la a0, victory_msg
        ecall

        jal ra, display_moves

        # Ask if they want to reset the game
        li a7, 4
        la a0, end_game
        ecall
        call readInt

        addi t1, x0, 1

        beq a0, t1, reset_game2

        j end_game2

        reset_game2:
            call reset_game1
            call clear_screen
            call reilluminate
            j end5

        end_game2:
            j exit

    end5:

    # Restoring values of used registers
    lw t2, 0(sp)
    addi sp, sp, 4
    lw a2, 0(sp)
    addi sp, sp, 4
    lw a1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4

    jr ra

# Reilluminate the player, box, target, and walls
reilluminate:
    addi sp, sp, -4
    sw ra, 0(sp)

    jal ra, illuminate_target
    jal ra, illuminate_box
    jal ra, illuminate_walls
    jal ra, illuminate_player

    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra

# Illuminate the target
illuminate_target:
    # Storing values of registers to use
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)
    addi sp, sp, -4
    sw a2, 0(sp)

    # set the target led
    add t1, x0, x0
    la t1, target
    lb a1, 0(t1)
    addi t1, t1, 1
    lb a2, 0(t1)
    li a0, 16719360

    jal ra, setLED

    # Restoring values of used registers
    lw a2, 0(sp)
    addi sp, sp, 4
    lw a1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4

    jr ra

# Illuminate the box
illuminate_box:
    # Storing values of registers to use
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)
    addi sp, sp, -4
    sw a2, 0(sp)

    # set the box led
    add t1, x0, x0
    la t1, box
    lb a1, 0(t1)
    addi t1, t1, 1
    lb a2, 0(t1)
    li a0, 13311
    jal ra, setLED

    # Restoring values of used registers
    lw a2, 0(sp)
    addi sp, sp, 4
    lw a1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4

    jr ra

# Illuminate the player
illuminate_player:
    # Storing values of registers to use
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)
    addi sp, sp, -4
    sw a2, 0(sp)

    # set the player led
    add t1, x0, x0
    la t1, character
    lb a1, 0(t1)
    addi t1, t1, 1
    lb a2, 0(t1)
    li a0, 327424
    jal ra, setLED

    # Restoring values of used registers
    lw a2, 0(sp)
    addi sp, sp, 4
    lw a1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4

    jr ra


# Illuminate the walls/edges
illuminate_walls:
    # Storing values of registers to use
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)
    addi sp, sp, -4
    sw a2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw t4, 0(sp)

    # Illuminate the upper wall
    addi t1, x0, 8
    addi t3, x0, 0
    li a0, 16762668
    add a1, x0, x0
    add a2, x0, x0
    forloop1:
        beq t3, t1, endloop1

        jal ra, setLED

        addi a1, a1, 1

        addi t3, t3, 1
        
        j forloop1

    endloop1:
    
    # Illuminate the left side wall
    addi t3, x0, 0
    add a1, x0, x0
    add a2, x0, x0
    forloop2:
        beq t3, t1, endloop2

        jal ra, setLED

        addi a2, a2, 1

        addi t3, t3, 1
        
        j forloop2

    endloop2:

    # Illuminate the right side wall
    addi t3, x0, 0
    addi a1, x0, 7
    add a2, x0, x0
    forloop3:
        beq t3, t1, endloop3

        jal ra, setLED

        addi a2, a2, 1

        addi t3, t3, 1
        
        j forloop3

    endloop3:

    # Illuminate the bottom wall
    addi t3, x0, 0
    add a1, x0, x0
    addi a2, x0, 7
    forloop4:
        beq t3, t1, endloop4

        jal ra, setLED

        addi a1, a1, 1

        addi t3, t3, 1
        
        j forloop4

    endloop4:

    # Restoring values of used registers
    lw t4, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw a2, 0(sp)
    addi sp, sp, 4
    lw a1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4

    jr ra

# Generates and stores a random character location
generate_char_location:
    # Storing values of registers to use
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)

    # generate and store character location
    add t1, x0, x0
    la t1, character
    addi a0, x0, 6
    jal ra, improved_rand
    addi a0, a0, 1
    sb a0, 0(t1)
    addi a0, x0, 6
    jal ra, improved_rand
    addi a0, a0, 1
    addi t1, t1, 1
    sb a0, 0(t1)

    # Restoring values of used registers
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4

    jr ra


# Check if given a0, a1 (x, y) are in a corner
# Return 0 if not in corner, 1 if in corner 
check_if_in_corner:
    # Storing values of registers to use
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw t4, 0(sp)
    addi sp, sp, -4
    sw t5, 0(sp)
    addi sp, sp, -4
    sw t6, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)

    # Initialize corner 1 coords.
    corner1:
    addi t1, x0, 1
    addi t2, x0, 1

    add t3, a0, x0
    add t4, a1, x0
    addi a0, x0, 0

    bne t1, t3, corner2
    bne t2, t4, corner2

    j return2

    # Initialize corner 2 coords.
    corner2:
    addi t1, x0, 1
    addi t2, x0, 6

    bne t1, t3, corner3
    bne t2, t4, corner3

    j return2

    # Initialize corner 3 coords.
    corner3:
    addi t1, x0, 6
    addi t2, x0, 1

    bne t1, t3, corner4
    bne t2, t4, corner4

    j return2

    # Initialize corner 4 coords.
    corner4:
    addi t1, x0, 6
    addi t2, x0, 6

    bne t1, t3, return1
    bne t2, t4, return1

    j return2

    return2:
        addi a0, x0, 1

    return1:

    # Restoring values of used registers
    lw a1, 0(sp)
    addi sp, sp, 4
    lw t6, 0(sp)
    addi sp, sp, 4
    lw t5, 0(sp)
    addi sp, sp, 4
    lw t4, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4

    jr ra

# Generate a valid box location
# Precondition: character location has already been generated
generate_box_location:
    # Storing values of registers to use
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw t4, 0(sp)
    addi sp, sp, -4
    sw t5, 0(sp)
    addi sp, sp, -4
    sw t6, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)

    # Get character x-coord.
    add t1, x0, x0
    la t1, character
    lb t2, 0(t1)

    while1: 

        # Get a valid x-coord in relation to character x-coord.
        addi a0, x0, 6
        jal ra, improved_rand
        addi a0, a0, 1

        add t1, x0, a0

        beq t1, t2, while1

        # Generate random y-coord.
        addi a0, x0, 6
        jal ra, improved_rand
        addi a0, a0, 1

        add t3, x0, a0

        # If in corner, loop again
        add a0, t1, x0
        add a1, t3, x0

        jal ra, check_if_in_corner

        addi t4, x0, 1

        beq a0, t4, while1
        
        # Store the coords
        add t5, x0, x0
        la t5, box
        sb t1, 0(t5)
        addi t5, t5, 1
        sb t3, 0(t5)

    # Restoring values of used registers
    lw a1, 0(sp)
    addi sp, sp, 4
    lw t6, 0(sp)
    addi sp, sp, 4
    lw t5, 0(sp)
    addi sp, sp, 4
    lw t4, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4

    jr ra

# Generate a valid target location
# Precondition: Character & box locations were already generated
generate_target_location:
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t0, 0(sp)
    addi sp, sp, -4
    sw t4, 0(sp)
    addi sp, sp, -4
    sw t5, 0(sp)
    addi sp, sp, -4
    sw t6, 0(sp)

    # Load the character & box coords
    la t0, character
    lb t1, 0(t0)
    addi t0, t0, 1
    lb t2, 0(t0)

    add t0, x0, x0
    la t0, box
    lb t3, 0(t0)
    addi t0, t0, 1
    lb t4, 0(t0)

    addi t5, x0, 1
    addi t6, x0, 6

    # Check if box is on wall
    beq t3, t5, generate_y
    beq t3, t6, generate_y
    beq t4, t5, generate_x
    beq t4, t6, generate_x

    generate_random:
        while4:
            addi a0, x0, 6
            jal ra, improved_rand
            addi a0, a0, 1

            beq a0, t1, while4
            beq a0, t3, while4

        endloop8:
            add t1, x0, x0
            la t1, target
            sb a0, 0(t1)
            addi t1, t1, 1

            addi a0, x0, 6
            jal ra, improved_rand
            addi a0, a0, 1

            sb a0, 0(t1)

            j end4


    generate_x:

        while2:
            addi a0, x0, 6
            jal ra, improved_rand
            addi a0, a0, 1

            beq a0, t1, while2
            beq a0, t3, while2

        endloop6:
            add t0, x0, x0
            la t0, target
            sb a0, 0(t0)
            addi t0, t0, 1
            sb t4, 0(t0)

            j end4


    generate_y:

        while3:
            addi a0, x0, 6
            jal ra, improved_rand
            addi a0, a0, 1

            beq a0, t2, while3
            beq a0, t4, while3

        endloop7:
            add t0, x0, x0
            la t0, target
            sb t3, 0(t0)
            addi t0, t0, 1
            sb a0, 0(t0)

    end4:

    # Restoring values of used registers
    lw t6, 0(sp)
    addi sp, sp, 4
    lw t5, 0(sp)
    addi sp, sp, 4
    lw t4, 0(sp)
    addi sp, sp, 4
    lw t0, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4

    jr ra

# Returns a "random" number from 0 to a0 (exclusive, and where a0 is given).
# Pseudorandom number generator algorithm used: 
# https://pi.math.cornell.edu/~mec/Winter2009/Luo/Linear%20Congruential%20Generator/linear%20congruential%20gen1.html
# https://sourceware.org/git/?p=glibc.git;a=blob;f=stdlib/random_r.c;hb=glibc-2.26#l362
# according to the two sources above, this should follow the "mixed congruential method" for LCG
# which follows from the "Hull-Dobell" theorem.
improved_rand:
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw t2, 0(sp)
    addi sp, sp, -4
    sw t3, 0(sp)

    beq s5, x0, base_case
    j recursive_case

    # Base case: if this is the first call to improved_rand
    base_case:

        # Get the seed x0 and return x0
        jal ra, rand

        # Initialize constants
        add s4, x0, a0 # xn-1
        li s6, 1103515245 # a
        li s7, 12345 # c
        li s8, 2147483648 # m

        addi s5, s5, 1

        j return3

    # Recursive case: if this is the n > 0 call to improved_rand
    recursive_case:
        add s9, x0, a0 # Max. result

        mul t1, s6, s4
        add t2, t1, s7
        remu t3, t2, s8

        add s4, t3, x0

        remu a0, t3, s9

        addi s5, s5, 1

    return3:

    lw t3, 0(sp)
    addi sp, sp, 4
    lw t2, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4

    jr ra

# -- HELPER FUNCTIONS --
     
# Takes in a number in a0, and returns a (not really) random 
# number from 0 to this number (exclusive)
rand:
    mv t0, a0
    li a7, 30
    ecall
    remu a0, a0, t0
    jr ra
    
# Takes in an RGB color in a0, an x-coordinate in a1, and a y-coordinate
# in a2. Then it sets the led at (x, y) to the given color.
setLED:
    # Storing values of registers to use
    addi sp, sp, -4
    sw a0, 0(sp)
    addi sp, sp, -4
    sw t1, 0(sp)
    addi sp, sp, -4
    sw ra, 0(sp)
    addi sp, sp, -4
    sw t0, 0(sp)
    addi sp, sp, -4
    sw a1, 0(sp)
    addi sp, sp, -4
    sw a2, 0(sp)

    # Set the actual LED
    li t1, LED_MATRIX_0_WIDTH
    mul t0, a2, t1
    add t0, t0, a1
    li t1, 4
    mul t0, t0, t1
    li t1, LED_MATRIX_0_BASE
    add t0, t1, t0
    sw a0, (0)t0

    # Restoring values of used registers
    lw a2, 0(sp)
    addi sp, sp, 4
    lw a1, 0(sp)
    addi sp, sp, 4
    lw t0, 0(sp)
    addi sp, sp, 4
    lw ra, 0(sp)
    addi sp, sp, 4
    lw t1, 0(sp)
    addi sp, sp, 4
    lw a0, 0(sp)
    addi sp, sp, 4

    jr ra
    
# Polls the d-pad input until a button is pressed, then returns a number
# representing the button that was pressed in a0.
# The possible return values are:
# 0: UP
# 1: DOWN
# 2: LEFT
# 3: RIGHT
pollDpad:
    mv a0, zero
    li t1, 4

pollLoop:
    bge a0, t1, pollLoopEnd
    li t2, D_PAD_0_BASE
    slli t3, a0, 2
    add t2, t2, t3
    lw t3, (0)t2
    bnez t3, pollRelease
    addi a0, a0, 1
    j pollLoop
pollLoopEnd:
    j pollDpad
pollRelease:
    lw t3, (0)t2
    bnez t3, pollRelease

pollExit:
    jr ra


# Taking user input functions
readInt:
    addi sp, sp, -12
    li a0, 0
    mv a1, sp
    li a2, 12
    li a7, 63
    ecall
    li a1, 1
    add a2, sp, a0
    addi a2, a2, -2
    mv a0, zero
parse:
    blt a2, sp, parseEnd
    lb a7, 0(a2)
    addi a7, a7, -48
    li a3, 9
    bltu a3, a7, error
    mul a7, a7, a1
    add a0, a0, a7
    li a3, 10
    mul a1, a1, a3
    addi a2, a2, -1
    j parse
parseEnd:
    addi sp, sp, 12
    ret

error:
    li a7, 93
    li a0, 1
    ecall
