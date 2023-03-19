




; -asfkfnsklfnasklfnsaklfnsaklfnsa



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

;-------------------------------------------------------------------------------
; [$21-$23] Controller State
;-------------------------------------------------------------------------------
; The state for the controller is stored across three bytes, each of which is a
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
JOYPAD_RELEASED = $23   ; Button "up" bitmask, 1 means released this frame.




;-------------------------------------------------------------------------------
; Character (Pattern) Data for the game. This is an NROM game so it uses a fixed
; CHR-ROM. To edit the graphics, open the `src/bin/CHR-ROM.bin` file in YY-CHR
; and select the "2BPP NES" option for the encoding.
;-------------------------------------------------------------------------------




;-------------------------------------------------------------------------------
; Core reset method for the game, this is called on powerup and when the system
; is reset. It is responsible for getting the system into a consistent state
; so that game logic will have the same effect every time it is run anew.
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
; The main routine for the program. This sets up and handles the execution of
; the game loop and controls memory flags that indicate to the rendering loop
; if the game logic has finished processing.
; 
; For the most part if you'r emodifying or playing with the code, you shouldn't
; have to make edits here. To change the logic for the game check out the
; `game_loop` subroutine below...
;-------------------------------------------------------------------------------


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


;-------------------------------------------------------------------------------
; Initializes the game on reset before the main loop begins to run
;-------------------------------------------------------------------------------


