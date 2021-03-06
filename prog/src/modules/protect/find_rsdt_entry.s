find_rsdt_entry:
        ;---------------------------------------
        ; 【スタックフレームの構築】
        ;---------------------------------------
                                                ; EBP + 12| テーブル識別子
                                                ; EBP +  8| RSDTテーブルのアドレス
                                                ; EBP +  4| EIP（戻り番地）
        push    ebp                             ; EBP +  0| EBP（元の値）
        mov     ebp, esp                        ; ------------------------

        ;---------------------------------------
        ; 【レジスタの保存】
        ;---------------------------------------
        push    ebx
        push    ecx
        push    esi
        push    edi

        ;---------------------------------------
        ; 引数を取得
        ;---------------------------------------
        mov     esi, [ebp + 8]                  ; EDI = RSDT
        mov     ecx, [ebp + 12]                 ; ECX = 識別子

        mov     ebx, 0                          ; adr = 0

        ;---------------------------------------
        ; ACPIテーブル検索処理
        ;---------------------------------------
        mov     edi, esi                        ;
        add     edi, [esi + 4]                  ; EDI = &ENTRY[MAX]
        add     esi, 36                         ; ESI = &ENTRY[0]

.10L:
        cmp     esi, edi                        ;
        jge     .10E

        lodsd                                   ; EAX = [ESI++] エントリ

        cmp     [eax], ecx                      ; ACPIテーブルの識別子と比較
        jne     .12E                            ;
        mov     ebx, eax                        ; 一致した場合はEBXに設定し
        jmp     .10E                            ; ループを抜ける

.12E:   jmp     .10L

.10E:
        mov     eax, ebx                        ; return adr

        ;---------------------------------------
        ; 【レジスタの復帰】
        ;---------------------------------------
        pop     edi
        pop     esi
        pop     ecx
        pop     ebx

        ;---------------------------------------
        ; 【スタックフレームの破棄】
        ;---------------------------------------
        mov     esp, ebp
        pop     ebp

        ret