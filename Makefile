SRC = src
OBJECTS = smb-movement.o
ROM = smb-movement.nes

all: $(ROM)

clean:
	del smb-movement.o
	del smb-movement.nes

$(ROM): $(OBJECTS)
	cl65 --target nes -o $(ROM) $(OBJECTS)

%.o: $(SRC)/%.s
	ca65 -o $@ -t nes $< 
