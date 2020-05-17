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
        SP_TASK_3           equ     STACK_BASE + (STACK_SIZE * 4)
                                                            ; タスク3のスタックポインタの初期値
        SP_TASK_4           equ     STACK_BASE + (STACK_SIZE * 5)
                                                            ; タスク4のスタックポインタの初期値
        SP_TASK_5           equ     STACK_BASE + (STACK_SIZE * 6)
                                                            ; タスク5のスタックポインタの初期値
        SP_TASK_6           equ     STACK_BASE + (STACK_SIZE * 7)
                                                            ; タスク6のスタックポインタの初期値

        PARAM_TASK_4        equ     0x0010_8000             ; 描画パラメータ：タスク4用
        PARAM_TASK_5        equ     0x0010_9000             ; 描画パラメータ：タスク4用
        PARAM_TASK_6        equ     0x0010_A000             ; 描画パラメータ：タスク4用

        CR3_BASE            equ     0x0010_5000             ; ページ変換テーブル：タスク3用
                                                            ; （0x0010_5000から4Kバイトの位置にページディレクトリを配置し、
                                                            ; その直後の4Kバイトの位置にページテーブルを配置する）

        CR3_TASK_4          equ     0x0020_0000             ; ページ変換テーブル：タスク4用
        CR3_TASK_5          equ     0x0020_2000             ; ページ変換テーブル：タスク5用
        CR3_TASK_6          equ     0x0020_4000             ; ページ変換テーブル：タスク6用

        FAT_SIZE            equ     (1024 * 128)            ; FAT-1/2
        ROOT_SIZE           equ     (1024 * 16)             ; ルートディレクトリ領域

        ENTRY_SIZE          equ     32                      ; エントリサイズ

        FAT_OFFSET          equ     (BOOT_SIZE + KERNEL_SIZE)
        FAT1_START          equ     (KERNEL_SIZE)
        FAT2_START          equ     (FAT1_START + FAT_SIZE)
        ROOT_START          equ     (FAT2_START + FAT_SIZE)
        FILE_START          equ     (ROOT_START + FAT_SIZE)

        ATTR_VOLUME_ID      equ     0x08                    ; FAT ディレクトリエントリの属性（ボリュームラベル）
        ATTR_ARCHIVE        equ     0x20                    ; FAT ディレクトリエントリの属性（アーカイブ）