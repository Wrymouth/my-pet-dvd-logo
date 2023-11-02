.include "include/hardware_constants.inc"
.include "include/game_constants.inc"
.include "include/macros.inc"

.importzp player_x, pad1_pressed
.importzp oam_bytes_used, oam_current_index, oam_offset_add

.export update_player
.proc update_player
  PUSH_REG
  LDA pad1_pressed
  AND #BTN_RIGHT
  BNE move_right ; zero flag clear
  LDA pad1_pressed
  AND #BTN_LEFT
  BNE move_left ; zero flag clear
  JMP done
move_right:
  LDA player_x
  CMP #RIGHT_OF_DVD_FIELD + 16
  BEQ done
  INC player_x
  INC player_x
  JMP done
move_left:
  LDA player_x
  CMP #LEFT_OF_DVD_FIELD
  BEQ done
  DEC player_x
  DEC player_x
done:
  PULL_REG
  RTS
.endproc

.export draw_player
.proc draw_player
  PUSH_REG
  ; write player tile to start of $0200
  LDX oam_current_index
  ; y
  LDA #PLAYER_Y
  STA $0200,x
  ; tile num
  LDA #$0A
  STA $0201,x
  ; attr
  LDA #$03
  STA $0202,x
  ; x
  LDA player_x
  STA $0203,x
  
  TXA
  CLC
  ADC oam_offset_add
  STA oam_current_index
done:
  PULL_REG
  RTS
.endproc