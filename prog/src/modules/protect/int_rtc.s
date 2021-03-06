rtc_int_en:
        ;---------------------------------------
        ; 【スタックフレームの構築】
        ;---------------------------------------
                                                ; EBP + 8| ビット
                                                ; --------------------
        push    ebp                             ; EBP + 4| EIP（戻り番地）
        mov     ebp, esp                        ; EBP + 0| EBP（元の値）

        ;---------------------------------------
        ; 【レジスタの保存】
        ;---------------------------------------
        push    eax

        ;---------------------------------------
        ; 割り込み許可設定
        ;---------------------------------------
        outp    0x70, 0x0B                      ; レジスタBを設定

        in      al, 0x71                        ; レジスタBの指定されたビットをセット
        or      al, [ebp + 8]                   ;

        out     0x71, al                        ; レジスタBに書き込み

        ;---------------------------------------
        ; 【レジスタの復帰】
        ;---------------------------------------
        pop     eax

        ;---------------------------------------
        ; 【スタックフレームの破棄】
        ;---------------------------------------
        mov     esp, ebp
        pop     ebp

        ret

int_rtc:
        ;---------------------------------------
        ; 【レジスタの保存】
        ;---------------------------------------
        pusha                                   ; スタックに全ての汎用レジスタのデータをプッシュ
        push    ds
        push    es

        ;---------------------------------------
        ; データ用セグメントセレクタの設定
        ;---------------------------------------
        mov     ax, 0x0010                      ; GDTの先頭からのバイト数
        mov     ds, ax
        mov     es, ax

        ;---------------------------------------
        ; RTCから時刻を取得
        ;---------------------------------------
        cdecl   rtc_get_time, RTC_TIME          ; EAZX = get_time(&RTC_TIME)

        ;---------------------------------------
        ; RTCの割り込み要因を取得
        ;---------------------------------------
        outp    0x70, 0x0C                      ; outp(0x70, 0x0C) レジスタCを選択
        in      al, 0x71                        ; AL = port(0x71)

        ;---------------------------------------
        ; 割り込みフラグをクリア（EOI）
        ;---------------------------------------
        mov     al, 0x20                        ; AL = EOIコマンド
        out     0xA0, al                        ; スレーブPIC
        out     0x20, al                        ; マスタPIC

        ;---------------------------------------
        ; 【レジスタの復帰】
        ;---------------------------------------
        pop     es
        pop     ds
        popa

        iret                                    ; 割り込み処理の終了
