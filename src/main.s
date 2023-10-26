.include "include/header.inc"
.include "include/hardware_constants.inc"
.include "include/game_constants.inc"

.segment "ZEROPAGE"
  ; local variables
  locals: .res 8

  ; controller tracking
  pad1_pressed: .res 1
  pad1_held: .res 1
  pad1_released: .res 1
  pad1_first_pressed: .res 1

  sleeping: .res 1
  timer: .res 1 ; ticks up every frame
  game_status: .res 1
  ; ppu data
  scroll: .res 1
  ppuctrl_settings: .res 1

  ; player data
  player_x: .res 1
  score_h: .res 1
  score_l: .res 1
  food_amount_h: .res 1
  food_amount_l: .res 1

  ; food data
  food_x: .res MAX_FOODS
  food_y: .res MAX_FOODS
  food_flags: .res MAX_FOODS

  ; bullet data
  bullet_x: .res 1
  bullet_y: .res 1
  bullet_flags: .res 1

  ; dvd data
  num_active_dvds: .res 1
  dvd_health: .res MAX_DVDS
  dvd_x: .res MAX_DVDS
  dvd_y: .res MAX_DVDS
  dvd_x_right: .res MAX_DVDS
  dvd_y_bottom: .res MAX_DVDS
  dvd_flags: .res MAX_DVDS
  dvd_bounces: .res MAX_DVDS

  ; enemy data
  enemy_x: .res 1
  enemy_y: .res 1
  enemy_x_right: .res 1
  enemy_y_bottom: .res 1
  enemy_flags: .res 1
  
.exportzp locals
.exportzp timer
.exportzp pad1_pressed, pad1_held, pad1_released, pad1_first_pressed
.exportzp player_x, score_l, score_h, food_amount_h, food_amount_l
.exportzp food_x, food_y, food_flags
.exportzp num_active_dvds, dvd_health, dvd_x, dvd_y, dvd_flags, dvd_x_right, dvd_y_bottom, dvd_bounces

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
.import read_controller1, handle_released_and_held
.import update_player, draw_player
.import handle_input_food, update_foods, draw_foods
.import init_dvds, update_dvds, draw_dvds
.import draw_background
.import draw_score

.export main
.proc main
  
  LDA #239   ; Y is only 240 lines tall!
  STA scroll
  ; set up dvds
  JSR init_dvds
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

  JSR draw_background

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait
  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA ppuctrl_settings
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK
  
main_loop:
  ; handle input 
  LDA pad1_pressed
  STA pad1_released
  STA pad1_held
  JSR read_controller1
  JSR handle_released_and_held

  LDA pad1_first_pressed
  AND #BTN_START
  BEQ pause_not_pressed
  LDA game_status
  EOR #GAME_STATUS_PAUSED
  STA game_status

pause_not_pressed:
  LDA game_status
  AND #GAME_STATUS_PAUSED
  BNE draw_stuff
  JSR handle_input_food
  JSR update_player
  JSR update_dvds
  JSR update_foods

  
;   ; Check if PPUCTRL needs to change
;   LDA scroll ; did we reach the end of a nametable?
;   BNE update_scroll
;   ; if yes,
;   ; Update base nametable
;   LDA ppuctrl_settings
;   EOR #%00000010 ; flip bit 1 to its opposite
;   STA ppuctrl_settings
;   ; Reset scroll to 240
;   LDA #240
;   STA scroll

; update_scroll:
;   DEC scroll

draw_stuff:
  JSR draw_player
  JSR draw_dvds
  JSR draw_foods
  JSR draw_score

  INC timer

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
