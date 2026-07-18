INCLUDE .\BIN\BOOTLD.SYM


NUMBUFF EQU $F0B7

DEVKBI EQU $48

GET_KBCHAR EQU $07E2


ORG $E000


	CALL RS_MESG
	DEFM 'TESTING PS2 KEYB'
	DB 10,13,0


	

	CALL SETNUMLOCK

AGAN:	CALL GET_KBCHAR2 
	LD A,'R'
	CALL RS_TX

	JP AGAN
	


GET_KBCHAR2:	XOR A
		
;GET CHAR FROM RS232
		CALL RS_KEYRD 							;CHAR IN RS232?
		JR Z, GT_TST2
		;JR Z, GET_KBCHAR2
		LD A,'S'
		CALL RS_RX 							; GET THAT CHAR
		RET
;GET CHAR FROM PS2 KEYBOARD
GT_TST2:	CALL PS2ISK 						;ZF=1 IF WE HAVE A KEY ELSE 0
		JR Z, GET_KBCHAR2 						;RECHECK
		LD A,'C'
		CALL RS_TX
		CALL READCHAR
		OR A
		JP Z,GET_KBCHAR2
		
		PUSH AF
		CALL RS_TX
		LD A, 10
		CALL RS_TX
		LD A, 13
		CALL RS_TX
		POP AF
		RET




RECHK: 	IN A,(DEVKBI+1)
	BIT 0,A
	JR Z, RECHK

	CALL RS_MESG
	DEFM 'KEY PRESSED'
	DB 10,13,0
	
	IN A,(DEVKBI)
	CALL PRINTNUM
	jP RECHK: 


; Sequence to turn on Num Lock
; Bit 0: Scroll Lock
; Bit 1: Num Lock
; Bit 2: Caps Lock

SETLED2: ;call getch

	

    LD A, $ED
    OUT (DEVKBI), A   ; Send LED data to the bridge
     
DA1:    IN A,(DEVKBI+1)
	push af
	call printnum
	pop af
    SLA a
    JR C,DA1	


	ld a,'a'
	call rs_TX
	
	call getch ;;should be $FA
	cp $FA
	jr z, allok
	ld a,'e'
	call rs_TX
	
	
	
allok:    LD A, 3
    OUT (DEVKBI), A   ; Send LED data to the bridge
        ld a,'c'
	call rs_TX	
	call getch
	cp $FA
	ret z
	ld a,'e'
	call rs_TX
	ld a,'2'
	call rs_TX
	ret

    LD A, 00000010B     ; Load status: Bit 1 (Num Lock) = 1
    OUT (DEVKBI), A   ; Send LED data to the bridge
    
DA2:    IN A,(DEVKBI+1)
	push af
	call printnum
	pop af
    SLA a
    JR C,DA2


    RET


getch:  IN A,(DEVKBI+1)
	BIT 0,A
	JR Z, getch:  

	CALL RS_MESG
	DEFM 'KEY PRESSED'
	DB 10,13,0
	
	IN A,(DEVKBI)
	CALL PRINTNUM
	ret
