; Linear neuron Mixed precision: y = w*x+acc : x,w fp16; y,acc in fp32
JMP start
w:  DB 2.0_H, 2.8_H, 1.5_H
x:  DB 0.75_H, 1.0_H, 0.45_H
wx:    DB 0.0_F
acc:    DB 0.9_F
; правильный ответ = 5.875
len:    DB 3

start:
    ; загрузка указателей и длины
    MOV A, w
    MOV B, x 
    MOV C, [len]
    MOV D, acc
    ; так как у нас всего два регистра fp32, их используем для умножения, результат пишем по выделенному адресу acc
    ; без ограничения в 2 регистра можно повторить код в linear_neuron.s
    ; тогда надо было бы просто добавить конвертацию FCVT.F.H FA, FHA
    CALL dotprod
    ; preparation for print_f16_3
    MOV D, 232
    CALL print_f32_3
    HLT
        
dotprod: 
; output = FHA; changes A,B,C, FHA,FHC,FHD
.loop:
    FMOV.H FHC, [A]
    FMOV.H FHD, [B]
    FCVT.F.H FA, FHC
    FCVT.F.H FB, FHD
    FMUL.F FA, FB
    ; прибавляем к накопленному результату, и кладем обратно
    FADD.F FA, [D]
    FMOV.F [D], FA
    ; fp16 занимает 2 байта
    ADD A, 2
    ADD B, 2
    DEC C
    JNZ .loop
    RET
    
put_char:                        ; put_char(A:char, D:*to)
        MOV [D], A               ; Write char to output
        INC D
        RET

; Print FA as decimal with 3 fractional digits
; Вход: FA (float32)
; Изменяет: FA, FB, FHC, A, C
print_f32_3:
        MOV A, 1                 ; Truncate mode (RTZ)
        FSCFG A

        FMOV.H FHC, 0.0
        FCVT.F.H FB, FHC

        FCMP.F FA, FB
        JNC .non_negative
        MOV A, '-'               ; Print sign
        CALL put_char
        FNEG.F FA                ; Делаем число положительным

.non_negative:
        FFTOI.F A, FA
        FITOF.F FB, A
        FSUB.F FA, FB
        
        ADD A, '0'
        CALL put_char

        MOV A, '.'
        CALL put_char

        MOV C, 4                 
.frac_loop:

        FMOV.H FHC, 10.0         ; FHC = 10.0 (16-bit)
        FCVT.F.H FB, FHC         ; FB = 10.0 (32-bit)

        FMUL.F FA, FB         ; Shift left one digit (FA = FA * 10)
        FFTOI.F A, FA            ; Извлекаем целую цифру
        FITOF.F FB, A
        FSUB.F FA, FB         ; Remove integer part
        
        ADD A, '0'
        CALL put_char
        
        DEC C
        JNZ .frac_loop
        RET