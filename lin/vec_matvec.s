JMP start

m:   DB 2
n:   DB 3
mat: DB 1.0_o3, 2.0_o3, 0.5_o3
     DB 1.5_o3, 1.0_o3, 2.0_o3
vec: DB 2.0_o3, 1.0_o3, 1.5_o3
res: DB 0.0_h, 0.0_h

start:
    MOV A, mat
    MOV C, [m]            
    MOV D, res
    CALL matvec
    HLT

matvec:
.row:
    MOV B, vec            
    FMOV.H FHD, 0.0       

    CALL dotprod
    FMOV.H [D], FHD
    
    FMOV.H FHA, FHD

    ADD D, 2              
    DEC C
    JNZ .row              
    RET

dotprod:
    VSET VL, 3
    VSET VA, {mat}, mat
    VSET VB, {vec}, vec
    VSET VC, 0x50  ; любой незанятый
    VDOT.F VC, VA, VB
    VSET VC, 0x50  ; любой незанятый
    VWAIT
    FMOV.H FHD, [0x50]
    RET