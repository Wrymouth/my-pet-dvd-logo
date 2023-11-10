.include "include/hardware_constants.inc"
.include "include/game_constants.inc"
.include "include/macros.inc"

.importzp locals
.importzp timer_l
.importzp pad1_first_pressed, button_feed
.importzp oam_current_index, oam_offset_add
.importzp food_amount_h, food_amount_l, food_flags, food_x, food_y
.importzp dvd_x, dvd_x_right, dvd_y, dvd_y_bottom, dvd_health, dvd_flags
.importzp player_x

.export handle_input_food
.proc handle_input_food
  PUSH_REG
  LDA pad1_first_pressed
  AND button_feed
  BEQ do_not_create
  JSR create_food
do_not_create:
  PULL_REG
  RTS
.endproc

.export update_foods
.proc update_foods
  current_food := locals+0
  PUSH_REG
  LDX #$00
update_active_foods:
  LDA food_flags,x
  AND #FOOD_FLAG_ACTIVE
  BEQ after_update
  STX current_food
  JSR update_food
after_update:
  INX
  CPX #MAX_FOODS
  BNE update_active_foods
  PULL_REG
  RTS
.endproc

.export draw_foods
.proc draw_foods
  current_food := locals+0
  PUSH_REG
  LDX #$00
draw_active_foods:
  LDA food_flags,x
  ; AND #FOOD_FLAG_ACTIVE
  ; BEQ after_draw
  LDA food_flags,x
  AND #FOOD_FLAG_VISIBLE
  BEQ after_draw ; branch on flag not set
  
  LDA food_flags,x
  AND #FOOD_FLAG_ACTIVE
  BNE after_erase ; branch on flag set

  LDA food_flags,x
  EOR #FOOD_FLAG_VISIBLE
  STA food_flags,x
after_erase:
  STX current_food
  JSR draw_food
after_draw:
  INX
  CPX #MAX_FOODS
  BNE draw_active_foods
  PULL_REG
  RTS
.endproc

.import dec_food_inv

.export create_food
.proc create_food
  PUSH_REG
  LDX #$FF

  LDA food_amount_l
  BNE check_food_empty
  LDA food_amount_h
  BEQ done
check_food_empty:
  INX
  CPX #MAX_FOODS
  BEQ done
  LDA food_flags,x
  AND #FOOD_FLAG_ACTIVE
  BNE check_food_empty
  ; actually create the food
  LDA #FOOD_FLAG_ACTIVE|FOOD_FLAG_VISIBLE
  STA food_flags,x
  LDA player_x
  CLC
  ADC #$02
  STA food_x,x
  LDA #PLAYER_Y+12
  STA food_y,x
  JSR dec_food_inv
done:
  PULL_REG
  RTS
.endproc

.proc update_food
  current_food := locals+0
  current_dvd  := locals+1
  PUSH_REG
  LDX current_food
  INC food_y,x

  LDA food_y,x
  CMP #Y_OUT_OF_BOUNDS
  BNE check_timer
  ; deactivate food because it's below the map
  JSR destroy_food
  JMP done
check_timer:
  LDA timer_l
  AND #$0F
  BNE check_collision
  INC food_y,x
  ; check this again because it might've fallen below the map from that
  LDA food_y,x
  CMP #Y_OUT_OF_BOUNDS
  BNE check_collision
  ; deactivate food because it's below the map
  JSR destroy_food
  JMP done
check_collision:
  ; go through each dvd, check for >x, >y, <x_right and <y_bottom
  LDY #$00 ; current_dvd
check_active_dvds:
  LDA dvd_flags,y
  AND #DVD_FLAG_ACTIVE
  BEQ after_check
  STY current_dvd
  JSR check_food_dvd_collision
after_check:
  INY
  CPY #MAX_DVDS
  BNE check_active_dvds
done:
  PULL_REG
  RTS
.endproc

.proc check_food_dvd_collision
  current_food := locals+0
  current_dvd  := locals+1
  PUSH_REG
  LDX current_food
  LDA food_x,x
  LDX current_dvd
  CMP dvd_x,x
  BMI done
  CMP dvd_x_right,x
  BPL done
  LDX current_food
  LDA food_y,x
  CLC
  ADC #$03
  LDX current_dvd
  CMP dvd_y,x
  BMI done
  CMP dvd_y_bottom,x
  BPL done
  JSR on_collision_dvd
done:
  PULL_REG
  RTS
.endproc

.proc on_collision_dvd
  current_food := locals+0
  current_dvd  := locals+1
  PUSH_REG
  LDX current_dvd
  INC dvd_health,x
  ; set food inactive 
  ; TODO: remember to check later whether it was set inactive
  ; so it can't collide with multiple dvds at once
  JSR destroy_food
  PULL_REG
  RTS
.endproc

.proc draw_food
  current_food := locals+0
  PUSH_REG
  ; Find the appropriate OAM address offset
  ; by starting at $0210 (after the player
  ; sprites) and adding $10 for each enemy
  ; until we hit the current index.
oam_address_found:
  LDX current_food
  LDY oam_current_index

  ; draw food
  LDA food_y, X
  STA $0200, Y
  LDA #$0B
  STA $0201, Y
  LDA #$01
  STA $0202, Y
  LDA food_x, X
  STA $0203, Y

  TYA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  PULL_REG
  RTS
.endproc

.proc destroy_food
  current_food := locals+0
  PUSH_REG
  LDX current_food
  LDA food_flags,x
  EOR #FOOD_FLAG_ACTIVE
  STA food_flags,x
  LDA #Y_OUT_OF_BOUNDS
  STA food_y,x
  PULL_REG
  RTS
.endproc