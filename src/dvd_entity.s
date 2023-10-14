.importzp dvd_x, dvd_y, dvd_dir_x, dvd_dir_y, dvd_health
.export update_dvd
.proc update_dvd
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  LDA dvd_x
  CMP #$e0
  BCC not_at_right_edge
  ; if BCC is not taken, we are greater than $e0
  LDA #$00
  STA dvd_dir_x    ; start moving left
  JMP direction_set ; we already chose a direction,
                    ; so we can skip the left side check
not_at_right_edge:
  LDA dvd_x
  CMP #$10
  BCS direction_set
  ; if BCS not taken, we are less than $10
  LDA #$01
  STA dvd_dir_x   ; start moving right
direction_set:
  ; now, actually update dvd_x
  LDA dvd_dir_x
  CMP #$01
  BEQ move_right
  ; if dvd_dir_x minus $01 is not zero,
  ; that means dvd_dir_x was $00 and
  ; we need to move left
  DEC dvd_x
  JMP done_with_x
move_right:
  INC dvd_x

done_with_x:

  ; y axis movement
  LDA dvd_dir_y
  CMP #$01
  BEQ move_up
move_down:
  INC dvd_y
  JMP direction_set_y
move_up:
  DEC dvd_y

direction_set_y:
  LDA dvd_y
  CMP #$20
  BCC at_top_edge
  CMP #$d0
  BCS at_bottom_edge
  JMP done_moving
at_bottom_edge:
  LDA #$01
  STA dvd_dir_y
  JMP done_moving
at_top_edge:
  LDA #$00
  STA dvd_dir_y

done_moving:
  ; all done, clean up and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

.export draw_dvd
.proc draw_dvd
  ; save registers
  PHP
  PHA
  TXA
  PHA
  TYA
  PHA

  ; write dvd ship tile numbers
  ; top left
  LDA #$05
  STA $0205
  ; top mid
  LDA #$06
  STA $0209
  ; top right
  LDA #$07
  STA $020D
  ; bottom left
  LDA #$08
  STA $0211
  ; bottom mid
  LDA #$09
  STA $0215
  ; bottom right
  LDA #$08
  STA $0219

  ; write dvd ship tile attributes
  ; use palette 0
  LDA #$00
  ORA dvd_health
  SBC #$01
  STA $0206
  STA $020A
  STA $020E
  STA $0212
  STA $0216
  LDA #%01000000
  ORA dvd_health
  SBC #$01
  STA $021A

  ; store tile locations
  ; top left tile:
  LDA dvd_y
  STA $0204
  LDA dvd_x
  STA $0207

  ; top mid tile (x + 8):
  LDA dvd_y
  STA $0208
  LDA dvd_x
  CLC
  ADC #$08
  STA $020B

  ; top right tile (x + 16):
  LDA dvd_y
  STA $020C
  LDA dvd_x
  CLC
  ADC #$10
  STA $020F

  ; bottom left tile (y + 8):
  LDA dvd_y
  CLC
  ADC #$08
  STA $0210
  LDA dvd_x
  STA $0213

  ; bottom mid tile (x + 8, y + 8)
  LDA dvd_y
  CLC
  ADC #$08
  STA $0214
  LDA dvd_x
  CLC
  ADC #$08
  STA $0217

  ; bottom right tile (x + 16, y + 8)
  LDA dvd_y
  CLC
  ADC #$08
  STA $0218
  LDA dvd_x
  CLC
  ADC #$10
  STA $021B

  ; restore registers and return
  PLA
  TAY
  PLA
  TAX
  PLA
  PLP
  RTS
.endproc