OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY
{
  /* Unified 32 KB BSRAM at 0x30000000 */
  ram (rwx) : ORIGIN = 0x30000000, LENGTH = 32K
}

SECTIONS
{
  .text : {
    *(.text.crt0)
    *(.text .text.*)
  } > ram

  .rodata : {
    *(.rodata .rodata.*)
  } > ram

  .data : {
    *(.data .data.*)
  } > ram

  .bss : {
    __bss_start = .;
    *(.bss .bss.*)
    *(COMMON)
    __bss_end = .;
  } > ram

  /* Top of Stack at end of 32 KB RAM (0x30008000) */
  __stack_top = ORIGIN(ram) + LENGTH(ram);
}