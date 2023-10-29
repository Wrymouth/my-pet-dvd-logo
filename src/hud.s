.include "include/hardware_constants.inc"
.include "include/game_constants.inc"
.include "include/macros.inc"

.importzp score_l, score_h, food_amount_h, food_amount_l

.export inc_score
.proc inc_score
    PUSH_REG
    LDA score_l
    CMP #$09
    BEQ inc_score_h
    INC score_l
    JMP done
inc_score_h:
    LDA score_h
    CMP #$09
    BEQ done
    INC score_h
    LDA #$00
    STA score_l
done:
    PULL_REG
    RTS
.endproc

.export inc_food_inv
.proc inc_food_inv
  PUSH_REG
  LDA food_amount_l
  ADC #FOOD_GAINED_FROM_ENEMY
  CMP #$0A
  BPL inc_food_h
  STA food_amount_l
  JMP done
inc_food_h:
  SEC
  SBC #$0A
  STA food_amount_l
  LDA food_amount_h
  CMP #$09
  BEQ done
  INC food_amount_h

done:
  PULL_REG
  RTS
.endproc

.export dec_food_inv
.proc dec_food_inv
  PUSH_REG
  LDA food_amount_l
  BEQ dec_food_h
  DEC food_amount_l
  JMP done
dec_food_h:
  LDA food_amount_h
  BEQ done
  DEC food_amount_h
  LDA #$09
  STA food_amount_l
done:
  PULL_REG
  RTS
.endproc

.export draw_score
.proc draw_score
  PUSH_REG
  LDA score_h
  ORA #HUD_MASK_CHR
  STA OAM_SCORE+1
  LDA #$03
  STA OAM_SCORE+2
  LDA #$00
  STA OAM_SCORE
  STA OAM_SCORE+3
  LDA score_l
  ORA #HUD_MASK_CHR
  STA OAM_SCORE+5
  LDA #$03
  STA OAM_SCORE+6
  LDA #$00
  STA OAM_SCORE+4
  LDA #$08
  STA OAM_SCORE+7
  PULL_REG
  RTS
.endproc

.export draw_food_inv
.proc draw_food_inv
  PUSH_REG
  LDA food_amount_h
  ORA #HUD_MASK_CHR
  STA OAM_FOOD_INV+1
  LDA #$03
  STA OAM_FOOD_INV+2
  LDA #$00
  STA OAM_FOOD_INV
  LDA #$F0
  STA OAM_FOOD_INV+3
  LDA food_amount_l
  ORA #HUD_MASK_CHR
  STA OAM_FOOD_INV+5
  LDA #$03
  STA OAM_FOOD_INV+6
  LDA #$00
  STA OAM_FOOD_INV+4
  LDA #$F8
  STA OAM_FOOD_INV+7
  PULL_REG
  RTS
.endproc