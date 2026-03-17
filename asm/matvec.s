JMP start

m:   DB 2
n:   DB 3
mat: DB 1.0_o3, 2.0_o3, 0.5_o3
     DB 1.5_o3, 1.0_o3, 2.0_o3
vec: DB 2.0_o3, 1.0_o3, 1.5_o3
res: DB 0.0_h, 0.0_h
cursor: DB 232            ; <-- Глобальный курсор консоли

start:
    MOV A, mat
    MOV C, [m]            ; Исправление 1: берем ЗНАЧЕНИЕ m
    MOV D, res
    CALL matvec
    HLT

matvec:
.row:
    MOV B, vec            ; Исправление 2: Возвращаем вектор в начало
    FMOV.H FHD, 0.0       ; Исправление 3: Обнуляем сумму для новой строки

    CALL dotprod
    FMOV.H [D], FHD
    
    ; --- Вывод на экран ---
    FMOV.H FHA, FHD
    PUSH A                ; Исправление 5: Спасаем указатель на матрицу!
    PUSH C                ; Спасаем счетчик строк
    
    CALL print_f16_3
    MOV A, ' '            ; Печатаем пробел, чтобы числа не слиплись
    CALL put_char
    
    POP C
    POP A                 ; Возвращаем указатель на матрицу
    ; ----------------------

    ADD D, 2              ; Исправление 4: float16 занимает 2 байта!
    DEC C
    JNZ .row              ; CMP C, 0 не нужен, DEC сам обновляет флаги
    RET

dotprod: ; res = FHD
    PUSH C 
    MOV C, [n]            ; Исправление 1: значение n
.col:
    FMOV.O3 FQA, [A]
    FMOV.O3 FQC, [B]
    FCVT.H.O3 FHA, FQA
    FCVT.H.O3 FHB, FQC
    FMUL.H FHA, FHB
    FADD.H FHD, FHA
    INC A
    INC B
    DEC C
    JNZ .col              ; CMP C, 0 не нужен
    POP C
    RET
    
put_char:
    PUSH B                ; Спасаем B
    MOV B, [cursor]       ; Берем текущую позицию на экране
    MOV [B], A            ; Печатаем символ
    INC B                 ; Сдвигаем курсор
    MOV [cursor], B       ; Сохраняем новую позицию
    POP B
    RET

; Print FHA as decimal with 3 fractional digits
print_f16_3:
    MOV A, 1                 ; Truncate mode (RTZ)
    FSCFG A

    FMOV.H FHB, 0.0
    FCMP.H FHA, FHB
    JNC .non_negative
    MOV A, '-'
    CALL put_char
    FNEG.H FHA

.non_negative:
    FFTOI.H A, FHA            ; Integer part
    FITOF.H FHB, A
    FSUB.H FHA, FHB           ; FHA = fractional part
    ADD A, '0'
    CALL put_char

    MOV A, '.'
    CALL put_char

    MOV C, 3                  ; 3 decimal digits
.frac_loop:
    FMOV.H FHB, 10.0
    FMUL.H FHA, FHB           ; Shift left one digit
    FFTOI.H A, FHA
    FITOF.H FHB, A
    FSUB.H FHA, FHB           ; Remove integer part
    ADD A, '0'
    CALL put_char
    DEC C
    JNZ .frac_loop
    RET