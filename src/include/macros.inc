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