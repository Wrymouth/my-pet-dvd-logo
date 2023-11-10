.include "include/header.inc"
.include "include/hardware_constants.inc"
.include "include/game_constants.inc"
.include "include/macros.inc"

.segment "ZEROPAGE"
  ; local variables
  locals: .res 8

  ; controller tracking
  pad1_pressed: .res 1
  pad1_held: .res 1
  pad1_released: .res 1
  pad1_first_pressed: .res 1

  button_feed: .res 1
  button_shoot: .res 1

  oam_bytes_used: .res 1
  oam_current_index: .res 1
  oam_offset_add: .res 1
  sleeping: .res 1
  rand_seed_h: .res 1
  rand_seed_l: .res 1
  timer_h: .res 1
  timer_l: .res 1 ; ticks up every frame
  random: .res 1
  game_status: .res 1
  game_state: .res 1
  game_state_address: .res 2
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
.exportzp timer_h, timer_l
.exportzp rand_seed_h, rand_seed_l, random
.exportzp pad1_pressed, pad1_held, pad1_released, pad1_first_pressed, button_feed, button_shoot
.exportzp oam_bytes_used, oam_current_index, oam_offset_add
.exportzp player_x, score_l, score_h, food_amount_h, food_amount_l
.exportzp food_x, food_y, food_flags
.exportzp enemy_x, enemy_y, enemy_x_right, enemy_y_bottom, enemy_flags
.exportzp bullet_x, bullet_y, bullet_flags
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


set_ppuctrl:
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
.import create_enemy, update_enemy, draw_enemy
.import handle_input_bullet, update_bullet, draw_bullet
.import draw_background, draw_hud_bg, draw_title_bg, draw_lose_background
.import draw_score, draw_food_inv, draw_title_buttons

.export get_rand_byte
.proc get_rand_byte
  PUSH_REG
  lda rand_seed_l
	tay ; store copy of high byte
	; compute seed+1 ($39>>1 = %11100)
	lsr ; shift to consume zeroes on left...
	lsr
	lsr
	sta rand_seed_l ; now recreate the remaining bits in reverse order... %111
	lsr
	eor rand_seed_l
	lsr
	eor rand_seed_l
	eor rand_seed_h ; recombine with original low byte
	sta rand_seed_l
	; compute seed+0 ($39 = %111001)
	tya ; original high byte
	sta rand_seed_h
	asl
	eor rand_seed_h
	asl
	eor rand_seed_h
	asl
	asl
	asl
	eor rand_seed_h
	sta random
  PULL_REG
  RTS
.endproc

.proc clear_oam
  PUSH_REG
  LDX #$00
loop:
  LDA #$FF
  STA $0200,x
  TXA
  CLC
  ADC #$04
  TAX
  CPX #$00
  BNE loop

  PULL_REG
  RTS
.endproc


.proc init_zeropage
  PUSH_REG
  LDA #$00
  LDY #Y_OUT_OF_BOUNDS
  STA score_h
  STA score_l
  STA food_amount_h
  STY food_x
  STY food_y
  STA food_flags

  STY bullet_x
  STY bullet_y
  STA bullet_flags

  ; dvd data
  STA num_active_dvds

  LDA #$90
  STA player_x
  LDA #FOOD_AMOUNT_START
  STA food_amount_l
  LDA #$04
  STA oam_offset_add
  LDA #Y_OUT_OF_BOUNDS
  STA bullet_y
  LDA #239   ; Y is only 240 lines tall!
  STA scroll
  LDA #BTN_A
  STA button_feed
  LDA #BTN_B
  STA button_shoot

  PULL_REG
  RTS
.endproc

.export main
.proc main

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


vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  
  LDA #GAME_STATE_TITLE
  STA game_state
  LDA game_status
  ORA #GAME_STATUS_STATE_SWITCHED
  STA game_status
main_loop:
  JSR clear_oam
  LDA #$00
  STA oam_current_index
  LDA oam_offset_add
  CMP #OAM_OFFSET_FORWARD
  BEQ set_oam_offset_backward
  LDA #OAM_OFFSET_FORWARD
  STA oam_offset_add
  JMP set_seed
set_oam_offset_backward:
  LDA #OAM_OFFSET_BACKWARD
  STA oam_offset_add
set_seed:
  LDA timer_l
  STA rand_seed_l
  LDA timer_h
  STA rand_seed_h
  JSR get_rand_byte
  ; handle input 
  LDA pad1_pressed
  STA pad1_released
  STA pad1_held
  JSR read_controller1
  JSR handle_released_and_held


  
  LDX game_state

  LDA game_states_l,x
  STA game_state_address+0
  LDA game_states_h,x
  STA game_state_address+1

  JSR do_game_state

  INC timer_l
  BNE set_sleeping
  INC timer_h
set_sleeping:
  ; Done processing; wait for next Vblank
  INC sleeping
sleep:
  LDA sleeping
  BNE sleep
  JMP main_loop
.endproc

.proc do_game_state
  JMP (game_state_address)
.endproc

.proc game_state_title
  PUSH_REG
  LDA game_status
  AND #GAME_STATUS_STATE_SWITCHED
  BEQ title_loop
  ; initialize zero-page values
  JSR init_zeropage

  LDA #%00000110  ; turn off screen
  STA PPUMASK
  JSR draw_title_bg
  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA ppuctrl_settings
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK
  LDA game_status
  EOR #GAME_STATUS_STATE_SWITCHED
  STA game_status
title_loop:
  LDA pad1_first_pressed
  AND #BTN_START
  BEQ start_not_pressed
  LDA #GAME_STATE_MAIN
  STA game_state
  LDA game_status
  ORA #GAME_STATUS_STATE_SWITCHED
  STA game_status
start_not_pressed:
  LDA pad1_first_pressed
  AND #BTN_SELECT
  BEQ select_not_pressed
  LDA button_feed
  STA locals+0
  LDA button_shoot
  STA button_feed
  LDA locals+0
  STA button_shoot
select_not_pressed:
  JSR draw_title_buttons
  PULL_REG
  RTS
.endproc

.proc game_state_main
  PUSH_REG
  LDA game_status
  AND #GAME_STATUS_STATE_SWITCHED
  BEQ game_loop
  LDA game_status
  EOR #GAME_STATUS_STATE_SWITCHED
  STA game_status
  JSR init_dvds
  JSR create_enemy
  ; disable ppu
  LDA #%00000110  ; turn off screen
  STA PPUMASK
  JSR draw_hud_bg
  LDA #%00011110  ; turn on screen
  STA PPUMASK
game_loop:
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
  JSR handle_input_bullet
  JSR update_player
  JSR update_dvds
  JSR update_foods
  JSR update_bullet
  JSR update_enemy

  LDA num_active_dvds
  BNE draw_stuff
  LDA #GAME_STATE_LOSE_TIMER
  STA game_state
  LDA game_status
  ORA #GAME_STATUS_STATE_SWITCHED
  STA game_status
draw_stuff:
  JSR clear_oam
  JSR draw_score
  JSR draw_food_inv
  JSR draw_player
  JSR draw_foods
  JSR draw_bullet

  JSR draw_dvds
  JSR draw_enemy
  PULL_REG
  RTS
.endproc

.proc game_state_lose_timer
  local_timer := locals+0
  PUSH_REG
  LDA game_status
  AND #GAME_STATUS_STATE_SWITCHED
  BEQ lose_time_dec
  LDA #LOSE_TIMER_BASE
  STA local_timer
  LDA game_status
  EOR #GAME_STATUS_STATE_SWITCHED
  STA game_status
lose_time_dec:
  DEC local_timer
  BNE loop
  LDA #GAME_STATE_LOSE
  STA game_state
  LDA game_status
  ORA #GAME_STATUS_STATE_SWITCHED
  STA game_status
loop:
  PULL_REG
  RTS
.endproc

.proc game_state_lose
  PUSH_REG
  LDA game_status
  AND #GAME_STATUS_STATE_SWITCHED
  BEQ restart_loop
  LDA #%00000110  ; turn off screen
  STA PPUMASK
  JSR draw_lose_background
  LDA #%00011110  ; turn on screen
  STA PPUMASK
  LDA game_status
  EOR #GAME_STATUS_STATE_SWITCHED
  STA game_status
restart_loop:
  LDA pad1_first_pressed
  AND #BTN_START
  BEQ start_not_pressed
  LDA #GAME_STATE_TITLE
  STA game_state
  LDA game_status
  ORA #GAME_STATUS_STATE_SWITCHED
  STA game_status
start_not_pressed:
  PULL_REG
  RTS
.endproc

.segment "RODATA"
palettes:
.byte $0f, $00, $10, $20 ; hp 4
.byte $0f, $08, $18, $28 ; hp 2
.byte $0f, $21, $11, $3A ; hp 3
.byte $0f, $21, $11, $15 ; hp 1

.byte $0f, $05, $05, $15 ; hp 1
.byte $0f, $08, $18, $28 ; hp 2
.byte $0f, $1A, $11, $3A ; hp 3
.byte $0f, $00, $10, $20 ; hp 4

game_states_l:
.byte .lobyte(game_state_title)
.byte .lobyte(game_state_main)
.byte .lobyte(game_state_lose_timer)
.byte .lobyte(game_state_lose)
game_states_h:
.byte .hibyte(game_state_title)
.byte .hibyte(game_state_main)
.byte .hibyte(game_state_lose_timer)
.byte .hibyte(game_state_lose)

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "dvd.chr"
