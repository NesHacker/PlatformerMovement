# Plarformer Movement
An SMB3 inspired movement and controls demo.

## Contributing
Find a bug? Think this could use a feature? Well then fork the repo and make a
pull request. For the most part as long as you don't change anything core to the
repository or cause the project to deviate from what I covered in the video,
then have at it.

### Building

#### Mac
1. Install [Homebrew](https://brew.sh/)
2. Install cc65 using homebrew from a terminal: `brew install cc65`
3. Run `make` from the project root to build the ROM.

#### Windows 10/11
1. Download and install [GNU Make](https://gnuwin32.sourceforge.net/packages/make.htm)
2. Download and install [cc65](https://cc65.github.io/)
3. In powershell, add the cc65 binary path: `$Env:Path += "C:\cc65\bin"`. Note:
   you can use the "Control Panel" or "System Settings" on Windows to update the
   path to include the CC65 binary directory.
4. Run `make` from the project root to build the ROM.

#### Linux
1. Download and install [cc65](https://cc65.github.io/) - How you go about this
   will be different depending on your distribution. On Ubuntu it should be as
   simple as `sudo apt-get install cc65`.
2. Run `make` from the project root to build the ROM.

### Code Style
One of the biggest points of this project is to act as a reference so that folks
can follow along with the code and learn. As such, keeping the code nice and
clean is important.

If you file a PR with assembly code changes, make sure that the code follows
these rules:

#### Code Format
1. Indent using spaces, two characters wide.
2. Do not exceed 80 characters per line.
3. Don't mix logic in files (joypad code shouldn't go in `Player.s`, for
   instance)

#### Casing
1. Instructions and registers in lowercase: `lsr a`
2. Declare subroutines with `.proc` using lower_case_piped: `.proc update_timer`
3. Tables in lower_case_piped: `delay_by_state: .byte 1, 4, 8, 7`
4. RAM Variables in lowerCamelCase: `playerLives = $400`
5. Global constants in UPPER_CASE_PIPED: `INITIAL_DELAY_FRAMES = 30`
6. Macros, Enums, and Scopes in CamelCase: `.scope GoombaController`

#### Number Formatting
1. Addresses & Fixed-Point in hex: `ldx $30`, `lda #$18`
2. Numeric constants in decimal: `START_X = 48`
3. Bitmasks in binary: `lda #%10000110`

#### Built-ins
1. Use PPU macros and constants where available: `VramColRow 2, 10, NAMETABLE_B`
2. Use Joypad Constants and macros for logic.
