;******************************************************************
; FAT: FAT-1
;******************************************************************
        times   (FAT1_START) - ($ - $$) db 0x00

FAT1:
        db      0xFF, 0xFF                      ; クラスタ: 0
        dw      0xFFFF                          ; クラスタ: 1
        dw      0xFFFF                          ; クラスタ: 2 本来のインデックスとしての機能を果たすのはここだけ？

;******************************************************************
; FAT: FAT-2
;******************************************************************
        times   (FAT2_START) - ($ - $$) db 0x00

FAT2:
        db      0xFF, 0xFF                      ; クラスタ: 0
        dw      0xFFFF                          ; クラスタ: 1
        dw      0xFFFF                          ; クラスタ: 2 本来のインデックスとしての機能を果たすのはここだけ？

;******************************************************************
; FAT: ルート領域
;******************************************************************
        times   (ROOT_START) - ($ - $$) db 0x00

FAT_ROOT:
        db      'BOOTABLE', 'DSK'               ; +  0: ボリュームラベル
        db      ATTR_ARCHIVE | ATTR_VOLUME_ID   ; + 11: 属性 0x28はボリュームラベルを表す
        db      0x00                            ; + 12: 予約
        db      0x00                            ; + 13: TS
        dw      (0 << 11) | (0 << 5) | (0 / 2)  ; + 14: 作成時刻
        dw      (0 << 9) | (0 << 5) | ( 1)      ; + 16: 作成日
        dw      (0 << 9) | (0 << 5) | ( 1)      ; + 18: アクセス日
        dw      0x0000                          ; + 20: 予約
        dw      (0 << 11) | (0 << 5) | (0 / 2)  ; + 22: 更新時刻
        dw      (0 << 9) | (0 << 5) | ( 1)      ; + 24: 更新日
        dw      0                               ; + 26: 先頭クラスタ
        dd      0                               ; + 28: ファイルサイズ

        db      'SPECIAL ', 'TXT'               ; +  0: ボリュームラベル
        db      ATTR_ARCHIVE                    ; + 11: 属性 0x20は通常ファイルを表す
        db      0x00                            ; + 12: 予約
        db      0x00                            ; + 13: TS
        dw      (0 << 11) | (0 << 5) | (0 / 2)  ; + 14: 作成時刻
        dw      (0 << 9) | (0 << 5) | ( 1)      ; + 16: 作成日
        dw      (0 << 9) | (0 << 5) | ( 1)      ; + 18: アクセス日
        dw      0x0000                          ; + 20: 予約
        dw      (0 << 11) | (0 << 5) | (0 / 2)  ; + 22: 更新時刻
        dw      (0 << 9) | (0 << 5) | ( 1)      ; + 24: 更新日
        dw      2                               ; + 26: 先頭クラスタ フィルの中身をデータ領域の選択に配置するため
        dd      FILE.end - FILE                 ; + 28: ファイルサイズ

;******************************************************************
; FAT: データ領域
;******************************************************************
        times   (FILE_START) - ($ - $$) db 0x00

FILE:   db      'hello, FAT!'
.end:   db      0

ALIGN 512, db 0x00

        times   (512 * 63) db 0x00              ; ブートイメージ全体のサイズを320Kに調整