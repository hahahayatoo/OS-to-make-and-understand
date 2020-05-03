draw_rect:
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
        ; 引数をレジスタに格納
        ;---------------------------------------
        mov     eax, [ebp + 8]
        mov     ebx, [ebp + 12]
        mov     ecx, [ebp + 16]
        mov     edx, [ebp + 20]
        mov     esi, [ebp + 24]

        ;---------------------------------------
        ; 座標軸の大小を確定
        ;---------------------------------------
        cmp     eax, ecx
        jl      .10E
        xchg    eax, ecx

.10E:
        cmp     ebx, edx
        jl      .20E
        xchg    ebx, edx

.20E:

        ;---------------------------------------
        ; 矩形を描画
        ;---------------------------------------
        cdecl   draw_line, eax, ebx, ecx, ebx, esi
        cdecl   draw_line, eax, ebx, eax, edx, esi

        dec     edx
        cdecl   draw_line, eax, edx, ecx, edx, esi
        inc     edx

        dec     ecx
        cdecl   draw_line, ecx, ebx, ecx, edx, esi

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