	JMP start
vec_a:
	DB 3, 5, 2
vec_b:
	DB 4, 1, 7
len:
	DB 3
start:
	MOV B, 0      ; результат
	MOV C, [len]  ; индекс

    MOV D, vec_a
    ADD D, C      ; будем индексировать с конца
    DEC D
.loop:
    CMP C, 0
    JZ .write100
    MOV A, [D]
    ADD D, [len]
    MUL [D]
    SUB D, [len]
    ADD B, A 
    DEC C  
    DEC D 
    JMP .loop

.end:
	HLT

.write100:
    MOV D, 232
; т.к. 8-bit, макс число = 255
    MOV A, B
    DIV 10
    CMP A, 0
    JZ  .write1
    DIV 10
    CMP A, 0
    JZ  .write10 
    ADD A, 48
    MOV [D], A
    INC D
    SUB A, 48
    MUL 100
    SUB B, A

.write10:
    MOV A, B
    DIV 10
    ADD A, 48
    MOV [D], A
    INC D
    SUB A, 48
    MUL 10
    SUB B, A 

.write1:
    ADD B, 48
    MOV [D], B
    JMP .end