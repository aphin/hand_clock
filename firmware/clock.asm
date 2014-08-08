; Фирмварь для наручных часов на ATMEGA48PA, дисплей Siemens C60, 6 кнопок
; TODO
; 1. Сделать более наглядную настройку времени (с подсветкой редактируемой величины)
; 2. Сделать регистр флагов обновления, чтобы не выполнять лишние рисования


;#define DEBUG

; Для себя:
; Регистры GPIORx
; GPIOR0.0 - флаг переноса BCD
; GPIOR0.1 - используется как вспомогательный флаг при опросе клавиатуры
; GPIOR0.2 - устанавливается в 1 каждую десятую долю секунды
; GPIOR0.3 - ...каждую секунду
; GPIOR0.4 - ...минуту
; GPIOR0.5 - ...час
; GPIOR0.6 - ...день
; GPIOR0.7 - ...месяц

.nolist
.include "C:\Program Files\Atmel\AVR Tools\AvrAssembler2\Appnotes\m48PAdef.inc"
.list

.include "definitions.inc"

.cseg ; Сегмент кода
.org 0

rjmp Start
; Прерывания
rjmp INT0r
rjmp INT1r
rjmp PCINT0r
rjmp PCINT1r
rjmp PCINT2r
rjmp WDT
rjmp T2_COMPA
rjmp T2_COMPB
rjmp T2_OVF
rjmp T1_CAPT
rjmp T1_COMPA
rjmp T1_COMPB
rjmp T1_OVF
rjmp T0_COMPA
rjmp T0_COMPB
rjmp T0_OVF
rjmp SPI_STC
rjmp USART_RX
rjmp USART_UDRE
rjmp USART_TX
rjmp AnalogDC
rjmp EE_RDY
rjmp AnalogCMP
rjmp TWI
rjmp SPM_RDY

Start:

.include "init.inc"
	
	rcall LCD_IdleOn

main:

	sleep

; Ждем обновления TC2 как в апп-нотах по RTC
	ldi tmp, 0x00
	sts OCR2B, tmp
wtr:
	lds tmp, ASSR
	sbrc tmp, OCR2BUB
	rjmp wtr

; обработка звука
	tst tmp2
	brne m_cont
	BEEP_OFF
m_cont:
	cpi mode, 0x00
	brne m_mode1

; Режим 0 - рисуем часы, подсветка 5 секунд по нажатию, режим Idle
	sbis GPIOR0, 3	; Выполняем рисование каждую секунду
	rjmp kbd_hand

	ldi tmp, 3
	mov lcd_x, tmp
	ldi tmp, 28
	mov lcd_y, tmp
	rcall LCD_DrawTime
	rcall LCD_DrawDate
	rjmp kbd_hand
; Режим 1 - рисуем дату-время, подсветка включена, режим Normal, рисуем с интервалом 0.1 сек
m_mode1:
	cpi mode, 0x01
	brne m_mode2
	sbis GPIOR0, 2
	rjmp kbd_hand
	
;	ldi refresh, 0b00011111

	ldi tmp, 3
	mov lcd_x, tmp
	ldi tmp, 28
	mov lcd_y, tmp

	rcall LCD_DrawTime
	rcall LCD_DrawDate
	
	rjmp kbd_hand
m_mode2:				

kbd_hand:
; звук при нажатии на кнопки
	mov tmp, kbd_press
	ori tmp, 0b11000000
	cpi tmp, 0xFF
	breq kbd_hcont
	BEEP_ON
	ldi tmp2, 5
kbd_hcont:
	cpi mode, 0x00
	brne m_kbd_mode1
; Обработчик кнопок режима 0
	sbrc kbd_press, 3
	rjmp nx_b
	LED_ON
	rcall LCD_IdleOff
	ldi tmp, 50
	mov led_timer, tmp
nx_b:
	sbrc kbd_press, 5
	rjmp nx_b1
	inc mode
	rcall LCD_Clear
	rcall LCD_IdleOff
	ori refresh, 0b00011111
	LED_ON
nx_b1:
	rjmp main
m_kbd_mode1:
; Обработчик кнопок режима 1
	cpi mode, 0x01
	breq m_kbd_mode1_cont
	rjmp m_kbd_mode2
m_kbd_mode1_cont:
	sbrc kbd_press, 5
	rjmp nx_b_m1
	clr mode
	rcall LCD_Clear
	rcall LCD_IdleOn
	ori refresh, 0b00011111
	LED_OFF
nx_b_m1:	; Кнопки 4, 1 (средние слева и справа соответственно) - выбор редактируемой величины
	sbrc kbd_press, 4
	rjmp nx_b1_m1
	ori refresh, 0b00011111
	tst mode_tmp
	breq m_mdtmp_max_set
	dec mode_tmp
	rjmp nx_b1_m1
m_mdtmp_max_set:
	ldi mode_tmp, 0x06
nx_b1_m1:
	sbrc kbd_press, 1
	rjmp nx_b2_m1
	ori refresh, 0b00011111
	inc mode_tmp
	cpi mode_tmp, 0x07
	brne nx_b2_m1
	clr mode_tmp
nx_b2_m1: ; Кнопки 0, 2 (справа верхняя и нижняя соответственно) - изменение выбранной величины
	sbrs kbd_press, 0
	rjmp nx_b2_cont
	sbrs kbd_press, 2
	rjmp nx_b2_cont
	rjmp nx_b3_m1

nx_b2_cont:
	ori refresh, 0b00011111
	LAPZ corr_table	; Таблица адресов корректируемых величин (для удобства)
	rcall mt_offset

	lpm tmp, Z+
	lpm tmp1, Z	; tmp1:tmp - адрес редактируемой величины
	mov ZH, tmp1
	mov ZL, tmp

	cli	; Отключаем прерывания, т.к. меняем время
	sbrc kbd_press, 0	; кнопка 1 - инкремент
	rjmp val_dec
	rcall BCD_Inc	; Увеличиваем значение в памяти 
	rjmp val_check
val_dec:
	ldi tmp, 0x99
	rcall BCD_Add	; аналогично BCD_Dec
val_check:
	ld tmp, Z	; в tmp число после модификации
	push tmp
	cpi mode_tmp, 0x02
	breq sec_corr
	cpi mode_tmp, 0x03
	breq day_corr
	cpi mode_tmp, 0x06
	breq no_corr
hr_mn_mo:
; для часов, минут и месяца
	pop tmp
	push ZH
	push ZL
	LAPZ corr_max_value
	rcall mt_offset
	lpm tmp1, Z	; следующее после максимального значение редактируемого параметра
	pop ZL
	pop ZH
	cp tmp, tmp1
	brlo no_corr	; коррекция не нужна
	clr tmp
	st Z, tmp
	rjmp no_corr
sec_corr:
; для секунд (тупо в лоб обнуляем)
	clr tmp
	st Z, tmp	; обнуляем число секунд
	sbiw ZL, 0x01
	st Z, tmp	; обнуляем чило десятых долей секунд
	rcall Tmp_to_TCNT2	; сброс счетчика таймера
	LASZ sec_cnt
	st Z, tmp	; обнуляем счетчик интервала 0.1 сек
	rjmp no_corr
day_corr:
; в стеке лежит скорректированное текущее число	
	push ZH	; а ZH:ZL указывает на него в оперативной памяти
	push ZL
	LASZ month
	ld tmp, Z	; месяц
	sbrc tmp, 4
	subi tmp, 6	; в tmp номер месяца в binary
	LAPZ month_len
	add ZL, tmp
	clr tmp
	adc ZH, tmp
	lpm tmp1, Z	; теперь тут число дней в месяце
	pop ZL
	pop ZH
	pop tmp	; tmp - текущее число
	cpi tmp, 0x00
	breq day_cr1
	cp tmp, tmp1
	brlo no_corr
	ldi tmp, 0x01
	rjmp day_cr2
day_cr1:
	mov tmp, tmp1
	dec tmp ; Здесь можно и без BCD_Inc, т.к. переполнения не будет
day_cr2:
	st Z, tmp
no_corr:
	sei	; Включаем прерывания обратно
nx_b3_m1:
	rjmp main

m_kbd_mode2:
; Обработчик кнопок режима 2
	sbrc kbd_press, 5
	rjmp nx_b_m2
	clr mode
	rcall LCD_Clear
	rcall LCD_IdleOn
	LED_OFF
nx_b_m2:
	rjmp main

; для экономии flash расчет смещения для mode_tmp вынесен в отдельную подпрограмму
mt_offset:
	push mode_tmp
	lsl mode_tmp
	add ZL, mode_tmp
	clr mode_tmp
	adc ZH, mode_tmp
	pop mode_tmp
	ret
;-------- Конец основного цикла

INT0r:
INT1r:
PCINT0r:
PCINT1r:
PCINT2r:
WDT:
T2_OVF:
T2_COMPB:
T1_CAPT:
T1_COMPA:
T1_COMPB:
T1_OVF:
T0_COMPA:
T0_COMPB:
T0_OVF:
SPI_STC:
USART_RX:
USART_UDRE:
USART_TX:
AnalogDC:
EE_RDY:
AnalogCMP:
TWI:
SPM_RDY:
	reti

Tmp_to_TCNT2:
	push tmp
	sts TCNT2, tmp
wl_tcnt_z:
	lds tmp, ASSR
	sbrc tmp, 4
	rjmp wl_tcnt_z	
	pop tmp
	ret

T2_COMPA:		; обработчик прерывания от таймера
	push tmp
	in tmp, SREG
	push tmp

	push ZH
	push ZL

	in tmp, GPIOR0
	andi tmp, 0b00000011
	out GPIOR0, tmp			; сбрасываем флаги временных событий

	rcall KBD_Check ; Скан кнопок
	
	ldi ZH, high(sec_duration)
	ldi ZL, low(sec_duration)
	ld tmp, Z
	inc sec_part_cnt
	cp sec_part_cnt, tmp
	brne t2_end

; Прошла 0.1 секунды
	sbi GPIOR0, 2	; Установили флаг
	
	rcall Time_Date_Inc	; Инкремент даты-времени
	clr sec_part_cnt	; Очистили счетчик
; Определяем, в каком режиме работают часы
	cpi mode, 0x00
	brne tc2_mode1
; Режим 0 - управление подсветкой
	tst led_timer		; Работа с подсветкой
	breq t2_end
	dec led_timer
	brne t2_end
	LED_OFF
	rcall LCD_IdleOn
	rjmp t2_end

tc2_mode1:
; Режим 1 - настройка даты, времени, корректировок
	nop

t2_end:
	tst tmp2
	breq t2_out1
	dec tmp2
t2_out1:
	pop ZL
	pop ZH
t2_out:
	pop tmp
	out SREG, tmp
	pop tmp
	reti

;-------- Подпрограммы
KBD_Check:
	push tmp
	sbis GPIOR0, 1
	rjmp row0_active
; row1 active
	in tmp, PIND
	andi tmp, 0b01110000
	lsr tmp
	or kbd, tmp
	ori tmp, 0b11000111
	and kbd, tmp
	sbi PORTD, 2
	nop
	cbi PORTD, 3
	nop
	cbi GPIOR0, 1
	rjmp kbd_end
row0_active:
	in tmp, PIND
	andi tmp, 0b01110000
	lsr tmp
	lsr tmp
	lsr tmp
	lsr tmp
	or kbd, tmp
	ori tmp, 0b11111000
	and kbd, tmp
	sbi PORTD, 3
	nop
	cbi PORTD, 2
	nop
	sbi GPIOR0, 1
kbd_end:
	ldi tmp, 0b00111111
	and kbd, tmp
	cp kbd, tmp
	brne kbd_ret
	ldi tmp, 0x80
	or kbd,tmp	; установлен флаг нажатия (для удобства)
kbd_ret:
; Здесь формируем kbd_press и kbd_release
	mov tmp, kbd
	eor tmp, kbd_prev	; tmp - содержит 1-цы если кнопка поменяла свое состояние
	ori tmp, 0b11000000	; лишнее отсекаем
	mov kbd_press, kbd_prev	; здесь 0 если кнопка нажата в прошлом такте
	mov kbd_release, kbd	; здесь 0 если кнопка нажата в этом такте
	and kbd_press, tmp ; если кнопка поменяла свое значение и она нажата в этом такте, то в нужном бите будет 1 (кнопка нажата)
	and kbd_release, tmp ; если кнопка была нажата в прошлом такте, но поменяла свое значение, то в нужном бите будет 1 (кнопка отпущена)
	com kbd_press
	com kbd_release
	mov kbd_prev, kbd	; настоящее значение теперь предыдущее

	pop tmp
	ret
;----------------------
LCD_DrawTime:
	push ZH
	push ZL
	push tmp
	push tmp1

	ldi tmp, 2
	mov lcd_mx, tmp
	ldi tmp, 3
	mov lcd_my, tmp
	ldi tmp1, 0xFF

	sbrs refresh, 1
	rjmp drw_clk_minute_skip
	andi refresh, 0b11111101
	LASZ hour	; рисуем часы
	ld tmp, Z
	
	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_clk_hrd
	cpi mode_tmp, 0x00
	brne drw_clk_hrd
	rcall Exch_bkg_frg
drw_clk_hrd:
	rcall LCD_DrawBCD
	pop frg_color
	pop bkg_color
	ldi tmp,':'
	rcall LCD_DrawChar
	rjmp drw_clk_minute
drw_clk_minute_skip:
	ldi tmp, 32
	add lcd_x, tmp
drw_clk_minute:
	sbrs refresh, 0
	rjmp drw_clk_sec_skip
	andi refresh, 0b11111110
	ldi tmp, 16
	add lcd_x, tmp
	LASZ minute
	ld tmp, Z
	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_clk_mnd
	cpi mode_tmp, 0x01
	brne drw_clk_mnd
	rcall Exch_bkg_frg
drw_clk_mnd:
	rcall LCD_DrawBCD
	pop frg_color
	pop bkg_color
	rjmp drw_clk_sec
drw_clk_sec_skip:
	ldi tmp, 32+16
	add lcd_x, tmp
drw_clk_sec:	; рисуем секунды
	ldi tmp, 1
	mov lcd_mx, tmp
	mov lcd_my, tmp
	ldi tmp, 14
	add lcd_y, tmp

	LASZ second
	ld tmp, Z
	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_clk_sed
	cpi mode_tmp, 0x02
	brne drw_clk_sed
	rcall Exch_bkg_frg
drw_clk_sed:
	rcall LCD_DrawBCD
	pop frg_color
	pop bkg_color

	pop tmp1
	pop tmp
	pop ZL
	pop ZH
	ret
;---------------------
Time_Date_Inc:
	push ZH
	push ZL
	push tmp

	ldi ZH, high(dsecond)
	ldi ZL, low(dsecond)
	rcall BCD_Inc	; доли секунды (задаются константой sec_part)
	ld tmp, Z
	cpi tmp, sec_part
	breq tdi_cnt1
	rjmp tdi_end
tdi_cnt1:
	clr tmp
	sbi GPIOR0, 3
	st Z+, tmp		
	rcall BCD_Inc	; секунды
	ld tmp, Z
	cpi tmp, 0x60
	breq tdi_cnt2
	rjmp tdi_end
tdi_cnt2:
	clr tmp
	sbi GPIOR0, 4
	ori refresh, 0b00000001
	st Z+, tmp
	rcall BCD_Inc ; минуты
	ld tmp, Z
	cpi tmp, 0x60
	breq tdi_cnt3
	rjmp tdi_end
tdi_cnt3:
	clr tmp
	sbi GPIOR0, 5
	ori refresh, 0b00000010
	st Z+, tmp
	rcall BCD_Inc ; часы
	ld tmp, Z
	cpi tmp, 0x24
	brne tdi_end
	clr tmp
	sbi GPIOR0, 6
	ori refresh, 0b00000100
	st Z+, tmp
	
	push ZH	; дни недели
	push ZL
	ldi ZH, high(day_of_week)
	ldi ZL, low(day_of_week)
	ld tmp, Z
	inc tmp
	cpi tmp, 0x07
	brne tdi_cnt
	clr tmp
tdi_cnt:
	st Z, tmp
	pop ZL
	pop ZH

	rcall BCD_Inc ; дни
	ld tmp, Z
; получаем число дней в месяце в регистр tmp1
	push tmp1
	push ZH
	push ZL
	push tmp
	ldi ZH, high(month)
	ldi ZL, low(month)
	ld tmp, Z	; в tmp - номер месяца в формате BCD
	sbrc tmp, 4
	subi tmp, 6	; в tmp номер месяца в binary
	dec tmp
	ldi ZH, high(month_len<<1)
	ldi ZL, low(month_len<<1)
	add ZL, tmp
	ldi tmp, 0x00
	adc ZH, tmp
	lpm tmp1, Z
	pop tmp
	pop ZL
	pop ZH
	cp tmp, tmp1
	pop tmp1
	brne tdi_end
	ldi tmp, 0x01
	sbi GPIOR0, 7
	ori refresh, 0b00001000
	st Z+, tmp
	rcall BCD_Inc ; месяцы
	ld tmp, Z
	cpi tmp, 0x13
	brne tdi_end
	ori refresh, 0b00010000
	ldi tmp, 0x01
	st Z+, tmp
	rcall BCD_Inc ; годы
	sbis GPIOR0, 0
	rjmp tdi_end
	adiw ZL, 0x01
	rcall BCD_Inc
tdi_end:
	pop tmp
	pop ZL
	pop ZH
	ret
;----------------------
BCD_Add:
; in: Z - указывает на BCD число в памяти
;     tmp - второе слагаемое (BCD)
; out: число по адресу Z
; GPIOR0(bit0) - BCD carry
	
	push tmp1
	push tmp

	cbi GPIOR0, 0
	ld tmp1, Z
	add tmp1, tmp
	brhs lsd_correct
	push tmp1
	andi tmp1, 0x0F
	cpi tmp1, 0x0A
	pop tmp1
	brlo msd
lsd_correct:
	ldi tmp, 0x06
	add tmp1, tmp
msd:
	push tmp1
	andi tmp1, 0xF0
	cpi tmp1, 0xA0
	pop tmp1
	brlo bcd_end
	ldi tmp, 0x60
	add tmp1, tmp
	brcc bcd_end
	sbi GPIOR0, 0 
bcd_end:
	st Z, tmp1

	pop tmp
	pop tmp1	
	ret
;-------------------
BCD_Inc:
; in: Z - указывает на BCD число в памяти
; out: число по адресу Z
	push tmp
	ldi tmp, 0x01
	rcall BCD_Add
	pop tmp
	ret
;-------------------
Send_SPI:
SPI_Send:
	push tmp
	out SPDR, tmp
#ifndef DEBUG
spi_wait:
	in tmp, SPSR
	sbrs tmp, SPIF
	rjmp spi_wait
#endif
	pop tmp
	ret	
;--------------------
delay_10us:
	push tmp
	ldi tmp, 24

delay_loop:
	dec tmp
	brne delay_loop

	pop tmp
	ret
;--------------------
delay_100ms:
#ifndef DEBUG
	ldi tmp2, 16
d100_w:
	cpi tmp2, 0x00
	brne d100_w
#endif
	ret
;--------------------
delay_10ms:
#ifndef DEBUG
	ldi tmp2, 2
d10_w:
	cpi tmp2, 0x00
	brne d10_w
#endif
	ret
;--------------------
LCD_DrawDate:
	push ZH
	push ZL
	push tmp
	push tmp1

	ldi tmp1, 0xFF

	ldi tmp, 1
	mov lcd_mx, tmp
	mov lcd_my, tmp

	ldi tmp, 0x05
	mov lcd_y, tmp

	LASZ day

	sbrs refresh, 2
	rjmp drw_dat_end	; если не надо обновить день, то и "автоматом" не надо обновить год, месяц и день недели

	andi refresh, 0b11111011
	mov lcd_x, tmp ; риусем число
	ld tmp, Z

	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_dat_day
	cpi mode_tmp, 0x03
	brne drw_dat_day
	rcall Exch_bkg_frg
drw_dat_day:
	rcall LCD_DrawBCD
	pop frg_color
	pop bkg_color

	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_dat_dayw
	cpi mode_tmp, 0x04
	brne drw_dat_dayw
	rcall Exch_bkg_frg
drw_dat_dayw:
	rcall LCD_DrawDayOfWeek
	pop frg_color
	pop bkg_color

	ldi tmp, 0x05
	mov lcd_y, tmp
	LASZ day

	sbrs refresh, 3
	rjmp drw_dat_end

	andi refresh, 0b11110111
	ldi tmp, 0x05+(0x08*3)
	mov lcd_x, tmp

	adiw ZL, 0x01
	ld tmp, Z+
	sbrc tmp, 4
	subi tmp, 6	; в tmp номер месяца в binary
	lsl tmp
	lsl tmp
	push ZH
	push ZL
	LAPZ month_names
	add ZL, tmp
	ldi tmp, 0x00
	adc ZH, tmp	; Z указывает на название месяца

	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_dat_mon
	cpi mode_tmp, 0x05
	brne drw_dat_mon
	rcall Exch_bkg_frg
drw_dat_mon:
	rcall LCD_DrawStringPM
	pop frg_color
	pop bkg_color
	pop ZL
	pop ZH

	sbrs refresh, 4
	rjmp drw_dat_end

	andi refresh, 0b11101111
	ldi tmp, 0x05+(0x08*7)
	mov lcd_x, tmp
	adiw ZL, 0x01
	ld tmp, Z
	push bkg_color
	push frg_color
	cpi mode, 0x01
	brne drw_dat_year
	cpi mode_tmp, 0x06
	brne drw_dat_year
	rcall Exch_bkg_frg
drw_dat_year:
	rcall LCD_DrawBCD
	sbiw ZL, 0x01
	ld tmp, Z
	rcall LCD_DrawBCD
	pop frg_color
	pop bkg_color
drw_dat_end:
	pop tmp1
	pop tmp
	pop ZL
	pop ZH
	ret
;--------------------
LCD_DrawDayOfWeek:
	push tmp1
	LASZ day_of_week 	; Рисуем день недели
	ld tmp, Z

	clr tmp1
	LAPZ week_day_center_coo
	add ZL, tmp
	adc ZH, tmp1
	lpm tmp1, Z

	mov lcd_x, tmp1
	ldi tmp1, 60
	mov lcd_y, tmp1

	LAPZ week_day_table
	lsl tmp
	add ZL, tmp
	clr tmp
	adc ZH, tmp
	lpm tmp, Z+
	lpm tmp1, Z
	mov ZL, tmp
	mov ZH, tmp1
	rcall LCD_DrawStringPM
	pop tmp1
	ret
;--------------------
.include "Sie_c60.inc"	; Siemens C60 routines

;-------- Данные

.include "CP866.inc"	; 8x8 font

month_len:
	.db 0x32,0x29,0x32,0x31,0x32,0x31,0x32,0x32,0x31,0x32,0x31,0x32

; Символьные константы
month_names:
	.db "ЯНВ",0x00
	.db "ФЕВ",0x00
	.db "МАР",0x00
	.db "АПР",0x00
	.db "МАЙ",0x00
	.db "ИЮН",0x00
	.db "ИЮЛ",0x00
	.db "АВГ",0x00
	.db "СЕН",0x00
	.db "ОКТ",0x00
	.db "НОЯ",0x00
	.db "ДЕК",0x00

week_day_names:
mon:	.db "ПОНЕДЕЛЬНИК",0x00
tue:	.db "ВТОРНИК",0x00
wed:	.db "СРЕДА",0x00
thu:	.db "ЧЕТВЕРГ",0x00
fri:	.db "ПЯТНИЦА",0x00
sat:	.db "СУББОТА",0x00
sun:	.db "ВОСКРЕСЕНИЕ",0x00

week_day_table:
	.dw mon<<1, tue<<1, wed<<1, thu<<1, fri<<1, sat<<1, sun<<1

week_day_center_coo:
	.db 6, 22, 30, 22, 22, 22, 6, 0x00

corr_table:
	.dw hour, minute, second, day, day_of_week, month, year

corr_max_value:
	.dw 0x24, 0x60, 0x60, 0x00, 0x07, 0x12, 0x9999

;-------- Конец cseg

.dseg ; Сегмент данных ОЗУ
.org 0x100
; Дата-время (BCD)
	dsecond: .db 0x00
	second: .db 0x00
	minute: .db 0x00
	hour: .db 0x00
	day: .db 0x00
	month: .db 0x00
	year: .dw 0x00
	day_of_week: .db 0x00

	tim_ovf_val: .db 0x00	; Длительность 5мс интервала (более точная корректировка)

	; цифровая настройка хода (очень точная корректировка)
	corr_period: .dd 0x00000000	; период, по прошествии которого осуществится корректировка (десятые доли секунды)
	corr_per_cnt: .dd 0x00000000
	corr_value: .dw 0x0000		; корректирующее значение (BCD) lsb - десятые доли секунд, msb - секунды, старший бит lsb - знак коррекции (+/-)

	sec_duration: .db 0x00	; Длительность секунды (грубая корректировка)
	sec_cnt: .db 0x00

;-------- Конец dseg

.eseg ; Сегмент eeprom

sec_dur_eep: .db 0x14

;-------- Конец eseg
