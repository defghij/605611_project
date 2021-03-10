/* System Call Information:
 *   man 2 syscall                                    // shows the ARM ABI for syscalls
 *   /usr/include/arm-linux-gnueabihf/asm/unistd-common.h // header for syscalls
 * Assemble and Link:
 *   To assemble and link the .s file into a binary use the following shell command
 *     as -mcpu=cortex-a72 -g --warn  <name>.s -o <name>.o; ld <name>.o -o <name>   // doesnt allow static linking 
 *     gcc -Wall -fpic -fno-stack-protector -z execstack <name>.s -o <name>
 *
 * ARM Convention:
 *  r0-r3: Arguments, additional agruments taken from stack
 *  r4-r11: Local variables
 *  r0: return values
 */
.syntax unified
.arm
.cpu cortex-a7
.extern scanf

.section .data
.balign 4
  _prompt:          .asciz "Enter phrase: "
  .set _prompt_len, .-_prompt
  _str_format:      .asciz "%s"
  .set _str_format_len, .-_str_format
  _canary_str:     .asciz "Canary: "
  .set _canary_str_len, .-_canary_str
  _canary_fail:     .asciz "You overwrote the stack canary.\n"
  .set _canary_fail_len, .-_canary_fail
  _canary_success: .asciz "You didnt overwrite the stack canary.\n"
  .set _canary_success_len, .-_canary_success
  _target_str:     .asciz "Target: "
  .set _target_str_len, .-_target_str
  _target_fail:    .asciz "Target not set to \"pass\".\n"
  .set _target_fail_len, .-_target_fail
  _buffer_str:     .asciz "Buffer: "
  .set _buffer_str_len, .-_buffer_str
  _newline_str:        .asciz "\n"
  .set _newline_str_len, .-_newline_str
  _hacker_str:     .asciz "hacker"
  .set _hacker_str_len, .-_hacker_str
  _fail_str:       .asciz "fail"
  .set _fail_str_len, .-_fail_str
  _pass_str:       .asciz "pass"
  .set _pass_str_len, .-_pass_str
  _success_str: .asciz "Congrats! You overwrote the target without touching the canary!\n"
  .set _success_str_len, .-_success_str
  _key_str:     .asciz "The key is: \"smash the stack\"\n"
  .set _key_str_len, .-_key_str


.section .text
.global main
.equ buffer_size, 12
.equ target_size, 5
.equ canary_size, 6

main:
  push {r0-r7,fp,lr}
  /* ## SETUP LOCAL VARIABLES ##
   * Set up space for local variables 
   * At this point we have the following temp registers:
   *  r4 = canary, 4 bytes
   *  r5 = target, 4 bytes
   *  r6 = overflow buffer, 24 bytes
   */
  // TODO Add a bunch of nulls so prevent really serious overflow when printing
  // with puts
  sub sp, sp, canary_size
  mov r4, sp        // Space for canary
  sub sp, sp, target_size
  mov r5, sp        // Space for target
  sub sp, sp, buffer_size 
  mov r6, sp        // space for overflow buffer

  // Set up target: "fail"
  ldr r7, =#0x6C696166
  str r7, [r5]
  ldr r7, =#0
  str r7, [r5, #4]
  
  // Set up Canary: "hacker"
  ldr r7, =#0x6B636168
  str r7, [r4]
  ldr r7, =#0x7265
  str r7, [r4, #4]


  // Print user prompt. 
  mov r0, #1
  ldr r1, =_prompt
  ldr r2, =_prompt_len
  mov r7, #4
  svc #0 

  // Get user-input ("%s") using scanf.
  ldr r0, =_str_format    // Load format string into R0
  mov r1, r6              // Move address on stack into R1
  bl scanf

  ldr r0, =_newline_str
  ldr r1, =_newline_str_len
  bl write_to_stdout

  mov r8, 0
  // Test target == "pass"
  ldr r1, [r5]
  ldr r2, =#0x73736170
  cmp r1, r2
  addeq r8, r8, #1
  blne target_fail
  
  // Test canary == "hacker"
  ldr r1, =#0x6B636168
  ldr r2, [r4]
  eor r3, r1, r2
  ldr r1, =#0x7265
  ldr r2, [r4, #4]
  eor r2, r1, r2
  add r1, r2, r3
  cmp r1, #0
  addeq r8, r8, #1
  blne canary_fail
  
  cmp r8, #2
  bleq print_key

  mov r0, r4
  mov r1, r5
  mov r2, r6
  bl review_stack

  pop {r0-r7,fp,lr}
  mov r7, #1
  svc #0

print_key:
  push {r4-r10, fp, lr} 
  
  ldr r0, =_success_str
  ldr r1, =_success_str_len
  bl write_to_stdout

  ldr r0, =_key_str
  ldr r1, =_key_str_len
  bl write_to_stdout

  pop {r4-r10, fp, lr}
  bx lr

/* Review Stack
 * Input: 
 *  r0: canary
 *  r1: target
 *  r2: overflow buffer
 * Output:
 *  Prints the contents of the canary, target, and overflow buffers.
 */
review_stack:
  push {r4,r5,r6,fp,lr} 
  mov r4, r0
  mov r5, r1
  mov r6, r2
  
  ldr r0, =_newline_str
  ldr r1, =_newline_str_len
  bl write_to_stdout
  
  // Print out canary //
  ldr r0, =_canary_str
  ldr r1, =_canary_str_len
  bl write_to_stdout
  
  mov r0, r4
  ldr r1, =canary_size
  bl write_by_len
  
  ldr r0, =_newline_str
  ldr r1, =_newline_str_len
  bl write_to_stdout


  // Print out target //
  ldr r0, =_target_str
  ldr r1, =_target_str_len
  bl write_to_stdout

  mov r0, r5
  ldr r1, =target_size
  bl write_by_len
  
  ldr r0, =_newline_str
  ldr r1, =_newline_str_len
  bl write_to_stdout

  // Print out buffer //
  ldr r0, =_buffer_str
  ldr r1, =_buffer_str_len
  bl write_to_stdout
  
  mov r0, r6
  ldr r1, =buffer_size
  bl write_by_len
  
  ldr r0, =_newline_str
  ldr r1, =_newline_str_len
  bl write_to_stdout
  
  pop {r4,r5,r6,fp,lr}
  bx lr


/* write_by_len
 * Input: 
 *  r0: char* buffer
 *  r1: lenth to print out
 * Output: None
 * Side Effects: Prints r1 chars from r0 to stdout.
 */
write_by_len:
  push {r4-r9, fp, lr}

  mov r4, #0
  mov r5, r1
  sub r5, r5, #1
  mov r1, r0
  for_loop_one_write_by_len:
    ldr r6, [r1]
    and r6, r6, #0xff
    cmp r6, #0
    _b:
    bne wbl_flowbl_write
    ldr r6, [r1]
    _c:
    add r6, r6, #0x20
    str r6, [r1]
    _d:

    wbl_flowbl_write:
    mov r0, #1
    mov r2, #1
    mov r7, #4
    svc #0 

    cmp r4, r5
    beq end_for_loop_one_write_by_len
    add r4, r4, #1
    add r1, r1, #1
    b for_loop_one_write_by_len

  end_for_loop_one_write_by_len:

  pop {r4-r9, fp, lr}
  bx lr

target_fail: 
  push {r7,fp}
  mov r0, #1
  ldr r1, =_target_fail
  ldr r2, =_target_fail_len
  mov r7, #4
  svc #0

  pop {r7,fp}
  bx lr

canary_fail:
  push {r7, fp}
  mov r0, #1
  ldr r1, =_canary_fail
  ldr r2, =_canary_fail_len
  mov r7, #4
  svc #0

  pop {r7,fp}
  bx lr

write_to_stdout:
  push {fp}
  mov r2, r1
  mov r1, r0
  mov r0, #1  // fd: stdout
  mov r7, #4  // syscall: write
  svc #0 
  pop {fp}
  bx lr


