;******************************************************************
; マクロ
;******************************************************************
%include        "../include/define.s"
%include        "../include/macro.s"

        ORG     BOOT_LOAD                       ; ロードアドレスをアセンブラに指示

;******************************************************************
; エントリポイント
;******************************************************************
entry:
        ;---------------------------------------
        ; BPB (BIOS Parameter Block)
        ;---------------------------------------
        jmp     ipl                             ; IPLへジャンプ
        times   90 - ($ - $$)  db  0x90

        ;---------------------------------------
        ; IPL (Initial Program Loader)
        ;---------------------------------------
ipl:
        cli                                     ; 割り込み禁止

        mov     ax, 0x0000                      ; AX = 0x0000 セグメントレジスタに設定する初期値
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, BOOT_LOAD                   ; スタックポインタにロード位置のアドレスを設定

        sti                                     ; 割り込み許可

        mov     [BOOT + drive.no], dl           ; ブートドライブを保存

        ;---------------------------------------
        ; 文字列を表示
        ;---------------------------------------
        cdecl   puts, .s0                       ; puts(.s0)

        ;---------------------------------------
        ; 残りのセクタを読み込む
        ;---------------------------------------
        mov     bx, BOOT_SECT - 1               ; BX = 残りのセクタ数
        mov     cx, BOOT_LOAD + SECT_SIZE       ; CX = 次のロードアドレス

        cdecl   read_chs, BOOT, bx, cx          ; AX = read_chs(BOOT, BX, CX)

        cmp     ax, bx                          ; AX（読み込んだセクタ数）とBX（残りセクタ数）が
.10Q:   jz      .10E                            ; 異なる場合は読み出し失敗と判断し
.10T:   cdecl   puts, .e0                       ; エラーメッセージを表示してから
        call    reboot                          ; 再起動する
.10E:

        ;---------------------------------------
        ; 次のステージへ移行
        ;---------------------------------------
        jmp     stage_2nd                       ; ブート処理の第2ステージ

        ;---------------------------------------
        ; データ
        ;---------------------------------------
.s0     db "Booting...", 0x0A, 0x0D, 0
.e0     db "Error: sctor read", 0

;******************************************************************
; ブートドライブに関する情報
;******************************************************************
ALIGN 2, db 0
BOOT:                                           ; ブートドライブに関する情報
    istruc      drive
        at      drive.no,       dw 0            ; ドライブ番号
        at      drive.cyln,     dw 0            ; C: シリンダ
        at      drive.head,     dw 0            ; H: ヘッド
        at      drive.sect,     dw 2            ; S: セクタ
    iend

;******************************************************************
; モジュール
;******************************************************************
%include        "../modules/real/puts.s"
%include        "../modules/real/reboot.s"
%include        "../modules/real/read_chs.s"

;******************************************************************
; ブートフラグ（先頭512バイトの終了）
; 0xAA55 は「ブートシグネチャ」と呼ばれるMBRの有効性を示す決まった値のデータ
; $ : 現在の番地
; $$: 先頭番地
;******************************************************************
        times   510 - ($ - $$)  db  0x00
        db      0x55, 0xAA

;******************************************************************
; リアルモードで取得した情報
;******************************************************************
FONT:                                           ; フォント
        .seg:   dw 0
        .off:   dw 0
ACPI_DATA:                                      ; ACPI data
        .adr:   dd 0                            ; ACPI data address
        .len:   dd 0                            ; ACPI data length

;******************************************************************
; モジュール（第2ステージ以降用）
;******************************************************************
%include        "../modules/real/itoa.s"
%include        "../modules/real/get_drive_param.s"
%include        "../modules/real/get_font_adr.s"
%include        "../modules/real/get_mem_info.s"
%include        "../modules/real/kbc.s"

;******************************************************************
; ブート処理の第2ステージ
;******************************************************************
stage_2nd:

        ;---------------------------------------
        ; 文字列を表示
        ;---------------------------------------
        cdecl   puts, .s0                       ; puts(.s0)

        ;---------------------------------------
        ; ドライブ情報を取得
        ;---------------------------------------
        cdecl get_drive_param, BOOT             ; get_drive_param(DX, BOOT.CYLN)
        cmp     ax, 0                           ;
.10Q:   jne     .10E                            ;
.10T:   cdecl   puts, .e0                       ;
        call    reboot                          ;
.10E:

        ;---------------------------------------
        ; ドライブ情報を表示
        ;---------------------------------------
        mov     ax, [BOOT + drive.no]           ; AX = ブートドライブ
        cdecl   itoa, ax, .p1, 2, 16, 0b0100    ;
        mov     ax, [BOOT + drive.cyln]         ;
        cdecl   itoa, ax, .p2, 4, 16, 0b0100    ;
        mov     ax, [BOOT + drive.head]         ; AX = ヘッド数
        cdecl   itoa, ax, .p3, 2, 16, 0b0100    ;
        mov     ax, [BOOT + drive.sect]         ; AX = トラックあたりのセクタ数
        cdecl   itoa, ax, .p4, 2, 16, 0b0100    ;
        cdecl   puts, .s1

        ;---------------------------------------
        ; 次のステージへ移行
        ;---------------------------------------
        jmp     stage_3rd

        ;---------------------------------------
        ; データ
        ;---------------------------------------
.s0     db "2nd stage...", 0x0A, 0x0D, 0

.s1     db " Drive:0x"
.p1     db "  , C:0x"
.p2     db "    , H:0x"
.p3     db "  , S:0x"
.p4     db "  ", 0x0A, 0x0D, 0

.e0     db "Can't get drive patameter.", 0

;******************************************************************
; ブート処理の第3ステージ
;******************************************************************
stage_3rd:

        ;---------------------------------------
        ; 文字列を表示
        ;---------------------------------------
        cdecl   puts, .s0                       ; puts(.s0)

        ;---------------------------------------
        ; BIOSに内蔵されているフォントを
        ; プロテクトモードで利用するフォントとして流用
        ;---------------------------------------
        cdecl   get_font_adr, FONT

        ;---------------------------------------
        ; フォントアドレスを表示
        ;---------------------------------------
        cdecl   itoa, word [FONT.seg], .p1, 4, 16, 0b0100
        cdecl   itoa, word [FONT.off], .p2, 4, 16, 0b0100
        cdecl   puts, .s1

        ;---------------------------------------
        ; メモリ情報の取得と表示
        ;---------------------------------------
        cdecl   get_mem_info                    ;

        mov     eax, [ACPI_DATA.adr]            ;
        cmp     eax, 0                          ;
        je      .10E                            ;

        cdecl   itoa, ax, .p4, 4, 16, 0b0100    ; 下位アドレスを変換
        shr     eax, 16
        cdecl   itoa, ax, .p3, 4, 16, 0b0100    ; 上位アドレスを変換
        cdecl   puts, .s2                       ; アドレスを表示
.10E:
        ;---------------------------------------
        ; 処理の終了
        ;---------------------------------------
        jmp     stage_4th

        ;---------------------------------------
        ; データ
        ;---------------------------------------
.s0     db "3rd stage...", 0x0A, 0x0D, 0

.s1     db " Font Address="
.p1     db "ZZZZ:"
.p2     db "ZZZZ", 0x0A, 0x0D, 0
        db 0x0A, 0x0D, 0

.s2     db " ACPI data="
.p3     db "ZZZZ"
.p4     db "ZZZZ", 0x0A, 0x0D, 0

;******************************************************************
; ブート処理の第4ステージ
;******************************************************************
stage_4th:

        ;---------------------------------------
        ; 文字列を表示
        ;---------------------------------------
        cdecl   puts, .s0

        ;---------------------------------------
        ; A20ゲートの有効化
        ;---------------------------------------
        cli                                     ; 割り込み禁止

        cdecl   KBC_Cmd_Write, 0xAD             ; キーボード無効化

        cdecl   KBC_Cmd_Write, 0xD0             ; 出力ポート読み出しコマンド
        cdecl   KBC_Data_Read, .key             ; 出力ポートデータを .key に格納

        mov     bl, [.key]                      ; BL = key
        or      bl, 0x02                        ; 出力ポートにA20ゲート信号 B1 をセット

        cdecl   KBC_Cmd_Write, 0xD1             ; 出力ポート書き込みコマンド
        cdecl   KBC_Data_Write, bx              ; 出力ポートデータを再設定

        cdecl   KBC_Cmd_Write, 0xAE             ; キーボード有効化

        sti                                     ; 割り込み許可

        ;---------------------------------------
        ; 文字列を表示
        ;---------------------------------------
        cdecl   puts, .s1

        ;---------------------------------------
        ; キーボードLEDのテスト
        ;---------------------------------------
        cdecl   puts, .s2

        mov     bx, 0
.10L:
        mov     ah, 0x00                        ; 
        int     0x16                            ; キー入力待ち

        cmp     al, '1'                         ;
        jb      .10E                            ; 入力された値が1,2,3以外であれば
        cmp     al, '3'                         ; 処理を終了する
        ja      .10E                            ;

        mov     cl, al                          ; CL = キー入力
        dec     cl                              ; CL -= 1
        and     cl, 0x03                        ; CL &= 0x03
        mov     ax, 0x0001                      ; AX = 0x0001
        shl     ax, cl                          ; AX <<= CL
        xor     bx, ax                          ; BX ^= AX

        ;---------------------------------------
        ; LEDコマンドの送信
        ;---------------------------------------
        cli                                     ; 割り込み禁止

        cdecl   KBC_Cmd_Write, 0xAD             ; キーボード無効化

        cdecl   KBC_Data_Write, 0xED            ; LEDコマンド
        cdecl   KBC_Data_Read, .key             ; 受信応答

        cmp     [.key], byte 0xFA
        jne     .11F

        cdecl   KBC_Data_Write, bx              ; LEDデータ出力
        jmp     .11E

.11F:
        cdecl   itoa, word [.key], .e1, 2, 16, 0b0100
        cdecl   puts, .e0                       ; 受信コード表示

.11E:
        cdecl   KBC_Cmd_Write, 0xAE             ; キーボード有効化

        sti                                     ; 割り込み許可

        jmp     .10L

.10E:

        ;---------------------------------------
        ; 文字列を表示
        ;---------------------------------------
        cdecl   puts, .s3

        ;---------------------------------------
        ; 処理の終了
        ;---------------------------------------
        jmp     $                               ; 無限ループ

.s0:    db "4th stage...", 0x0A, 0x0D, 0
.s1:    db " A20 Gate Enabled.", 0x0A, 0x0D, 0
.s2:    db " Keyborad LED Test...", 0
.s3:    db " (done)", 0x0A, 0x0D, 0
.e0:    db "["
.e1:    db "ZZ]", 0

.key:   dw 0

;******************************************************************
; パディング（ブートプログラムを8Kバイトにする）
;******************************************************************
        times BOOT_SIZE - ($ - $$)      db 0    ; パディング