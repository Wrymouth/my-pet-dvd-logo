.macro PUSH_REG
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA
.endmacro

.macro PULL_REG
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
.endmacro

.macro INC16 addr
  clc
  lda     addr
  adc     #$01
  sta     addr
  lda     addr+1
  adc     #$00
  sta     addr+1
.endmacro

.macro DEC16 addr
  sec
  lda     addr
  sbc     #$01
  sta     addr
  lda     addr+1
  sbc     #$00
  sta     addr+1
.endmacro