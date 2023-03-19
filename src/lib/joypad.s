; Common NES Joypad Macros

; Controller port addresses
JOYPAD1 = $4016
JOYPAD2 = $4017

; Joypad Button Masks
JOYPAD1_BITMASK = $50
JOYPAD1_BITMASK_LAST = $51
JOYPAD2_BITMASK = $52
JOYPAD2_BITMASK_LAST = $53

; Button mask bits
BUTTON_A      = 1 << 7
BUTTON_B      = 1 << 6
BUTTON_SELECT = 1 << 5
BUTTON_START  = 1 << 4
BUTTON_UP     = 1 << 3
BUTTON_DOWN   = 1 << 2
BUTTON_LEFT   = 1 << 1
BUTTON_RIGHT  = 1 << 0

.macro ReadJoypad1
  ; Copy previous frame's button mask
  lda JOYPAD1_BITMASK
  sta JOYPAD1_BITMASK_LAST
  ; Strobe / Initialize Bitmask
  lda #1
  sta JOYPAD1
  sta JOYPAD1_BITMASK
  lsr a
  sta JOYPAD1
  ; Loop to load all buttons
: lda JOYPAD1
  lsr a
  rol JOYPAD1_BITMASK
  bcc :-
.endmacro

.macro ReadJoypad2
  lda JOYPAD2_BITMASK
  sta JOYPAD1_BITMASK_LAST
  lda #1
  sta JOYPAD1
  sta JOYPAD2_BITMASK
  lsr a
  sta JOYPAD1
: lda JOYPAD2
  lsr a
  rol JOYPAD2_BITMASK
  bcc :-
.endmacro

.macro ReadJoypads
  lda JOYPAD1_BITMASK
  sta JOYPAD1_BITMASK_LAST
  lda JOYPAD2_BITMASK
  sta JOYPAD2_BITMASK_LAST
  lda #1
  sta JOYPAD1
  sta JOYPAD2_BITMASK
  lsr a
  sta JOYPAD1
: lda JOYPAD1
  and #%00000011
  cmp #1
  rol JOYPAD1_BITMASK
  lda JOYPAD2
  and #%00000011
  cmp #1
  rol JOYPAD2_BITMASK
  bcc :-
.endmacro
