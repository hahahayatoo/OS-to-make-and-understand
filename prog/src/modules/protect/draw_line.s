draw_line:
        ;---------------------------------------
        ; 【スタックフレームの構築】
        ;---------------------------------------
                                                ; EBP + 24| 色
                                                ; EBP + 20| Y1 終点のY座標
                                                ; EBP + 16| X1 終点のX座標
                                                ; EBP + 12| Y0 起点のY座標
                                                ; EBP +  8| X0 起点のX座標
                                                ; --------------------
        push    ebp                             ; EBP +  4| EIP（戻り番地）
        mov     ebp, esp                        ; EBP +  0| EBP（元の値）
                                                ; --------------------
        push    dword 0                         ; EBP -  4| sum 総体軸の積算値
        push    dword 0                         ; EBP -  8| x0 X座標
        push    dword 0                         ; EBP - 12| dx X増分
        push    dword 0                         ; EBP - 16| inc_x X座標増分（1 or -1）
        push    dword 0                         ; EBP - 20| y0 Y座標
        push    dword 0                         ; EBP - 24| dy Y増分
        push    dword 0                         ; EBP - 28| inc_y Y座標増分（1 or -1）

        ;---------------------------------------
        ; 【レジスタの保存】
        ;---------------------------------------
        push    eax
        push    ebx
        push    ecx
        push    edx
        push    esi
        push    edi

        ;---------------------------------------
        ; 幅を計算（X軸）
        ;---------------------------------------
        mov     eax, [ebp + 8]                  ; EAX = X0
        mov     ebx, [ebp + 16]                 ; EBX = X1
        sub     ebx, eax                        ; EBX = X1 - X0
        jge     .10F

        neg     ebx
        mov     esi, -1
        jmp     .10E

.10F:
        mov     esi, 1

.10E:

        ;---------------------------------------
        ; 高さを計算（Y軸）
        ;---------------------------------------
        mov     ecx, [ebp + 12]                 ; ECX = Y0
        mov     edx, [ebp + 20]                 ; ECX = Y1
        sub     edx, ecx                        ; EDX = Y1 - Y0
        jge     .20F

        neg     edx
        mov     edi, -1
        jmp     .20E

.20F:
        mov     edi, 1

.20E:

        ;---------------------------------------
        ; X軸
        ;---------------------------------------
        mov     [ebp - 8], eax                  ; X軸：開始座標
        mov     [ebp - 12], ebx                 ; X軸：描画幅
        mov     [ebp - 16], esi                 ; X軸：増分（基準軸： 1 or -1）

        ;---------------------------------------
        ; Y軸
        ;---------------------------------------
        mov     [ebp - 20], ecx                 ; Y軸：開始座標
        mov     [ebp - 24], edx                 ; Y軸：描画幅
        mov     [ebp - 28], edi                 ; Y軸：増分（基準軸： 1 or -1）

        ;---------------------------------------
        ; 基準軸を決める
        ;---------------------------------------
        cmp     ebx, edx                        ; 幅と高さを比較して、
        jg      .22F                            ; 大きい方を基準軸とする

        lea     esi, [ebp - 20]                 ; 基準軸：X
        lea     edi, [ebp - 8]                  ; 相対軸：Y

        jmp     .22E

.22F:
        lea     esi, [ebp - 8]                  ; 基準軸：Y
        lea     edi, [ebp - 20]                 ; 相対軸：X

.22E:

        ;---------------------------------------
        ; 繰り返し回数（基準軸のドット数）
        ;---------------------------------------
        mov     ecx, [esi - 4]                  ; ECX = 基準軸描画幅
        cmp     ecx, 0                          ;
        jnz     .30E                            ;
        mov     ecx, 1                          ; 基準軸の長さが0の場合は繰り返し回数を1にする

.30E:

        ;---------------------------------------
        ; 線を描画する
        ;---------------------------------------
.50L:
%ifdef  USE_SYSTEM_CALL
        mov     eax, ecx                        ; 繰り返し回数を保存

        mov     ebx, [ebp + 24]                 ; EBX = 表示色
        mov     ecx, [ebp - 8]                  ; ECX = X座標
        mov     edx, [ebp - 20]                 ; EDX = Y座標
        int     0x82

        mov     ecx, eax
%else
        cdecl   draw_pixel, dword [ebp - 8], \
                            dword [ebp - 20], \
                            dword [ebp + 24]    ; 点の描画
%endif

        mov     eax, [esi - 8]                  ; 基準軸を更新（1ドット分）
        add     [esi - 0], eax                  ; 基準軸増分は 1 or -1

        mov     eax, [ebp - 4]                  ; 相対軸を更新
        add     eax, [edi - 4]                  ; 相対軸の積算値に相対軸の増分を加算

        mov     ebx, [esi - 4]                  ; EBX = 基準軸の増分

        cmp     eax, ebx                        ; 積算値 <= 相対軸の増分
        jl      .52E
        sub     eax, ebx                        ; 積算値から相対軸の増分を減算

        mov     ebx, [edi - 8]                  ; 相対軸の座標を更新（1ドット分）
        add     [edi - 0], ebx                  ; EBX = 相対軸増分

.52E:
        mov     [ebp - 4], eax                  ; 積算値を更新

        loop    .50L

.50E:

        ;---------------------------------------
        ; 【レジスタの復帰】
        ;---------------------------------------
         pop    edi
         pop    esi
         pop    edx
         pop    ecx
         pop    ebx
         pop    eax

        ;---------------------------------------
        ; 【スタックフレームの破棄】
        ;---------------------------------------
        mov     esp, ebp
        pop     ebp

        ret