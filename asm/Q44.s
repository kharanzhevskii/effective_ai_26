; Q4.4: a = 2.5 (0x28), b = 1.25 (0x14)
JMP start

a_val:
	DB 0x28
b_val:
	DB 0x14

start:
	MOV A, [a_val]
	MOV B, [b_val]
    MOV D, 232

	; 1) получить c = a + b
	; 2) получить d = a - b
	; 3) сохранить c и d в память
    MOV C, A
    ADD C, B 
    ;MOV C, A
    ;SUB C, B

.writeQ:
    MOV B, C 
    ;MOV A, C    ; исходное число
    SHR B, 4    ; целая часть
    AND C, 0x0F ; дробная часть

    CMP B, 10
    JC  .write1
    MOV [D], 49 ; если есть десяток, там единица
    INC D
    SUB B, 10
.write1:
    ADD B, 48
    MOV [D], B
    INC D
    MOV [D], 46 ; код точки
    INC D
.writetail:
    CMP C, 0
    JZ .end
    MOV A, C 
    MUL 10 
    MOV C, A
    SHR A, 4
    ADD A, 48
    MOV [D], A 
    INC D
    AND C, 0x0F ; дробная часть
    JMP .writetail

.end:
    HLT
