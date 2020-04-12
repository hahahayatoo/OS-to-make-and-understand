get_drive_param:
        ;---------------------------------------
        ; 【スタックフレームの構築】
        ;---------------------------------------
                                                ; BP +4| パラメータバッファ
                                                ; BP +2| IP（戻り番地）
        push    bp                              ; BP +0| BP（元の値）
        mov     bp, sp                          ; -----|----------

        ;---------------------------------------
        ; 【レジスタの保存】
        ;---------------------------------------
        push    bx
        push    cx
        push    es
        push    si
        push    di

        ;---------------------------------------
        ; 【処理の開始】
        ;---------------------------------------
        mov     si, [bp + 4]                    ; SI = SRCバッファ

        mov     ax, 0                           ; Disk Base Table Pointer の初期化
        mov     es, ax                          ; ES = 0
        mov     di, ax                          ; DI = 0

        mov     ah, 8                           ; // get drive parameters
        mov     dl, [si + drive.no]             ; DL = ドライブ番号
        int     0x13                            ; CF = BIOS(0x13, 8)
.10Q:   jc      .10F
.10T:
        mov     al, cl                          ; AX = セクタ数
        and     ax, 0x3F                        ; 下位6ビットだけ必要なのでマスク

        shr     cl, 6                           ; CX = 最大シリンダ数
        ror     cx, 8                           ; CH, CLレジスタに10bitの情報として格納
        inc     cx                              ; シリンダは0始まりなので1加算
        
        movzx   bx, dh                          ; BX = ヘッド数
        inc     bx                              ;ヘッド数は0始まりなので1加算

        mov     [si + drive.cyln], cx           ; 構造体を使用したオフセットアドレスに
        mov     [si + drive.head], bx           ; 取得した情報を格納する
        mov     [si + drive.sect], ax           ;

        jmp     .10E
.10F:
        mov     ax, 0                           ; 情報取得に失敗した場合はAXに0を格納
.10E:

        ;---------------------------------------
        ; レジスタの復帰
        ;---------------------------------------
        pop     di
        pop     si
        pop     es
        pop     cx
        pop     bx

        ;---------------------------------------
        ; 【スタックフレームの破棄】
        ;---------------------------------------
        mov     sp, bp
        pop     bp

        ret