.include "include/hardware_constants.inc"
.segment "ZEROPAGE"
.importzp dvd_x, dvd_y, player_x, dvd_health

.segment "CODE"

  .import main
  
  .export reset_handler
  .proc reset_handler
    SEI
    CLD
    LDX #$00
    STX PPUCTRL
    STX PPUMASK
  vblankwait:
    BIT PPUSTATUS
    BPL vblankwait
    ; initialize zero-page values
    LDA #$90
    STA player_x
    LDA #$80
    STA dvd_x
    LDA #$a0
    STA dvd_y
    LDA #$04
    STA dvd_health
    JMP main
  .endproc