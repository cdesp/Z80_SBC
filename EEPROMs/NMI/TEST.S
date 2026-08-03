include ..\Bootloader\BIN\BOOTLD.SYM

org $6000


jp start





start::
       ld a,$85
       LD B,4
       CALL PUTPGINBANK
       JP BOOTMENU		
