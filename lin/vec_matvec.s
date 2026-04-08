JMP start

m:   DB 2
n:   DB 3
mat: DB 1.0_o3, 2.0_o3, 0.5_o3
     DB 1.5_o3, 1.0_o3, 2.0_o3
vec: DB 2.0_o3, 1.0_o3, 1.5_o3
res: DB 0.0_h, 0.0_h

start:
    MOV C, [m]
    VSET VL, 3
    VSET VA, {mat}, mat
    MOV D, res

.row:
    VSET VB, {vec}, vec
    VSET VC, 0x60
    
    VDOT.O3 VC, VA, VB
    VWAIT
    FMOV.O3 FQA, [0x60]
    FCVT.H.O3 FHA, FQA
    FMOV.H [D], FHA
    
    ADD D, 2                ; float16 = 2 байта
    ; VA автоматически сдвинулся на 3 байта вперед
    
    DEC C
    JNZ .row
    
    HLT