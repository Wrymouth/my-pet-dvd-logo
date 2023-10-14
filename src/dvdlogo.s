.include "include/header.inc"
.include "include/hardware_constants.inc"
.include "include/game_constants.inc"

.segment "ZEROPAGE"
  pad1: .res 1
  sleeping: .res 1
  ; ppu data
  scroll: .res 1
  ppuctrl_settings: .res 1

  ; player data
  player_x: .res 1
  score: .res 1

  ; dvd data
  dvd_health: .res NUM_DVDS
	dvd_x: .res NUM_DVDS
	dvd_y: .res NUM_DVDS
  dvd_dir_x: .res NUM_DVDS
  dvd_dir_y: .res NUM_DVDS
  dvd_flags: .res NUM_DVDS
  
  ; dvd helpers
  current_dvd: .res 1


.exportzp player_x, dvd_x, dvd_y, dvd_dir_x, dvd_dir_y, dvd_health, pad1

.segment "CODE"

.proc irq_handler

.endproc

.proc nmi_handler
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; copy sprite data to OAM
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  
  ; set PPUCTRL
  LDA ppuctrl_settings
  STA PPUCTRL

  ; set scroll values
  LDA #$00 ; X scroll first
  STA PPUSCROLL
  LDA scroll
  STA PPUSCROLL

  ; all done, disable sleeping in main loop
  LDA #$00
  STA sleeping

  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTI
.endproc

.import reset_handler

.import update_player
.import draw_player
.import update_dvd
.import draw_dvd
.import read_controller1

.export main
.proc main
  LDA #239   ; Y is only 240 lines tall!
  STA scroll
  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
  LDA #$29
load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes

  ; write sprite data
  LDX #$00
load_sprites:
  LDA sprites,X
  STA $0200,X
  INX
  CPX #$24
  BNE load_sprites
  
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
	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$c2
	STA PPUADDR
	LDA #%01000000
	STA PPUDATA

	LDA PPUSTATUS
	LDA #$23
	STA PPUADDR
	LDA #$e0
	STA PPUADDR
	LDA #%00001100
	STA PPUDATA

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait
  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA ppuctrl_settings
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK
  
main_loop:
  JSR read_controller1

  JSR update_player
  JSR draw_player

  JSR update_dvd
  JSR draw_dvd
  
  ; Check if PPUCTRL needs to change
  LDA scroll ; did we reach the end of a nametable?
  BNE update_scroll
  ; if yes,
  ; Update base nametable
  LDA ppuctrl_settings
  EOR #%00000010 ; flip bit 1 to its opposite
  STA ppuctrl_settings
  ; Reset scroll to 240
  LDA #240
  STA scroll

update_scroll:
  DEC scroll
  ; Done processing; wait for next Vblank
  INC sleeping
  
sleep:
  LDA sleeping
  BNE sleep
  JMP main_loop
.endproc

.segment "RODATA"
palettes:
.byte $0f, $19, $09, $29
.byte $0f, $2b, $3c, $39
.byte $0f, $12, $23, $27
.byte $0f, $0c, $07, $13

.byte $0f, $05, $05, $15 ; hp 1
.byte $0f, $08, $18, $28 ; hp 2
.byte $0f, $1A, $2A, $3A ; hp 3
.byte $0f, $00, $10, $20 ; hp 4

sprites:
.byte $70, $05, $00, $80
.byte $70, $06, $00, $88
.byte $78, $07, $00, $80
.byte $78, $08, $00, $88
.byte $78, $09, $00, $88
.byte $78, $0A, $00, $88

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "dvd.chr"
