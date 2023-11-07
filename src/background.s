.include "include/hardware_constants.inc"
.include "include/game_constants.inc"
.include "include/macros.inc"

.importzp locals

.export draw_background
.proc draw_background
    PUSH_REG
    ; write nametables
	; big stars first
	LDA PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$6b
	STA PPUADDR
	LDX #$2f
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$57
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$23
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$52
	STA PPUADDR
	STX PPUDATA

	; next, small star 1
	LDA PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$74
	STA PPUADDR
	LDX #$2d
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$43
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$5d
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$73
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$2f
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$f7
	STA PPUADDR
	STX PPUDATA

	; finally, small star 2
	LDA PPUSTATUS
	LDA #$20
	STA PPUADDR
	LDA #$f1
	STA PPUADDR
	LDX #$2e
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$21
	STA PPUADDR
	LDA #$a8
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$22
	STA PPUADDR
	LDA #$7a
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$44
	STA PPUADDR
	STX PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$7c
	STA PPUADDR
	STX PPUDATA

	; finally, attribute table
	; LDA PPUSTATUS
	; LDA #$23
	; STA PPUADDR
	; LDA #$c2
	; STA PPUADDR
	; LDA #%01000000
	; STA PPUDATA

	; LDA PPUSTATUS
	; LDA #$23
	; STA PPUADDR
	; LDA #$e0
	; STA PPUADDR
	; LDA #%00001100
	; STA PPUDATA
    PULL_REG
    RTS
.endproc

.export draw_hud_bg
.proc draw_hud_bg
	hud_bg_l := locals+0
	hud_bg_h := locals+1
	bg_size_l  := locals+2
	bg_size_h  := locals+3
	current_index_l := locals+4
	current_index_h := locals+5

	PUSH_REG
	LDA #<background_dvds ; low
	STA hud_bg_l
	LDA #>background_dvds ; high
	STA hud_bg_h

	LDA #<960
	STA bg_size_l
	LDA #>960
	STA bg_size_h
	LDX #$20
	STX current_index_h
	LDX #$00
	STX current_index_l
draw_tile:
	LDA current_index_h
	STA PPUADDR
	LDA current_index_l
	STA PPUADDR
	LDA (hud_bg_l), y
	STA PPUDATA
	INC16 hud_bg_l
	INC16 current_index_l
	DEC16 bg_size_l
	LDA bg_size_l
	BNE draw_tile
	LDA bg_size_h
	BNE draw_tile

	;attr table
	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$c6
	STA PPUADDR
	LDA #%00000100
	STA PPUDATA

	PULL_REG
	RTS
.endproc

.segment "RODATA"
background_dvds:
	.incbin "dvd_bg.nam"