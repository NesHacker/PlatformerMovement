;-------------------------------------------------------------------------------
; Controls demo for illustrating "bad acceleration". Unlike the core demo this
; uses integer values for acceleration as opposed fixed-point numbers.
;
; This controller is unused by default, uncomment the `BAD_ACCELERATION_MODE`
; constant in the main `smb-movement.s` file to enable this controller and
; disable the normal movememnt controls.
;-------------------------------------------------------------------------------
; [$30-$3F] Player State (Movement, Animation, etc.)
;-------------------------------------------------------------------------------
.scope BadAcceleration
  velocityX = $30       ; Unsigned, px/frame
  spriteX = $31         ; Unsigned screen coordinate

  animationFrame = $32  ; Animation frame
  animationTimer = $33  ; Timer for the delay between animation frames
  FRAME_DELAY = 8       ; Delay between animation frames

  .proc init
    jsr init_position_and_velocity
    jsr init_sprites
    lda #FRAME_DELAY
    sta animationTimer
    rts
  .endproc

  .proc init_position_and_velocity
    lda #0
    sta velocityX
    lda #8
    sta spriteX
    rts
  .endproc

  .proc init_sprites
    NUM_SPRITES = 2
    LEFT_TILE = $80
    RIGHT_TILE = $82
    ATTRS = %00000000
    ldx #0
  @loop:
    lda initial_sprite_data, x
    sta $200, x
    inx
    cpx #(4 * NUM_SPRITES)
    bne @loop
    rts
  initial_sprite_data:
    .byte 143, LEFT_TILE, ATTRS, 8
    .byte 143, RIGHT_TILE, ATTRS, 8 + 8
  .endproc

  .proc update
    lda #BUTTON_RIGHT
    and Joypad::pressed
    beq @check_reset
    inc velocityX
  @check_reset:
    lda #BUTTON_START
    and Joypad::pressed
    beq @perform_updates
    jsr init_position_and_velocity
  @perform_updates:
    jsr update_position
    jsr update_animation
    rts
  .endproc

  .proc update_position
    lda velocityX
    beq @update_sprite
  @add_velocity:
    clc
    adc spriteX
    sta spriteX
  @update_sprite:
    lda spriteX
    sta $200 + OAM_X
    clc
    adc #8
    sta $204 + OAM_X
    rts
  .endproc

  .proc update_animation
    dec animationTimer
    beq @next_frame
    rts
  @next_frame:
    lda #FRAME_DELAY
    sta animationTimer
    lda #1
    eor animationFrame
    sta animationFrame
    asl
    asl
    clc
    adc #$80
    sta $200 + OAM_TILE
    adc #2
    sta $204 + OAM_TILE
    rts
  .endproc
.endscope
