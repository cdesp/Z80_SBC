ORG $6000

INCLUDE ..\OSATLAS.SYM

inctm equ $0E0A;
mytab equ $0dc1;

jp skip
EI
call COPYINTTAB

ld b,10
LD hl, INTTAB
dogn: ld a,(hl)
push bc
push hl
call soutas
pop hl
pop bc
inc hl
djnz dogn


skip:

ld hl,inttab
ld a,(hl)
push hl
call soutas
pop hl
inc hl
ld a,(hl)
call soutas

call myINTSER

;call inctm 

LD B,1

AGN1:
LD HL,TIMECTR
LD A, (HL)
PUSH BC
CALL SOUTAS
CALL DEL2
POP BC
DJNZ AGN1


 
JP MENU


myINTSER:	PUSH AF
		PUSH BC
		PUSH DE
		PUSH HL						
		PUSH IX
		
;TEST INTERRUPT MODULE
;AND ACT ON WHAT DEVICE CAUSED THE INTERRUPT
		IN A, (DEVINT)							;WAS DEVINP BEFORE V 0.43
		AND 0X07							;BITS 0-2		
		;DEC A 								;CONVERT 1-8 TO 0-7 NOT NEEDED ON NEW BOARD ONLY ON MY PROTOTYPE
		;CP 8
		;JR NC,IS_EX							;ALWAYS LESS THAN 8
		LD IX, INTTAB
		LD B, 0
		LD C, A
		SLA C								;DOUBLE THIS CAUSE 2 BYTES PER ADDR
		ADD IX, BC
		push bc
		ld a,b
		call soutas
		pop bc
		ld a,c
		call soutas
		LD L, (IX)
		LD H, (IX + 1)
		push hl
		ld a,h
		call soutas
		ld a,l
		call soutas
		pop hl

		LD BC, myIS_EX
		PUSH BC								;RETURN ADDRESS
		JP (HL)								;JP TO HL
		
myIS_EX:		POP IX
		POP HL
		POP DE
		POP BC
		POP AF
		EI
		RET								;SAME AS RETI FOR IM1