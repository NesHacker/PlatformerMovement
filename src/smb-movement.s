; smb-movement - A movement and controls demo inspried by Super Mario Bros. 3
; By NesHacker

.include "lib/ppu.s"

FLAGS = $20

.macro SetRenderFlag
  lda #%10000000
  ora FLAGS
  sta FLAGS
.endmacro

.macro UnsetRenderFlag
  lda #%01111111
  and FLAGS
  sta FLAGS
.endmacro

;-------------------------------------------------------------------------------
; iNES Header, Vectors, and Startup Section
;-------------------------------------------------------------------------------
.segment "HEADER"
  .byte $4E, $45, $53, $1A  ; iNES header identifier
  .byte 2                   ; 2x 16KB PRG-ROM Banks
  .byte 1                   ; 1x  8KB CHR-ROM
  .byte $10                 ; mapper 0 (NROM)
  .byte $00                 ; System: NES
  
.segment "STARTUP" 

.segment "CHARS"
.incbin "./src/bin/CHR-ROM.bin"

.segment "VECTORS"
  .addr nmi, reset, 0

.segment "CODE"

.proc reset
  sei
  cld
  ldx #$ff
  txs
  ldx #0
  stx PPU_CTRL
  stx PPU_MASK
  stx $4010
  ldx #%01000000
  stx $4017
  bit PPU_STATUS
  VblankWait
  ldx #0
  lda #0
@ram_reset_loop:
  sta $000, x
  sta $100, x
  sta $200, x
  sta $300, x
  sta $400, x
  sta $500, x
  sta $600, x
  sta $700, x
  inx
  bne @ram_reset_loop
  lda #%11101111
@sprite_reset_loop: 
  sta $200, x
  inx
  bne @sprite_reset_loop
  lda #$00
  sta OAM_ADDR
  lda #$02
  sta OAM_DMA
  VblankWait
  bit PPU_STATUS
  lda #$3F
  sta PPU_ADDR
  lda #$00
  sta PPU_ADDR
  lda #$0F
  ldx #$20
@resetPalettesLoop:
  sta PPU_DATA
  dex
  bne @resetPalettesLoop
  jmp main
.endproc

.proc main
  jsr init_game
loop:
  jsr game_loop
  SetRenderFlag
@wait_for_render:
  bit FLAGS
  bmi @wait_for_render
  jmp loop
.endproc

.proc nmi
  bit FLAGS
  bpl @return
  jsr render_loop
  UnsetRenderFlag
@return:
  rti
.endproc

.scope WalkAnimation
  TIMER = $40
  DURATION = 8

  .proc init
    lda #DURATION
    sta TIMER
    rts 
  .endproc

  .proc run
    dec TIMER
    beq @next_frame
    rts
  @next_frame:
    ldx #DURATION
    stx TIMER
    lda $0200 + 1
    cmp #$80
    beq @frame2
  @frame1:
    lda #$80
    sta $0200 + 1
    lda #$82
    sta $0204 + 1
    rts
  @frame2:
    lda #$84
    sta $0200 + 1
    lda #$86
    sta $0204 + 1
    rts
  .endproc
.endscope

.proc init_game
  jsr init_palettes
  jsr init_sprites                      
  jsr WalkAnimation::init

  lda #%10100000
  sta PPU_CTRL
  lda #%00011110
  sta PPU_MASK
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
  .byte $0F, $00, $10, $30    ; Gray Stone
  .byte $0F, $07, $19, $17    ; Grass / Dirt
  .byte $0F, $0F, $0F, $0F
  .byte $0F, $0F, $0F, $0F
  .byte $0F, $0B, $14, $35    ; Character
  .byte $0F, $0F, $0F, $0F
  .byte $0F, $0F, $0F, $0F
  .byte $0F, $0F, $0F, $0F
.endproc

.proc init_sprites
  NUM_SPRITES = 2
  ldx #0
@loop:
  lda data, x
  sta $200, x
  inx
  cpx #(4 * NUM_SPRITES)
  bne @loop
  rts
data:
  .byte 116, $80, %00000000, 120
  .byte 116, $82, %00000000, 128
.endproc




.proc game_loop
  jsr WalkAnimation::run
  rts
.endproc

.proc render_loop
  lda #$00
  sta OAM_ADDR
  lda #$02
  sta OAM_DMA
  rts
.endproc


