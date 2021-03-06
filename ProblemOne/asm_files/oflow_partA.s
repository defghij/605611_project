/* Author: Chuck L. Norris
 * Association: Johns Hopkins University
 * Date: 24 March 2021
 * Purpose: This provides an exploitable buffer as a vehicle for exposition of stack/buffer
 *  overflows.
 * Theory of Operation: 
 *  Local variables are declared on the stack. User input is copied to the stack
 *  using a vulnerable strcopy-like function that does no length checking. Using this 
 *  vulnerable function the user can overwrite one of the local variables. There is a 
 *  check on the value of this local variable. If overwritten with the correct value the
 *  program prints a secret key.
 * Input: 
 *  string: Single command line argument. Input is interpretted as ASCII.
 * Output:
 *  Write strings to standard out depending on the state of the stack and local 
 *  variables.
 *
 * Local Variables: The way this binary allocates space on the stack and then 
 * keeps track of those variables is not consistent with typical compiled
 * programs. In this program, a pointer to each variable on the stack is 
 * stored in a register. This can be done because we know exactly how many 
 * local variables we have and the number of local variables is small. 
 * Typically in compiled programs an offset from the stack pointer is stored. 
 * To access a local variable we would add the offset to the stack pointer.
 * 
 * An additional step taken in this binary is to zero out memory on the stack. This is
 * typically done by a compiler during program initialization. 
 *
 * Assembly Information:
 * System Call Information:
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


.section .text
.global main
.equ buffer_size, 12
.equ target_size, 4

main:
  push {r0-r7,fp,lr}
  
  // Make sure there is an argument
  mov r2, r0
  cmp r2, #2
  beq _get_argument

  // Print usage statement 
  ldr r0, = _usage_str
  ldr r1, = _usage_str_len
  bl write_to_stdout
  b exit

  _get_argument:
  ldr r8, [r1, #4] // r8 <-- (char *) argv[1]

  // ## SETUP LOCAL VARIABLES ##
  sub sp, sp, target_size
  mov r5, sp        // Space for target
  sub sp, sp, buffer_size 
  mov r6, sp        // space for overflow buffer

  // Set up target: "fail"
  ldr r7, =#0x6C696166
  str r7, [r5]
  
  mov r0, r6
  mov r1, buffer_size 
  bl memzero

  // Copy commandline argument to buffer.
  mov r0, r8
  mov r1, r6
  bl copy_str
  
  mov r0, r5
  mov r1, r6
  bl review_stack

  mov r8, 0
  // Test target == "pass"
  ldr r1, [r5]
  ldr r2, =#0x73736170
  cmp r1, r2
  addeq r8, r8, #1
  blne target_fail
  
  cmp r8, #1
  bleq print_key

  
  exit:
  pop {r0-r7,fp,lr}
  mov r7, #1
  svc #0


/* target_fail:
 *  Informs user that the target was overwritten with incorrect value.
 * Input: None
 * Output: None
 * Side Effects:
 *  Writes failure message to stdout.
 */
target_fail: 
  push {r7,fp}
  mov r0, #1
  ldr r1, =_target_fail
  ldr r2, =_target_fail_len
  mov r7, #4
  svc #0

  pop {r7,fp}
  bx lr


/* print_key:
 *  Shows the secret key with the target buffer is overwritten correctly.
 * Input: None
 * Output: None
 * Side Effects:
 *  Writes secret key to stdout.
 */
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


/* review_stack:
 *  function to print out formatted local variable contents.
 * Input: 
 *  r0: target
 *  r1: overflow buffer
 * Output: None
 * Side effects:
 *  Prints the contents of the canary, target, and overflow buffers.
 */
review_stack:
  push {r4,r5,r6,fp,lr} 
  mov r5, r0
  mov r6, r1
  
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

  ldr r0, =_newline_str
  ldr r1, =_newline_str_len
  bl write_to_stdout
  
  pop {r4,r5,r6,fp,lr}
  bx lr


/* copy_str:
 *  Copy string from one buffer to another..
 * Input: 
 *  r0: char* src
 *  r1: char* dst
 * Output: None
 * Side Effects: N/a
 */
copy_str:
  push {lr}
  _copy_str_while_loop:
    ldr r2, [r0]
    and r2, r2, #0xFF

    cmp r2, #0
    beq _end_copy_str_while_loop
    strb r2, [r1]
    add r0, r0, #1
    add r1, r1, #1
    b _copy_str_while_loop
  
  _end_copy_str_while_loop:

  pop {lr}
  bx lr 


/* memzero:
 *  Fill vuffer with zeros.
 * Input: 
 *  r0: char* buffer
 *  r1: lenth of buffer
 * Output: None
 * Side Effects: N/A
 */
memzero:
  push {r4, lr}
  cmp r1, #0
  add r1, #1
  beq _end_memzero
  _memzero:
  mov r2, #0x0
    _memzero_while_loop:
    sub r1, #1
    cmp r1, #0
    beq _end_memzero_while_loop
    strb r2, [r0]
    add r0, #1
    b _memzero_while_loop
    _end_memzero_while_loop:
  _end_memzero:

  pop {r4, lr}
  bx lr


/* write_by_len:
 *  print output using given length
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
    bne wbl_flowbl_write
    ldr r6, [r1]
    add r6, r6, #0x20
    str r6, [r1]

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


/* write_to_stdout:
 *  Wrapper for Syscall::write. Prints null-terminated string.
 * Input: 
 *  r0: char* buffer
 *  r1: lenth to print out
 * Output: None
 * Side Effects: Prints r1 chars from r0 to stdout.
 */
write_to_stdout:
  push {fp}
  mov r2, r1
  mov r1, r0
  mov r0, #1  // fd: stdout
  mov r7, #4  // syscall: write
  svc #0 
  pop {fp}
  bx lr


.section .data
.balign 4
  _usage_str:      .asciz "./binary <string>\nThis program takes one argument.\n"
  .set _usage_str_len, .-_usage_str
  _canary_str:     .asciz "Canary: "
  .set _canary_str_len, .-_canary_str
  _canary_fail:     .asciz "You overwrote the stack canary.\n"
  .set _canary_fail_len, .-_canary_fail
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
  _success_str: .asciz "Congrats! You overwrote the target!\n"
  .set _success_str_len, .-_success_str
  _key_str:     .asciz "The key is: \"smash the stack\"\n"
  .set _key_str_len, .-_key_str

