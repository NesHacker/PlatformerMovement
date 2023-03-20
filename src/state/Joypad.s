;-------------------------------------------------------------------------------
; [$21-$22] Controller State
;-------------------------------------------------------------------------------
; The state for the controller is stored across two bytes, each of which is a
; bitmask where each bit corresponds to a single button on the controller. This
; demo only uses the first controller (JOYPAD_1).
;
; The bits in each mask are mapped as such:
;
; [AB-+^.<>]
;  ||||||||
;  |||||||+--------> Bit 0: D-PAD Right
;  ||||||+---------> Bit 1: D-PAD Left
;  |||||+----------> Bit 2: D-PAD Down
;  ||||+-----------> Bit 3: D-PAD Up
;  |||+------------> Bit 4: Start
;  ||+-------------> Bit 5: Select
;  |+--------------> Bit 6: B
;  +---------------> Bit 7: A
;
;-------------------------------------------------------------------------------

JOYPAD_DOWN     = $21   ; Button "down" bitmaks, 1 means down & 0 means up.
JOYPAD_PRESSED  = $22   ; Button "pressed" bitmask, 1 means pressed this frame.

; Controller port addresses
JOYPAD1 = $4016
JOYPAD2 = $4017

; Button mask bits
BUTTON_A      = 1 << 7
BUTTON_B      = 1 << 6
BUTTON_SELECT = 1 << 5
BUTTON_START  = 1 << 4
BUTTON_UP     = 1 << 3
BUTTON_DOWN   = 1 << 2
BUTTON_LEFT   = 1 << 1
BUTTON_RIGHT  = 1 << 0

; Joypad State controller
.scope Joypad
  .proc update
    lda JOYPAD_DOWN
    tay
    lda #1
    sta JOYPAD1
    sta JOYPAD_DOWN
    lsr
    sta JOYPAD1
  @loop:
    lda JOYPAD1
    lsr
    rol JOYPAD_DOWN
    bcc @loop
    tya
    eor JOYPAD_DOWN
    and JOYPAD_DOWN
    sta JOYPAD_PRESSED
    rts
  .endproc
.endscope
