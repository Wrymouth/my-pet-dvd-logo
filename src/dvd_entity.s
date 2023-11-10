.include "include/hardware_constants.inc"
.include "include/game_constants.inc"
.include "include/macros.inc"

.importzp locals
.importzp random, rand_seed_l
.importzp oam_bytes_used, oam_current_index, oam_offset_add
.importzp num_active_dvds, dvd_health, dvd_x, dvd_x_right, dvd_y, dvd_y_bottom, dvd_flags, dvd_bounces

.import inc_score

.export init_dvds
.proc init_dvds
  current_dvd := locals+0
  PUSH_REG
  LDX #$00 ; current_dvd
activate_dvds:
  STX current_dvd
  JSR create_dvd_init
  INX
  CPX #INITIAL_DVD_SPAWN
  BNE activate_dvds

  PULL_REG
  RTS
.endproc

.export update_dvds
.proc update_dvds
  current_dvd := locals+0

  PUSH_REG
  JSR setup_dvds_collision_check
  LDX #$00 ; current_dvd
update_active_dvds:
  LDA dvd_flags,x
  AND #DVD_FLAG_ACTIVE
  BEQ after_update
  STX current_dvd
  JSR update_dvd
after_update:
  INX
  CPX #MAX_DVDS
  BNE update_active_dvds

  PULL_REG
  RTS
.endproc

.proc setup_dvds_collision_check
  dvd_a := locals+0 ; initialized here 
  dvd_b := locals+1 ; initialized here
  collision_occurred := locals+2 ; returned from subroutine

  PUSH_REG
  ; check if there at least 2 DVDs with 4HP
  ; then check if any of them are colliding with each other
  LDX #$00 ; current dvd_a
  LDY #$00 ; current dvd_b
  STY collision_occurred ; set collision_occurred to FALSE for now
check_dvd_x:
  LDA num_active_dvds
  CMP #MAX_DVDS
  BEQ done
  LDA dvd_flags,x
  AND #DVD_FLAG_ACTIVE ; check if set
  BEQ not_colliding_x
  ; AND #DVD_FLAG_DO_NOT_CHECK_COLLISION ; check if not set
  ; BNE not_colliding_x
  LDA dvd_health,x
  CMP #DVD_MAX_HEALTH
  BNE not_colliding_x
  JMP start_dvd_y
not_colliding_x:
  ; LDA dvd_flags,x
  ; ORA #DVD_FLAG_DO_NOT_CHECK_COLLISION
  ; STA dvd_flags,x
after_check_x:
  INX
  CPX #MAX_DVDS
  BNE check_dvd_x
  JMP done
start_dvd_y:
  TXA
  TAY ; we know the dvds before this won't collide, so start counting at the current dvd
  INY ; can't collide with yourself, and we know everything before is ineligible
check_dvd_y:
  LDA dvd_flags,y
  AND #DVD_FLAG_ACTIVE ; check if set
  BEQ not_colliding_y
  ; AND #DVD_FLAG_DO_NOT_CHECK_COLLISION ; check if not set
  ; BNE not_colliding_y
  LDA dvd_health,y
  CMP #DVD_MAX_HEALTH
  BNE not_colliding_y
  STX dvd_a
  STY dvd_b
  JSR check_dvds_collision ; returns a value to collision_occurred
  LDA collision_occurred
  BEQ after_check_y
  JMP done 
not_colliding_y:
  ; LDA dvd_flags,y
  ; ORA #DVD_FLAG_DO_NOT_CHECK_COLLISION
  ; STA dvd_flags,y
  ; LDA dvd_flags,y
  ; ORA #DVD_FLAG_DO_NOT_CHECK_COLLISION
  ; STA dvd_flags,y
after_check_y:
  INY
  TYA
  CMP #MAX_DVDS
  BNE check_dvd_y
  INX
  JMP check_dvd_x
done:
  ; clear "collided" flags

  PULL_REG
  RTS
.endproc

.proc check_dvds_collision
  dvd_a := locals+0 ; arg
  dvd_b := locals+1 ; arg
  collision_occurred := locals+2 ; ret
  PUSH_REG
  LDX dvd_a
  LDY dvd_b
  
  ; compare left side of A to right side of B
  LDA dvd_x,x
  CMP dvd_x_right,y
  BPL no_collision
  ; compare right side of A to left side of B
  LDA dvd_x_right,x
  CMP dvd_x,y
  BMI no_collision
  ; compare bottom of A to top of B
  LDA dvd_y_bottom,x
  CMP dvd_y,y
  BMI no_collision
  ; compare top of A to bottom of B
  LDA dvd_y,x
  CMP dvd_y_bottom,y
  BPL no_collision

  JSR on_collision_dvds
  LDA #TRUE
  STA collision_occurred
  JMP done
no_collision:
  LDA #FALSE
  STA collision_occurred
done:
  PULL_REG
  RTS
.endproc

.proc on_collision_dvds
  dvd_a := locals+0 ; arg
  dvd_b := locals+1 ; arg

  PUSH_REG
  JSR create_dvd_from_parent
  LDX dvd_a
  LDY dvd_b
  LDA dvd_flags,x
  EOR #DVD_FLAG_MOVING_RIGHT|DVD_FLAG_MOVING_UP
  ORA #DVD_FLAG_DO_NOT_CHECK_COLLISION
  STA dvd_flags,x
  LDA dvd_flags,y
  EOR #DVD_FLAG_MOVING_RIGHT|DVD_FLAG_MOVING_UP
  ORA #DVD_FLAG_DO_NOT_CHECK_COLLISION
  STA dvd_flags,y
  LDA #DVD_MAX_HEALTH-1
  STA dvd_health,x
  STA dvd_health,y
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
  CPX #MAX_DVDS
  BNE draw_active_dvds
  PULL_REG
  RTS
.endproc

.import get_rand_byte

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
  INC rand_seed_l
  JSR get_rand_byte
  LDA random
  AND #MASK_LOW_NIBBLE
  TAY
  LDA rand_x_pos,y
  STA dvd_x,x
  LDA random
  AND #MASK_HIGH_NIBBLE
  LSR
  LSR
  LSR
  LSR
  TAY
  LDA rand_y_pos,y
  STA dvd_y,x
  LDA #$00
  STA dvd_bounces,x

  INC num_active_dvds

  PULL_REG
  RTS
.endproc

.proc create_dvd_from_parent
  dvd_a := locals+0 ; arg
  dvd_b := locals+1 ; arg

  PUSH_REG
  ; scan for inactive dvd slots
  LDX #$00
  LDY dvd_a
find_inactive:
  LDA dvd_flags,x
  AND #DVD_FLAG_ACTIVE
  BNE after_search

  ; create the dvd
  LDA #$02
  STA dvd_health,x
  LDA dvd_x,y
  STA dvd_x,x
  LDA dvd_y,y
  STA dvd_y,x
  LDA dvd_x_right,x
  STA dvd_x_right,y
  LDA dvd_y_bottom,x
  STA dvd_y_bottom,y
  
  ; set up flags, such that the new dvd moves
  ; in a different direction than both of its parents
  LDA dvd_flags,y
  AND #DVD_FLAG_MOVING_RIGHT
  EOR #DVD_FLAG_MOVING_RIGHT
  STA dvd_flags,x
  
  LDY dvd_b
  LDA dvd_flags,y
  AND #DVD_FLAG_MOVING_UP
  EOR #DVD_FLAG_MOVING_UP
  ORA dvd_flags,x
  ORA #DVD_FLAG_ACTIVE|DVD_FLAG_VISIBLE
  STA dvd_flags,x
  LDY dvd_a
  LDA dvd_flags,y
  EOR #DVD_FLAG_MOVING_UP
  STA dvd_flags,x
  
  LDA #$00
  STA dvd_bounces,x
  INC num_active_dvds
  JMP done

after_search:
  INX
  CPX #MAX_DVDS
  BNE find_inactive
done:
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
done_moving:
  LDA bounces
  CMP #$02
  BNE increase_bounce_counter
  JSR inc_score
increase_bounce_counter:
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
oam_address_found:
  LDX current_dvd
  LDY oam_current_index

  ; dvd top-left
  LDA dvd_y, X
  STA $0200, Y
  LDA #$05
  STA $0201, Y
  LDA #$00
  ORA dvd_health, X
  SEC
  SBC #$01
  STA $0202, Y
  LDA dvd_x, X
  STA $0203, Y

  TYA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAY

  ; dvd top-middle
  LDA dvd_y, X
  STA $0200, Y
  LDA #$06
  STA $0201, Y
  LDA #$00
  ORA dvd_health, X
  SEC
  SBC #$01
  STA $0202, Y
  LDA dvd_x, X
  CLC
  ADC #$08
  STA $0203, Y

  TYA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAY

  ; dvd top-right
  LDA dvd_y, X
  STA $0200, Y
  LDA #$07
  STA $0201, Y
  LDA #$00
  ORA dvd_health, X
  SEC
  SBC #$01
  STA $0202, Y
  LDA dvd_x, X
  CLC
  ADC #$10
  STA $0203, Y

  TYA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAY

  ; dvd bottom-left
  LDA dvd_y, X
  CLC
  ADC #$08
  STA $0200, Y
  LDA #$08
  STA $0201, Y
  LDA #$00
  ORA dvd_health, X
  SEC
  SBC #$01
  STA $0202, Y
  LDA dvd_x, X
  STA $0203, Y

  TYA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAY

  ; dvd bottom-middle
  LDA dvd_y, X
  CLC
  ADC #$08
  STA $0200, Y
  LDA #$09
  STA $0201, Y
  LDA #$00
  ORA dvd_health, X
  SEC
  SBC #$01
  STA $0202, Y
  LDA dvd_x, X
  CLC
  ADC #$08
  STA $0203, Y

  TYA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAY
  
  ; dvd bottom-right
  LDA dvd_y, X
  CLC
  ADC #$08
  STA $0200, Y
  LDA #$08
  STA $0201, Y
  LDA #%01000000 ; flipped sprite
  ORA dvd_health, X
  SEC
  SBC #$01
  STA $0202, Y
  LDA dvd_x, X
  CLC
  ADC #$10
  STA $0203, Y

    TYA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAY

  PULL_REG
  RTS
.endproc

.export destroy_dvd
.proc destroy_dvd
  current_dvd := locals+0
  PUSH_REG
  LDX current_dvd
  LDA dvd_flags,x
  EOR #DVD_FLAG_ACTIVE
  STA dvd_flags,x
  LDA #Y_OUT_OF_BOUNDS
  STA dvd_y,x
  DEC num_active_dvds
  PULL_REG
  RTS
.endproc

.segment "RODATA"
init_dvd_health:
.byte $02, $02, $02

init_dvd_x:
.byte $d0, $40, $10

init_dvd_y:
.byte $60, $38, $80

init_dvd_flags:
.byte %11010000, %11110000, %11100000

.import rand_x_pos
.import rand_y_pos