.include "include/hardware_constants.inc"
.include "include/game_constants.inc"
.segment "ZEROPAGE"
.importzp dvd_x, dvd_y, player_x, dvd_health, food_amount_l

.segment "CODE"

  .import main
  
  .export reset_handler
  .proc reset_handler
    SEI
    CLD
    LDX #$00
    STX PPUCTRL
    STX PPUMASK
  clear_memory:
    STA $0000, x
    STA $0100, x
    STA $0300, x
    STA $0400, x
    STA $0500, x
    STA $0600, x
    STA $0700, x
            
    LDA #$FF
    STA $0200, x ;sprites get special treatment
    LDA #$00


    INX
    CPX #$00
    BNE clear_memory
  vblankwait:
    BIT PPUSTATUS
    BPL vblankwait
    ; initialize zero-page values
    LDA #$90
    STA player_x
    LDA #FOOD_AMOUNT_START
    STA food_amount_l
    JMP main
  .endproc