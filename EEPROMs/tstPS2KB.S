INCLUDE .\BIN\BOOTLD.SYM


NUMBUFF EQU $F0B7

DEVKBI EQU $48


ORG $E000


	CALL RS_MESG
	DEFM 'TESTING PS2 KEYB'
	DB 10,13,0


	

	CALL SETLED:
	JP BOOTMENU


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

SETLED: ;call getch

	

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
