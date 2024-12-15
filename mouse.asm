pcolr0 = $2C0
bkcolor = $2C8
color1 = $2C5
color2 = $2C6
PORTA = $D300
CRITIC = $42
DMACTL = 559
GRACTL = $D01D
HPOSP0 = $D000
HPOSP1 = $D001
PMBASE = $D407

; CIO
IOCB = $340
ICCOM = $342
ICBAL = $344
ICBAH = $345
ICBLL = $348
ICBLH = $349
CIOV = $e456
EOL = $9B
CMD_PUT_RECORDS = 9
		
		run install_irq
		org $600
		
install_irq
		lda DMACTL
		ora #8
		sta DMACTL
		lda #2
		sta GRACTL
		lda #$98     ;set PMBASE to $9800
		sta PMBASE
		lda #(14*16)+10
		sta pcolr0
		 
		sei
		lda #<start
		sta $210
		lda #>start
		sta $211
		lda #$80
		sta $d200		;set AUDF1
		lda $10			;read POKMSK
		ora #1
		sta $10			;enable POKMSK
		sta $d20e		;enable IRQEN
		cli
		jsr banner
finito	jmp finito
		
start 	
		txa				;push X to stack
		pha
		tya				;push Y to stack
		pha
		
		lda CRITIC
		bne finish
		
		lda PORTA
		ror
		ror
		ror
		ror
		and #5
		cmp prevy		;compare A with xret
		beq stgx	 	;no change in xpos
	
		ldx prevy
		ldy ypos
		jsr updcnt
		sty ypos
		sta prevy

; clear cursor area
		ldx $FF		;load number of lines to clear
		lda #0		;load bitmap to clear with
clear_cur
		sta $9A00, x
		dex
		bne clear_cur

; draw cursor
		ldx #16
		ldy ypos

copycur:
		lda cursor-1, x
		sta $9A00, y
		dey
		dex
		bne copycur

; load encoders and update cursor position	
stgx	lda PORTA
		lsr
		lsr
		lsr
		lsr
		lsr
		and #5
		
		cmp prevx		;compare A with xret
		beq finish	 	;no change in xpos
	
		ldx prevx
		ldy xpos
		jsr updcnt
		sty xpos
		sta prevx

		lda xpos
		sta HPOSP0
		
finish	
		pla				;restore x and y registers
		tay
		pla
		tax
		pla
		rti

updcnt					;ldx prev
		cmp #0			;A has current PORTA, X has previous PORTA
		bne i2
		cpx #4
		beq increm

i2		cmp #4
		bne i3
		cpx #0
		beq decrem

i3		cmp #1
		bne i4
		cpx #0
		beq increm

i4		cmp #0
		bne i5
		cpx #1
		beq decrem

i5		cmp #5
		bne i6
		cpx #1
		beq increm

i6		cmp #1
		bne i7
		cpx #5
		beq decrem

i7		cmp #4
		bne i8
		cpx #5
		beq increm

i8		cmp #5
		bne done
		cpx #4
		beq decrem
				
		jmp done
				
decrem	dey
		jmp done
increm	iny	
done	rts

banner
		LDX #$00			 ; Set IOCB 0
		LDA #CMD_PUT_RECORDS ; Set command
		STA ICCOM,X          ; Store command in ICCOM of IOCB 0
		LDA #<MESSAGE1       ; Load low byte of the first message address
		STA ICBAL,X          ; Store low byte in IOCB 0
		LDA #>MESSAGE1       ; Load high byte of the first message address
		STA ICBAH,X          ; Store high byte in IOCB 0

		LDA #20
		STA ICBLL,X
		LDA #0
		STA ICBLH,X
		JSR CIOV
		RTS
		
prevx   .byte 00
prevy   .byte 00		
xpos	.byte 80
ypos	.byte 100 

cursor
	.byte $80 ; |X       |
	.byte $C0 ; |XX      |
	.byte $E0 ; |XXX     |
	.byte $F0 ; |XXXX    |
	.byte $F8 ; |XXXXX   |
	.byte $FC ; |XXXXXX  |
	.byte $FE ; |XXXXXXX |
	.byte $FF ; |XXXXXXXX|
	.byte $F0 ; |XXXX    |
	.byte $D8 ; |XX XX   |
	.byte $98 ; |X  XX   |
	.byte $0C ; |    XX  |
	.byte $0C ; |    XX  |
	.byte $0C ; |    XX  |
	.byte $06 ; |     XX |
	.byte $06 ; |     XX |

MESSAGE1:
    .BYTE 'Mouse initialized...',EOL