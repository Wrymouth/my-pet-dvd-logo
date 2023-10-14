.include "include/hardware_constants.inc"

.segment "ZEROPAGE"
.importzp pad1

.segment "CODE"
.export read_controller1
.proc read_controller1
  PHA
  TXA
  PHA
  PHP
  ; write a 1, then a 0, to CONT1
  ; to latch button states
  LDA #$01
  STA CONT1
  LDA #$00
  STA CONT1
  LDA #%00000001
  STA pad1
get_buttons:
  LDA CONT1 ; Read next button's state
  LSR A           ; Shift button state right, into carry flag
  ROL pad1        ; Rotate button state from carry flag
                  ; onto right side of pad1
                  ; and leftmost 0 of pad1 into carry flag
  BCC get_buttons ; Continue until original "1" is in carry flag
  PLP
  PLA
  TAX
  PLA
  RTS
.endproc