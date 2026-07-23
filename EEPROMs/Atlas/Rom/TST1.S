ORG $6000

INCLUDE OSATLAS.SYM



STRG_DIRNMCHG EQU $0FDF


LD HL,DIRNM
LD A,'\'
LD (HL),A
CALL RS_TXT
CALL RS_NEWLINE

LD HL,FN1
CALL STRG_DIRNMCHG2 

LD HL,DIRNM
CALL RS_TXT
CALL RS_NEWLINE




		JP MENU


NEXTDIR:        INC     HL		;1ST LETTER ALWAYS NON 0
		LD      A, (HL)
                OR      A
                RET Z
		CP '/'
		RET Z
		CP '\'
		RET Z
                JR      NEXTDIR

STRG_DIRNMCHG2:  PUSH    HL
                LD      A, (HL)
                CP      '\'
                JR      Z, DNC_RESET
                CP      '/'
                JR      Z, DNC_RESET
                CP      '.'
                JR      NZ, DNC_ADD
                CP      '.'
                JR      Z, DNC_RMV
                POP     HL
                RET                            ; Do nothing for . or similar
DNC_RESET:      LD      HL, DIRNM
                LD      (HL), '\'
                INC     HL
DNC_TERMIN:     LD      (HL), 0
                INC     HL
                LD      (HL), 0
                POP     HL
                RET
DNC_RMV:        LD      HL, DIRNM
RMLP:           PUSH    HL
                POP     DE                    ;DE=HL
                CALL    NEXTDIR               ;STARTS FROM HL+1
                LD      A, (HL)
                OR      A
                JR      NZ, RMLP
                ; DE POINTS TO THE PREVIOUS DIR
		LD 	HL,DIRNM
		OR A
		SBC 	HL,DE
		JR 	NZ, SKP0
		INC DE
SKP0:		EX      DE,HL
                JR      DNC_TERMIN
DNC_ADD:        EX      DE, HL                 ; DE points to the new directory name
                LD      HL, DIRNM
ADDNXT:         CALL    NEXTDIR
                LD      A, (HL)
                OR      A
                JR      NZ, ADDNXT
                EX      DE, HL
						;DE points to the destination 
                DEC DE				;check for '/' 
                LD A,(DE)
                INC DE
                CP '/'
                JR Z, ADDNXT2
                CP '\'
                JR Z, ADDNXT2
                LD A,'\'
                LD (DE),A       
                INC DE
ADDNXT2:        LD      A, (HL)
                LD      (DE), A
                INC     HL
                INC     DE
                OR      A
                JR      NZ, ADDNXT2
                EX      DE, HL
                LD      (HL), 0                ; Signal end of directories with a second zero
                POP     HL
                RET


FN1 DEFM ".."
	DB 0

PSERR DEFM "eRROR PARSING"
	DB 0



	

