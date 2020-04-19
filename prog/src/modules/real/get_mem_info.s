get_mem_info:
        ;---------------------------------------
        ; 【レジスタの保存】
        ;---------------------------------------
        push    eax
        push    ebx
        push    ecx
        push    edx
        push    si
        push    di
        push    bp

        ;---------------------------------------
        ; 【処理の開始】
        ;---------------------------------------
ALIGN 4, db 0
.b0:    times E820_RECORD_SIZE db 0

        cdecl puts, .s0

        mov     bp, 0                           ; 表示行数の初期化
        mov     ebx, 0                          ; インデックスの初期化
.10L:
        mov     eax, 0x0000E820                 ; EAX = 0xE820（固定）

        mov     ecx, E820_RECORD_SIZE           ; ECX = 書き込みバイト数
        mov     edx, 'PAMS'                     ; EDX = 'SMAP'（固定）
        mov     di, .b0                         ; ES:DI = バッファ（情報書き込み先）
        int     0x15                            ; BIOS(0x15, 0xE820)

        cmp     eax, 'PAMS'                     ; 未対応のBIOSの場合EAXに'SMAP'は格納されない
        je      .12E                            ; そのため、未対応のBIOSであれば処理を終了する
        jmp     .10E                            ;
.12E:
        jnc     .14E                            ; CFの値を見てエラー発生状況を確認
        jmp     .10E                            ; エラーが発生していれば処理を終了
.14E:
        cdecl   put_mem_info, di                ; 1レコード分のメモリ情報を表示

        ; ACPI dataのアドレスを取得
        mov     eax, [di + 16]                  ; EAX = レコードタイプ
        cmp     eax, 3                          ; レコードタイプがACPI dataであれば
        jne     .15E                            ; ACPI_DATAにデータを格納する処理に分岐

        mov     eax, [di + 0]                   ; EAX = BASEアドレス
        mov     [ACPI_DATA.adr], eax            ; ACPI_DATA.adrにBASEアドレスを格納

        mov     eax, [di + 8]                   ; EAX = Length
        mov     [ACPI_DATA.len], eax            ; ACPI_DATAにLengthを格納
.15E:
        cmp     ebx, 0                          ; 最終レコードを取得していれば
        jz      .16E                            ; EBX が 0 になるので処理を終了する

        inc     bp                              ; 8行表示する毎に表示を中断する
        and     bp, 0x07                        ; 具体的には現在の表示件数と 0x07 の AND をとり
        jnz     .16E                            ; 0 になれば 8 の倍数行表示したと判断して中断

        cdecl   puts, .s2                       ; 中断メッセージを表示して
        mov     ah, 0x10                        ;
        int     0x16                            ; キー入力を待つ

        cdecl   puts, .s3                       ; 中断メッセージを消去

.16E:
        cmp     ebx, 0                          ; EBX が 0 でなければ最終レコードではないので
        jne     .10L                            ; 読み取り処理を続ける
.10E:
        cdecl   puts, .s1

        ;---------------------------------------
        ; 【レジスタの復帰】
        ;---------------------------------------
        pop     bp
        pop     di
        pop     si
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax

        ret;

.s0:	db " E820 Memory Map:", 0x0A, 0x0D
        db " Base_____________ Length___________ Type____", 0x0A, 0x0D, 0
.s1:	db " ----------------- ----------------- --------", 0x0A, 0x0D, 0
.s2:    db "<more...>", 0
.s3:    db 0x0D, "         ", 0x0D, 0

put_mem_info:
        ;---------------------------------------
        ; 【スタックフレームの構築】
        ;---------------------------------------
                                                ; BP +4| バッファアドレス
                                                ; BP +2| IP（戻り番地）
        push    bp                              ; BP +0| BP（元の値）
        mov     bp, sp                          ; -----|----------

        ;---------------------------------------
        ; 【レジスタの保存】
        ;---------------------------------------
        push    bx
        push    si

        ;---------------------------------------
        ; 引数を取得
        ;---------------------------------------
        mov     si, [bp + 4]                    ; SI = バッファアドレス

        ; Base(64bit)
        cdecl   itoa, word [si + 6], .p2 + 0, 4, 16, 0b0100
        cdecl   itoa, word [si + 4], .p2 + 4, 4, 16, 0b0100
        cdecl   itoa, word [si + 2], .p3 + 0, 4, 16, 0b0100
        cdecl   itoa, word [si + 0], .p3 + 4, 4, 16, 0b0100

        ; Length(64bit)
        cdecl   itoa, word [si + 14], .p4 + 0, 4, 16, 0b0100
        cdecl   itoa, word [si + 12], .p4 + 4, 4, 16, 0b0100
        cdecl   itoa, word [si + 10], .p5 + 0, 4, 16, 0b0100
        cdecl   itoa, word [si +  8], .p5 + 4, 4, 16, 0b0100

        ;Type(32bit)
        cdecl   itoa, word [si + 18], .p6 + 0, 4, 16, 0b0100
        cdecl   itoa, word [si + 16], .p6 + 4, 4, 16, 0b0100

        cdecl   puts, .s1                       ; レコード情報を表示

        mov     bx, [si + 16]                   ; タイプを文字列で表示
        and     bx, 0x07                        ; BX = Type(0~5)
        shl     bx, 1                           ; BX *= 2   // 要素テーブルに変換
        add     bx, .t0                         ; BX += .t0 // テーブルの先頭アドレスを加算
        cdecl   puts, word [bx]                 ; puts(*BX)

        ;---------------------------------------
        ; 【レジスタの復帰】
        ;---------------------------------------
        pop     si
        pop     bx

        ;---------------------------------------
        ; 【スタックフレームの破棄】
        ;---------------------------------------
        mov     sp, bp
        pop     bp

        ret;

        ;---------------------------------------
        ; データ
        ;---------------------------------------
.s1:    db " "
.p2:    db "ZZZZZZZZ_"
.p3:    db "ZZZZZZZZ "
.p4:    db "ZZZZZZZZ_"
.p5:    db "ZZZZZZZZ "
.p6:    db "ZZZZZZZZ", 0

.s4:    db " (Unknown)", 0x0A, 0x0D, 0          ; レコードタイプによって[si + 16] 
.s5:    db " (usable)", 0x0A, 0x0D, 0           ; の値が異なることを利用して
.s6:    db " (reserved)", 0x0A, 0x0D, 0         ; いい感じにタイプを文字列で表示する
.s7:    db " (ACPI data)", 0x0A, 0x0D, 0        ; add     bx, .t0
.s8:    db " (ACPI NVS)", 0x0A, 0x0D, 0         ; でその処理を実現している
.s9:    db " (bad memory)", 0x0A, 0x0D, 0       ;

.t0:    dw .s4, .s5, .s6, .s7, .s8, .s9, .s4, .s4