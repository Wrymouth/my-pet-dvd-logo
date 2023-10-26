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
  CMP #$09
  BEQ inc_food_h
  INC food_amount_l
  JMP done
inc_food_h:
  LDA food_amount_h
  CMP #$09
  BEQ done
  INC food_amount_h
  LDA #$00
  STA food_amount_l
done:
  PULL_REG
  RTS
.endproc

.export draw_score
.proc draw_score
    PUSH_REG
    LDA score_h
    ORA #SCORE_MASK_CHR
    STA OAM_SCORE+1
    LDA #$03
    STA OAM_SCORE+2
    LDA #$00
    STA OAM_SCORE
    STA OAM_SCORE+3
    LDA score_l
    ORA #SCORE_MASK_CHR
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