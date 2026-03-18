; Linear neuron: y = w*x+acc in fp16
JMP start
w:  DB 2.0_H, 2.8_H, 1.5_H
x:  DB 0.75_H, 1.0_H, 0.45_H
acc:    DB 0.9_H
; правильный ответ = 5.875
len:    DB 3

start:
    ; загрузка указателей и длины
    MOV A, w
    MOV B, x 
    MOV C, [len]
    MOV D, acc
    ; где лежит ответ (fp16)
    FMOV.H FHA, [acc]
    CALL dotprod
    ; preparation for print_f16_3
    MOV D, 232
    CALL print_f16_3
    HLT
        
dotprod: 
; output = FHA; changes A,B,C, FHA,FHC,FHD
.loop:
    FMOV.H FHC, [A]
    FMOV.H FHD, [B]
    FMUL.H FHC, FHD
    FADD.H FHA, FHC
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

; Print FHA as decimal with 3 fractional digits
; Modifies: FHA, FHB, A, C
print_f16_3:
        MOV A, 1                 ; Truncate mode
        FSCFG A

        FMOV.H FHB, 0.0
        FCMP.H FHA, FHB
        JNC .non_negative
        MOV A, '-'                ; Print sign
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

        ; как правило уже в третьем знаке будет ошибка
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
    
    

