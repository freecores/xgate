; 345678901234567890123456789012345678901234567890123456789012345678901234567890
; Interrupt test for xgate RISC processor core
; Bob Hayes - May 11 2010


        CPU     XGATE

        ORG     $fe00
        DS.W    2       ; reserve two words at channel 0
        ; channel 1
        DC.W    _IRQ1   ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 2
        DC.W    _IRQ2   ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 3
        DC.W    _IRQ3   ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 4
        DC.W    _IRQ4   ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 5
        DC.W    _IRQ5   ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 6
        DC.W    _IRQ6   ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 7
        DC.W    _IRQ7   ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 8
        DC.W    _IRQ8   ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 9
        DC.W    _IRQ9   ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 10
        DC.W    _IRQ10  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 11
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 12
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 13
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 14
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 15
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 16
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 17
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 18
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 19
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 20
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 21
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 22
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 23
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 24
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 25
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 26
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 27
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 28
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 29
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 30
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 31
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 32
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 33
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 34
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 35
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 36
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 37
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 38
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 39
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 40
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 41
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 42
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 43
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 44
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 45
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 46
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 47
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 48
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 49
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables
        ; channel 50
        DC.W    _ERROR  ; point to start address
        DC.W    V_PTR   ; point to initial variables

        ORG     $2000 ; with comment

V_PTR   EQU     123

        DC.W    END_CODE_
        DS.W    8
        DC.B    $56
        DS.B    11

        ALIGN   1

;-------------------------------------------------------------------------------
;   Place where undefined interrupts go
;-------------------------------------------------------------------------------
_ERROR
        LDL     R2,#$04    ; Sent Message to Testbench Error Register
        LDH     R2,#$80
        LDL     R3,#$ff
        STB     R3,(R2,#0)

        SIF
        RTS


;-------------------------------------------------------------------------------
;   Test IRQ
;-------------------------------------------------------------------------------
_IRQ1
        LDL     R2,#$00    ; Sent Message to Testbench Check Point Register
        LDH     R2,#$80    ; R3 = Testbench base address = Checkpoint address
        LDL     R3,#1      ; Checkpoint Value
        STB     R3,(R2,#0) ; Send Checkpoint value

        ;Test Interrupt
        STW     R3,(R2,#$0a)    ; Should be even offsets
_TB_POLL_1
        LDW     R4,(R2,#$0a)    ;
        CMP     R3,R4           ;
        BEQ     _TB_POLL_1

_END_1
        LDL     R3,#101
        STB     R3,(R2,#0) ; Send Checkpoint value

        SIF
        RTS


;-------------------------------------------------------------------------------
;   Test Interrupt
;-------------------------------------------------------------------------------
_IRQ2
        LDL     R2,#$00    ; Sent Message to Testbench Check Point Register
        LDH     R2,#$80    ; R3 = Testbench base address = Checkpoint address
        LDL     R3,#2      ; Checkpoint Value
        STB     R3,(R2,#0) ; Send Checkpoint value

        ;Test Interrupt
        STW     R3,(R2,#$0a)    ; Should be even offsets
_TB_POLL_2
        LDW     R4,(R2,#$0a)    ;
        CMP     R3,R4           ;
        BEQ     _TB_POLL_2

_END_2
        LDL     R3,#102
        STB     R3,(R2,#0) ; Send Checkpoint value

        SIF
        RTS


;-------------------------------------------------------------------------------
;   Test Interrupt
;-------------------------------------------------------------------------------
_IRQ3
        LDL     R2,#$00    ; Sent Message to Testbench Check Point Register
        LDH     R2,#$80    ; R3 = Testbench base address = Checkpoint address
        LDL     R3,#3      ; Checkpoint Value
        STB     R3,(R2,#0) ; Send Checkpoint value

        ;Test Interrupt
        STW     R3,(R2,#$0a)    ; Should be even offsets
_TB_POLL_3
        LDW     R4,(R2,#$0a)    ;
        CMP     R3,R4           ;
        BEQ     _TB_POLL_3

_END_3
        LDL     R3,#103
        STB     R3,(R2,#0) ; Send Checkpoint value

        SIF
        RTS


;-------------------------------------------------------------------------------
;   Test Interrupt
;-------------------------------------------------------------------------------
_IRQ4
        LDL     R2,#$00    ; Sent Message to Testbench Check Point Register
        LDH     R2,#$80
        LDL     R3,#4      ; Checkpoint Value
        STB     R3,(R2,#0)

        ;Test Interrupt
        STW     R3,(R2,#$0a)    ; Should be even offsets
_TB_POLL_4
        LDW     R4,(R2,#$0a)    ;
        CMP     R3,R4           ;
        BEQ     _TB_POLL_4

_END_4
        LDL     R3,#8
        STB     R3,(R2,#0) ; Send Checkpoint value

        SIF
        RTS


;-------------------------------------------------------------------------------
;   Test Interrupt
;-------------------------------------------------------------------------------
_IRQ5
        LDL     R2,#$00    ; Sent Message to Testbench Check Point Register
        LDH     R2,#$80
        LDL     R3,#$05    ; Checkpoint Value
        STB     R3,(R2,#0)

        ;Test Interrupt
        STW     R3,(R2,#$0a)    ; Should be even offsets
_TB_POLL_5
        LDW     R4,(R2,#$0a)    ;
        CMP     R3,R4           ;
        BEQ     _TB_POLL_5

_END_5
        LDL     R3,#10
        STB     R3,(R2,#0) ; Send Checkpoint value

        SIF
        RTS


;-------------------------------------------------------------------------------
;   Test Interrupt
;-------------------------------------------------------------------------------
_IRQ6
        LDL     R2,#$00    ; Sent Message to Testbench Check Point Register
        LDH     R2,#$80
        LDL     R3,#6      ; Checkpoint Value
        STB     R3,(R2,#0)

        ;Test Interrupt
        STW     R3,(R2,#$0a)    ; Should be even offsets
_TB_POLL_6
        LDW     R4,(R2,#$0a)    ;
        CMP     R3,R4           ;
        BEQ     _TB_POLL_6

_END_6
        LDL     R3,#$12
        STB     R3,(R2,#0) ; Send Checkpoint value

        SIF
        RTS


;-------------------------------------------------------------------------------
;   Test Interrupt
;-------------------------------------------------------------------------------
_IRQ7
        LDL     R2,#$00    ; Sent Message to Testbench Check Point Register
        LDH     R2,#$80
        LDL     R3,#7      ; Checkpoint Value
        STB     R3,(R2,#0)

        ;Test Interrupt
        STW     R3,(R2,#$0a)    ; Should be even offsets
_TB_POLL_7
        LDW     R4,(R2,#$0a)    ;
        CMP     R3,R4           ;
        BEQ     _TB_POLL_7

_END_7
        LDL     R3,#14
        STB     R3,(R2,#0) ; Send Checkpoint value

        SIF
        RTS


;-------------------------------------------------------------------------------
;   Test Interrupt
;-------------------------------------------------------------------------------
_IRQ8
        LDL     R2,#$00    ; Sent Message to Testbench Check Point Register
        LDH     R2,#$80
        LDL     R3,#8      ; Checkpoint Value
        STB     R3,(R2,#0)

        ;Test Interrupt
        STW     R3,(R2,#$0a)    ; Should be even offsets
_TB_POLL_8
        LDW     R4,(R2,#$0a)    ;
        CMP     R3,R4           ;
        BEQ     _TB_POLL_8

_END_8
        LDL     R3,#16
        STB     R3,(R2,#0) ; Send Checkpoint value

        SIF
        RTS


;-------------------------------------------------------------------------------
;   Test Interrupt
;-------------------------------------------------------------------------------
_IRQ9
        LDL     R2,#$00    ; Sent Message to Testbench Check Point Register
        LDH     R2,#$80
        LDL     R3,#9      ; Checkpoint Value
        STB     R3,(R2,#0)

        ;Test Interrupt
        STW     R3,(R2,#$0a)    ; Should be even offsets
_TB_POLL_9
        LDW     R4,(R2,#$0a)    ;
        CMP     R3,R4           ;
        BEQ     _TB_POLL_9

_END_9
        LDL     R3,#18
        STB     R3,(R2,#0) ; Send Checkpoint value

        SIF
        RTS


;-------------------------------------------------------------------------------
;   Test Interrupt
;-------------------------------------------------------------------------------
_IRQ10
        LDL     R2,#$00    ; Sent Message to Testbench Check Point Register
        LDH     R2,#$80
        LDL     R3,#10     ; Checkpoint Value
        STB     R3,(R2,#0)

        ;Test Interrupt
        STW     R3,(R2,#$0a)    ; Should be even offsets
_TB_POLL_10
        LDW     R4,(R2,#$0a)    ;
        CMP     R3,R4           ;
        BEQ     _TB_POLL_10

_END_10
        LDL     R3,#$20
        STB     R3,(R2,#0) ; Send Checkpoint value

        SIF
        RTS


;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
END_CODE_

        ORG     $8000 ; Special Testbench Addresses
_BENCH  DS.W    16




