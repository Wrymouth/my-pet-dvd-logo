.include "include/hardware_constants.inc"
.include "include/game_constants.inc"
.include "include/macros.inc"

.importzp locals
.importzp timer_l, pad1_first_pressed, button_shoot
.importzp rand_seed_l, random
.importzp oam_current_index, oam_offset_add
.importzp num_active_dvds, dvd_health, dvd_x, dvd_x_right, dvd_y, dvd_y_bottom, dvd_flags
.importzp food_amount_h, food_amount_l
.importzp enemy_x, enemy_x_right, enemy_y, enemy_y_bottom, enemy_flags
.importzp bullet_x, bullet_y, bullet_flags
.importzp player_x


.import inc_score, get_rand_byte

.export create_enemy
.proc create_enemy
  PUSH_REG
  
  ; set active
  LDA #ENEMY_FLAG_ACTIVE|ENEMY_FLAG_VISIBLE
  STA enemy_flags

  ; x and y pos (randomize)
  INC rand_seed_l
  JSR get_rand_byte
  LDA random
  AND #MASK_LOW_NIBBLE
  TAX
  LDA rand_x_pos,x
  STA enemy_x
  LDA random
  AND #MASK_HIGH_NIBBLE
  LSR
  LSR
  LSR
  LSR
  TAX
  LDA rand_y_pos,x
  STA enemy_y

  PULL_REG
  RTS
.endproc

.export update_enemy
.proc update_enemy
  PUSH_REG
  LDA enemy_flags
  AND #ENEMY_FLAG_ACTIVE
  BNE movement
  ; create new enemy cause the old one must have died
  LDA num_active_dvds
  CMP #$02
  BMI done ; branch on less than
  JSR create_enemy
  JMP done
movement:  
  LDA enemy_x
  CMP #RIGHT_OF_DVD_FIELD
  BCC not_at_right_edge
  ; if BCC is not taken, we are greater than $e0 and direction should change
  LDA enemy_flags
  EOR #ENEMY_FLAG_MOVING_RIGHT
  STA enemy_flags   ; start moving left
  JMP direction_set ; we already chose a direction,
                    ; so we can skip the left side check
not_at_right_edge:
  LDA enemy_x
  CMP #LEFT_OF_DVD_FIELD
  BCS direction_set
  ; if BCS not taken, we are less than $10 and direction should change
  LDA enemy_flags
  ORA #ENEMY_FLAG_MOVING_RIGHT
  STA enemy_flags    ; start moving right
direction_set:
  ; now, actually update dvd_x
  LDA enemy_flags
  AND #ENEMY_FLAG_MOVING_RIGHT
  BNE move_right
  DEC enemy_x ; move left
  JMP done_with_x
move_right:
  INC enemy_x ; move right

done_with_x:

  ; y axis 
  LDA enemy_flags
  AND #ENEMY_FLAG_MOVING_UP
  BNE move_up
move_down:
  INC enemy_y
  JMP direction_set_y
move_up:
  DEC enemy_y

direction_set_y:
  LDA enemy_y
  CMP #TOP_OF_DVD_FIELD
  BCC at_top_edge
  CMP #BOTTOM_OF_DVD_FIELD
  BCS at_bottom_edge
  JMP done_moving
at_bottom_edge:
  LDA enemy_flags
  ORA #ENEMY_FLAG_MOVING_UP
  STA enemy_flags    ; start moving up
  JMP done_moving
at_top_edge:
  LDA enemy_flags
  EOR #ENEMY_FLAG_MOVING_UP
  STA enemy_flags    ; start moving down
done_moving:
  LDA enemy_x
  CLC
  ADC #ENEMY_WIDTH
  STA enemy_x_right
  LDA enemy_y
  CLC
  ADC #ENEMY_HEIGHT
  STA enemy_y_bottom
done:
  ; all done, clean up and return
  PULL_REG
  RTS
.endproc

.export draw_enemy
.proc draw_enemy
  PUSH_REG
  LDX oam_current_index

  ; dvd top-left
  LDA enemy_y
  STA $0200,x
  LDA #$0D
  STA $0201,x
  LDA #$02
  STA $0202,x
  LDA enemy_x
  STA $0203,x

  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAX

  ; dvd top-middle
  LDA enemy_y
  STA $0200,x
  LDA #$0E
  STA $0201,x
  LDA #$02
  STA $0202,x
  LDA enemy_x
  CLC
  ADC #$08
  STA $0203,x

  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAX

  ; dvd top-right
  LDA enemy_y
  STA $0200,x
  LDA #$0F
  STA $0201,x
  LDA #$02
  STA $0202,x
  LDA enemy_x
  CLC
  ADC #$10
  STA $0203,x

  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAX

  ; dvd bottom-left
  LDA enemy_y
  CLC
  ADC #$08
  STA $0200,x
  LDA #$1D
  STA $0201,x
  LDA #$02
  STA $0202,x
  LDA enemy_x
  STA $0203,x

  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAX

  ; dvd bottom-middle
  LDA enemy_y
  CLC
  ADC #$08
  STA $0200,x
  LDA #$1E
  STA $0201,x
  LDA #$02
  STA $0202,x
  LDA enemy_x
  CLC
  ADC #$08
  STA $0203,x

  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAX

  ; dvd bottom-right
  LDA enemy_y
  CLC
  ADC #$08
  STA $0200,x
  LDA #$1F
  STA $0201,x
  LDA #$02
  STA $0202,x
  LDA enemy_x
  CLC
  ADC #$10
  STA $0203,x
  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  ; restore registers and return
  PULL_REG
  RTS
.endproc

.proc destroy_enemy
  PUSH_REG
  LDA enemy_flags
  EOR #ENEMY_FLAG_ACTIVE
  STA enemy_flags
  LDA #Y_OUT_OF_BOUNDS
  STA enemy_y
  PULL_REG
  RTS
.endproc

.export create_bullet
.proc create_bullet
  PUSH_REG
  LDA bullet_flags
  AND #BULLET_FLAG_ACTIVE
  BNE done
  ; actually create the bullet
  LDA #BULLET_FLAG_ACTIVE|BULLET_FLAG_VISIBLE
  STA bullet_flags
  LDA player_x
  CLC
  ADC #$02
  STA bullet_x
  LDA #PLAYER_Y+12
  STA bullet_y
done:
  PULL_REG
  RTS
.endproc

.export handle_input_bullet
.proc handle_input_bullet
  PUSH_REG
  LDA pad1_first_pressed
  AND button_shoot
  BEQ do_not_create
  JSR create_bullet
do_not_create:
  PULL_REG
  RTS
.endproc

.export update_bullet
.proc update_bullet
  PUSH_REG
  LDA bullet_flags
  AND #BULLET_FLAG_ACTIVE
  BEQ done

  LDA bullet_y
  CLC
  ADC #BULLET_SPEED
  STA bullet_y

  CMP #Y_OUT_OF_BOUNDS
  BCC check_timer
  ; deactivate food because it's below the map
  JSR destroy_bullet
  JMP done
check_timer:
  LDA timer_l
  AND #$0F
  BNE check_collision
  INC bullet_y
  ; check this again because it might've fallen below the map from that
  LDA bullet_y
  CMP #Y_OUT_OF_BOUNDS
  BNE check_collision
  ; deactivate food because it's below the map
  JSR destroy_bullet
  JMP done
check_collision:
  LDA bullet_flags
  AND #ENEMY_FLAG_ACTIVE
  BEQ done
  JSR check_bullet_enemy_collision
  JSR setup_bullet_dvd_collision_check
done:
  PULL_REG
  RTS
.endproc

.proc check_bullet_enemy_collision
  PUSH_REG
  LDA bullet_x
  INX
  CMP enemy_x
  BMI done
  CMP enemy_x_right
  BPL done
  LDA bullet_y
  CLC
  ADC #$03
  CMP enemy_y
  BMI done
  CMP enemy_y_bottom
  BPL done
  JSR on_collision_enemy
done:
  PULL_REG
  RTS
.endproc

.proc setup_bullet_dvd_collision_check
  current_dvd := locals+0 ; initialized here
  PUSH_REG
  LDX #$00
check_active_dvds:
  LDA dvd_flags,x
  AND #DVD_FLAG_ACTIVE
  BEQ after_check
  STX current_dvd
  JSR check_bullet_dvd_collision
after_check:
  INX
  CPX #MAX_DVDS
  BNE check_active_dvds
  PULL_REG
  RTS
.endproc

.proc check_bullet_dvd_collision
  current_dvd := locals+0 ; arg
  PUSH_REG
  LDA bullet_x
  CMP dvd_x,x
  BMI done
  CMP dvd_x_right,x
  BPL done
  LDA bullet_y
  CLC
  ADC #$03
  CMP dvd_y,x
  BMI done
  CMP dvd_y_bottom,x
  BPL done
  JSR on_collision_bullet_dvd
done:
  PULL_REG
  RTS
.endproc

.import inc_food_inv
.proc on_collision_enemy
  PUSH_REG
  ; set bullet inactive 
  ; TODO: remember to check later whether it was set inactive
  ; so it can't collide with multiple dvds at once
  JSR inc_food_inv
  JSR destroy_enemy
  JSR destroy_bullet
  PULL_REG
  RTS
.endproc

.import destroy_dvd
.proc on_collision_bullet_dvd
  current_dvd := locals+0 ; arg
  PUSH_REG
  LDX current_dvd
  DEC dvd_health,x
  BNE done
  JSR destroy_dvd
done:
  JSR destroy_bullet
  PULL_REG
  RTS
.endproc

.export draw_bullet
.proc draw_bullet
  PUSH_REG
  ; draw bullet
  LDX oam_current_index
  LDA bullet_y
  STA $0200,x
  LDA #$0C
  STA $0201,x
  LDA #$00
  STA $0202,x
  LDA bullet_x
  STA $0203,x
  
  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  
  PULL_REG
  RTS
.endproc

.proc destroy_bullet
  PUSH_REG
  LDA bullet_flags
  EOR #BULLET_FLAG_ACTIVE
  STA bullet_flags
  LDA #Y_OUT_OF_BOUNDS
  STA bullet_y
  PULL_REG
  RTS
.endproc

.segment "RODATA"

.export rand_x_pos
rand_x_pos:
.byte $12, $20, $50, $23, $d0, $a4, $3a, $6b, $8f, $70, $1c, $46, $66, $94, $cc, $ba

.export rand_y_pos
rand_y_pos:
.byte $42, $60, $50, $43, $c0, $a4, $aa, $6b, $8f, $70, $80, $46, $66, $94, $b0, $ba