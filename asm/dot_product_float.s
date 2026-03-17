JMP start
vec_a: DB 2.0_o3, 3.0_o3, 1.5_o3
vec_b: DB 0.75_o3, 1.0_o3, 2.5_o3
acc:   DB 0.0_h

start:
    MOV A, vec_a
    MOV B, vec_b 
    MOV C, 3
    MOV D, acc
    FMOV.H FHD, [acc]
    CALL dotprod
    ; in preparation for print_f16_3
    FMOV.H FHA, FHD
    MOV D, 232
    CALL print_f16_3
    HLT
        
dotprod: ; res = FHD
.loop:
    FMOV.O3 FQA, [A]
    FMOV.O3 FQC, [B]
    FCVT.H.O3 FHA, FQA
    FCVT.H.O3 FHB, FQC
    FMUL.H FHA, FHB
    FADD.H FHD, FHA
    DEC C
    INC A
    INC B
    CMP C, 0
    JNE .loop
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
    
    

