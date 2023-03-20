ifeq ($(OS), Windows_NT)
	RM=del
else
	RM=rm
endif

SRC = src
OBJECTS = smb-movement.o
ROM = smb-movement.nes

all: $(ROM)

clean:
	$(RM) smb-movement.o
	$(RM) smb-movement.nes

$(ROM): $(OBJECTS)
	cl65 --target nes -o $(ROM) $(OBJECTS)

%.o: $(SRC)/%.s
	ca65 -o $@ -t nes $<
