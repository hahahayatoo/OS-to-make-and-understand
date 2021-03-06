memcpy:
        ;---------------------------------------
        ; 【スタックフレームの構築】
        ;---------------------------------------
                                                ; BP + 0| BP（元の値）
                                                ; BP + 4| IP（戻り番地）
                                                ; ------|-----------
                                                ; BP + 8| コピー先（引数1）
                                                ; BP +12| コピー元（引数2）
        push    ebp                             ; BP +16| バイト数（引数3）
        mov     ebp, esp                        ; ------|-----------

        ;---------------------------------------
        ; 【レジスタの保存】
        ;---------------------------------------
        push    ecx
        push    esi
        push    edi

        ;---------------------------------------
        ;---------------------------------------
        cld                                     ; DF = 0; // +方向
        mov     edi, [ebp +  8]                 ; DIにコピー先を設定
        mov     esi, [ebp + 12]                 ; SIにコピー元を設定
        mov     ecx, [ebp + 16]                 ; CXにバイト数を設定

        rep movsb                               ; while (*DI++ = *SI++) ;

        ;---------------------------------------
        ; 【レジスタの復帰】
        ;---------------------------------------
         pop    edi
         pop    esi
         pop    ecx

        ;---------------------------------------
        ; 【スタックフレームの破棄】
        ;---------------------------------------
        mov     esp, ebp
        pop     ebp

        ret