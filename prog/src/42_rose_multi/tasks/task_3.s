task_3:
        ;---------------------------------------
        ; 【スタックフレームの構築】
        ;---------------------------------------
        mov     ebp, esp                        ; EBP +  0| EBP（元の値）
                                                ; ----------------
        push    dword 0                         ; EBP -  4| x0 = 0 X座標原点
        push    dword 0                         ; EBP -  8| y0 = 0 Y座標原点
        push    dword 0                         ; EBP - 12| x = 0 X座標描画
        push    dword 0                         ; EBP - 16| x = 0 X座標描画
        push    dword 0                         ; EBP - 20| r = 0 角度

        ;---------------------------------------
        ; 初期化
        ;---------------------------------------
        mov     esi, 0x0010_7000                ; ESI = 描画パラメータ

        ;---------------------------------------
        ; タイトル表示
        ;---------------------------------------
        mov     eax, [esi + rose.x0]            ; EAX = 左上座標: X0
        mov     ebx, [esi + rose.y0]            ; EBX = 左上座標: Y0

        shr     eax, 3                          ; ESI = EAX / 8  X座標を文字位置に変換
        shr     ebx, 4                          ; EDI = EBX / 16 Y座標を文字位置に変換
        dec     ebx                             ; Y座標を1文字分上に移動
        mov     ecx, [esi + rose.color_s]       ; 文字色
        lea     edx, [esi + rose.title]         ; タイトル

        cdecl   draw_str, eax, ebx, ecx, edx    ; draw_str()

        ;---------------------------------------
        ; X軸の中点
        ;---------------------------------------
        mov     eax, [esi + rose.x0]            ; EAX = 左上座標: X0
        mov     ebx, [esi + rose.x1]            ; EBX = 右下座標: X1
        sub     ebx, eax                        ; EBX = X1 - X0
        shr     ebx, 1                          ; EBX /= 2
        add     ebx, eax                        ; EBX += X0
        mov     [ebp - 4], ebx                  ; x0 = EBX X座標原点

        ;---------------------------------------
        ; Y軸の中点
        ;---------------------------------------
        mov     eax, [esi + rose.y0]            ; EAX = 左上座標: Y0
        mov     ebx, [esi + rose.y1]            ; EBX = 右下座標: Y1
        sub     ebx, eax                        ; EBX = Y1 - Y0
        shr     ebx, 1                          ; EBX /= 2
        add     ebx, eax                        ; EBX += Y0
        mov     [ebp - 8], ebx                  ; y0 = EBX Y座標原点

        ;---------------------------------------
        ; X軸の描画
        ;---------------------------------------
        mov     eax, [esi + rose.x0]            ; EAX = 左上座標: X0
        mov     ebx, [ebp - 8]                  ; EBX = Y軸の原点
        mov     ecx, [esi + rose.x1]            ; ECX = 右下座標: X1

        cdecl   draw_line, eax, ebx, ecx, ebx, dword [esi + rose.color_x]
                                                ; X軸

        ;---------------------------------------
        ; Y軸の描画
        ;---------------------------------------
        mov     eax, [esi + rose.y0]            ; EAX = 左上座標: Y0
        mov     ebx, [ebp - 4]                  ; EBX = X軸の原点
        mov     ecx, [esi + rose.y1]            ; ECX = 右下座標: Y1

        cdecl   draw_line, ebx, eax, ebx, ecx, dword [esi + rose.color_y]
                                                ; Y軸

        ;---------------------------------------
        ; 枠の描画
        ;---------------------------------------
        mov     eax, [esi + rose.x0]            ; EAX = 左上座標: X0
        mov     ebx, [esi + rose.y0]            ; EBX = 左上座標: Y0
        mov     ecx, [esi + rose.x1]            ; ECX = 右下座標: X1
        mov     edx, [esi + rose.y1]            ; EDX = 右下座標: Y1

        cdecl   draw_rect, eax, ebx, ecx, edx, dword [esi + rose.color_z]
                                                ; 枠

        ;---------------------------------------
        ; 振幅をX軸の約95%とする
        ;---------------------------------------
        mov     eax, [esi + rose.x1]            ; EAX = 右下座標: X1
        sub     eax, [esi + rose.x0]            ; EAX -= X0座標
        shr     eax, 1                          ; EAX /= 2
        mov     ebx, eax                        ; EBX = EAX
        shr     ebx, 4                          ; EBX /= 16
        sub     eax, ebx                        ; EAX -= EBX

        ;---------------------------------------
        ; FPUの初期化（バラ曲線の初期化）
        ;---------------------------------------
        cdecl   fpu_rose_init, eax, dword [esi + rose.n], dword [esi + rose.d]

        ;---------------------------------------
        ; メインループ
        ;---------------------------------------
.10L:

        ;---------------------------------------
        ; 座標計算
        ;---------------------------------------
        lea     ebx, [ebp - 12]                 ; EBX = &x
        lea     ecx, [ebp - 16]                 ; ECX = &y
        mov     eax, [ebp - 20]                 ; EAX = r

        cdecl   fpu_rose_update, ebx, ecx, eax

        ;---------------------------------------
        ; 角度更新（r = r % 36000）
        ;---------------------------------------
        mov     edx, 0                          ; EDX = 0
        inc     eax                             ; EAX++
        mov     ebx, 360 * 100                  ; EBX = 36000
        div     ebx                             ; EDX = EDX:EAX % EBX
        mov     [ebp - 20], edx

        ;---------------------------------------
        ; ドット描画
        ;---------------------------------------
        mov     ecx, [ebp - 12]                 ; ECX = X座標
        mov     edx, [ebp - 16]                 ; EDX = Y座標

        add     ecx, [ebp - 4]                  ; ECX += X座標原点
        add     edx, [ebp - 8]                  ; EDX += Y座標原点

        mov     ebx, [esi + rose.color_f]       ; EBX = 描画色

        int     0x82

        ;---------------------------------------
        ; ウェイト
        ;---------------------------------------
        cdecl   wait_tick, 2

        ;---------------------------------------
        ; ドット描画（消去）
        ;---------------------------------------
        mov     ebx, [esi + rose.color_b]       ; EBX = 背景色
        int     0x82

        jmp     .10L

        ;---------------------------------------
        ; 描画パラメータ
        ;---------------------------------------
ALIGN 4, db 0
DRAW_PARAM:
.t3:
    istruc rose
        at  rose.x0,        dd      32          ; 左上座標: X0
        at  rose.y0,        dd      32          ; 左上座標: Y0
        at  rose.x1,        dd      208         ; 右下座標: X1
        at  rose.y1,        dd      208         ; 右下座標: Y1

        at  rose.n,         dd      2           ; 変数: n
        at  rose.d,         dd      1           ; 変数: d

        at  rose.color_x,   dd      0x0007      ; 描画色: X軸
        at  rose.color_y,   dd      0x0007      ; 描画色: Y軸
        at  rose.color_z,   dd      0x000F      ; 描画色: 枠
        at  rose.color_s,   dd      0x030F      ; 描画色: 文字
        at  rose.color_f,   dd      0x000F      ; 描画色: グラフ描画色
        at  rose.color_b,   dd      0x0003      ; 描画色: グラフ削除色

        at  rose.title,     db      "Task-3", 0 ; タイトル
    iend

.t4:
    istruc rose
        at  rose.x0,        dd      248         ; 左上座標: X0
        at  rose.y0,        dd      32          ; 左上座標: Y0
        at  rose.x1,        dd      424         ; 右下座標: X1
        at  rose.y1,        dd      208         ; 右下座標: Y1

        at  rose.n,         dd      3           ; 変数: n
        at  rose.d,         dd      1           ; 変数: d

        at  rose.color_x,   dd      0x0007      ; 描画色: X軸
        at  rose.color_y,   dd      0x0007      ; 描画色: Y軸
        at  rose.color_z,   dd      0x000F      ; 描画色: 枠
        at  rose.color_s,   dd      0x040F      ; 描画色: 文字
        at  rose.color_f,   dd      0x000F      ; 描画色: グラフ描画色
        at  rose.color_b,   dd      0x0004      ; 描画色: グラフ削除色

        at  rose.title,     db      "Task-4", 0 ; タイトル
    iend

.t5:
    istruc rose
        at  rose.x0,        dd      32          ; 左上座標: X0
        at  rose.y0,        dd      272         ; 左上座標: Y0
        at  rose.x1,        dd      208         ; 右下座標: X1
        at  rose.y1,        dd      448         ; 右下座標: Y1

        at  rose.n,         dd      2           ; 変数: n
        at  rose.d,         dd      6           ; 変数: d

        at  rose.color_x,   dd      0x0007      ; 描画色: X軸
        at  rose.color_y,   dd      0x0007      ; 描画色: Y軸
        at  rose.color_z,   dd      0x000F      ; 描画色: 枠
        at  rose.color_s,   dd      0x050F      ; 描画色: 文字
        at  rose.color_f,   dd      0x000F      ; 描画色: グラフ描画色
        at  rose.color_b,   dd      0x0005      ; 描画色: グラフ削除色

        at  rose.title,     db      "Task-5", 0 ; タイトル
    iend

.t6:
    istruc rose
        at  rose.x0,        dd      248         ; 左上座標: X0
        at  rose.y0,        dd      272         ; 左上座標: Y0
        at  rose.x1,        dd      424         ; 右下座標: X1
        at  rose.y1,        dd      448         ; 右下座標: Y1

        at  rose.n,         dd      4           ; 変数: n
        at  rose.d,         dd      6           ; 変数: d

        at  rose.color_x,   dd      0x0007      ; 描画色: X軸
        at  rose.color_y,   dd      0x0007      ; 描画色: Y軸
        at  rose.color_z,   dd      0x000F      ; 描画色: 枠
        at  rose.color_s,   dd      0x060F      ; 描画色: 文字
        at  rose.color_f,   dd      0x000F      ; 描画色: グラフ描画色
        at  rose.color_b,   dd      0x0006      ; 描画色: グラフ削除色

        at  rose.title,     db      "Task-6", 0 ; タイトル
    iend

fpu_rose_init:
        ;---------------------------------------
        ; 【スタックフレームの構築】
        ;---------------------------------------
                                                ; EBP + 16| d 角速度
                                                ; EBP + 12| n 花弁の枚数（nが偶数: 2n枚, 奇数: n枚）
                                                ; EBP +  8| A 振幅
                                                ; --------------------
                                                ; EBP +  4| EIP（戻り番地）
        push    ebp                             ; EBP +  0| EBP（元の値）
        mov     ebp, esp                        ; --------------------
        push    dword 180                       ; EBP -  4| dword i = 180

        ;---------------------------------------
        ; FPUスタックの初期化
        ; ST0: A
        ; ST1: k = n /d
        ; ST2: r = π / 180
        ;---------------------------------------
        fldpi                                   ; π をスタックに積む
        fidiv   dword [ebp - 4]                 ; r を算出
        fild    dword [ebp + 12]                ; n をスタックに積む
        fidiv   dword [ebp + 16]                ; k を算出
        fild    dword [ebp + 8]                 ; A をスタックに積む

        ;---------------------------------------
        ; 【スタックフレームの破棄】
        ;---------------------------------------
        mov     esp, ebp
        pop     ebp

        ret

fpu_rose_update:
        ;---------------------------------------
        ; 【スタックフレームの構築】
        ;---------------------------------------
                                                ; EBP + 16| t 角度
                                                ; EBP + 12| py 計算したY座標を格納するアドレス
                                                ; EBP +  8| px 計算したX座標を格納するアドレス
                                                ; --------------------
                                                ; EBP +  4| EIP（戻り番地）
        push    ebp                             ; EBP +  0| EBP（元の値）
        mov     ebp, esp                        ; --------------------

        ;---------------------------------------
        ; 【レジスタの保存】
        ;---------------------------------------
        push    eax
        push    ebx

        ;---------------------------------------
        ; X/Y座標の保存先を設定
        ;---------------------------------------
        mov     eax, [ebp + 8]                  ; EAX = pX X座標へのポインタ
        mov     ebx, [ebp + 12]                 ; EBX = pY Y座標へのポインタ

        ;---------------------------------------
        ; t（角度）から座標を計算する
        ; FPUスタックの初期化が完了しているものとする
        ;---------------------------------------
        fild    dword [ebp + 16]                ; t をFPUスタックに積む
        fmul    st0, st3                        ; ST0 *= ST3 'Θ = r * t'
        fld     st0                             ; ST0の値（Θ）をFPUスタックに積む

        fsincos                                 ; ST0の値からsin, cosを算出する
                                                ; sin(Θ)はST0への代入で、cos(Θ)はそのうえに積む

        fxch    st2                             ; ST0 と ST2 を入れ替える
        fmul    st0, st4                        ; ST0 *= ST4     'k * Θ'
        fsin                                    ; ST0 = sin(ST0) 'sin(kΘ)'
        fmul    st0, st3                        ; ST0 *= ST3     'A * sin(kΘ)'

        fxch    st2                             ; ST0 と ST2 を入れ替える
        fmul    st0, st2                        ; ST0 *= ST2 'x = A * sin(kΘ) * cos(Θ)'
        fistp   dword [eax]                     ; ST0（x）をポップしEAXに格納

        fmulp   st1, st0                        ; ST1 *= ST0 'y = A * sin(kΘ) * cos(Θ)' をした後でST0をポップ
        fchs                                    ; Y座標は増加すると画面上は下に向かうため ST0（y） の符号反転
        fistp   dword [ebx]                     ; ST0（-y）をポップしEBXに格納

        ;---------------------------------------
        ; 【レジスタの復帰】
        ;---------------------------------------
        pop     ebx
        pop     eax

        ;---------------------------------------
        ; 【スタックフレームの破棄】
        ;---------------------------------------
        mov     esp, ebp
        pop     ebp

        ret