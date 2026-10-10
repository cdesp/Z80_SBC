.section .text.crt0
.global _start
.type _start, @function

_start:
    /* 1. Set Stack Pointer to top of 32 KB BSRAM (0x30008000) */
    la sp, __stack_top

    /* 2. Zero out the uninitialized data section (.bss) */
    la t0, __bss_start
    la t1, __bss_end
clear_bss_loop:
    bgeu t0, t1, call_main
    sw zero, 0(t0)
    addi t0, t0, 4
    j clear_bss_loop

call_main:
    /* 3. Jump to main function */
    call main

shutdown:
    /* 4. Infinite loop if main returns */
    j shutdown