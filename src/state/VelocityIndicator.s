;-------------------------------------------------------------------------------
; Velocity Indicator
;-------------------------------------------------------------------------------
.scope VelocityIndicator
  ZERO_X = 89   ; Range: [78]--[89]--[100]
  ZERO_Y = 200  ; Range: [189]-[200]-[211]

  .proc init
    .ifdef VIDEO_DEMO_MODE
      rts
    .endif
    ; Set up the indicator sprite and reset its position
    lda #ZERO_Y
    sta $208
    lda #$E0
    sta $208 + OAM_TILE
    lda #%00000000
    sta $208 + OAM_ATTR
    lda #ZERO_X
    sta $208 + OAM_X
    rts
  .endproc

  .proc update
    .ifdef VIDEO_DEMO_MODE
      rts
    .endif
    ; Change the position of the "Velocity Indicator" sprite based on the
    ; current X and Y velocities (via the lookup tables below).
    lda Player::velocityY
    clc
    adc #56
    tax
    lda y_pos, x
    sta $208
    lda Player::velocityX
    clc
    adc #$28
    tax
    lda x_pos, x
    sta $208 + OAM_X
    rts
    ; Doing the interpolation from min to max velocities to position the
    ; indicator sprite with lookup tables is really wasteful, but since the ROM
    ; doesn't do too much I'm not so worried about it xD
  y_pos:
    .byte 189, 189, 189, 189, 189, 189, 190, 190, 190, 190, 190, 191, 191, 191
    .byte 191, 191, 191, 192, 192, 192, 192, 192, 193, 193, 193, 193, 193, 193
    .byte 194, 194, 194, 194, 194, 195, 195, 195, 195, 195, 195, 196, 196, 196
    .byte 196, 196, 197, 197, 197, 197, 197, 197, 198, 198, 198, 198, 198, 199
    .byte 199, 199, 199, 199, 200, 200, 200, 200, 200, 200, 201, 201, 201, 201
    .byte 201, 202, 202, 202, 202, 202, 202, 203, 203, 203, 203, 203, 204, 204
    .byte 204, 204, 204, 204, 205, 205, 205, 205, 205, 206, 206, 206, 206, 206
    .byte 206, 207, 207, 207, 207, 207, 208, 208, 208, 208, 208, 208, 209, 209
    .byte 209, 209, 209, 210, 210, 210, 210, 210, 211
  x_pos:
    .byte 78, 78, 78, 78, 79, 79, 79, 79, 80, 80, 80, 81, 81, 81, 81, 82, 82, 82
    .byte 82, 83, 83, 83, 84, 84, 84, 84, 85, 85, 85, 85, 86, 86, 86, 87, 87, 87
    .byte 87, 88, 88, 88, 89, 89, 89, 89, 90, 90, 90, 90, 91, 91, 91, 92, 92, 92
    .byte 92, 93, 93, 93, 93, 94, 94, 94, 95, 95, 95, 95, 96, 96, 96, 96, 97, 97
    .byte 97, 98, 98, 98, 98, 99, 99, 99, 100
  .endproc
.endscope
