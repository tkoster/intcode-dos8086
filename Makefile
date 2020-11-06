.PHONY: all clean launch_dosbox

all: day2p1.com

day2p1.com: day2p1.asm
	nasm -fbin -oday2p1.com -lday2p1.lst day2p1.asm

clean:
	rm -rf day2p1.com day2p1.lst

launch_dosbox: day2p1.com
	dosbox -conf misc/dosbox.conf day2p1.com
