; Макросы и определения

;------- Константы
.equ num_mode = 0x02
.equ sec_part = 8
.equ OCR2A_val = 127
.equ TimCntVal = 32
;-------

;------- Определения
.def lcd_X = r2	; Текущие координаты
.def lcd_Y = r3
.def bkg_color = r4 ; Цвета фона и текста
.def frg_color = r5
.def lcd_mx = r6	; множители масштабирования
.def lcd_my = r7

.def kbd = r8	; Битовая маска нажатых кнопок
.def kbd_prev = r12	; Битовая маска нажатых кнопок предыдущего такта
.def kbd_press = r13 ; Нажатые кнопки (из 1 в 0)
.def kbd_release = r14 ; Отпущенные кнопки (из 1 в 0)

.def sec_part_cnt = r10
.def refresh = r23	; Регистр с флагами обновления
; Биты:
; 0 - надо обновить минуты
; 1 - часы
; 2 - число/день недели
; 3 - месяц
; 4 - год
; т.к. рисование идет не быстрее чем раз в секунду, то секунды обновляются каждый такт и так

.def led_timer=r9	; Таймер подсветки (0.1 секундные интерваллы)
.def mode=r19	; Режим работы: 0 - часы (отображение даты-времени), 1 - настройка даты, времени,
				; 2 - таймер, 3 - секундомер 
.def mode_tmp=r24 ; Для режима 1 - здесь хранится текущий редактируемый параметр (час, минута, секунда и т.д.)
				  ; 0 - час, 1 - минута, 2 - секунда, 3 - число, 4 - день недели, 5 - месяц, 6 - год (пока так)
				  ; этот же параметр и указывает какая часть рисуемой даты-времени будет подсвечена

.def tmp=r16	; Temp
.def tmp1=r17
.def tmp2=r18
;-------

;------- Макросы
.macro CS_LOW
	cbi PORTB, 1
	nop
.endm
.macro CS_HIGH
	sbi PORTB, 1
	nop
.endm
.macro LED_ON
	sbi PORTC, 1
	nop
.endm
.macro LED_OFF
	cbi PORTC, 1
	nop
.endm
.macro CMD_SET
	cbi PORTB, 0
	nop
.endm
.macro DATA_SET
	sbi PORTB, 0
	nop
.endm
.macro LCD_RESET_LOW
	cbi PORTC, 0
	nop
.endm
.macro LCD_RESET_HIGH
	sbi PORTC, 0
	nop
.endm
.macro LAPZ
	ldi ZH, high(@0 << 1)
	ldi ZL, low(@0 << 1)
.endm
.macro LAPX
	ldi XH, high(@0 << 1)
	ldi XL, low(@0 << 1)
.endm
.macro LAPY
	ldi YH, high(@0 << 1)
	ldi YL, low(@0 << 1)
.endm
.macro LASZ
	ldi ZH, high(@0)
	ldi ZL, low(@0)
.endm
.macro LASX
	ldi XH, high(@0)
	ldi XL, low(@0)
.endm
.macro LASY
	ldi YH, high(@0)
	ldi YL, low(@0)
.endm
.macro BEEP_ON
	sbi PORTC, 2
	nop
.endm
.macro BEEP_OFF
	cbi PORTC, 2
	nop
.endm
;-------
