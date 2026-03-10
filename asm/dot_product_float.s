; float dot product
JMP start
vec_a: DB 2.0_o3, 3.0_o3, 1.5_o3
vec_b: DB 1.75_o3, 1.0_o3, 2.5_o3
len:   DB 3
acc:   DB 0.0_h

start:
    MOV A, vec_a
    MOV B, vec_b
    MOV C, [len]
    MOV D, acc

.loop:
    CMP C, 0
    JZ .end
    FMUL.o3 [B]
    FADD.o3 D, A 
    INC A 
    INC B 
    DEC C

.end:
    HLT