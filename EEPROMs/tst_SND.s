INCLUDE .\BIN\BOOTLD.SYM

NUMBUFF EQU $F0B7

DEVSND EQU $40
DEVAY1 EQU $41
DEVAY2 EQU $42
DEVAY3 EQU $43
DEVMUX EQU $45


ORG $E000
JP START

;----SOUND MODULE
		@CHANDATA:       ;SONG DATA ADDRESS 0 FOR NO DATA
                DEFS 2
                DEFS 2
                DEFS 2
                DEFS 2
		@CHANDEL:	;CHANNEL DELAY TO MUTE
                DEFS 2
                DEFS 2
                DEFS 2
                DEFS 2
		@CHANCN:         ;CURRENT NOTES IDX FOR CURRENT NOTE PLAYING
                DEFS 1
                DEFS 1
                DEFS 1
                DEFS 1
		@CHANST         DEFS 1    ;CHANNEL STATUS  BITS 0-3 SET MEANS DISABLED                
		@LINESTR 	DEFS 2		;ADDRESS OF LINEBUF FOR PRINTING ON STRING
		@LINEPOS 	DEFS 1
		@NUMBUF		DEFS 7
		@STRG_STAT	DEFS 1 	;STORAGE_NEW STAUS BIT 0=0 NOT CONNECTED, 1=CONNECTED, BIT 7 DEVICE EXISTS

INCLUDE ..\..\MyModular\EEPROMs\ATL_SOUND.Z80


		@MYNUM DEFS 13 							;10CHARS MESSAGE FOR NUMBER AND 3 TERMINATED
		


@SOUTAS:	PUSH HL
		PUSH BC
		PUSH DE
		PUSH AF 							;SERIAL PRINT ASCII IN DECIMAL
		LD H, 0
		LD L, A
		LD DE, MYNUM
		CALL OUTASC
		
		LD A, 10
		LD (DE), A
		INC DE
		LD A, 13
		LD (DE), A
		INC DE
		XOR A
		LD (DE), A
		
		LD HL, MYNUM
		CALL RS_TXT
		POP AF
		POP DE	
		POP BC
		POP HL
		RET

;A:THE NUMBER
;HL THE MESSAGE
@SPRN_MESNUM:   PUSH HL
		PUSH BC
		PUSH DE
		PUSH AF 
		
		PUSH AF
		CALL RS_TXT ;MESSAGE FIRST
		LD A, ' '
		CALL RS_TX
		
		LD HL, MYNUM
		LD A, '0'
		LD (HL),A
		INC HL
		LD A, 'x'
		LD (HL),A
		INC HL
		POP AF
		CALL StrfHex ;OUTASC
		XOR A
		LD (HL), A		
		LD HL, MYNUM
		CALL RS_TXT
		CALL RS_NEWLINE	
		
		POP AF
		POP DE	
		POP BC
		POP HL
		RET

@SPRN_NUMMES:   PUSH HL
		PUSH BC
		PUSH DE
		PUSH AF 
		
		PUSH HL		
		
		;CALL BN2BCD	;A THE NUMBER OUTPUT AT HL THE BCD NUMBER		
		CALL B2D8 	;B2DBUF HAS THE NUMBER TO PRINT AS ASCII TEXT
		LD HL,B2DBUF
		CALL SkipWhitespace
		CALL RS_TXT
		LD A, ' '
		CALL RS_TX
		LD HL, MYNUM
		CALL RS_TXT
		POP HL
		CALL RS_TXT ;MESSAGE 
		CALL RS_NEWLINE	
		
		POP AF
		POP DE	
		POP BC
		POP HL
		RET

;NEW TABLE FOR 2MHz
        @nD2E2   EQU $0324                             ; D#2 / Eb2
        @nE2     EQU $02F6                             ; E2
        @nF2     EQU $02CC                             ; F2
        @nF2G2   EQU $02A4                             ; F#2 / Gb2
        @nG2     EQU $027E                             ; G2
        @nG2A2   EQU $025A                             ; G#2 / Ab2
        @nA2     EQU $0238                             ; A2
        @nA2B2   EQU $0218                             ; A#2 / Bb2
        @nB2     EQU $01FA                             ; B2
        @nC3     EQU $01DE                             ; C3
        @nC3D3   EQU $01C3                             ; C#3 / Db3
        @nD3     EQU $01AA                             ; D3
        @nD3E3   EQU $0192                             ; D#3 / Eb3
        @nE3     EQU $017B                             ; E3
        @nF3     EQU $0166                             ; F3
        @nF3G3   EQU $0152                             ; F#3 / Gb3
        @nG3     EQU $013F                             ; G3
        @nG3A3   EQU $012D                             ; G#3 / Ab3
        @nA3     EQU $011C                             ; A3
        @nA3B3   EQU $010C                             ; A#3 / Bb3
        @nB3     EQU $00FD                             ; B3
        @nC4     EQU $00EF                             ; C4 (Middle C)
        @nC4D4   EQU $00E1                             ; C#4 / Db4
        @nD4     EQU $00D5                             ; D4
        @nD4E4   EQU $00C9                             ; D#4 / Eb4
        @nE4     EQU $00BE                             ; E4
        @nF4     EQU $00B3                             ; F4
        @nF4G4   EQU $00A9                             ; F#4 / Gb4
        @nG4     EQU $009F                             ; G4
        @nG4A4   EQU $0096                             ; G#4 / Ab4
        @nA4     EQU $008E                             ; A4 (Concert A)
        @nA4B4   EQU $0086                             ; A#4 / Bb4
        @nB4     EQU $007F                             ; B4
        @nC5     EQU $0077                             ; C5
        @nC5D5   EQU $0071                             ; C#5 / Db5
        @nD5     EQU $006A                             ; D5
        @nD5E5   EQU $0064                             ; D#5 / Eb5
        @nE5     EQU $005F                             ; E5
        @nF5     EQU $0059                             ; F5
        @nF5G5   EQU $0054                             ; F#5 / Gb5
        @nG5     EQU $0050                             ; G5
        @nG5A5   EQU $004B                             ; G#5 / Ab5
        @nA5     EQU $0047                             ; A5
        @nA5B5   EQU $0043                             ; A#5 / Bb5
        @nB5     EQU $003F                             ; B5
        @nC6     EQU $003C                             ; C6
        @nC6D6   EQU $0038                             ; C#6 / Db6
        @nD6     EQU $0035                             ; D6
        @nD6E6   EQU $0032                             ; D#6 / Eb6
        @nE6     EQU $002F                             ; E6
        @nF6     EQU $002D                             ; F6
        @nF6G6   EQU $002A                             ; F#6 / Gb6
        @nG6     EQU $0028                             ; G6
        @nG6A6   EQU $0026                             ; G#6 / Ab6
        @nA6     EQU $0024                             ; A6
        @nA6B6   EQU $0022                             ; A#6 / Bb6
        @nB6     EQU $0020                             ; B6
        @nC7     EQU $001E                             ; C7
        @nC7D7   EQU $001C                             ; C#7 / Db7
        @nD7     EQU $001B                             ; D7
        @nD7E7   EQU $0019                             ; D#7 / Eb7
        @nE7     EQU $0018                             ; E7
        @nF7     EQU $0016                             ; F7
        @nF7G7   EQU $0015                             ; F#7 / Gb7
        @nG7     EQU $0014                             ; G7
        @nG7A7   EQU $0013                             ; G#7 / Ab7
        @nA7     EQU $0012                             ; A7
        @nA7B7   EQU $0011                             ; A#7 / Bb7
        @nB7     EQU $0010                             ; B7
        @nC8     EQU $000F                             ; C8
        @nC8D8   EQU $000E                             ; C#8 / Db8
        @nD8     EQU $000D                             ; D8
	@nPAUSE	 EQU $0908			       ;NO NOTE JUST PAUSE
        @nEND    EQU $0909                             ; Signals end of song


; Duration Constants
STC equ  1  ; Short Staccato note
LNG equ  2  ; Longer note / hold

;===============================================================================
; POPCORN MELODY DATA TABLE (Recalculated for 2.0 MHz Clock)
;===============================================================================
;===============================================================================
; POPCORN MELODY DATA TABLE (Correct High/Low Byte Order for 2.0 MHz Clock)
;===============================================================================
STC EQU 1
LNG EQU 2

POPCORN_DATA:
;-------------------------------------------------------------------------------
; POPCORN (Main Melody Hook) - Z80 Sound Data Table
; Tuned for: 2MHz SN76489 Layout (10-bit Clean Values)
;-------------------------------------------------------------------------------

; Duration Equates
STC     EQU 1   ; Short Staccato note
LNG     EQU 2   ; Longer note / hold

POPCORN_SONG:
;-------------------------------------------------------------------------------
; POPCORN (Main Melody Hook) - Z80 Sound Data Table
; Tuned for: 2MHz SN76489 Layout (10-bit Clean Values)
;-------------------------------------------------------------------------------

; Duration Equates
VST	EQU 1	;VERY SHORT
STC     EQU 2   ; Short Staccato note
LNG     EQU 4   ; Longer note / hold


POPCORN_SONG: 
	DW nG5
	DB STC
	DW nF5
	DB STC
	DW nG5
	DB STC
	DW nD5
	DB STC
	DW nA4
	DB VST
	DW nD5
	DB STC
	DW nG4
	DB LNG
	
	DW nG5
	DB STC
	DW nF5
	DB STC
	DW nG5
	DB STC
	DW nD5
	DB STC
	DW nA4
	DB VST
	DW nD5
	DB STC
	DW nG4
	DB LNG

;PHASE 2
	DW nG5
	DB STC
	DW nA5
	DB STC
	DW nA5B5	
	DB VST
	DW nA5
	DB STC
	DW nA5B5	
	DB STC
	DW nA5B5
	DB STC
	DW nG5
	DB VST	
	DW nA5
	DB STC
	DW nG5
	DB VST	
	DW nA5
	DB STC
	DW nA5
	DB STC
	DW nF5
	DB VST
	DW nG5
	DB STC	
	DW nF5
	DB VST
	DW nG5
	DB STC	
	DW nG5
	DB STC	
	DW nD5E5
	DB VST
	DW nG5
	DB STC	
	DW nPAUSE
	DB STC

	DW nG5
	DB STC
	DW nF5	
	DB STC
	DW nG5
	DB STC
	DW nD5
	DB STC
	DW nA4B4
	DB VST
	DW nD5
	DB STC
	DW nG4
	DB LNG

	DW nG5
	DB STC
	DW nF5	
	DB STC
	DW nG5
	DB STC
	DW nD5
	DB STC
	DW nA4B4
	DB VST
	DW nD5
	DB STC
	DW nG4
	DB LNG

	DW nG5
	DB STC
	DW nA5
	DB STC


	DW nA5B5
	DB STC
	DW nA5
	DB VST
	DW nA5B5
	DB STC
	DW nA5B5
	DB STC
	DW nG5
	DB STC
	DW nA5
	DB STC
	DW nG5
	DB STC
	DW nA5
	DB STC
	DW nA5
	DB STC
	DW nF5
	DB VST
	DW nG5
	DB STC
	DW nF5
	DB STC
	DW nG5
	DB STC
	DW nG5
	DB STC
	DW nA5
	DB STC
	DW nA5B5
	DB STC
	DW nPAUSE
	DB STC
	DW nD6
	DB STC
	DW nC6
	DB STC




	

	DW nEND
	DW nEND


;-------------------------------------------------------------------------------
; SND_NOTE: Plays a single note on a specified channel.
;
; Parameters:
;   HL: Clean 10-bit pitch value (0 - 1023)
;   A:  Channel number (0, 1, or 2)
;-------------------------------------------------------------------------------
SND_NOTE:   PUSH AF
            PUSH BC
            PUSH HL             ; Preserve HL as requested

            ; 1. Isolate channel, shift to bits 6 & 5, and set Bit 7 command flag
            AND $03             ; Keep channel 0-3
            RLCA
            RLCA
            RLCA
            RLCA
            RLCA                ; Channel is now at bits 6 and 5
            OR $80              ; Force Bit 7 to 1 (SN76489 Latch Command)
            LD B, A             ; Save this base command byte in B

            ; 2. Extract the 4 LSBs from HL for the first byte
            LD A, L
            AND $0F             ; Keep lowest 4 bits
            OR B                ; Merge with channel and Latch command flag
            CALL SND_OUT        ; Send 1st Byte (1 C1 C0 0 D3 D2 D1 D0)

            ; 3. Extract the 6 MSBs from HL for the second byte
            ; We need to shift the 10-bit value right by 4 bits
            POP HL              ; Retrieve HL to read original value
            PUSH HL             ; Keep it pushed to satisfy "Preserved" constraint
            
            SRL H               ; Shift HL right by 4 bits
            RR L
            SRL H
            RR L
            SRL H
            RR L
            SRL H
            RR L                ; L now holds the upper 6 bits in its lower 6 slots

            LD A, L
            AND $3F             ; Ensure bits 6 and 7 are 0 (Bit 7 must be 0)
            CALL SND_OUT        ; Send 2nd Byte (0 0 D9 D8 D7 D6 D5 D4)

            POP HL
            POP BC
            POP AF
            RET

; Delay routine: Loops until BC reaches 0
; Adjust the starting value of BC to control tempo
DELAY:
    DEC BC
    LD A, B
    OR C
    JR NZ, DELAY
    RET

;===============================================================================
; POPCORN MELODY PLAYER (~20 Second Loop)
;===============================================================================
PLAY_POPCORN:
    LD IX, POPCORN_SONG     ; Point IX to the start of the melody data


PLAY_LOOP:
    ; Read the Note Frequency (2 bytes)
    LD L, (IX+0)
    LD H, (IX+1)
    
    ; Check if we hit the end of the song marker ($0909)
    LD A, H
    CP $09
    JR NZ, CONTINUE_PLAY
    LD A, L
    CP $09
    RET Z
    CP $08 
    JR NZ, CONTINUE_PLAY
;PAUSE
    LD A, 0
    LD C, SNDMUTE
    CALL SND_SETVOLUME
   
    JR SKIP_NOTE    


CONTINUE_PLAY:
    ; Set the Channel
    LD A, 0
    LD C, SNDVOLHI
    CALL SND_SETVOLUME

    LD A, 0                 ; Play on Channel 1
    CALL SND_NOTE           ; Call your custom sound function

    ; Read the Duration (1 byte)
SKIP_NOTE    
    LD E, (IX+2)            ; Get duration multiplier
    LD D, 0
    
DELAY_OUTER:
    PUSH DE
    PUSH IX
    LD B,65
    CALL DELAYMILI
    POP IX
    POP DE
    
    DEC DE
    LD A, D
    OR E
    JR NZ, DELAY_OUTER

    ; Move to the next note entry (3 bytes forward: 2 for freq, 1 for duration)
    INC IX
    INC IX
    INC IX
    LD A, 0
    LD C, SNDMUTE

    LD B,20
    CALL DELAYMILI
    JR PLAY_LOOP





SND_SETSN76489:	LD A,$80		;D7 CONTROLS THE AUDIO SELECTION
		OUT (DEVMUX),A		;D7=1 THEN SN76489, D7=0 THEN AY38912
		CALL SND_INIT		
		;CALL SND_BEEP

		LD A, 0
		LD C, SNDVOLHI
		CALL SND_SETVOLUME

CALL PLAY_POPCORN




		LD B,200
		CALL DELAYMILI
		;CALL SND_BEEP2
;		;CALL PLAY_POPCORN
		CALL SND_MUTEALL	
		RET





START:	CALL RS_MESG
	DEFM 'TESTING SOUND'
	DB 10,13,0
	
	CALL SND_SETSN76489
	



	JP BOOTMENU


	call printnum

    RET

STR_I2C	DEFM "I2C INITIALIZED"
	DB 10,13,0

STR0	DEFM "LCD INITIALIZED"
	DB 0



