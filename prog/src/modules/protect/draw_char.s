draw_char:
        ;---------------------------------------
        ; 【スタックフレームの構築】
        ;---------------------------------------
                                                ; BP + 20| 文字
                                                ; BP + 16| 描画色
                                                ; BP + 12| 行(0~29)
                                                ; BP +  8| 列(0~79)
                                                ; BP +  4| IP（戻り番地）
        push    ebp                             ; BP +  0| BP（元の値）
        mov     ebp, esp                        ; ------|-----------

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
        ; テスト&セット
        ;---------------------------------------
%ifdef  USE_TEST_AND_SET
        cdecl   test_and_set, IN_USE
%endif

        ;---------------------------------------
        ; コピー元フォントアドレスを設定
        ;---------------------------------------
        movzx   esi, byte [ebp + 20]            ; CL = 文字コード
        shl     esi, 4                          ; CL *= 16 // 1文字が16バイトなのでx16
        add     esi, [FONT_ADR]                 ; ESI = フォントアドレス
                                                ; // BIOSのフォントを格納しているアドレスを加算して算出

        ;---------------------------------------
        ; コピー先アドレスを取得
        ; Adr = 0xA0000 + (640 / 8 * 16) * y + x
        ;---------------------------------------
        mov     edi, [ebp + 12]                 ; Y (行)
        shl     edi, 8                          ; EDI = Y * 256
        lea     edi, [edi * 4 + edi + 0xA0000]  ; EDI = Y * 4 + Y
        add     edi, [ebp + 8]                  ; X (列)

        ;---------------------------------------
        ; 1文字分のフォントを出力
        ;---------------------------------------
        movzx   ebx, word [ebp + 16]            ; 表示色

        cdecl   vga_set_read_plane, 0x03        ; 書き込みプレーン：輝度
        cdecl   vga_set_write_plane, 0x08       ; 読み込みプレーン：輝度
        cdecl   vram_font_copy, esi, edi, 0x08, ebx

        cdecl   vga_set_read_plane, 0x02        ; 書き込みプレーン：赤
        cdecl   vga_set_write_plane, 0x04       ; 読み込みプレーン：赤
        cdecl   vram_font_copy, esi, edi, 0x04, ebx

        cdecl   vga_set_read_plane, 0x01        ; 書き込みプレーン：緑
        cdecl   vga_set_write_plane, 0x02       ; 読み込みプレーン：緑
        cdecl   vram_font_copy, esi, edi, 0x02, ebx

        cdecl   vga_set_read_plane, 0x00        ; 書き込みプレーン：青
        cdecl   vga_set_write_plane, 0x01       ; 読み込みプレーン：青
        cdecl   vram_font_copy, esi, edi, 0x01, ebx

        ;---------------------------------------
        ; IN_USEの解放
        ;---------------------------------------
%ifdef  USE_TEST_AND_SET
        mov     [IN_USE], dword 0               ; TEST_AND_SET(IN_USE) リソースの空き待ち
%endif

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

%ifdef  USE_TEST_AND_SET
ALIGN 4, db 0
IN_USE: dd 0
%endif