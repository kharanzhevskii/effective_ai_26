; Обратный отсчёт: 5 4 3 2 1 0
	MOV A, 232    ; console start
	MOV B, 6      ; счётчик
    MOV C, B
    ADD C, 47    ; цифру в ascii (тк нумерация с нуля)

.loop:
    MOV [A], C 
    INC A
    DEC B 
    DEC C
    CMP B, 0
    JNZ .loop

	HLT