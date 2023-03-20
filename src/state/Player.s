;-------------------------------------------------------------------------------
; [$30-$4F] Player State (Movement, Animation, etc.)
;-------------------------------------------------------------------------------
.scope Player
  targetVelocityX   = $30   ; Signed Fixed Point 4.4
  velocityX         = $31   ; Signed Fixed Point 4.4
  positionX         = $32   ; Signed Fixed Point 12.4
  spriteX           = $34   ; Unsigned Screen Coordinates
  heading           = $35   ; See `.enum Heading`, below...

  ; Currently unused, but coming soon...
  ; targetVelocityY = $36   ; Signed Fixed Point 4.4
  ; velocityY       = $37   ; Signed Fixed Point 4.4
  ; positionY       = $38   ; Signed Fixed Point 12.4
  ; spriteY         = $3A   ; Unsigned Screen Coordinates

  motionState              = $3B ; See `.enum MotionState`, below...
  animationFrame           = $3C
  animationTimer           = $3D
  idleState                = $3E ; See `.enum IdleState`, below...
  idleTimer                = $3F

  .enum Heading
    Right = 0
    Left = 1
  .endenum

  .enum MotionState
    Still = 0
    Walk  = 1
    Pivot = 2
  .endenum

  .enum IdleState
    Still = 0
    Blink1 = 1
    Still2 = 2
    Blink2 = 3
  .endenum

  .proc init
    ; Set the initial x-position to 48 ($30 hex and $0300 in 12.4 fixed point)
    lda #$30
    sta spriteX
    lda #0
    sta positionX
    lda #$03
    sta positionX+1
    rts
  .endproc

  .scope Movement
    .proc update
      jsr set_target_velocity
      jsr accelerate
      jsr apply_velocity
      jsr bound_position
      rts
    .endproc

    .proc set_target_velocity
      ; Check if the B button is being pressed and save the state in the X register
      ldx #0
      lda #BUTTON_B
      and Joypad::down
      beq @check_right
      inx
    @check_right:
      ; Check if the right d-pad is down and if so set the target velocity by using
      ; the lookup table at the end of the routine. This is why we set x to either
      ; 0 or 1, so we could use the table to set the "walk right" or "run right"
      ; velocity.
      lda #BUTTON_RIGHT
      and Joypad::down
      beq @check_left
      lda right_velocity, x
      sta targetVelocityX
      rts
    @check_left:
      ; Similar to `@check_right` above, but for the left direction
      lda #BUTTON_LEFT
      and Joypad::down
      beq @no_direction
      lda left_velocity, x
      sta targetVelocityX
      rts
    @no_direction:
      ; If the player isn't pressing left or right the horizontal velocity is 0
      lda #0
      sta targetVelocityX
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
      lda velocityX
      sec
      sbc targetVelocityX
      bne @check_greater
      rts
    @check_greater:
      bmi @lesser
      dec velocityX
      rts
    @lesser:
      inc velocityX
      rts
    .endproc

    .proc apply_velocity
      ; Check to see if we're moving to the right (positive) or the left (negative)
      lda velocityX
      bmi @negative
    @positive:
      ; Positive velocity is easy: just add the 4.4 fixed point velocity to the
      ; 12.4 fixed point position.
      clc
      adc positionX
      sta positionX
      lda #0
      adc positionX + 1
      sta positionX + 1
      rts
    @negative:
      ; There's probably a really clever way to do this just with ADC but I am lazy
      ; and conceptually it made things easier in my head to invert the negative
      ; velocity and use SBC.
      lda #0
      sec
      sbc velocityX
      sta $00
      lda positionX
      sec
      sbc $00
      sta positionX
      lda positionX+1
      sbc #0
      sta positionX+1
      rts
    .endproc

    .proc bound_position
      ; Convert the fixed point position coordinate into screen coordinates
      lda positionX
      sta $00
      lda positionX + 1
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
      sta spriteX
      ; Check if we are moving left or right (negative or positive respectively)
      lda velocityX
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
      sta spriteX
      lda #$0E
      sta positionX+1
      lda #$F0
      sta positionX
      ; Finally, set the velocity to 0 since the player is being "stopped"
      lda #0
      sta velocityX
      rts
    @negative:
      ; The negative case is really simple, just check if the high order byte of the
      ; 12.4 fixed point position is negative. If so bound everything to 0.
      lda positionX+1
      bmi @bound_lower
      rts
    @bound_lower:
      lda #0
      sta positionX
      sta positionX + 1
      sta spriteX
      sta velocityX
      rts
    .endproc
  .endscope

  .scope Sprite
    .proc update
      jsr update_motion_state
      jsr update_animation_frame
      jsr update_heading
      jsr update_idle_state
      jsr update_sprite_tiles
      jsr update_sprite_position
      rts
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
      lda targetVelocityX
      cmp velocityX
      bne @accelerating
    @steady:
      lda velocityX
      beq @still
      bne @walk
    @still:
      lda #MotionState::Still
      sta motionState
      rts
    @accelerating:
      lda #BUTTON_LEFT
      ora #BUTTON_RIGHT
      and Joypad::down
      beq @walk
      lda #%10000000
      and targetVelocityX
      sta $00
      lda #%10000000
      and velocityX
      cmp $00
      beq @walk
    @pivot:
      lda #MotionState::Pivot
      sta motionState
      rts
    @walk:
      lda #MotionState::Walk
      sta motionState
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
      lda velocityX
      bne @moving
      lda delay_by_velocity
      sta animationTimer
      rts
    @moving:
      dec animationTimer
      beq @next_frame
      rts
    @next_frame:
      ldx velocityX
      bpl @transition_state
      lda #0
      sec
      sbc velocityX
      tax
    @transition_state:
      lda delay_by_velocity, x
      sta animationTimer
      lda #1
      eor animationFrame
      sta animationFrame
      rts
    delay_by_velocity:
      .byte 12, 11, 11, 11, 11, 11, 10, 10, 10, 10, 10
      .byte 9, 9, 9, 9, 9, 8, 8, 8, 8, 8, 7, 7, 7, 7, 7
      .byte 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4
    .endproc

    .proc update_heading
      ; If the target velocity is 0 then the player isn't pressing left or right and
      ; the heading doesn't need to change.
      lda targetVelocityX
      bne @check_heading
      rts
      ; If the target velocity is non-zero, check to see if player is heading in the
      ; desired direction.
    @check_heading:
      asl
      lda #0
      rol
      cmp heading
      bne @update_heading
      rts
    @update_heading:
      ; If the desired heading is not equal to the current heading based on the
      ; target velocity, then update the heading.
      sta heading
      ; Toggle the "horizontal" mirroring on the character sprites
      lda #%01000000
      eor $200 + OAM_ATTR
      sta $200 + OAM_ATTR
      sta $204 + OAM_ATTR
      rts
    .endproc

    .proc update_idle_state
      lda motionState
      cmp #MotionState::Still
      beq @update_timer
      lda timers
      sta idleTimer
      lda #IdleState::Still
      sta idleState
      rts
    @update_timer:
      dec idleTimer
      beq @update_state
      rts
    @update_state:
      ldx idleState
      inx
      cpx #4
      bne @set_state
      ldx #0
    @set_state:
      stx idleState
      lda timers, x
      sta idleTimer
      rts
    timers:
      .byte 245, 10, 10, 10
    .endproc

    .proc update_sprite_tiles
      lda motionState
      cmp #MotionState::Pivot
      beq @pivot
      cmp #MotionState::Walk
      beq @walk
    @still:
      lda idleState
      asl
      asl
      clc
      adc heading
      tax
      lda idle_tiles, x
      sta $200 + OAM_TILE
      lda idle_tiles + 2, x
      sta $204 + OAM_TILE
      rts
    @walk:
      lda animationFrame
      asl
      asl
      clc
      adc heading
      tax
      lda walk_tiles, x
      sta $200 + OAM_TILE
      lda walk_tiles +2, x
      sta $204 + OAM_TILE
      rts
    @pivot:
      ldx heading
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
    idle_tiles:
      .byte $80, $82, $82, $80
      .byte $9C, $9E, $9E, $9C
      .byte $80, $82, $82, $80
      .byte $9C, $9E, $9E, $9C
    .endproc

    .proc update_sprite_position
      ; This is computed in `bound_position` above, so all we have to do is set the
      ; sprite coordinates appropriately.
      lda spriteX
      sta $200 + OAM_X
      clc
      adc #8
      sta $204 + OAM_X
      rts
    .endproc
  .endscope
.endscope
