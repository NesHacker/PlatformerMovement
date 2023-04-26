;-------------------------------------------------------------------------------
; [$20-$2F] Core Game State
;-------------------------------------------------------------------------------
.scope Game
  ; Holds major flags for the game. Bit 7 indicates to the NMI handler that
  ; state update are complete and the VRAM can be updated. Bits 0-6 are unused.
  flags = $20

  .proc init
    jsr init_palettes
    jsr init_nametable
    rts
  .endproc

  .proc init_palettes
    bit PPU_STATUS
    lda #$3F
    sta PPU_ADDR
    lda #$00
    sta PPU_ADDR
    ldx #0
  @loop:
    lda palettes, x
    sta PPU_DATA
    inx
    cpx #32
    bne @loop
    rts
  palettes:
    .byte $0F, $17, $18, $07    ; Grass / Dirt
    .byte $0F, $00, $10, $30    ; Gray Stone
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $0B, $14, $35    ; Character
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $0F, $0F, $0F
    .byte $0F, $0F, $0F, $0F
  .endproc

  .proc init_nametable
    jsr draw_ground
    .ifndef VIDEO_DEMO_MODE
      jsr draw_button_indicator
      jsr draw_velocity_indicator
    .endif
    VramReset
    rts
  .endproc

  .proc draw_ground
    VramColRow 0, 20, NAMETABLE_A
    lda #$04
    jsr ppu_full_line
    lda #$05
    jsr ppu_full_line
    lda #$06
    jsr ppu_full_line
    rts
  .endproc

  .proc draw_button_indicator
    VramColRow 2, 24, NAMETABLE_A
    ldy #$20
    ldx #$7
    jsr ppu_fill_and_increment
    VramColRow 2, 25, NAMETABLE_A
    lda #$29
    ldx #6
    jsr ppu_fill_line
    lda #$26
    sta PPU_DATA
    VramColRow 2, 26, NAMETABLE_A
    lda #$27
    ldx #6
    jsr ppu_fill_line
    lda #$28
    sta PPU_DATA
    rts
  .endproc

  .proc draw_velocity_indicator
    VramColRow 10, 24, NAMETABLE_A
    ldy #$30
    sty PPU_DATA
    iny
    sty PPU_DATA
    iny
    sty PPU_DATA
    VramColRow 10, 25, NAMETABLE_A
    iny
    sty PPU_DATA
    iny
    sty PPU_DATA
    iny
    sty PPU_DATA
    VramColRow 10, 26, NAMETABLE_A
    iny
    sty PPU_DATA
    iny
    sty PPU_DATA
    iny
    sty PPU_DATA
    rts
  .endproc
.endscope

.macro SetRenderFlag
  lda #%10000000
  ora Game::flags
  sta Game::flags
.endmacro

.macro UnsetRenderFlag
  lda #%01111111
  and Game::flags
  sta Game::flags
.endmacro
