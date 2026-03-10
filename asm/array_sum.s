	JMP start
data:
	;DB 10, 20, 30, 15, 25
    ;DB 12, 20, 39, 15, 26
    ;DB 2, 0, 5, 0, 4
    DB 0, 0, 5, 0, 4
len:
	DB 5
    
start:
	MOV A, 0      ; сумма
	MOV B, data   ; указатель
	MOV C, [len]  ; счётчик
    MOV D, 232    ; консоль

.loop:
    ADD A, [B]
    INC B
    DEC C 
    CMP C, 0
    JNZ .loop

    CMP A, 0
    JNZ .write100

    ADD A, 48
    MOV [D], A 

.end:
	HLT

.write100:
; т.к. 8-bit, макс число = 255
    MOV B, A
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

