; vim: tabstop=8 softtabstop=0 shiftwidth=8 textwidth=80 noexpandtab syntax=nasm

	CPU 286

%include "exebin.mac"

EXE_begin
EXE_stack 64

section .text

main:
	; Print the program header.

	mov dx, header
	call prints

	; Run the interpreter.

	call interpret

	; Exit.

	mov ax,0x4c00 ; syscall exit(0)
	int 0x21

interpret:
	; Reset the interpreter registers to zero.

	mov cx,(reg_end-reg_start)
.l0:	mov bx,cx
	mov byte [reg_start+bx-1],0x00
	loop .l0

	; DEBUG: set some registers

	mov word [reg_op+2],0x3322
	mov word [reg_op],0x1100
	mov word [reg_a+2],0xddcc
	mov word [reg_a],0xbbaa

	; DEBUG: Print the values of the Intcode interpreter registers.

	call print_intocode_registers

interpret_loop:
	; TODO: Decode and execute Incode instruction.

interpret_end:
	; Print some newlines and return.

	mov dx,crlf
	times 3 call prints
	ret

print_intocode_registers:
	; Print the values of the Intcode interpreter registers.
	;
	; For debugging.

	push dx

	mov dx,reg_op
	call printi32
	mov dx,space
	call prints

	mov dx,reg_a
	call printi32
	mov dx,space
	call prints

	pop dx
	ret

prints:
	; Print a string using INT 21,9.
	;
	; The string should be terminated with a '$'.
	;
	; Arguments:
	;   DX - address of the string

	push ax

	mov ah,0x9
	int 0x21

	pop ax
	ret

printi32:
	; Print a 32-bit LE integer in memory as hexadecimal using INT 21,2.
	;
	; Arguments:
	;   DX - the address of the number

	pusha

	mov bx,dx
	mov si,2 ; two words, starting with the high word
.word:
	mov ax,[bx+si] ; read word into AX
	mov cx,4 ; four bytes
.nibble:
	rol ax,4 ; rotate in the next nibble to print
	mov dl,al
	and dl,0x0f
	add dl,'0' ; convert to ASCII
	cmp dl,'9'
	jbe .output
	add dl,('a'-'9'-1) ; 'a' does not succeed '9' in ASCII
.output:
	push ax
	mov ah,2 ; syscall putchr
	int 0x21
	pop ax
	loop .nibble ; repeat for next nibble
	sub si,2 ; repeat for the low word
	jnb .word

	popa
	ret

section .data

; Strings

header:
	db 'Intcode Interpreter - By Thomas Koster',13,10,'$'
crlf:
	db 13,10,'$'
space:
	db ' ','$'

; Intcode program

intcode_program:
	dd 1,0,0,0,99

section .bss

; Interpreter registers

reg_start:
reg_op:
	resd 1
reg_a:
	resd 1
reg_end:

EXE_end
