		NAME PAGING FUNCTIONS
		
		GLOBAL PAGEIN_NEWROM
		GLOBAL PAGEOUT_NEWROM
		
; ================================
; Bank constants
; ================================
		BANK_BASIC EQU 6 						; slot $C000–$DFFF
		BASIC_PAGE EQU 121						; <-- replace with your BASIC page
		NEWROM_PAGE EQU 126 						; <-- replace with your new ROM page
		
; Temporary storage for interrupt state
		IFF_STATE   EQU SERERR              ; in RAM < $8000

; ================================
; Save IFF to (IFF_STATE)
; ================================
SAVE_IFF:
        PUSH AF
        LD   A,I                 ; get I register
        JP   PO, SIF1              ; if P/V=0 → IFF2=0 (disabled)
        LD   A,1
        JR   SIF2
SIF1:   XOR  A                   ; A=0
SIF2:   LD  (IFF_STATE),A
        POP  AF
        RET

; ================================
; Restore IFF from (IFF_STATE)
; ================================
RESTORE_IFF:
        PUSH AF
        LD   A,(IFF_STATE)
        OR   A
        JR   Z, noei
        EI
        JR   done
noei:   DI
done:   POP  AF
        RET

; ================================
; PAGEIN_NEWROM
; ================================
PAGEIN_NEWROM:
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        PUSH IX
        PUSH IY

        CALL SAVE_IFF
        DI

        LD   A,NEWROM_PAGE
        LD   B,BANK_BASIC
        CALL PUTPGINBANK

        CALL RESTORE_IFF

        POP  IY
        POP  IX
        POP  HL
        POP  DE
        POP  BC
        POP  AF
        RET

; ================================
; PAGEOUT_NEWROM
; ================================
PAGEOUT_NEWROM:
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        PUSH IX
        PUSH IY

        CALL SAVE_IFF
        DI

        LD   A,BASIC_PAGE
        LD   B,BANK_BASIC
        CALL PUTPGINBANK

        CALL RESTORE_IFF

        POP  IY
        POP  IX
        POP  HL
        POP  DE
        POP  BC
        POP  AF
        RET
