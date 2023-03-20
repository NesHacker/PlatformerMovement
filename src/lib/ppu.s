; NES Picture Processing Unit (PPU) Constants and Macros
; See: https://www.nesdev.org/wiki/PPU_registers

; PPU Registers

; Controller ($2000) > write
;
; 7654 3210
; |||| ||||
; |||| ||++- Base nametable address
; |||| ||    (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
; |||| |+--- VRAM address increment per CPU read/write of PPUDATA
; |||| |     (0: add 1, going across; 1: add 32, going down)
; |||| +---- Sprite pattern table address for 8x8 sprites
; ||||       (0: $0000; 1: $1000; ignored in 8x16 mode)
; |||+------ Background pattern table address (0: $0000; 1: $1000)
; ||+------- Sprite size (0: 8x8; 1: 8x16)
; |+-------- PPU master/slave select
; |          (0: read backdrop from EXT pins; 1: output color on EXT pins)
; +--------- Generate an NMI at the start of the
;            vertical blanking interval (0: off; 1: on)
;
; Equivalently, bits 0 and 1 are the most significant bit of the scrolling
; coordinates (see Nametables and PPU scroll):
;
; 7654 3210
;        ||
;        |+- 1: Add 256 to the X scroll position
;        +-- 1: Add 240 to the Y scroll position
PPU_CTRL = $2000

; Mask ($2001) > write
;
; 76543210
; ||||||||
; |||||||+- Grayscale (0: normal color; 1: produce a monochrome display)
; ||||||+-- 1: Show background in leftmost 8 pixels of screen; 0: Hide
; |||||+--- 1: Show sprites in leftmost 8 pixels of screen; 0: Hide
; ||||+---- 1: Show background
; |||+----- 1: Show sprites
; ||+------ Intensify reds (and darken other colors)
; |+------- Intensify greens (and darken other colors)
; +-------- Intensify blues (and darken other colors)
PPU_MASK = $2001


; Status ($2002) < read
;
; 7654 3210
; |||| ||||
; |||+-++++- Least significant bits previously written into a PPU register
; |||        (due to register not being updated for this address)
; ||+------- Sprite overflow. The intent was for this flag to be set
; ||         whenever more than eight sprites appear on a scanline, but a
; ||         hardware bug causes the actual behavior to be more complicated
; ||         and generate false positives as well as false negatives; see
; ||         PPU sprite evaluation. This flag is set during sprite
; ||         evaluation and cleared at dot 1 (the second dot) of the
; ||         pre-render line.
; |+-------- Sprite 0 Hit.  Set when a nonzero pixel of sprite 0 overlaps
; |          a nonzero background pixel; cleared at dot 1 of the pre-render
; |          line.  Used for raster timing.
; +--------- Vertical blank has started (0: not in VBLANK; 1: in VBLANK).
;            Set at dot 1 of line 241 (the line *after* the post-render
;            line); cleared after reading $2002 and at dot 1 of the
;            pre-render line.
PPU_STATUS = $2002

; OAM address ($2003) > write / OAM data ($2004) > write
; Set the "sprite" address using OAMADDR ($2003)
; Then write the following bytes via OAMDATA ($2004)
OAM_ADDR  = $2003
OAM_DATA	= $2004
OAM_DMA   = $4014

; - Byte 0 (Y Position)
OAM_Y    = 0

; - Byte 1 (Tile Index)
;
; 76543210
; ||||||||
; |||||||+- Bank ($0000 or $1000) of tiles
; +++++++-- Tile number of top of sprite (0 to 254; bottom half gets the next tile)
OAM_TILE = 1

; - Byte 2 (Attributes)
;
; 76543210
; ||||||||
; ||||||++- Palette (4 to 7) of sprite
; |||+++--- Unimplemented
; ||+------ Priority (0: in front of background; 1: behind background)
; |+------- Flip sprite horizontally
; +-------- Flip sprite vertically
OAM_ATTR = 2

; - Byte 3 (X Position)
OAM_X    = 3

; Scroll ($2005) >> write x2
; http://wiki.nesdev.com/w/index.php/The_skinny_on_NES_scrolling#2006-2005-2005-2006_example
PPU_SCROLL	= $2005

; Address ($2006) >> write x2
PPU_ADDR		= $2006

; Data ($2007) <> read/write
PPU_DATA		= $2007

; VRAM Addresses
NAMETABLE_A = $2000
NAMETABLE_B = $2400
NAMETABLE_C = $2800
NAMETABLE_D = $2c00
ATTR_A      = $23c0
ATTR_B      = $27c0
ATTR_C      = $2bc0
ATTR_D      = $2fc0
PALETTE     = $3f00

.macro EnableRendering
  lda #%00011110
  sta PPU_MASK
.endmacro

.macro DisableRendering
  lda #0
  sta PPU_MASK
.endmacro

.macro EnableNMI
  lda #%10000000
  sta PPU_CTRL
.endmacro

.macro DisableNMI
  lda #0
  sta PPU_CTRL
.endmacro

.macro Vram address
  bit PPU_STATUS
  lda #.HIBYTE(address)
  sta PPU_ADDR
  lda #.LOBYTE(address)
  sta PPU_ADDR
.endmacro

.macro VramColRow col, row, nametable
  Vram (nametable + row*$20 + col)
.endmacro

.macro VramReset
  bit PPU_STATUS
  lda #0
  sta PPU_ADDR
  sta PPU_ADDR
.endmacro

.macro VramPalette
  lda #$3f
  sta $2006
  lda #$00
  sta $2006
.endmacro

.macro OAMReset
  lda #0
  sta OAM_ADDR
.endmacro

.macro LoadPalettes address
  Vram PALETTE
  ldx #0
: lda address, x
  sta PPU_DATA
  inx
  cpx #$20
  bne :-
.endmacro

.macro Sprite0ClearWait
: bit PPU_STATUS
	bvs :-
.endmacro

.macro Sprite0HitWait
: bit PPU_STATUS
	bvc :-
.endmacro

.macro VblankWait
: bit PPU_STATUS
  bpl :-
.endmacro

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
