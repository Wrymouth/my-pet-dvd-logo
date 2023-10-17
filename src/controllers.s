.include "include/hardware_constants.inc"
.include "include/macros.inc"

.segment "ZEROPAGE"
.importzp pad1_pressed, pad1_held, pad1_released

.segment "CODE"
.export read_controller1
.proc read_controller1
  PHA
  TXA
  PHA
  PHP
  LDA pad1_pressed
  ; write a 1, then a 0, to CONT1
  ; to latch button states
  LDA #$01
  STA CONT1
  LDA #$00
  STA CONT1
  LDA #%00000001
  STA pad1_pressed
get_buttons:
  LDA CONT1 ; Read next button's state
  LSR A           ; Shift button state right, into carry flag
  ROL pad1_pressed        ; Rotate button state from carry flag
                  ; onto right side of pad1
                  ; and leftmost 0 of pad1 into carry flag
  BCC get_buttons ; Continue until original "1" is in carry flag
  PLP
  PLA
  TAX
  PLA
  RTS
.endproc

.export handle_released_and_held
.proc handle_released_and_held
  PUSH_REG
  ; get released buttons
  LDA pad1_pressed
  EOR #$FF
  AND pad1_released
  STA pad1_released
  ; get held buttons
  LDA pad1_held
  AND pad1_pressed
  STA pad1_held
  PULL_REG
  RTS
.endproc