lba_chs:
        ;---------------------------------------
        ; 【スタックフレームの構築】
        ;---------------------------------------
                                                ; BP +8| LBA
                                                ; BP +6| 変換後のCHS格納アドレス
                                                ; BP +4| ドライブパラメータ格納アドレス
                                                ; BP +2| IP（戻り番地）
        push    bp                              ; BP +0| BP（元の値）
        mov     bp, sp                          ; -----|----------

        ;---------------------------------------
        ; 【レジスタの保存】
        ;---------------------------------------
        push    ax
        push    bx
        push    dx
        push    si
        push    di

        ;---------------------------------------
        ; 【処理の開始】
        ;---------------------------------------
        mov     si, [bp + 4]
        mov     di, [bp + 6]

        mov     al, [si + drive.head]           ; AL = 最大ヘッド数 
        mul     byte [si + drive.sect]          ; AX = 最大ヘッド数 * 最大セクタ数
        mov     bx, ax                          ; BX = シリンダあたりのセクタ数
        mov     dx, 0                           ; DX = LBA (上位2バイト)
        mov     ax, [bp + 8]                    ; AX = LBA (下位2バイト)
        div     bx                              ; DX = DX:AX % BX // 残り
                                                ; AX = DX:AX / BX // シリンダ番号

        mov     [di + drive.cyln], ax           ; drv_chs.cyln = シリンダ番号

        mov     ax, dx                          ; AX = 残り
        div     byte [si + drive.sect]          ; AH = AX % 最大セクタ数 // セクタ番号
                                                ; AL = AX / 最大セクタ数 // ヘッド番号

        movzx   dx, ah                          ; DX = セクタ番号
        inc     dx                              ; (セクタは1始まりなので1加算)

        mov     ah, 0x00                        ; AX = ヘッド位置

        mov     [di + drive.head], ax           ; drice_chs.head = ヘッド番号
        mov     [di + drive.sect], dx           ; drive_chs.sect = セクタ番号

        ;---------------------------------------
        ; レジスタの復帰
        ;---------------------------------------
        pop     di
        pop     si
        pop     dx
        pop     bx
        pop     ax

        ;---------------------------------------
        ; 【スタックフレームの破棄】
        ;---------------------------------------
        mov     sp, bp
        pop     bp

        ret