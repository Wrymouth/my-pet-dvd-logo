.include "include/hardware_constants.inc"
.include "include/game_constants.inc"
.include "include/macros.inc"

.importzp oam_current_index, oam_offset_add
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
  LDX oam_current_index
  LDA #$00
  STA $0200,x
  LDA score_h
  ORA #HUD_MASK_CHR
  STA $0201,x
  LDA #$03
  STA $0202,x
  LDA #$00
  STA $0203,x

  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAX

  LDA #$00
  STA $0200,x
  LDA score_l
  ORA #HUD_MASK_CHR
  STA $0201,x
  LDA #$03
  STA $0202,x
  LDA #$08
  STA $0203,x

  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  PULL_REG
  RTS
.endproc

.export draw_food_inv
.proc draw_food_inv
  PUSH_REG
  LDX oam_current_index
  LDA #$00
  STA $0200,x
  LDA food_amount_h
  ORA #HUD_MASK_CHR
  STA $0201,x
  LDA #$03
  STA $0202,x
  LDA #$F0
  STA $0203,x

  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  TAX

  LDA #$00
  STA $0200,x
  LDA food_amount_l
  ORA #HUD_MASK_CHR
  STA $0201,x
  LDA #$03
  STA $0202,x
  LDA #$F8
  STA $0203,x

  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
  PULL_REG
  RTS
.endproc