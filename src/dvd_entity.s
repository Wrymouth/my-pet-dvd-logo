.include "include/hardware_constants.inc"
.include "include/game_constants.inc"
.include "include/macros.inc"

.importzp locals
.importzp score
.importzp dvd_health, dvd_x, dvd_x_right, dvd_y, dvd_y_bottom, dvd_flags, dvd_bounces


.export init_dvds
.proc init_dvds
  current_dvd := locals+0
  PUSH_REG
  LDX #$00 ; current_dvd
activate_dvds:
  STX current_dvd
  JSR create_dvd_init
  INX
  TXA
  CMP #INITIAL_DVD_SPAWN
  BNE activate_dvds

  PULL_REG
  RTS
.endproc

.export update_dvds
.proc update_dvds
  current_dvd := locals+0

  PUSH_REG
  LDX #$00 ; current_dvd
update_active_dvds:
  LDA dvd_flags,x
  AND #DVD_FLAG_ACTIVE
  BEQ after_update
  STX current_dvd
  JSR update_dvd
after_update:
  INX
  TXA
  CMP #NUM_DVDS
  BNE update_active_dvds

  PULL_REG
  RTS
.endproc

.export draw_dvds
.proc draw_dvds
  current_dvd := locals+0

  PUSH_REG
  LDX #$00
draw_active_dvds:

  LDA dvd_flags,x
  AND #DVD_FLAG_VISIBLE
  BEQ after_draw ; branch on flag not set
  
  LDA dvd_flags,x
  AND #DVD_FLAG_ACTIVE
  BNE after_erase ; branch on flag set
  
  LDA dvd_flags,x
  EOR #DVD_FLAG_VISIBLE
  STA dvd_flags,x
after_erase:
  STX current_dvd
  JSR draw_dvd
after_draw:
  INX
  TXA
  CMP #NUM_DVDS
  BNE draw_active_dvds
  PULL_REG
  RTS
.endproc

.proc create_dvd_init
  current_dvd := locals+0

  PUSH_REG
  LDX current_dvd
  
  ; set active
  LDA init_dvd_flags,x
  STA dvd_flags,x

  ; health
  LDA init_dvd_health,x
  STA dvd_health,x

  ; x and y pos
  LDA init_dvd_x,x
  STA dvd_x,x
  LDA init_dvd_y,x
  STA dvd_y,x

  PULL_REG
  RTS
.endproc

.export update_dvd
.proc update_dvd
  current_dvd := locals+0
  bounces := locals+1

  PUSH_REG
  LDX current_dvd

  ; check if HP has increased past max
  LDA dvd_health,x
  CMP #DVD_MAX_HEALTH+1
  BNE movement
  ; destroy DVD
  JSR destroy_dvd
  JMP done
movement:  
  ; init bounces
  LDA #$00
  STA bounces

  LDA dvd_x,x
  CMP #RIGHT_OF_DVD_FIELD
  BCC not_at_right_edge
  ; if BCC is not taken, we are greater than $e0 and direction should change
  INC bounces
  LDA dvd_flags,x
  EOR #DVD_FLAG_MOVING_RIGHT
  STA dvd_flags,x    ; start moving left
  JMP direction_set ; we already chose a direction,
                    ; so we can skip the left side check
not_at_right_edge:
  LDA dvd_x,x
  CMP #LEFT_OF_DVD_FIELD
  BCS direction_set
  ; if BCS not taken, we are less than $10 and direction should change
  INC bounces
  LDA dvd_flags,x
  ORA #DVD_FLAG_MOVING_RIGHT
  STA dvd_flags,x    ; start moving right
direction_set:
  ; now, actually update dvd_x
  LDA dvd_flags,x
  AND #DVD_FLAG_MOVING_RIGHT
  BNE move_right
  DEC dvd_x,x ; move left
  JMP done_with_x
move_right:
  INC dvd_x,x ; move right

done_with_x:

  ; y axis 
  LDA dvd_flags,x
  AND #DVD_FLAG_MOVING_UP
  BNE move_up
move_down:
  INC dvd_y,x
  JMP direction_set_y
move_up:
  DEC dvd_y,x

direction_set_y:
  LDA dvd_y,x
  CMP #TOP_OF_DVD_FIELD
  BCC at_top_edge
  CMP #BOTTOM_OF_DVD_FIELD
  BCS at_bottom_edge
  JMP done_moving
at_bottom_edge:
  INC bounces
  LDA dvd_flags,x
  ORA #DVD_FLAG_MOVING_UP
  STA dvd_flags,x    ; start moving up
  JMP done_moving
at_top_edge:
  INC bounces
  LDA dvd_flags,x
  EOR #DVD_FLAG_MOVING_UP
  STA dvd_flags,x    ; start moving down
  
  LDA bounces
  CMP #$02
  BNE done_moving
  INC score
done_moving:
  LDA bounces
  BEQ set_width_height
  INC dvd_bounces,x
  ; check if HP should be lost
  LDA dvd_bounces,x
  CMP #DVD_MAX_BOUNCES
  BNE set_width_height
  DEC dvd_health,x
  BNE reset_bounces
  JSR destroy_dvd
reset_bounces:
  LDA #$00
  STA dvd_bounces,x
  ; after movement, set the bottom and right positions
set_width_height:
  LDA dvd_x,x
  CLC
  ADC #DVD_WIDTH
  STA dvd_x_right,x
  LDA dvd_y,x
  CLC
  ADC #DVD_HEIGHT
  STA dvd_y_bottom,x
done:
  ; all done, clean up and return
  PULL_REG
  RTS
.endproc

.export draw_dvd
.proc draw_dvd
  current_dvd := locals+0

  PUSH_REG
  ; Find the appropriate OAM address offset
  ; by starting at $0210 (after the player
  ; sprites) and adding $10 for each enemy
  ; until we hit the current index.
  LDA #$04
  LDX current_dvd
  BEQ oam_address_found
find_address:
  CLC
  ADC #$18
  DEX
  BNE find_address

oam_address_found:
  LDX current_dvd
  TAY ; use Y to hold OAM address offset

  ; dvd top-left
  LDA dvd_y, X
  STA $0200, Y
  INY
  LDA #$05
  STA $0200, Y
  INY
  LDA #$00
  ORA dvd_health, X
  SEC
  SBC #$01
  STA $0200, Y
  INY
  LDA dvd_x, X
  STA $0200, Y
  INY

  ; dvd top-middle
  LDA dvd_y, X
  STA $0200, Y
  INY
  LDA #$06
  STA $0200, Y
  INY
  LDA #$00
  ORA dvd_health, X
  SEC
  SBC #$01
  STA $0200, Y
  INY
  LDA dvd_x, X
  CLC
  ADC #$08
  STA $0200, Y
  INY

  ; dvd top-right
  LDA dvd_y, X
  STA $0200, Y
  INY
  LDA #$07
  STA $0200, Y
  INY
  LDA #$00
  ORA dvd_health, X
  SEC
  SBC #$01
  STA $0200, Y
  INY
  LDA dvd_x, X
  CLC
  ADC #$10
  STA $0200, Y
  INY

  ; dvd bottom-left
  LDA dvd_y, X
  CLC
  ADC #$08
  STA $0200, Y
  INY
  LDA #$08
  STA $0200, Y
  INY
  LDA #$00
  ORA dvd_health, X
  SEC
  SBC #$01
  STA $0200, Y
  INY
  LDA dvd_x, X
  STA $0200, Y
  INY

  ; dvd bottom-middle
  LDA dvd_y, X
  CLC
  ADC #$08
  STA $0200, Y
  INY
  LDA #$09
  STA $0200, Y
  INY
  LDA #$00
  ORA dvd_health, X
  SEC
  SBC #$01
  STA $0200, Y
  INY
  LDA dvd_x, X
  CLC
  ADC #$08
  STA $0200, Y
  INY
  
  ; dvd bottom-right
  LDA dvd_y, X
  CLC
  ADC #$08
  STA $0200, Y
  INY
  LDA #$08
  STA $0200, Y
  INY
  LDA #%01000000 ; flipped sprite
  ORA dvd_health, X
  SEC
  SBC #$01
  STA $0200, Y
  INY
  LDA dvd_x, X
  CLC
  ADC #$10
  STA $0200, Y
  INY

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.proc destroy_dvd
  current_dvd := locals+0
  PUSH_REG
  LDX current_dvd
  LDA dvd_flags,x
  EOR #DVD_FLAG_ACTIVE
  STA dvd_flags,x
  LDA #Y_OUT_OF_BOUNDS
  STA dvd_y,x
  PULL_REG
  RTS
.endproc

.segment "RODATA"
init_dvd_health:
.byte $02, $02, $02

init_dvd_x:
.byte $d0, $40, $10

init_dvd_y:
.byte $60, $38, $20

init_dvd_flags:
.byte %11010000, %11100000, %11100000