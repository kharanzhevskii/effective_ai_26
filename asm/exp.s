JMP start
x:   DB 1.75_h
res: DB 0.0_h

start:
    MOV A, x
    FMOV.H FHA, [A]

    ; Round-to-Nearest (RNE)
    MOV C, 0
    FSCFG C

    ; e^-x = 1 / e^|x|
    MOV B, 0                ; Флаг знака (0=плюс, 1=минус)
    FMOV.H FHB, 0.0
    FCMP.H FHA, FHB  
    JNC .is_positive        
    MOV B, 1
    FNEG.H FHA

.is_positive:
    ; Разделение на k = целая и r = дробная
    FFTOI.H A, FHA
    FITOF.H FHB, A          
    FSUB.H FHA, FHB

    ; Аппроксимация Паде [2/2] для e^r 
 
    FMOV.H FHB, FHA
    FMUL.H FHB, FHB      ; FHB = r^2

    FMOV.H FHD, 12.0        
    FADD.H FHB, FHD      ; FHB = 12 + r^2  (Назовем это "Base")

    FMOV.H FHC, FHA
    FMOV.H FHD, 6.0
    FMUL.H FHC, FHD      ; FHC = 6 * r     (Назовем это "Term")

    FMOV.H FHD, FHB         
    FADD.H FHD, FHC      ; FHD = Base + Term (Числитель)

    FSUB.H FHB, FHC      ; FHB = Base - Term (Знаменатель)

    FDIV.H FHD, FHB      ; FHD = Числитель / Знаменатель = e^r

.exp_loop:
    CMP A, 0
    JZ .sign
    FMOV.H FHC, 2.71828     ; e
    FMUL.H FHD, FHC
    DEC A
    JMP .exp_loop
    
.sign:
    CMP B, 1
    JNE .skip_sign
    FMOV.H FHA, 1.0
    FDIV.H FHA, FHD
    JMP .end
.skip_sign:
    FMOV.H FHA, FHD

.end:
    MOV D, 232
    CALL print_f16_3
    MOV B, res
    FMOV.H [B], FHA
    HLT

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

        MOV C, 5                  ; 3 decimal digits
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