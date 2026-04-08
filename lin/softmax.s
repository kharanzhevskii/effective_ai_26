JMP start

logits: DB 1.0_h, 2.0_h, 0.5_h
len:    DB 3
res:    DB 0.0_h, 0.0_h, 0.0_h

start:
    VSET VL, 3

    ; === ШАГ 1: Находим max(logits) ===
    VSET VA, {logits}, logits
    VSET VC, 0x60
    VMAX.H VC, VA           ; Редукция (2 операнда):[0x60] = max
    VWAIT

    ; Размножаем max в вектор длины 3 (0x60, 0x62, 0x64)
    FMOV.H FHA, [0x60]
    FMOV.H [0x62], FHA
    FMOV.H [0x64], FHA

    ; === ШАГ 2: Вычитаем max из логитов (x_i = logits - max) ===
    VSET VA, {logits}, logits
    VSET VB, 0x60           ; Наш сгенерированный вектор [max, max, max]
    VSET VC, 0x70           ; Сюда запишем x_i
    VSUB.H VC, VA, VB
    VWAIT

    ; === ШАГ 3: Вычисляем exp(x_i) на CPU ===
    MOV A, 0x70             ; Читаем x_i отсюда
    MOV B, 0x80             ; Пишем exp(x_i) сюда
    MOV C, [len]
.exp_loop:
    FMOV.H FHA, [A]
    CALL exp_f16            ; Вызов нашей функции из прошлой домашки
    FMOV.H [B], FHA
    ADD A, 2
    ADD B, 2
    DEC C
    JNZ .exp_loop

    ; === ШАГ 4: Сумма экспонент ===
    VSET VA, 0x80           ; Вектор экспонент
    VSET VC, 0x90
    VADD.H VC, VA           ; Редукция: [0x90] = sum(exp)
    VWAIT

    ; Размножаем sum в вектор длины 3 (0x90, 0x92, 0x94)
    FMOV.H FHA, [0x90]
    FMOV.H [0x92], FHA
    FMOV.H[0x94], FHA

    ; === ШАГ 5: Финальное деление (Softmax) ===
    VSET VA, 0x80           ; Вектор экспонент
    VSET VB, 0x90           ; Вектор сумм
    VSET VC, {res}, res     ; Финальный результат
    VDIV.H VC, VA, VB
    VWAIT
    
    HLT

; Моя экспонента
exp_f16:
    PUSH A
    PUSH B
    PUSH C
    MOV C, 0
    FSCFG C                 ; RNE rounding
    MOV B, 0                ; Флаг знака
    FMOV.H FHB, 0.0
    FCMP_RR.H FHA, FHB
    JNC .is_pos
    MOV B, 1
    FNEG.H FHA              ; x = |x|
.is_pos:
    FFTOI.H A, FHA          ; A = k
    FITOF.H FHB, A
    FSUB_RR.H FHA, FHB      ; FHA = r
    FMOV.H FHB, FHA
    FMUL_RR.H FHB, FHB      ; r^2
    FMOV.H FHD, 12.0
    FADD_RR.H FHB, FHD      ; 12 + r^2
    FMOV.H FHC, FHA
    FMOV.H FHD, 6.0
    FMUL_RR.H FHC, FHD      ; 6 * r
    FMOV.H FHD, FHB
    FADD_RR.H FHD, FHC      ; Числитель
    FSUB_RR.H FHB, FHC      ; Знаменатель
    FDIV_RR.H FHD, FHB      ; e^r
.exp_loop_inner:
    CMP A, 0
    JZ .exp_done
    FMOV.H FHC, 2.71828     ; * e, стоило 
    FMUL_RR.H FHD, FHC
    DEC A
    JMP .exp_loop_inner
.exp_done:
    CMP B, 1
    JNE .ret
    FMOV.H FHA, 1.0
    FDIV_RR.H FHA, FHD
    JMP .clean
.ret:
    FMOV.H FHA, FHD
.clean:
    POP C
    POP B
    POP A
    RET