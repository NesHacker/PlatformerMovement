; smb-movement - A movement and controls demo inspried by Super Mario Bros. 3
; By NesHacker

;-------------------------------------------------------------------------------
; System Memory Map
;-------------------------------------------------------------------------------
; $00-$1F:    Subroutine Scratch Memory
;             Volatile Memory used for parameters, return values, and temporary
;             / scratch data.
;-------------------------------------------------------------------------------
; $20-$FF:    Game State
;             Region of memory used to hold game state on the zero page. Since
;             zero page memory access is faster than absolute addressing store
;             values that are frequently read/written here.
;-------------------------------------------------------------------------------
; $100-$1FF:  The Stack
;             Region of memory set aside for the system stack.
;-------------------------------------------------------------------------------
; $200-$2FF:  OAM Sprite Memory
;             This holds the OAM information for the sprites used by the game.
;             Every frame, inside the `render_loop` routine below, the data here
;             is transferred to the PPU in its entirety.
;-------------------------------------------------------------------------------
; $300-$7FF:  General Purpose RAM
;             General purpose storage for other game related state. Since this
;             demo is pretty simple none of this memory is used, so feel free
;             to use it when making modifications or hacking your own logic.
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; iNES Header, Vectors, and Startup Section
;-------------------------------------------------------------------------------
.segment "HEADER"
  .byte $4E, $45, $53, $1A  ; iNES header identifier
  .byte 2                   ; 2x 16KB PRG-ROM Banks
  .byte 1                   ; 1x  8KB CHR-ROM
  .byte $00                 ; mapper 0 (NROM)
  .byte $00                 ; System: NES

.segment "STARTUP"

.segment "VECTORS"
  .addr nmi, reset, 0

;-------------------------------------------------------------------------------
; Character (Pattern) Data for the game. This is an NROM game so it uses a fixed
; CHR-ROM. To edit the graphics, open the `src/bin/CHR-ROM.bin` file in YY-CHR.
; To get the file displaying correctly use the "2BPP NES" format.
;
; The first table contains the 8x16 sprites for the game, to make it easier to
; edit them use the "FC/NES x16" pattern option. The second table consists of
; mostly background tiles, so using the "Normal" pattern option is best.
;-------------------------------------------------------------------------------
.segment "CHARS"
.incbin "./src/bin/CHR-ROM.bin"

;-------------------------------------------------------------------------------
; Main Game Code
;-------------------------------------------------------------------------------
.segment "CODE"

; Uncomment this line to enable "video demo" mode, which I used to record the
; demo gameplay for the video.
; VIDEO_DEMO_MODE = 1

; Library Includes
.include "lib/ppu.s"

; State Controllers
.include "state/Game.s"
.include "state/Joypad.s"
.include "state/Player.s"
.include "state/VelocityIndicator.s"

;-------------------------------------------------------------------------------
; Core reset method for the game, this is called on powerup and when the system
; is reset. It is responsible for getting the system into a consistent state
; so that game logic will have the same effect every time it is run anew.
;-------------------------------------------------------------------------------
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

;-------------------------------------------------------------------------------
; The main routine for the program. This sets up and handles the execution of
; the game loop and controls memory flags that indicate to the rendering loop
; if the game logic has finished processing.
;
; For the most part if you're emodifying or playing with the code, you shouldn't
; have to make edits here. Instead make changes to `init_game` and `game_loop`
; below...
;-------------------------------------------------------------------------------
.proc main
  jsr init_game
loop:
  jsr game_loop
  SetRenderFlag
@wait_for_render:
  bit Game::flags
  bmi @wait_for_render
  jmp loop
.endproc

;-------------------------------------------------------------------------------
; Non-maskable Interrupt Handler. This interrupt is executed at the end of each
; PPU rendering frame during the Vertical Blanking Interval (VBLANK). This
; interval lasts rougly 2273 CPU cycles, and to avoid graphical glitches all
; drawing in the "rendering_loop" should be completed within that timeframe.
;
; For the most part if you're modifying or playing with the code, you shouldn't
; have to touch the nmi directly. To change how the game renders update the
; `render_loop` routine below...
;-------------------------------------------------------------------------------
.proc nmi
  bit Game::flags
  bpl @return
  jsr render_loop
  UnsetRenderFlag
@return:
  rti
.endproc

;-------------------------------------------------------------------------------
; Initializes the game on reset before the main loop begins to run
;-------------------------------------------------------------------------------
.proc init_game
  ; Initialize the game state
  jsr Game::init
  jsr Player::init

  .ifndef VIDEO_DEMO_MODE
    jsr VelocityIndicator::init
  .endif

  ; Enable rendering and NMI
  lda #%10110000
  sta PPU_CTRL
  lda #%00011110
  sta PPU_MASK
  rts
.endproc

;-------------------------------------------------------------------------------
; Main game loop logic that runs every tick
;-------------------------------------------------------------------------------
.proc game_loop
  jsr Joypad::update
  jsr Player::Movement::update
  jsr Player::Sprite::update
  .ifndef VIDEO_DEMO_MODE
    jsr VelocityIndicator::update
  .endif
  rts
.endproc

;-------------------------------------------------------------------------------
; Rendering loop logic that runs during the NMI
;-------------------------------------------------------------------------------
.proc render_loop
  ; Update the binary button indicator tiles
  .ifndef VIDEO_DEMO_MODE
    VramColRow 2, 25, NAMETABLE_A
    lda Joypad::downTiles
    sta PPU_DATA
    lda Joypad::downTiles + 1
    sta PPU_DATA
    lda Joypad::downTiles + 4
    sta PPU_DATA
    lda Joypad::downTiles + 5
    sta PPU_DATA
    lda Joypad::downTiles + 6
    sta PPU_DATA
    lda Joypad::downTiles + 7
    sta PPU_DATA
  .endif

  ; Transfer Sprites via OAM
  lda #$00
  sta OAM_ADDR
  lda #$02
  sta OAM_DMA

  ; Reset the VRAM address
  VramReset

  rts
.endproc
