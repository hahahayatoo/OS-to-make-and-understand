power_off:
        ;---------------------------------------
        ; 【レジスタの保存】
        ;---------------------------------------
        push    eax
        push    ebx
        push    ecx
        push    edx
        push    esi

        ;---------------------------------------
        ; 電断開始メッセージ
        ;---------------------------------------
        cdecl   draw_str, 25, 14, 0x020F, .s0

        ;---------------------------------------
        ; ページングを無効化
        ; ページングで設定した範囲外にACPIデータ領域が存在した場合は色々とややこしいので
        ;---------------------------------------
        mov     eax, cr0                        ; PGビットをクリア
        and     eax, 0x7FFF_FFFF                ; CR0 &= ~PG
        mov     cr0, eax
        jmp     $ + 2                           ; FLUSH

        ;---------------------------------------
        ; ACPIデータの確認
        ;---------------------------------------
        mov     eax, [0x7C00 + 512 + 4]         ; EAX = ACPIアドレス
        mov     ebx, [0x7C00 + 512 + 8]         ; EBX = 長さ
        cmp     eax, 0                          ; ACPIアドレスが0の時はブート処理時に
        je      .10E                            ; ACPIデータ領域を検出できなかったと判断して処理を中断

        ;---------------------------------------
        ; RSDTテーブルの検索
        ;---------------------------------------
        cdecl   acpi_find, eax, ebx, 'RSDT'     ; EAX = acpi_find('RSDT')
        cmp     eax, 0                          ; RSDTからすべての情報を取得するので
        je      .10E                            ; RSDTテーブルが取得できなければ処理を中断

        ;---------------------------------------
        ; RSDTテーブルからFACPテーブルの検索
        ;---------------------------------------
        cdecl   find_rsdt_entry, eax, 'FACP'    ; EAX = find_rsdt_entry('FACP')
        cmp     eax, 0                          ;
        je      .10E                            ; FADTのアドレスが取得できなければ処理中断

        mov     ebx, [eax + 40]                 ; DSDTアドレスの取得
        cmp     ebx, 0
        je      .10E                            ; DSDTのアドレスが取得できていなければ処理を中断

        ;---------------------------------------
        ; ACPIレジスタの保存
        ;---------------------------------------
        mov     ecx, [eax + 64]                 ; ACPIレジスタの保存
        mov     [PM1a_CNT_BLK], ecx             ; PM1a_CNT_BLK = FACP.PM1a_CNT_BLK

        mov     ecx, [eax + 68]                 ;
        mov     [PM1b_CNT_BLK], ecx             ; PM1b_CNT_BLK = FACP.PM1b_CNT_BLK

        ;---------------------------------------
        ; S5名前空間の検索
        ;---------------------------------------
        mov     ecx, [ebx + 4]                  ; ECX = DSDT.Length データ長
        sub     ecx, 36                         ; ECX -= 36 テーブルヘッダ分減算
        add     ebx, 36                         ; EBX += 36 テーブルヘッダ分加算
        cdecl   acpi_find, ebx, ecx, '_S5_'     ; EAX = acpi_find('_S5_')
        cmp     eax, 0
        je      .10E                            ; S5名前空間の定義が見つからなければ処理中断

        ;---------------------------------------
        ; パッケージデータの取得
        ;---------------------------------------
        add     eax, 4                          ; EAX = 先頭の要素
        cdecl   acpi_package_value, eax         ; EAX = パッケージデータ
        mov     [S5_PACKAGE], eax               ; S5_PACKAGE = パッケージデータ

.10E:
        ;---------------------------------------
        ; ページングを有効化
        ;---------------------------------------
        mov     eax, cr0
        or      eax, (1 << 31)                  ; CR0 |= PG
        mov     cr0, eax
        jmp     $ + 2                           ; FLUSH

        ;---------------------------------------
        ; ACPIレジスタの取得
        ;---------------------------------------
        mov     edx, [PM1a_CNT_BLK]             ; EDX = FACP.PM1a_CNT_BLK
        cmp     edx, 0                          ; PM1a_CNT_BLK のアドレスが 0 の場合は
        je      .20E                            ; 正しいレジスタのアドレスを取得できなかったと判断

        ;---------------------------------------
        ; カウントダウンの表示
        ;---------------------------------------
        cdecl   draw_str, 38, 14, 0x020F, .s3
        cdecl   wait_tick, 100
        cdecl   draw_str, 38, 14, 0x020F, .s2
        cdecl   wait_tick, 100
        cdecl   draw_str, 38, 14, 0x020F, .s1
        cdecl   wait_tick, 100

        ;---------------------------------------
        ; PM1a_CNT_BLKの設定
        ;---------------------------------------
        movzx   ax, [S5_PACKAGE.0]
        shl     ax, 10                          ; AX = SLP_TYPx
        or      ax, 1 << 13                     ; AX |= SLP_EN
        out     dx, ax                          ; 取得したシステム情報を PM1a_CNT_BLK にセット

        ;---------------------------------------
        ; PM1b_CNT_BLKの確認
        ;---------------------------------------
        mov     edx, [PM1b_CNT_BLK]
        cmp     edx, 0                          ; PM1b_CNT_BLK のアドレスが 0 の場合は
        je      .20E                            ; PM1b_CNT_BLK の設定が不要のため設定処理を飛ばす

        ;---------------------------------------
        ; PM1b_CNT_BLKの設定
        ;---------------------------------------
        movzx   ax, [S5_PACKAGE.1]              ; S5システム状態を表すパッケージの下位1バイト目を設定
        shl     ax, 10
        or      ax, 1 << 13
        out     dx, ax

.20E:
        ;---------------------------------------
        ; 電断待ち
        ;---------------------------------------
        cdecl   wait_tick, 100

        ;---------------------------------------
        ; 電断失敗メッセージ
        ;---------------------------------------
        cdecl   draw_str, 38, 14, 0x020F, .s4

.s0:    db  " Power off...  ", 0
.s1:    db  " 1", 0
.s2:    db  " 2", 0
.s3:    db  " 3", 0
.s4:    db  "NG", 0

ALIGN 4, db 0
PM1a_CNT_BLK:   dd 0
PM1b_CNT_BLK:   dd 0
S5_PACKAGE:
.0:             db 0
.1:             db 0
.2:             db 0
.3:             db 0