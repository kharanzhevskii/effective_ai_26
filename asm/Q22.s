; Q2.2: a = 1.5 (0x06), b = 2.0 (0x08)
JMP start

a_val:
	DB 0x06
b_val:
	DB 0x08
res:
	DB 0x00

start:
	MOV A, [a_val]
	MOV B, [b_val]
    MOV D, 232

	; 1) вычислить a * b в Q2.2
	; 2) учесть масштаб (сдвиг вправо на 2)
	; 3) сохранить результат в [res]

    MUL B 
    SHR A, 2 
    AND A, 0x0F 
    MOV C, A

.writeQ:
    MOV B, C 
    SHR B, 2    ; целая часть
    AND C, 0x03 ; дробная часть

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
    SHR A, 2
    ADD A, 48
    MOV [D], A 
    INC D
    AND C, 0x03 ; дробная часть
    JMP .writetail

.end:
    HLT