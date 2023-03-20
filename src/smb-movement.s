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

;-------------------------------------------------------------------------------
; Initializes the game on reset before the main loop begins to run
;-------------------------------------------------------------------------------
.proc init_game
  ; Initialize the game state
  jsr init_palettes
  jsr init_sprites
  jsr init_nametable

  ; Enable rendering and NMI
  lda #%10110000
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
  .byte 143, $80, %00000000, 120
  .byte 143, $82, %00000000, 128
.endproc

.proc init_nametable
  ; Draw the ground platform
  VramColRow 0, 20, NAMETABLE_A
  lda #$04
  jsr ppu_full_line
  lda #$05
  jsr ppu_full_line
  lda #$06
  jsr ppu_full_line

  ; Draw the press button indicators
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

  ; Draw the horizontal velocity indicator
  VramColRow 1, 27, NAMETABLE_A
  lda #$30
  sta PPU_DATA
  lda #$31
  sta PPU_DATA
  sta PPU_DATA
  sta PPU_DATA
  lda #$34
  sta PPU_DATA
  sta PPU_DATA
  sta PPU_DATA
  lda #$35
  sta PPU_DATA

  VramReset
  rts
.endproc

.proc ppu_full_line
  ; Fills a full line of 32 tiles with the value in `A`.
  ldx #32
  jsr ppu_fill_line
  rts
.endproc

.proc ppu_fill_line
  ; Writes `A` into VRAM `X` times.
@loop:
  sta PPU_DATA
  dex
  bne @loop
  rts
.endproc

.proc ppu_fill_and_increment
  ; Writes the value `Y` into VRAM `X` times, incrementing `Y` after each write.
  ; Useful if you have background tiles laid out linearly in the pattern table.
@loop:
  tya
  iny
  sta PPU_DATA
  dex
  bne @loop
  rts
.endproc





;-------------------------------------------------------------------------------
; Main game loop logic that runs every tick
;-------------------------------------------------------------------------------

TARGET_VELOCITY           = $30 ; Signed Fixed Point 4.4
VELOCITY                  = $31 ; Signed Fixed Point 4.4
POSITION_X                = $32 ; Signed Fixed Point 12.4
POSITION_X_SPRITE         = $34 ; Unsigned Screen Coordinates
HEADING                   = $35 ; 0 = Right, 1 = Left
ANIMATION_FRAME           = $36
ANIMATION_TIMER           = $37
ANIMATION_MOTION_STATE    = $38 ; 0 = Still, 1 = Walk/Run, 2 = Pivot

.enum MotionState
  Still = 0
  Walk  = 1
  Pivot = 2
.endenum

.proc game_loop
  ; 1) Read the joypad and update the controller state
  jsr read_joypad1

  ; 2) Update player movement state based on controller input
  jsr update_player_movement

  ; 3) Update player sprite based on movement state
  jsr update_player_sprite

  rts
.endproc

.proc update_player_movement
  jsr set_target_velocity
  jsr accelerate
  jsr apply_velocity
  jsr bound_position
  rts
.endproc

.proc update_player_sprite
  jsr update_motion_state
  jsr update_animation_frame
  jsr update_heading
  jsr update_sprite_tiles
  jsr update_sprite_position
  rts
.endproc

.proc update_sprite_tiles
  ldx HEADING
  lda ANIMATION_MOTION_STATE
  cmp #MotionState::Pivot
  beq @pivot
  cmp #MotionState::Walk
  beq @walk
@still:
  lda walk_tiles, x
  sta $200 + OAM_TILE
  lda walk_tiles +2, x
  sta $204 + OAM_TILE
  rts
@walk:
  lda ANIMATION_FRAME
  asl
  asl
  clc
  adc HEADING
  tax
  lda walk_tiles, x
  sta $200 + OAM_TILE
  lda walk_tiles +2, x
  sta $204 + OAM_TILE
  rts
@pivot:

  lda pivot_tiles, x
  sta $200 + OAM_TILE
  lda pivot_tiles + 2, x
  sta $204 + OAM_TILE
  rts
pivot_tiles:
  .byte $98, $9A, $9A, $98 ; Pivot is the same no matter the animation frame
walk_tiles:
  .byte $80, $82, $82, $80 ; Frame 1
  .byte $84, $86, $86, $84 ; Frame 2
.endproc

.proc update_sprite_position
  ; This is computed in `bound_position` above, so all we have to do is set the
  ; sprite X coordinates appropriately.
  lda POSITION_X_SPRITE
  sta $200 + 3
  clc
  adc #8
  sta $0204 + 3
  rts
.endproc

.proc update_animation_frame
  ; If V == 0:
  ;   Set initial timer
  ; Else:
  ;   Decrement timer
  ;   If frame timer == 0:
  ;     Reset frame timer based on V
  ;     Increment the frame
  lda VELOCITY
  bne @moving
  lda delay_by_velocity
  sta ANIMATION_TIMER
  rts
@moving:
  dec ANIMATION_TIMER
  beq @next_frame
  rts
@next_frame:
  ldx VELOCITY
  bpl @transition_state
  lda #0
  sec
  sbc VELOCITY
  tax
@transition_state:
  lda delay_by_velocity, x
  sta ANIMATION_TIMER
  lda #1
  eor ANIMATION_FRAME
  sta ANIMATION_FRAME
  rts
delay_by_velocity:
  .byte 12, 11, 11, 11, 11, 11, 10, 10, 10, 10, 10
  .byte 9, 9, 9, 9, 9, 8, 8, 8, 8, 8, 7, 7, 7, 7, 7
  .byte 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4
.endproc

.proc update_motion_state
  ; If T = V:
  ;   // Steady motion
  ;   If T == 0: STILL
  ;   Else: WALK
  ; If T <> V:
  ;   // Accelerating
  ;   If <- or -> being pressed:
  ;     If T > 0 && V < 0: PIVOT
  ;     If T < 0 && V > 0: PIVOT
  ;   Else: WALK
  lda TARGET_VELOCITY
  cmp VELOCITY
  bne @accelerating
@steady:
  lda VELOCITY
  beq @still
  bne @walk
@still:
  lda #MotionState::Still
  sta ANIMATION_MOTION_STATE
  rts
@accelerating:
  lda #BUTTON_LEFT
  ora #BUTTON_RIGHT
  and JOYPAD_DOWN
  beq @walk
  lda #%10000000
  and TARGET_VELOCITY
  sta $00
  lda #%10000000
  and VELOCITY
  cmp $00
  beq @walk
@pivot:
  lda #MotionState::Pivot
  sta ANIMATION_MOTION_STATE
  rts
@walk:
  lda #MotionState::Walk
  sta ANIMATION_MOTION_STATE
  rts
.endproc

.proc update_heading
  ; If the target velocity is 0 then the player isn't pressing left or right and
  ; the heading doesn't need to change.
  lda TARGET_VELOCITY
  bne @check_heading
  rts
  ; If the target velocity is non-zero, check to see if player is heading in the
  ; desired direction.
@check_heading:
  asl
  lda #0
  rol
  cmp HEADING
  bne @update_heading
  rts
@update_heading:
  ; If the desired heading is not equal to the current heading based on the
  ; target velocity, then update the heading.
  sta HEADING
  ; Toggle the "horizontal" mirroring on the character sprites
  lda #%01000000
  eor $200 + OAM_ATTR
  sta $200 + OAM_ATTR
  sta $204 + OAM_ATTR
  rts
.endproc

;-------------------------------------------------------------------------------
; Horizontal Movement and Controls
;-------------------------------------------------------------------------------
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
  bmi @lesser
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
