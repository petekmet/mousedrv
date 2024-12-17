
; In amiga mouse:
; 1 YA (V-pulse)
; 2 XA (H-pulse)
; 3 YB (VQ-pulse)
; 4 XB (HQ-pulse)

; for Y you rotate PORTA 4x, to get Y AB on 0 and 2
; for X you rotate PORTA 5x, to get X AB on 0 and 2

; Assume A = current state of encoder, X = previous state of encoder
; Encoder states: 00, 01, 11, 10

; Quadrature encoder state transition table
; Current | Previous | Direction
; 00      | 01       | Clockwise
; 01      | 11       | Clockwise
; 11      | 10       | Clockwise
; 10      | 00       | Clockwise
; 00      | 10       | Counterclockwise
; 10      | 11       | Counterclockwise
; 11      | 01       | Counterclockwise
; 01      | 00       | Counterclockwise

; Define state transition table
state_table:
    .byte 0, 1, 0, -1  ; 00 -> 00, 01, 11, 10
    .byte -1, 0, 1, 0  ; 01 -> 00, 01, 11, 10
    .byte 0, -1, 0, 1  ; 11 -> 00, 01, 11, 10
    .byte 1, 0, -1, 0  ; 10 -> 00, 01, 11, 10

; Calculate index into state transition table
    lda X              ; Load previous state into A
    asl                ; Multiply by 2 (shift left)
    tay                ; Store in Y register
    lda A              ; Load current state into A
    clc                ; Clear carry
    adc Y              ; Add Y to A (index = previous * 4 + current)
    tay                ; Store index in Y

; Get direction from state transition table
    lda state_table, Y ; Load direction from table
    beq done           ; If direction is 0, no movement

; Update position based on direction
    bpl clockwise      ; If positive, clockwise
    bmi counterclockwise ; If negative, counterclockwise

clockwise:
    iny                ; Increment position
    jmp done

counterclockwise:
    dey                ; Decrement position

done:
    rts                ; Return from subroutine