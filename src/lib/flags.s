;-------------------------------------------------------------------------------
; [$20] Game Flags
;-------------------------------------------------------------------------------
; Bitmask for storing major flags and inidicators for the game. Bits 0-6 are
; unused for this demo, but bit 7 is used to indicate that state updates have
; finished and that PPU VRAM updates can occur.
;-------------------------------------------------------------------------------
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
