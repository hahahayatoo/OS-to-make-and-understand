int_timer:
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
        ; TICK
        ;---------------------------------------
        inc     dword [TIMER_COUNT]             ; TIMER_COUNT++ 割り込み回数の更新

        ;---------------------------------------
        ; 割り込み終了コマンドの送信
        ;---------------------------------------
        outp    0x20, 0x20                      ; マスタPICにEOIコマンド送信

        ;---------------------------------------
        ; タスクの切り替え
        ; 現在のタスクによってタスクを切り替える
        ;---------------------------------------
        str     ax                              ; AX = TR 現在のタスクレジスタ
        cmp     ax, SS_TASK_0                   ;  case SS_TASK_0: タスク1に切り替え
        je      .11L                            ;
        cmp     ax, SS_TASK_1                   ;  case SS_TASK_1: タスク2に切り替え
        je      .12L                            ;
        cmp     ax, SS_TASK_2                   ;  case SS_TASK_2: タスク3に切り替え
        je      .13L                            ;
        cmp     ax, SS_TASK_3                   ;  case SS_TASK_3: タスク4に切り替え
        je      .14L                            ;
        cmp     ax, SS_TASK_4                   ;  case SS_TASK_4: タスク5に切り替え
        je      .15L                            ;
        cmp     ax, SS_TASK_5                   ;  case SS_TASK_5: タスク6に切り替え
        je      .16L                            ;
                                                ;
        jmp     SS_TASK_0:0                     ;         default: タスク0に切り替え
        jmp     .10E

.11L:
        jmp     SS_TASK_1:0
        jmp     .10E

.12L:
        jmp     SS_TASK_2:0
        jmp     .10E

.13L:
        jmp     SS_TASK_3:0
        jmp     .10E

.14L:
        jmp     SS_TASK_4:0
        jmp     .10E

.15L:
        jmp     SS_TASK_5:0
        jmp     .10E

.16L:
        jmp     SS_TASK_6:0
        jmp     .10E

.10E:
        ;---------------------------------------
        ; 【レジスタの復帰】
        ;---------------------------------------
        pop     es
        pop     ds
        popa

        iret                                    ; 割り込み処理の終了

ALIGN   4, db 0
TIMER_COUNT:    dd 0