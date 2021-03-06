int_keyboard:
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
        ; KBCのバッファ読み取り
        ;---------------------------------------
        in      al, 0x60                        ; AL = キーコードの取得

        ;---------------------------------------
        ; キーコードの保存
        ;---------------------------------------
        cdecl   ring_wr, _KEY_BUFF, eax         ; ring_wr(_KEY_BUFF, EAX) キーコードの保存

        ;---------------------------------------
        ; 割り込み終了コマンドの送信
        ;---------------------------------------
        outp    0x20, 0x20                      ; マスタPICにEOIコマンド送信

        ;---------------------------------------
        ; 【レジスタの復帰】
        ;---------------------------------------
        pop     es
        pop     ds
        popa

        iret                                    ; 割り込み処理の終了

ALIGN   4, db 0
_KEY_BUFF:      times ring_buff_size db 0