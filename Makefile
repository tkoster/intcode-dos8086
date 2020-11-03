.PHONY: all clean launch_dosbox

all: day2p1.exe

day2p1.exe: day2p1.asm
	nasm -fbin -oday2p1.exe -lday2p1.lst -imisc day2p1.asm

clean:
	rm -rf day2p1.exe day2p1.lst

launch_dosbox: day2p1.exe
	dosbox -conf misc/dosbox.conf day2p1.exe
