; 345678901234567890123456789012345678901234567890123456789012345678901234567890
; Instruction set test for xgate RISC processor core
; Bob Hayes - Sept 23 2009
;  Version 0.1 Basic tests of Debug Mode


	CPU	XGATE
	
	ORG	$fe00
	DS.W	2 	; reserve two words at channel 0
	; channel 1
	DC.W	_START  ; point to start address
	DC.W	V_PTR   ; point to initial variables
	; channel 2
	DC.W	_START2	; point to start address
	DC.W	V_PTR   ; point to initial variables
	; channel 3
	DC.W	_ERROR	; point to start address
	DC.W	V_PTR   ; point to initial variables
	; channel 4
	DC.W	_ERROR	; point to start address
	DC.W	V_PTR   ; point to initial variables
	; channel 5
	DC.W	_ERROR	; point to start address
	DC.W	V_PTR   ; point to initial variables
	; channel 6
	DC.W	_ERROR	; point to start address
	DC.W	V_PTR   ; point to initial variables
	; channel 7
	DC.W	_ERROR	; point to start address
	DC.W	V_PTR   ; point to initial variables
	; channel 8
	DC.W	_ERROR	; point to start address
	DC.W	V_PTR   ; point to initial variables
	; channel 9
	DC.W	_ERROR	; point to start address
	DC.W	V_PTR   ; point to initial variables
	; channel 10
	DC.W	_ERROR	; point to start address
	DC.W	V_PTR   	; point to initial variables

	ORG	$2000 ; with comment

V_PTR	EQU	123


        DC.W	BACK_
	DS.W	8
	DC.B	$56
	DS.B	11

	ALIGN	1

;-------------------------------------------------------------------------------
;   Place where undefined interrupts go
;-------------------------------------------------------------------------------
_ERROR
        LDL	R2,#$04    ; Sent Message to Testbench Error Register
	LDH     R2,#$80
	LDL     R3,#$ff
	STB     R3,(R2,#0)
	
        SIF
	RTS


;-------------------------------------------------------------------------------
;   Test Debug Mode and Single Step instructions
;
;    Note: The testbench checks the PC values so adding or removing instructions
;          from this test will also require a change to the testbench
;          expected values.
;-------------------------------------------------------------------------------
_START
	LDL	R2,#$00    ; Sent Message to Testbench Check Point Register
	LDH     R2,#$80
	LDL     R3,#$01
	STB     R3,(R2,#0)
	STB     R3,(R2,#2) ; Send Message to clear Testbench interrupt register


	; Test
	LDL	R4,#$c3	;
	STW     R4,(R0,#$08)	;
	LDL	R3,#$01		; R3 = $01
	
	BRK			; Enter Debug mode and start doing Single Step Commands
				;  from the testbench. Verify PC and R3 values.

	ADDL    R3,#$01		; R3 + $01 => R3 (R3 = $02)
	NOP
	BRA	_BRA_OK1	; Do Foward Branch Single Step
	ADDL    R3,#$40		; For error detection
	NOP
	ADDL    R3,#$60		; For error detection
_BRA_OK2
	STW     R3,(R0,#$0c)	; 
	ADDL    R3,#$01		; R3 + $01 => R3 (R3 = $04)
	
				; Testbench Clears Debug mode

	CMP     R4,R7    	; Check Load and Store commands received correct data
	BNE     _FAIL
	LDW     R5,(R0,#$0c)	;
	ADDL    R5,#$01		; R5 + $01 => R5 (R5 = $04) Catch up to latest R3 value
	CMP     R3,R5    	;
	BNE     _FAIL
	
	LDL	R2,#$00		; Sent Message to Testbench Check Point Register
	LDH     R2,#$80
	LDL     R3,#$02
	STB     R3,(R2,#0)
	
	SIF	
	RTS

_BRA_OK1
	ADDL    R3,#$01		; R3 + $01 => R3 (R3 = $03)
	LDW     R7,(R0,#$08)	;
	BRA	_BRA_OK2	; Do Backward Branch

_FAIL
	LDL	R2,#$04    ; Sent Message to Testbench Error Register
	LDH     R2,#$80
	LDL     R3,#$01
	STB     R3,(R2,#0)

        SIF
	RTS


;-------------------------------------------------------------------------------
;   Test Debug Command
;-------------------------------------------------------------------------------
_START2
	LDL	R2,#$00    ; Sent Message to Testbench Check Point Register
	LDH     R2,#$80
	LDL     R3,#$03
	STB     R3,(R2,#0)
	STB     R3,(R2,#2) ; Send Message to clear Testbench interrupt register


	; Test
	LDL	R3,#$01		; R3 = $01
	LDL	R4,#$01		; R4 = $01
	LDL	R7,#$01		; R4 = $01
	
_T2_LOOP
	ADDL    R3,#$01		; R3 + $01 => R3 (R3 = $02)
	NOP
	BRA	_T2_LOOP	; Create an infinate loop. The testbench will
				;  take control using the Debug bit and change
				;  the PC to exit the loop.

	ADDL    R4,#$01		; Test bench will set the PC to here

	CMP     R4,R7    	; Check Load and Store commands received correct data
	BNE     _FAIL2
	
_END_2	LDL	R2,#$00		; Sent Message to Testbench Check Point Register
	LDH     R2,#$80
	LDL     R3,#$04
	STB     R3,(R2,#0)
	
	SIF	
	RTS


_FAIL2
	LDL	R2,#$04    ; Sent Message to Testbench Error Register
	LDH     R2,#$80
	LDL     R3,#$02
	STB     R3,(R2,#0)

        SIF
	RTS


;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
	

;empty line

BACK_


	SIF	R7
	BRK

	ORG	$8000 ; Special Testbench Addresses
_BENCH	DS.W	8




