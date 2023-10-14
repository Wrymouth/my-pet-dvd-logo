.include "include/hardware_constants.inc"
.include "include/macros.inc"

.importzp player_x, pad1

.export update_player
.proc update_player
  PUSH_REG
  LDA pad1
  AND #BTN_RIGHT
  BNE move_right ; zero flag clear
  LDA pad1
  AND #BTN_LEFT
  BNE move_left ; zero flag clear
  JMP done
move_right:
  INC player_x
  JMP done
move_left:
  DEC player_x
done:
  PULL_REG
  RTS
.endproc

.export draw_player
.proc draw_player
  PUSH_REG
  ; write player tile to start of $0200
  ; tile num
  LDA #$0A
  STA $0201
  ; attr
  LDA #$00
  STA $0202
  ; y
  LDA #$10
  STA $0200
  ; x
  LDA player_x
  STA $0203
done:
  PULL_REG
  RTS
.endproc