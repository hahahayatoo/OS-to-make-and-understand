        BOOT_LOAD           equ     0x7C00                  ; ブートプログラムのロード位置

        BOOT_SIZE           equ     (1024 * 8)              ; ブートコードサイズ
        SECT_SIZE           equ     (512)                   ; セクタサイズ
        BOOT_END            equ     (BOOT_LOAD + BOOT_SIZE)

        E820_RECORD_SIZE    equ     20                      ; BIOSで取得したメモリ情報を格納する領域のサイズ

        VECT_BASE           equ     0x0010_0000             ; 0010_0000:0010_07FF

        KERNEL_LOAD         equ     0x0010_1000
        KERNEL_SIZE         equ     (1024 * 8)              ; カーネルサイズ

        BOOT_SECT           equ     (BOOT_SIZE / SECT_SIZE) ; ブートプログラムのセクタ数
        KERNEL_SECT         equ     (KERNEL_SIZE / SECT_SIZE)

        STACK_BASE          equ     0x0010_3000             ; タスク用スタックエリア
        STACK_SIZE          equ     1024                    ; スタックサイズ

        SP_TASK_0           equ     STACK_BASE + (STACK_SIZE * 1)
                                                            ; タスク0のスタックポインタの初期値
        SP_TASK_1           equ     STACK_BASE + (STACK_SIZE * 2)
                                                            ; タスク1のスタックポインタの初期値
        SP_TASK_2           equ     STACK_BASE + (STACK_SIZE * 3)
                                                            ; タスク2のスタックポインタの初期値