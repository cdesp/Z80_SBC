
DEVSER EQU $20

ORG 0

DI
JP START

SERERR EQU $
B2DINV DEFS 200
STACK EQU $-1
B2DBUF EQU B2DINV+20
B2DEND EQU B2DINV+40
LINEPOS EQU B2DINV+45
LINESTR EQU B2DINV+47
NUMBUF EQU B2DINV+70
STRGBUFF EQU B2DINV+70
MANUFACTURER_ID EQU B2DINV+1
DEVICE_ID EQU B2DINV+2
;            
;TSADD EQU 1111100000000B
;TSADD EQU 1111111111001B
TSADD EQU 8192
CNT EQU 10


TESTFLS:
; Constants based on YOUR datasheet Table 4-2
FLASH_BASE  EQU 0x2000          ; Your base address (8192)
ADDR_5555   EQU FLASH_BASE + 0x5555
ADDR_2AAA   EQU FLASH_BASE + 0x2AAA

GET_FLASH_ID:
    ; 1. Software ID Entry sequence (from your table)
    LD A, 0xAA
    LD (ADDR_5555), A
    
    LD A, 0x55
    LD (ADDR_2AAA), A
    
    LD A, 0x90                  ; Software ID Entry command
    LD (ADDR_5555), A
    
    ; 2. Read Manufacturer ID (Note 5: A0=0)
    LD HL, FLASH_BASE + 0x0000  ; A0 = 0
    LD A, (HL)
    LD (MANUFACTURER_ID), A     ; Expect 0xBF
    
    ; 3. Read Device ID (Note 5: A0=1)
    LD HL, FLASH_BASE + 0x0001  ; A0 = 1
    LD A, (HL)
    LD (DEVICE_ID), A           ; Expect 0xD7 for '040
    
    ; 4. Exit ID Mode (Reset)
    LD A, 0xAA
    
    LD (ADDR_5555), A
    
    LD A, 0x55
    
    LD (ADDR_2AAA), A
    
    LD A, 0xF0
    
    LD (ADDR_5555), A  ;reset
    RET

; HL = Target Sector Address (must be aligned to 4KB boundary)
ERASE_SECTOR:
    LD A, 0xAA
    LD (ADDR_5555), A
    LD A, 0x55
    LD (ADDR_2AAA), A
    LD A, 0x80
    LD (ADDR_5555), A
    LD A, 0xAA
    LD (ADDR_5555), A
    LD A, 0x55
    LD (ADDR_2AAA), A
    
    ; The 6th cycle: Send 0x30 to the Sector Address
    LD A, 0x30
    LD (HL), A
    
    ; Polling is mandatory here too!
    ; Erase completion can be checked by reading the sector address 
    ; and checking for 0xFF.
    CALL DELAY500MS 
    RET

ERASE_FIRST_8KB:
    
    LD HL, FLASH_BASE + 0x0000        ; Target Sector 0
    
    CALL ERASE_SECTOR
    
    
    LD HL, FLASH_BASE + 0x1000        ; Target Sector 1
    
    CALL ERASE_SECTOR
    
    RET

;HL ADDR
;A BYTE
WRBYTE:
    PUSH AF
    LD A, 0xAA
    
    LD (ADDR_5555), A
    
    LD A, 0x55
    
    LD (ADDR_2AAA), A
    
    LD A, 0xF0
    
    LD (ADDR_5555), A  ;reset

    NOP
    NOP

    LD A, 0xAA
    LD (ADDR_5555), A    
    LD A, 0x55
    LD (ADDR_2AAA), A    
    LD A, 0xA0                  ; Software ID Entry command
    LD (ADDR_5555), A
    POP AF

    NOP
    NOP

    LD (HL),A
	
    PUSH BC
    PUSH HL 
    PUSH AF
    CALL DELAY500MS 
    POP AF
    POP HL
    POP BC
    RET

    ; --- POLLING LOOP (Wait until DQ7 matches the data) ---

    WAIT_READY:
    
    LD E, (HL)        ; Read back the memory location
    
    XOR E             ; XOR original data with read data
    
    AND 0x80          ; Check DQ7 (bit 7)
    
    JR NZ, WAIT_READY ; If bits differ, the write is still in progress
    RET




RDBYTES:
        LD HL,MESG4
	CALL RS_TXT  

	LD HL,TSADD 
	LD BC,CNT 
	CALL TEST_RD
	RET

START:   
    LD SP,8000

    OUT ($60),A

    LD A,1
    CALL RS_INI


 
MAIN:   LD HL,NL
	CALL RS_TXT
	LD HL,NL
	CALL RS_TXT
	LD HL,MESG
	CALL RS_TXT
	

        CALL ERASE_FIRST_8KB
       
        CALL DELAY500MS 
	CALL RDBYTES

	

	LD HL,TSADD
	LD A,254
	LD B,5
LL1:	CALL WRBYTE
	INC HL
	DEC A
	DJNZ LL1


    CALL GET_FLASH_ID
    LD A,(MANUFACTURER_ID)
    LD H,0
    LD L,A
    CALL OUTHL
    LD HL,NL
    CALL RS_TXT
    LD A,(DEVICE_ID)
    LD H,0
    LD L,A
    CALL OUTHL
    LD HL,NL
    CALL RS_TXT

    CALL RDBYTES
    HALT

 


	LD A,0
	LD HL,TSADD
	LD B,255 
DA:	LD (HL),A
	INC HL
	DJNZ DA

	LD A,255
	;LD HL, 8447
	LD B,255 
DA2:	LD (HL),A
	INC HL
	DJNZ DA2


        LD HL,MESG4
	CALL RS_TXT  

	LD HL,TSADD 
	LD BC,255*2 
	CALL TEST_RD

	LD HL,NL
	CALL RS_TXT

	LD HL,8192
	LD BC,255
	CALL TEST_RD


	LD HL,MESG1
	CALL RS_TXT 

	LD HL,TSADD 
	LD BC,CNT
	CALL TEST_MEM	
	JR NC, EXIT1

	;LD HL,TSADD 
	;PUSH HL
	;LD BC,CNT
	;CALL TEST_RD
	;POP HL
	PUSH DE
	PUSH HL
	CALL OUTHL	;SHOW ADDR
	POP HL
	LD A,(HL);
	LD H,0
	LD L,A
	CALL OUTHL	;SHOW CONTENTS
	POP HL		;L HAS THE BYTE h HAS THE WRITTEN BYTE
	LD D,H
	LD H,0
	PUSH DE
	CALL OUTHL	;SHOW CONTENTS WHEN FAILED
	POP DE
	LD H,0
	LD L,D
	CALL OUTHL	;SHOW BYTE WRITTEN 0XAA OR 0X55
	LD HL, FALMSG
	CALL RS_TXT


	LD HL,NL
	CALL RS_TXT

	LD HL,MESG4
	CALL RS_TXT  
	LD B,1
AGN32	PUSH BC
	LD HL,TSADD 
	LD BC,CNT
	CALL TEST_RD

	LD HL,NL
	CALL RS_TXT


	LD B,3	
	CALL DELAYSEC
        LD HL,NL
	CALL RS_TXT
        LD HL,NL
	CALL RS_TXT

	LD A,$AB
	LD HL,TSADD
	LD B,CNT 
DA2:	LD (HL),A
	INC HL
	DJNZ DA2
	POP BC
	DJNZ AGN32

	LD B,6	
	CALL DELAYSEC
	JP MAIN
	HALT

EXIT1:	LD HL,SUCMSG
	CALL RS_TXT
	HALT

 JP MAIN   

DELAYSEC: 
	LD A,B
	ADD A,B
	LD B,A
LP1:	PUSH BC
	CALL DELAY500MS 
	POP BC
	DJNZ LP1
	RET

OUTHL: 	LD DE,ASCOUT
	CALL OUTASC
	LD A,10
	LD (DE),A
	INC DE
	LD A,13
	LD (DE),A
	INC DE
	XOR A
	LD (DE),A
	LD HL,ASCOUT
	CALL RS_TXT
	RET


MESG: DEFM "HELLO WORLD"
NL:   DB 10,13,0

MESG1: DEFM "TESTING..."
      DB 10,13,0

MESG4: DEFM "READING..."
      DB 10,13,0

SUCMSG: DEFM "SUCCESS"
      DB 10,13,0

FALMSG: DEFM "FAILED"
      DB 10,13,0



DELAY500MS:
    LD BC,0FFFFH

D1:
    DEC BC
    LD A,B
    OR C
    JR NZ,D1

    LD BC,0FFFFH

D2:
    DEC BC
    LD A,B
    OR C
    JR NZ,D2

    RET


;HL = START
;BC = NO OF BYTES
TEST_RD:
	PUSH HL
	PUSH BC
	CALL OUTHL	
	POP BC
	POP HL
	PUSH HL
	PUSH BC
	LD A,(HL)
	LD H,0
	LD L,A
	CALL OUTHL
	POP BC
	POP HL
	INC HL
	DEC BC
	LD A,B
	OR C
	JR NZ,TEST_RD
	RET
	
	
			

 ; ==============================================================================
; MEMORY TEST ROUTINE
; Input:  HL = Start Address
;         BC = Number of bytes to test
; Output: Carry flag set (C) = Error found (A = expected, E = actual)
;         Carry flag cleared (NC) = Success
; ==============================================================================
TEST_MEM:
    PUSH HL             ; Save start address
    PUSH BC             ; Save length
    
    ; --- PASS 1: Write/Verify 0xAA (10101010) ---
    LD A, 0AAh
    CALL FILL_AND_VERIFY
    JR C, MEM_ERROR     ; If error, exit with C set

    POP BC              ; Restore registers for Pass 2
    POP HL
    PUSH HL
    PUSH BC

    ; --- PASS 2: Write/Verify 0x55 (01010101) ---
    LD A, 055h
    CALL FILL_AND_VERIFY
    JR C, MEM_ERROR     ; If error, exit with C set

    POP BC              ; Cleanup
    POP HL
    OR A                ; Clear Carry flag (Success)
    RET

MEM_ERROR:
    POP BC              ; Cleanup stack
    POP HL
    SCF                 ; Set Carry flag (Error)
    RET

; Helper: Fills memory with pattern in A, then verifies it
FILL_AND_VERIFY:
    PUSH HL
    PUSH BC
    PUSH AF             ; Save pattern
    LD D,A		;save
.FILL:
    LD A,D
    LD (HL), A
    INC HL
    DEC BC
    LD A, B
    OR C
    JR NZ, .FILL
    
    POP AF              ; Restore pattern
    POP BC
    POP HL 
    LD D,A
.VERIFY: 
    LD A,D
    CP (HL)             ; Compare memory with pattern
    JR NZ, .ERROR       ; If mismatch, set Carry
    INC HL
    DEC BC
    LD A, B
    OR C
    JR NZ, .VERIFY
    OR A                ; Success (Clear Carry)
    RET
.ERROR:
    LD D, A
    LD E, (HL)          ; Put actual byte in E for debugging
    SCF                 ; Set Carry
    RET

INCLUDE ATL_SERIAL.z80
INCLUDE ATL_UTILS.Z80

ORG 1600
ASCOUT EQU $
