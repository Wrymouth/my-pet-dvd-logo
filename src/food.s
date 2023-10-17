.include "include/hardware_constants.inc"
.include "include/game_constants.inc"
.include "include/macros.inc"

.importzp locals
.importzp pad1_held, pad1_pressed, pad1_released
.importzp food_flags, food_x, food_y
.importzp player_x

.export handle_input_food
.proc handle_input_food
  PUSH_REG
  LDA pad1_pressed
  EOR pad1_held
  AND #BTN_A
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
  TXA
  CMP #NUM_FOODS
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
  AND #FOOD_FLAG_ACTIVE
  BEQ after_draw
  STX current_food
  JSR draw_food
after_draw:
  INX
  TXA
  CMP #NUM_FOODS
  BNE draw_active_foods
  PULL_REG
  RTS
.endproc

.export create_food
.proc create_food
  PUSH_REG
  LDX #$FF
check_food_empty:
  INX
  TXA
  CMP #NUM_FOODS
  BEQ done
  LDA food_flags,x
  AND #FOOD_FLAG_ACTIVE
  BNE check_food_empty
  ; actually create the food
  LDA #FOOD_FLAG_ACTIVE
  STA food_flags,x
  LDA player_x
  STA food_x,x
  LDA #PLAYER_Y+10
  STA food_y,x
done:
  PULL_REG
  RTS
.endproc

.proc update_food
  current_food := locals+0
  PUSH_REG
  LDX current_food
  INC food_y,x
  LDA food_y,x
  CMP #Y_OUT_OF_BOUNDS
  BNE done
  ; deactivate food because it's below the map
  LDA food_flags,x
  EOR #%10000000
  STA food_flags,x
done:
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
  LDA #$7C
  LDX current_food
  BEQ oam_address_found
find_address:
  CLC
  ADC #FOOD_SPRITE_SIZE
  DEX
  BNE find_address

  oam_address_found:
  LDX current_food
  TAY ; use Y to hold OAM address offset

  ; draw food
  LDA food_y, X
  STA $0200, Y
  INY
  LDA #$0B
  STA $0200, Y
  INY
  LDA #$00
  STA $0200, Y
  INY
  LDA food_x, X
  STA $0200, Y
  PULL_REG
  RTS
.endproc