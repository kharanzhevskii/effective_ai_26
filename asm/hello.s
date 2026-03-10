	JMP start
hello:
	DB "Hello World!"
	DB 0

start:
	MOV C, hello  ; string ptr
	MOV D, 232    ; console ptr
	CALL print
	HLT

print:              ; print(C, D)
	PUSH A
	PUSH B
	MOV B, 0
.loop:
	MOV A, [C]
	MOV [D], A
	INC C
	INC D
	CMP B, [C]
	JNZ .loop
	POP B
	POP A
	RET