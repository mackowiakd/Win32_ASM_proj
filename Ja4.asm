; ================================================
; Definicja makra
; ================================================

MatrixMulRow MACRO matrixA_offset, result_offset
    LOCAL lbl
    movaps xmm0, [matrixA + matrixA_offset]   
    vinsertf128 ymm0, ymm0, xmm0, 1           
    vmovaps ymm1, ymm0                        
    vmulps ymm0, ymm0, ymm6                   
    vmulps ymm1, ymm1, ymm7                   
    vhaddps ymm2, ymm0, ymm1                  
    vhaddps ymm2 ,ymm2, ymm2                  
    vextractf128 xmm3, ymm2, 1                
    unpcklps xmm2, xmm3                       
    vmovups [resultMatrix + result_offset], xmm2 
ENDM

; ================================================


.data
    ALIGN 16                               ; align 32 nie dziala
    matrixA REAL4 5.0, 2.0, 3.0, 4.0,  5.0, 6.0, 7.0, 22.0,  9.0, 10.0, 11.0, 12.0,  13.0, 14.0, 8.0, 9.0
    matrixB REAL4 1.0, 2.0, 1.0, 4.0,   1.0, 6.0, 1.0, 1.0,   1.0, 1.0, 9.0, 1.0,  3.0, 1.0, 1.0, 1.0

    public resultMatrix
    resultMatrix REAL4 16 dup(0.0)
    zero REAL4 0.0
   
  

.code

public get_resultMatrix
get_resultMatrix proc
    ; Funkcja zwraca wska?nik do macierzy wynikowej
    lea rax, resultMatrix                   ;Warto?? zwracana przez funkcj? (np. wska?nik lub liczba) zawsze trafia do rejestru RAX
    ret
get_resultMatrix endp

load_matrixA proc
    ; Wczytaj dane do rejestrów xmm
    movaps xmm0, [matrixA]   ; xmm0 = a0 a1 a2 a3
    movaps xmm1, [matrixA + 16] ; xmm1 = b0 b1 b2 b3
    movaps xmm2, [matrixA + 32] ; xmm2 = c0 c1 c2 c3
    movaps xmm3, [matrixA + 48] ; xmm2 = c0 c1 c2 c3

    ret
load_matrixA endp;

load_matrixB proc
                                            ; Wczytaj dane do rejestrów xmm
    movaps xmm0, [matrixB]                  ; xmm0 = a0 a1 a2 a3
    movaps xmm1, [matrixB + 16]             ; xmm1 = b0 b1 b2 b3
    movaps xmm2, [matrixB + 32]             ; xmm2 = c0 c1 c2 c3
    movaps xmm3, [matrixB + 48]             ; xmm2 = c0 c1 c2 c3
    ret
 
load_matrixB endp;

save_matrixB proc
                                            ; Wczytaj dane do rejestrów xmm
    movaps [matrixB],      xmm0             ; xmm0 = a0 a1 a2 a3
    movaps [matrixB + 16], xmm1             ; xmm1 = b0 b1 b2 b3
    movaps [matrixB + 32], xmm2             ; xmm2 = c0 c1 c2 c3
    movaps [matrixB + 48], xmm3             ; xmm2 = c0 c1 c2 c3
    ret
 
save_matrixB endp;

load_resultMatrix proc
    vmovaps [resultMatrix], xmm0           ; a0 a1 a2 a3
    vmovaps [resultMatrix + 16], xmm1      ; b0 b1 b2 b3
    vmovaps [resultMatrix + 32], xmm2      ; c0 c1 c2 c3
    vmovaps [resultMatrix + 48], xmm3      ; d0 d1 d2 d3
    ret

load_resultMatrix endp;


transpose proc 
    call load_matrixA         ; wczytanie macierzy A do xmm0-xmm3
                                       
    ; xmm0 = a0 a1 a2 a3
    ; xmm1 = b0 b1 b2 b3
    ; xmm2 = c0 c1 c2 c3
    ; xmm3 = d0 d1 d2 d3
    ; Krok 1: przeplatanie par (xmm4–xmm7 to bufor)

    movaps xmm4, xmm0        ; kopiuj a
    unpcklps xmm0, xmm1      ; xmm0 = a0 b0 a1 b1
    unpckhps xmm4, xmm1      ; xmm4 = a2 b2 a3 b3

    movaps xmm5, xmm2
    unpcklps xmm2, xmm3      ; xmm2 = c0 d0 c1 d1
    unpckhps xmm5, xmm3      ; xmm5 = c2 d2 c3 d3

    ; Krok 2: finalne przeplatanie (XOR logiczny osiowy)
    movaps xmm1, xmm0
    shufps xmm0, xmm2, 44h   ; xmm0 = a0 b0 c0 d0 maska 
    shufps xmm1, xmm2, 0EEh  ; xmm1 = a1 b1 c1 d1

    movaps xmm2, xmm4
    shufps xmm2, xmm5, 44h  ; xmm4 = a2 b2 c2 d2
    shufps xmm4, xmm5, 0EEh  ; xmm7 = a3 b3 c3 d3
    
    movaps xmm3, xmm4
    call load_resultMatrix; 

    ret;

transpose endp;


gaussian_elimination proc
   
 ;j=0 =>kolejna do elimiancji
    ;i=0
     vbroadcastss ymm1,  [zero]         ;w0 nie bedzie zerowane   

    ;i=1;
    vmovaps xmm0, [matrixA]             ; a0 a1 a2 a3
    shufps xmm0, xmm0, 00h              ; a0 a0 a0 a0

    vmovaps xmm2, [matrixA+16 ]         ; b0 b1 b2 b3
    shufps xmm2, xmm2, 00h              ; b0 b0 b0 b0
    divps xmm2, xmm0                    ; b0/a0 b0/a0 b0/a0 b0/a0

    ;i=2
   
    vmovaps xmm3, [matrixA+32]          ; 
    shufps xmm3, xmm3, 00h              ; c0 c0 c0 c0
    divps xmm3, xmm0                    ; c0/a0 c0/a0 c0/a0 c0/a0

    ;i=3

    vmovaps xmm4, [matrixA+48 ]         ; 
    shufps xmm4, xmm4, 00h              ; d0 d0 d0 d0
    divps xmm4, xmm0                    ; d0/a0 d0/a0 d0/a0 d0/a0
   
    vinsertf128 ymm1, ymm1, xmm2, 1     ;   0   0  0  0  | b0/a0 ... b0/a0 
    vinsertf128 ymm3, ymm3, xmm4, 1     ;c0/a0 ... c0/a0 | d0/a0 ... d0/a0
   
    vmovaps xmm0, [matrixA]             ; a0 a1 a2 a3
    vinsertf128 ymm0, ymm0, xmm0, 1     ; a0 a1 a2 a3 | a0 a1 a2 a3

    vmulps ymm1, ymm1, ymm0             ; mnozenie w0, w1 przez w0[0,0] (wspolczynnik elminacji k0)
    vmulps ymm3, ymm3, ymm0             ; mnozenie w2, w3 przez w0[0,0] (wspolczynnik elminacji k0)

    
    vmovups ymm0, [matrixA]             ; LADUJE TYLKO dolna polowa macierzy 
    vmovups ymm4, [matrixA+32]          ; w ymm0 jest upper half macierzy

    vsubps ymm0, ymm0, ymm1             ; zerowanie k0,  => wejsciowa macierz do kolejnej eliminacji
    vsubps ymm4, ymm4, ymm3             ; zerowanie k0, => wejsciowa macierz do kolejnej eliminacji
   
    vmovups [resultMatrix], ymm0        ; zapisanie wyzerowan k0 w w1
   


;j=1 
    ;i=0,1
    vbroadcastss xmm1,  [zero]          ; do maskowania k0 w w1

    i=2;
    vextractf128 xmm2, ymm0, 1          ; 0 b1 b2 b3 
    shufps xmm2, xmm2, 55h              ; b1 b1 b1 b1

    vextractf128 xmm3, ymm4, 0          ; 0 c1 c2 c3
    shufps xmm3, xmm3, 55h              ; c1 c1 c1 c1
    divps xmm3, xmm2                    ; c1/b1 c1/b1 c1/b1 c1/b1 
    
    
    ;i=3
    vextractf128 xmm5, ymm4, 1          ; 0 d1 d2 d3
    shufps xmm5, xmm5, 55h              ; d1 d1 d1 d1
    divps xmm5, xmm2                    ; d1/b1 d1/b1 d1/b1 d1/b1
    
  
                   
    vextractf128 xmm2, ymm0, 1          ; 0 b1 b2 b3 
    vinsertf128 ymm2, ymm2, xmm2, 1     ; 0 b1 b2 b3 | 0 b1 b2 b3 
    vinsertf128 ymm3, ymm3, xmm5, 1     ; w2, w3 => wspolczynniki elminacji k1
    
    vmulps ymm3, ymm3, ymm2             ; mnozenie c_dte, d_det przez b_row
    vsubps ymm4, ymm4, ymm3             ; zerowanie k1 
    
   
  
   
 ;j=2     
    ;i= 0,1,2
    ;  zerowanie k3=> tylko w3  (operacja tylko na ostatnim xmm macierzy A)
    
    ;i=3
    vextractf128 xmm2, ymm4, 0          ; 0 0 c2 c3
    shufps xmm2, xmm2, 0AAh              ;c2 c2 c2 c2

    vextractf128 xmm3, ymm4, 1          ; 0 0 d2 d3
    shufps xmm3, xmm3, 0AAh             ; d2 d2 d2 d2
    divps xmm3, xmm2                    ; d2/c2 d2/c2 d2/c2 d2/c2
   

    vextractf128 xmm2, ymm4, 0          ; 0 0 c2 c3
    mulps xmm3, xmm2					; mnozenie d2/c2 * c_row => wspolczynnik elminacji k2

    vextractf128 xmm1, ymm4, 1          ; 0 0 d2 d3
    subps xmm1, xmm3                    ; zerowanie k2 ( w3)
    vinsertf128 ymm4, ymm4, xmm1, 1     ; wstawwienie z powrotem ostatatniego wyzerowanego wiersza
    
    vmovups [resultMatrix + 32], ymm4   ; wyzerow k2  
    
    ret                            
   
gaussian_elimination endp           





multiplic proc
                                      
    call load_matrixB                   ; wczytanie macierzy A do xmm0-xmm3
    call transpose                      ; transponowanie macierzy B
    call save_matrixB                   ; zapisanie macierzy B do tablicy matrixB
   
   
    vmovups ymm6,[matrixB]              ; 1 polowa macierzy B 
    vmovups ymm7,[matrixB+32]           ; 

    ;wyw makra
    MatrixMulRow 0, 0          ; i=0
    MatrixMulRow 16, 16        ; i=1
    MatrixMulRow 32, 32        ; i=2
    MatrixMulRow 48, 48        ; i=3
   
    RET                                 
   
multiplic endp;


public det
det proc
    ; powinno byc call gaussian_elimination ale jest w prog glownym 
    ; przekazanie wyniku z gaussian_elimination przez stos wiec wskaznik jest w RCX

    movss xmm0, DWORD PTR [rcx]        ; mat[0]
    mulss xmm0, DWORD PTR [rcx + 20]   ; mat[5]
    mulss xmm0, DWORD PTR [rcx + 40]   ; mat[10]
    mulss xmm0, DWORD PTR [rcx + 60]   ; mat[15]

    ret
det endp

 
END

