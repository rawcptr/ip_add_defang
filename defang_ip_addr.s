.text

.extern malloc
.global _defang_ip_addr 

// defang_ip_addr(char* str) -> char* (null terminated)
_defang_ip_addr:
    stp x29, x30, [SP, #-16]!
    mov x29, SP // save FP, LR 

    // Callee-saved registers: x19-x28
    // REGISTER -> thing
    // x0  output string (caller saved but can copy.)
    // x19 dot count
    // x20 original length
    // x21 current input str ptr    for pass 1
    // x22 new str ptr              from malloc
    // x23 input read ptr           for pass 2
    // x24 output read ptr          for pass 2
    // x25 tmp for length calc
    // x26 original input str ptr

    stp x19, x20, [SP, #-16]! // current SP is SP - 16
    stp x21, x22, [SP, #-16]! // current SP is SP - 32
    stp x23, x24, [SP, #-16]! // current SP is SP - 48
    stp x25, x26, [SP, #-16]! // current SP is SP - 64

    mov x26, x0               // x26 = original_inp_str_ptr
    mov x19, #0               // x19 = dot_count 
    mov x20, #0               // x20 = original_length
    mov x21, x26              // x21 = current_inp_str for pass 1 (starts at original inp str)


// count dots and the original length:
.L_pass1_loop:
    // load byte from current tmp_str_ptr 
    ldrb w25, [x21]        // w25 = *tmp_str_ptr (32 bit)
    cmp w25, #0            // check for \0 
    beq .L_pass1_end       // atp, x19 = dotcount, x20 = length

    cmp w25, #'.'          // check current byte is '.'
    bne .L_pass1_char      // for regular char

    add x19, x19, #1       // dot_count +=1

.L_pass1_char:
    add x20, x20, #1       // original_length +=1 
    add x21, x21, #1       // tmp_str_ptr += 1
    b .L_pass1_loop        // continue loop for pass 1

.L_pass1_end:
    // new_len = original_len + dot_count * 2 + 1

    lsl x25, x19, #1       // multiply dot count by 2
    add x25, x25, x20      // calc length of the output str

    // no lea [r20 + r25*1 + 1] shenanigans here!! 
    add x25, x25, #1       // space for \0

    mov x0, x25            // move length of final str in x0
    bl _malloc             // call malloc with x0 bytes, and return ptr in x0
    cmp x0, #0             // check if malloc failed
    beq .L_malloc_fail

    mov x22, x0            // Save malloc result
    mov x23, x26           // x23 = input_read_ptr = original_inp_str_ptr 
    mov x24, x22           // x24 = output_write_ptr = new_string_base_ptr 

    b .L_pass2_loop        // jump to second pass

.L_malloc_fail:
    mov x0, #0
    b .L_epilogue_start

.L_pass2_loop:
    ldrb w25, [x23], #1    // w25 = *x23; x23 = x23 + 1 (input_read_ptr advances)

    cmp w25, #0            // check for null terminator
    beq .L_pass2_end

    cmp w25, #'.'
    bne .L_pass2_char

    // value is '.' Write '[', '.', ']' 
    mov w0, #'['
    strb w0, [x24], #1     // store byte from w0 to *x24, then x24 += 1

    mov w0, #'.' 
    strb w0, [x24], #1     // store byte from w0 to *x24, then x24 += 1

    mov w0, #']' 
    strb w0, [x24], #1     // store byte from w0 to *x24, then x24 += 1

    b .L_pass2_loop


.L_pass2_char:
    strb w25, [x24], #1     // store byte from w25 to *x24, then x24 += 1

    b .L_pass2_loop         // jump back to the loop

.L_pass2_end:
    strb wzr, [x24]         // store null terminator at *x24.
    mov x0, x22             // return the final string 

.L_epilogue_start:
    ldp x25, x26, [SP], #16 // restore x25, x26 and increment SP by 16
    ldp x23, x24, [SP], #16 // restore x23, x24 and increment SP by 16
    ldp x21, x22, [SP], #16 // restore x21, x22 and increment SP by 16
    ldp x19, x20, [SP], #16 // restore x19, x20 and increment SP by 16

    // restore frame pointer (x29) and link register (x30)
    // this is the final stack cleanup for the frame.
    ldp x29, x30, [SP], #16 // restore x29, x30 and increment SP by 16 

    ret // return to caller