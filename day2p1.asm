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

	; SI contains the address of the current Intcode instruction.
	; Initialize SI to the address of the Intcode program.

	mov si,intcode_program

interpret_loop:
	; Load next opcode into AX.
	; Decode it and jump to its code.

	mov ax,[si]
	cmp ax,1
	je interpret_add
	cmp ax,2
	je interpret_mul
	cmp ax,99
	je interpret_hlt

	; Invalid Intcode instruction.
	; Print an error message.

	mov dx,error_invalid_instruction
	call prints

interpret_end:
	; Print some newlines and return.

	mov dx,crlf
	times 3 call prints
	ret

interpret_add:
	; Print the opcode name "add".

	mov dx,op_add
	call prints

	; Dereference the first operand and store the value in interpreter
	; register X.

	mov bx,[si+4]
	mov di,reg_x
	call deref

	; Dereference the second operand and store the value in interpreter
	; register Y.

	mov bx,[si+8]
	mov di,reg_y
	call deref

	; Add the interpreter X and Y registers.
	; Store the result in the Y register.

	clc
	mov ax,[reg_x]
	adc ax,[reg_y]
	mov [reg_y],ax
	mov ax,[reg_x+2]
	adc ax,[reg_y+2]
	mov [reg_y+2],ax

	; Set BX to the offset (in bytes) for the destination referenced by the
	; Intcode address in the third operand.

	mov bx,[si+12]
	shl bx,2

	; Copy the value of the interpreter Y register to the Intcode program
	; memory.

	mov ax,[reg_y]
	mov [intcode_program+bx],ax
	mov ax,[reg_y+2]
	mov [intcode_program+bx+2],ax

	; Advance the Intcode program counter by 4 (16 bytes) and process the
	; next instruction.

	add si,16
	jmp interpret_loop

interpret_mul:
	; Print the opcode name "mul".

	mov dx,op_mul
	call prints

	; Dereference the first operand and store the value in interpreter
	; register X.

	mov bx,[si+4]
	mov di,reg_x
	call deref

	; Dereference the second operand and store the value in interpreter
	; register Y.

	mov bx,[si+8]
	mov di,reg_y
	call deref

	; Multiply the interpreter X and Y registers.

	mov ax,[reg_x]    ; multiplicand low
	mov dx,[reg_x+2]  ; multiplicand high
	mov bx,[reg_y]    ; multiplier low
	mov cx,[reg_y+2]  ; multiplier high
	xchg bx,ax
	push ax
	xchg dx,ax
	or ax,ax
	jz .la
	mul dx
.la:	xchg cx,ax
	or ax,ax
	jz .lb
	mul bx
	add cx,ax
.lb:	pop ax
	mul bx
	add dx,cx

	; Store product in the Z register.

	mov [reg_z],ax
	mov [reg_z+2],dx

	; Set BX to the offset (in bytes) for the destination referenced by the
	; Intcode address in the third operand.

	mov bx,[si+12]
	shl bx,2

	; Copy the value of the interpreter Z register to the Intcode program
	; memory.

	mov ax,[reg_z]
	mov [intcode_program+bx],ax
	mov ax,[reg_z+2]
	mov [intcode_program+bx+2],ax

	; Advance the Intcode program counter by 4 (16 bytes) and process the
	; next instruction.

	add si,16
	jmp interpret_loop

interpret_hlt:
	; Print the opcode name "hlt".

	mov dx,op_hlt
	call prints

	; Print the first two cells of Intcode memory as output.

	call print_intcode_memory

	; Exit the interpreter.

	jmp interpret_end

deref:
	; Dereference an Intcode address.
	;
	; This subroutine interprets the value in BX as an Intcode address. The
	; 32-bit value at that location in Intcode memory is copied to the
	; memory location addresses by DI.
	;
	; An Intcode address is an offset into the Intcode program memory (in
	; cells, not bytes or words).
	;
	; Arguments:
	;   BX - the Intcode address of the value to store
	;   DI - the address to store the value

	shl bx,2
	mov ax,[intcode_program+bx] ; low word
	mov [di],ax
	mov ax,[intcode_program+bx+2] ; high word
	mov [di+2],ax
	ret

print_intcode_memory:
	; Print the first two values of the Intcode program memory.
	;
	; For debugging and day 2 output.

	push dx

	mov dx,intcode_program
	call printi32
	mov dx,space
	call prints
	mov dx,intcode_program+4
	call printi32
	mov dx,crlf
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

; Strings:

header: db 'Intcode Interpreter - By Thomas Koster',13,10,'$'
crlf:	db 13,10,'$'
space:	db ' $'
op_add:	db 'add',13,10,'$'
op_mul:	db 'mul',13,10,'$'
op_hlt:	db 'hlt',13,10,'$'
error_invalid_instruction:
	db 'Error: invalid instruction$'

; Intcode program memory:

intcode_program:
	; Gravity assist program, expected output: 007a54b4 (8017076 decimal)

	dd 1,12,2,3,1,1,2,3,1,3,4,3,1,5,0,3,2,10,1,19,1,6,19,23,2,23,6,27,1,5,27,31,1,31,9,35,2,10,35,39,1,5,39,43,2,43,10,47,1,47,6,51,2,51,6,55,2,55,13,59,2,6,59,63,1,63,5,67,1,6,67,71,2,71,9,75,1,6,75,79,2,13,79,83,1,9,83,87,1,87,13,91,2,91,10,95,1,6,95,99,1,99,13,103,1,13,103,107,2,107,10,111,1,9,111,115,1,115,10,119,1,5,119,123,1,6,123,127,1,10,127,131,1,2,131,135,1,135,10,0,99,2,14,0,0

	; This padding is necessary to produce a valid EXE. Without it, the
	; program is truncated when DOS loads it into memory. I suspect a bug in
	; the macro used to produce the EXE file header.

	times 20 db 1

section .bss

; Interpreter registers:
; These are used internally by the interpreter to execute Intcode instructions.

reg_start:
reg_x:
	resd 1
reg_y:
	resd 1
reg_z:
	resd 1
reg_end:

EXE_end
