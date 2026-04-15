start:
    ; =========================================================
    ; ШАГ 1: Конвертация 784 пикселей (uint8 -> fp16)
    ; =========================================================
    PUSH 200        ; [SP+4] dp_in
    PUSH 0          ; [SP+3] off_in
    PUSH 204        ;[SP+2] dp_out
    PUSH 0          ; [SP+1] off_out

    MOV C, 4              
    MOV B, 16             
.px_loop:
    MOV DP,[SP+4]
    MOV A, [SP+3]
    MOV D, [A]           ; Читаем пиксель
    INC A
    MOV [SP+3], A
    JNZ .in_no_wrap      
    MOV A, [SP+4]
    INC A
    MOV [SP+4], A
.in_no_wrap:

    CMP D, 0
    JZ .is_zero
    FMOV.H FHA, 1.0_h    ; Белый
    JMP .write_px
.is_zero:
    FMOV.H FHA, -1.0_h   ; Черный
.write_px:

    MOV DP, [SP+2]
    MOV A,[SP+1]
    FMOV.H [A], FHA      ; Пишем FP16
    ADD A, 2
    MOV [SP+1], A
    JNZ .out_no_wrap     
    MOV A, [SP+2]
    INC A
    MOV [SP+2], A
.out_no_wrap:

    DEC B
    JNZ .px_loop         
    DEC C
    JNZ .px_loop         

    ; Убираем переменные из стека
    POP A
    POP A
    POP A
    POP A

    ; =========================================================
    ; ШАГ 2: СЛОЙ 1 (hidden = ReLU(W1 * X + b1))
    ; =========================================================
    MOV DP, 0             ; На всякий случай возвращаем DP=0 для VU
    VSET VL, 784
    VSET VA, 0x0100       ; W1
    VSET VC, 0xD300       ; hidden_1
    MOV C, 32
.l1_dot:
    VSET VB, 0xCC00       ; X
    VDOT.H VC, VA, VB
    DEC C
    JNZ .l1_dot

    VSET VL, 32
    VSET VA, 0xD300       ; hidden_1
    VSET VB, 0xC500       ; b1
    VADD.H VA, VA, VB
    VWAIT                 ; Синхронизация перед ReLU

    VSET VA, 0xD300
    VMAX.H VA, VA, 0.0_h  ; ReLU
    VWAIT

    ; =========================================================
    ; ШАГ 3: СЛОЙ 2 (logits = W2 * hidden + b2)
    ; =========================================================
    ; VL остался равен 32
    VSET VA, 0xC540       ; W2
    VSET VC, 0xD400       ; logits
    MOV C, 10
.l2_dot:
    VSET VB, 0xD300       ; hidden_1
    VDOT.H VC, VA, VB
    DEC C
    JNZ .l2_dot

    VSET VL, 10
    VSET VA, 0xD400       ; logits
    VSET VB, 0xC7C0       ; b2
    VADD.H VA, VA, VB
    VWAIT                 ; Ждем окончания последних вычислений

    ; ГОТОВО! 10 логитов (формат FP16) лежат по адресу 0xD400 (Стр 212, смещ 0)
    HLT

; ====================================================================
; КАРТА ПАМЯТИ
; ====================================================================
@page 1
@include "mnist_weights.bin"

@page 200
input_x: