;******************************************************************
; エントリポイント
;******************************************************************
entry:
        jmp     ipl                             ; IPLへジャンプ

        ;---------------------------------------
        ; BPB (BIOS Parameter Block)
        ;---------------------------------------
        times   90 - ($ - $$)  db  0x90

        ;---------------------------------------
        ; IPL (Initial Program Loader)
        ;---------------------------------------
ipl:
        jmp     $                               ; while(1); // 無限ループ
;******************************************************************
; ブートフラグ（先頭512バイトの終了）
; 0xAA55 は「ブートシグネチャ」と呼ばれるMBRの有効性を示す決まった値のデータ
;******************************************************************
        times   510 - ($ - $$)  db  0x00
        db      0x55, 0xAA