INCLUDE .\BIN\BOOTLD.SYM

MENU EQU $07A7

NUMBUFF EQU $F0B7


VIDADDR EQU $A000
VIDCNFG EQU $BFF8 ;32760

ORG $6000
JP INITVGA

@OS_PRINTMSG:	POP HL
		PUSH HL
		CALL RS_TXT ; PRINTS A ZT STRING ON HL
		POP DE  ;DE ON STRING
		PUSH HL ;CONTINUE AFTER THE MESG	
		; DO OTHER STUFF WITHT THE STRING ADDESS LIKE PRINT ON SCREEN STRING ON DE
		
		RET

STRG_LOADFILE:  PUSH    DE
                PUSH    BC
                CALL    COPYFNAME
                XOR     A                      ; Read-only
                CALL    STRG_OPNFILE
                JR      NZ, FOPENERR
                POP     BC                     ; Byte count
                POP     DE                     ; Destination buffer
                CALL    STRG_BLKREAD
                JR      Z, FREADOK
                CALL    PRINTNUM
                CALL    OS_PRINTMSG
                DEFM    " ERROR READING FILE"
                DB      10, 13, 0
                PUSH    DE
                PUSH    BC
                JR      FOPENERR
FREADOK:        PUSH    BC
                CALL    B2D16
                LD      HL, B2DBUF
                CALL    SKIPSPC
                CALL    RS_TXT
                CALL    OS_PRINTMSG
                DEFM    " BYTES READ"
                DB      10, 13, 0
                CALL    STRG_CLSFILE
                POP     BC                     ; Bytes loaded to buffer
                CALL    OS_PRINTMSG
                DEFM    " CLOSED"
                DB      10, 13, 0
                XOR     A
                RET
FOPENERR:       POP     BC
                POP     DE
                CALL    PRINTNUM
                CALL    OS_PRINTMSG
                DEFM    "-->ERROR AT LOADFILE"
                DB      10, 13, 0
                LD      HL, STRGBUFF
                CALL    RS_TXT
                CALL    RS_NEWLINE
                SCF
                RET




INITVGA:	NOP
		;SET SCREENS ENABLED
		LD HL,SCRNST
		RES 0,(HL)	;DISABLE LCD
		SET 1,(HL)	;ENABLE VGA
;VGA SCREEN		
		LD HL, CHARSETFILE		
		LD BC, 3000		;MAX FILE SIZE
		LD DE, $5000;FONT_ADDR 
		CALL STRG_LOADFILE
		JR NC, CHFILOK
		CALL RS_MESG
		DEFM "ERROR LOADING CHARSET"
		DB 13,10,0
		HALT
CHFILOK:	CALL VGA_INIT
                CALL OS_PRNMSGSCR
		DEFM "VGA INITIALIZED"
		DB 10,13,0	

JP BOOTMENU


LD HL,MESS2
LD DE,VIDADDR
CALL PUTMESS

LD B,5
CALL GETPGINBANK
LD (TMP),A

CALL VGA_SETLOWTX

LD A,$C7
LD B,5
CALL PUTPGINBANK

LD A,$C7
ADD 3		;CONFIG PAGE
LD B,6
CALL PUTPGINBANK
LD HL,VIDCNFG 
LD A, (HL)
CALL PRINTNUM
INC HL
LD A, (HL)
CALL PRINTNUM



LD HL,MESS1
LD DE,VIDADDR
CALL PUTMESS


;LD A,(TMP)
;LD B,5
;CALL PUTPGINBANK


JP MENU

TMP	DEFB 0,0

PUTMESS: LD A,(HL)
	CP 0
	RET Z
	LD (DE),A
	INC DE
	INC HL
	JR PUTMESS
 
CHARSETFILE	DEFM "\FONT.CHR"		;2560 BYTES 
		DB 0

MESS1: DEFM "HELLO WORLD"
       DB 0

MESS2: DEFM "WORLD HELLO"
       DB 0
