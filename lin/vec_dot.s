JMP start
vec_a: DB 3, 5, 2, 4, 1
vec_b: DB 4, 1, 6, 2, 3
len:   DB 5
addr: DB 0x50

start:
    VSET VL, 5
    VSET VA, {vec_a}, vec_a
    VSET VB, {vec_b}, vec_b
    VSET VC, 0x50  ; любой незанятый
    VMUL.U VC, VA, VB
    VWAIT
    ; происходит автомат сдвиг на длину вектора
    VSET VC, 0x50
    VSET VA, 0x50
    VADD.U VA, VC
    VWAIT
    MOV A, [0x50]
    HLT  