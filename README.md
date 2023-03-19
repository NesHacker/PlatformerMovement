# Super Mario Bros. Movement
A movement and controls demo inspried by Super Mario Bros. 3


## Building the Project

### Mac
1. Install [Homebrew](https://brew.sh/)
2. Install cc65 using homebrew from a terminal: `brew install cc65`
3. Run `make` from the project root to build the ROM.

### Windows 10/11
1. Download and install [GNU Make](https://gnuwin32.sourceforge.net/packages/make.htm)
2. Download and install [cc65](https://cc65.github.io/)
3. In powershell, add the cc65 binary path: `$Env:Path += "C:\cc65\bin"`. Note:
   you can use the "Control Panel" or "System Settings" on Windows to update the
   path to include the CC65 binary directory.
4. Run `make` from the project root to build the ROM.

### Linux
1. Download and install [cc65](https://cc65.github.io/) - How you go about this
   will be different depending on your distribution. On Ubuntu it should be as
   simple as `sudo apt-get install cc65`.
2. Run `make` from the project root to build the ROM.
