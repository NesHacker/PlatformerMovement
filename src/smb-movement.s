; smb-movement - A movement and controls demo inspried by Super Mario Bros. 3
; By NesHacker

;-------------------------------------------------------------------------------
; System Memory Map
;-------------------------------------------------------------------------------
; $00-$1F:    Subroutine Scratch Memory
;             Volatile Memory used for
;-------------------------------------------------------------------------------
; $20-$7F:    Game State
;             Region of memory used to hold game state on the zero page. Since
;             zero page memory access is faster than absolute addressing store
;             values that are frequently read/written here.
;-------------------------------------------------------------------------------
; $80-$FF:    Render State
;             Fast access zero page memory used for rendering state and updates.
;             This includes things like animation timers, nametable data, etc.
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
  .byte $10                 ; mapper 0 (NROM)
  .byte $00                 ; System: NES

.segment "STARTUP"

.segment "VECTORS"
  .addr nmi, reset, 0

;-------------------------------------------------------------------------------
; Character (Pattern) Data for the game. This is an NROM game so it uses a fixed
; CHR-ROM. To edit the graphics, open the `src/bin/CHR-ROM.bin` file in YY-CHR
; and select the "2BPP NES" format and "FC/NES x16" pattern (this game uses 8x16
; pixel sprites, like SMB3).
;-------------------------------------------------------------------------------
.segment "CHARS"
.incbin "./src/bin/CHR-ROM.bin"

.segment "CODE"

.include "lib/flags.s"
.include "lib/joypad.s"
.include "lib/ppu.s"

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
  bit FLAGS
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

;-------------------------------------------------------------------------------
; Initializes the game on reset before the main loop begins to run
;-------------------------------------------------------------------------------
.proc init_game
  jsr init_palettes
  jsr init_sprites
  jsr init_nametable

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
  .byte $0F, $17, $18, $07    ; Grass / Dirt
  .byte $0F, $00, $10, $30    ; Gray Stone
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
  .byte 135, $80, %00000000, 120
  .byte 135, $82, %00000000, 128
.endproc


.proc init_nametable
  ; TODO Clean this up and factor drawing out in to generator routines...
  bit PPU_STATUS
  VramColRow 0, 19, NAMETABLE_A
  ldx #$20
  lda #$06
: sta PPU_DATA
  dex
  bne :-
  ldy #10
: ldx #$20
  lda #$08
: sta PPU_DATA
  dex
  bne :-
  dey
  bne :--
  VramReset
  rts
.endproc

;-------------------------------------------------------------------------------
; Main game loop logic that runs every tick
;-------------------------------------------------------------------------------

TARGET_VELOCITY   = $30
VELOCITY          = $31
POSITION_X        = $32
POSITION_X_SPRITE = $34

HEADING                   = $35 ; 0 = Right, 1 = Left
ANIMATION_INDEX           = $36
ANIMATION_TIMER           = $37
ANIMATION_FRAME_DURATION  = $38




.proc game_loop
  jsr read_joypad1
  ;jsr WalkAnimation::run

  ; Horizontal Movement
  jsr set_target_velocity
  jsr accelerate
  jsr apply_velocity
  jsr bound_position
  jsr set_player_sprite_position



  rts
.endproc

.proc apply_velocity
  ; Check to see if we're moving to the right (positive) or the left (negative)
  lda VELOCITY
  bmi @negative
@positive:
  ; Positive velocity is easy: just add the 4.4 fixed point velocity to the
  ; 12.4 fixed point position.
  clc
  adc POSITION_X
  sta POSITION_X
  lda #0
  adc POSITION_X + 1
  sta POSITION_X + 1
  rts
@negative:
  ; There's probably a really clever way to do this just with ADC but I am lazy
  ; and conceptually it made things easier in my head to invert the negative
  ; velocity and use SBC.
  lda #0
  sec
  sbc VELOCITY
  sta $00
  lda POSITION_X
  sec
  sbc $00
  sta POSITION_X
  lda POSITION_X+1
  sbc #0
  sta POSITION_X+1
  rts
.endproc

.proc bound_position
  ; Convert the fixed point position coordinate into screen coordinates
  lda POSITION_X
  sta $00
  lda POSITION_X + 1
  sta $01
  lsr $01
  ror $00
  lsr $01
  ror $00
  lsr $01
  ror $00
  lsr $01
  ror $00
  ; Assume that everything is fine and save the sprite position
  lda $00
  sta POSITION_X_SPRITE
  ; Check if we are moving left or right (negative or positive respectively)
  lda VELOCITY
  bmi @negative
@positive:
  lda $01
  bne @bound_upper
  lda $00
  cmp #239
  bcs @bound_upper
  rts
@bound_upper:
  ; $EF = 239 = 255 - 16, this is the right bound since the screen is 256 pixels
  ; wide and the character is 16 pixels wide.
  lda #$EF
  sta POSITION_X_SPRITE
  lda #$0E
  sta POSITION_X+1
  lda #$F0
  sta POSITION_X
  ; Finally, set the velocity to 0 since the player is being "stopped"
  lda #0
  sta VELOCITY
  rts
@negative:
  ; The negative case is really simple, just check if the high order byte of the
  ; 12.4 fixed point position is negative. If so bound everything to 0.
  lda POSITION_X+1
  bmi @bound_lower
  rts
@bound_lower:
  lda #0
  sta POSITION_X
  sta POSITION_X + 1
  sta POSITION_X_SPRITE
  sta VELOCITY
  rts
.endproc

.proc set_player_sprite_position
  ; This is computed in `bound_position` above, so all we have to do is set the
  ; sprite X coordinates appropriately.
  lda POSITION_X_SPRITE
  sta $200 + 3
  clc
  adc #8
  sta $0204 + 3
  rts
.endproc

.proc set_target_velocity
  ; Check if the B button is being pressed and save the state in the X register
  ldx #0
  lda #BUTTON_B
  and JOYPAD_DOWN
  beq @check_right
  inx
@check_right:
  ; Check if the right d-pad is down and if so set the target velocity by using
  ; the lookup table at the end of the routine. This is why we set x to either
  ; 0 or 1, so we could use the table to set the "walk right" or "run right"
  ; velocity.
  lda #BUTTON_RIGHT
  and JOYPAD_DOWN
  beq @check_left
  lda right_velocity, x
  sta TARGET_VELOCITY
  rts
@check_left:
  ; Similar to `@check_right` above, but for the left direction
  lda #BUTTON_LEFT
  and JOYPAD_DOWN
  beq @no_direction
  lda left_velocity, x
  sta TARGET_VELOCITY
  rts
@no_direction:
  ; If the player isn't pressing left or right the horizontal velocity is 0
  lda #0
  sta TARGET_VELOCITY
  rts
  ; The velocities are stored in signed 4.4 fixed point, just like in SMB3.
  ; The idea is that the left 4 bits are the "whole" part of the number and the
  ; right four bits are the "fractional" part.
right_velocity:
  .byte $18, $28
left_velocity:
  .byte $E8, $D8
.endproc

.proc accelerate
  ; Subtract the current velocity from the target velocity to compare the two
  ; values.
  ;
  ; If V - T == 0:
  ;   Then the current velocity is at the target and we are done.
  ; If V - T < 0:
  ;   Then the velocity is greater than the target and should be *decreased*.
  ; Otherwise, if V - T > 0:
  ;   Then the velocity is less than the target and should be *increased*.
  ;
  ; I'm pretty sure SMB3 uses a lookup table to handle the specific acceleration
  ; values, but I just keep things simple and use inc/dec to increase the value
  ; by a maximum of 1 each frame (which gives the effect of a constant
  ; acceleration).
  lda VELOCITY
  sec
  sbc TARGET_VELOCITY
  bne @check_greater
  rts
@check_greater:
  bmi @lesser:
  dec VELOCITY
  rts
@lesser:
  inc VELOCITY
  rts
.endproc


;-------------------------------------------------------------------------------
; Rendering loop logic that runs during the NMI
;-------------------------------------------------------------------------------
.proc render_loop
  lda #$00
  sta OAM_ADDR
  lda #$02
  sta OAM_DMA
  rts
.endproc
