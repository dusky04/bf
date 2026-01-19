.PHONY: all

all: bf

bf: bf.odin
	odin build bf.odin -file

clean:
	rm -f bf
