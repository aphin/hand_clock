; Фирмварь для наручных часов на ATMEGA48PA, дисплей Siemens C60, 6 кнопок
; TODO
; 1. Запилить секундомер

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
	tst snd_flag	; если звук выключен - не обрабатываем
	breq m_tdr
	
	tst tmp2		; время вышло
	brne m_snd_cont
	ldi snd_flag, 0	; выключаем звук
	ldi snd, 0
	BEEP_OFF
	rjmp m_tdr

m_snd_cont:
	tst snd				; если счетчик не равен нулю, то
	brne m_snd_cont
	LAPZ sound_pattern	; загружаем следующий паттерн (или первый)
	push snd_flag
	dec snd_flag
	add ZL, snd_flag
	ldi tmp, 0x00
	adc ZH, tmp
	lpm snd, Z
	pop snd_flag
	sbrs snd_flag, 0	; проверяем на не-четность (так как флаг считается от 1-цы)
	rjmp m_snd_silent	; если четный - то выключаем бипер
	BEEP_ON				; если не четный - то включаем
	rjmp m_snd_cont3
m_snd_silent:
	BEEP_OFF
m_snd_cont3:
	inc snd_flag
	cpi snd_flag, 6
	brne m_tdr
	ldi snd_flag, 1

; обработка таймера
m_tdr:
	sbrs refresh, 6 ; таймер запущен
	rjmp m_cont
	sbis GPIOR0, 3
	rjmp m_cont
	LASZ timer_sec
	ld tmp, Z+
	cpi tmp, 0x00
	brne m_tdr1
	ld tmp, Z
	cpi tmp, 0x00
	breq m_tdr_stop
m_tdr1:
	sbiw ZL, 0x01
	ldi tmp, 0x99
	rcall BCD_Add	; BCD_Dec
	ld tmp, Z
	cpi tmp, 0x60
	brlo m_tdr_ref
	ldi tmp, 0x59
	st Z+, tmp
	ldi tmp, 0x99
	rcall BCD_Add	; BCD_Dec
	ld tmp, Z
m_tdr_ref:
	ori refresh, 0b00100000
	rjmp m_cont
m_tdr_stop:
	ldi tmp, 0x00
	st Z, tmp
	andi refresh, 0b10111111
	ori refresh, 0b00100000
	ldi snd_flag, 1	; звуковой сигнал
	ldi snd, 0
	ldi tmp2, 255


m_cont:					; обработка режимов
	cpi mode, 0x00
	brne m_mode1

; Режим 0 - рисуем часы, подсветка 5 секунд по нажатию, режим Idle
	sbis GPIOR0, 3	; Выполняем рисование каждую секунду
	rjmp kbd_hand

m_draw_dt:
	ldi tmp, 3
	mov lcd_x, tmp
	ldi tmp, 20
	mov lcd_y, tmp
	rcall LCD_DrawTime
	rcall LCD_DrawDate
	rcall LCD_DrawBattery
	ldi tmp, 3
	mov lcd_x, tmp
	ldi tmp, 20
	mov lcd_y, tmp

	rjmp kbd_hand

; Режим 1 - рисуем дату-время, подсветка включена, режим Normal, рисуем с интервалом 0.1 сек
m_mode1:
	cpi mode, 0x01
	brne m_mode2
	sbis GPIOR0, 2
	rjmp kbd_hand
	rjmp m_draw_dt

m_mode2:				
; Режим 2 - здесь обрабатывается таймер
	sbrs refresh, 5	; бит 5 указывает на необходимость обновления таймера
	rjmp kbd_hand
	andi refresh, 0b11011111
	rcall LCD_DrawTimer

kbd_hand:
; звук при нажатии на кнопки
	mov tmp, kbd_press
	ori tmp, 0b11000000
	cpi tmp, 0xFF
	breq kbd_hcont
	ldi snd_flag, 1 ; устанавливаем номер сэмпла (0) и включаем звук
	ldi snd, 0
	ldi tmp2, 20	; длительность задается так же как и для функций Delay (проиграется только бип)

kbd_hcont:
	cpi mode, 0x00
	brne m_kbd_mode1
; Обработчик кнопок режима 0
	sbrc kbd_press, 3
	rjmp nx_b
	LED_ON
	rcall LCD_IdleOff
	ldi tmp, 40
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
	sbrc kbd_press, 1	; включаем режим таймера
	rjmp nx_b2
	ldi mode, 0x02
	rcall LCD_Clear
	ldi tmp, 26
	mov lcd_x, tmp
	ldi tmp, 5
	mov lcd_y, tmp
	ldi tmp, 1
	mov lcd_mx, tmp
	mov lcd_my, tmp
	LAPZ tim_str
	rcall LCD_DrawStringPM
	ori refresh, 0b00100000
nx_b2:
	sbrc kbd_press, 0	; изменяем режим отображения
	rjmp nx_b3
	inc style
	cpi style, 3
	brne nx_b2_c
	ldi style, 0
nx_b2_c:
	ori refresh, 0b00000011
	
	ldi tmp, 20+14	; Очищаем область рисования секунд
	mov lcd_y, tmp
	ldi tmp, 3+(5*16)
	mov lcd_x, tmp
	ldi tmp, 2
	mov lcd_mx, tmp
	mov lcd_my, tmp
	ldi tmp, 0x20
	rcall LCD_DrawChar

nx_b3:
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
	clr sec_part_cnt ; обнуляем счетчик интервала 0.1 сек
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
; Обработчик кнопок режима 2 (таймер)
	sbrc kbd_press, 1
	rjmp nx_b_m2
	clr mode
	rcall LCD_Clear
	rcall LCD_IdleOn
	ori refresh, 0b00011111
nx_b_m2:
	sbrc kbd_press, 3
	rjmp nx_b1_m2
	LED_ON
	rcall LCD_IdleOff
	ldi tmp, 40
	mov led_timer, tmp
nx_b1_m2:
	sbrc kbd_press, 0 ; старт/стоп таймера
	rjmp nx_b2_m2
	ldi tmp, 0b01000000
	eor refresh, tmp
nx_b2_m2:
	sbrc kbd_press, 4 ; инкремент минут (только если таймер остановлен)
	rjmp nx_b3_m2
	sbrc refresh, 6
	rjmp main
	LASZ timer_min
	rcall BCD_Inc
	ori refresh, 0b00100000
nx_b3_m2:
	sbrc kbd_press, 5 ; декремент минут (тоже только если таймер остановлен)
	rjmp nx_b4_m2
	sbrc refresh, 6
	rjmp main
	LASZ timer_min
	ldi tmp, 0x99
	rcall BCD_Add
	ori refresh, 0b00100000
nx_b4_m2:
	sbrc kbd_press, 2 ; инкремент секунд (так же если таймер остановлен)
	rjmp main
	sbrc refresh, 6
	rjmp main
	LASZ timer_sec
	rcall BCD_Inc
	ld tmp, Z
	cpi tmp, 0x60
	brne b4_m2_end
	ldi tmp, 0x00
	st Z, tmp
b4_m2_end:
	ori refresh, 0b00100000
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
	push tmp1

	push ZH
	push ZL
	push YH
	push YL

	in tmp, GPIOR0
	andi tmp, 0b00000011
	out GPIOR0, tmp			; сбрасываем флаги временных событий

	rcall KBD_Check ; Скан кнопок
	
	ldi tmp, TimCntVal
	inc sec_part_cnt
	cp sec_part_cnt, tmp
	brne t2_end

; Прошла 1/8 секунды
	sbi GPIOR0, 2	; Установили флаг
	
	rcall Time_Date_Inc	; Инкремент даты-времени
t2_snd:
	tst snd
	breq t2_snd1
	dec snd
t2_snd1:
	clr sec_part_cnt	; Очистили счетчик
; Корректировка времени (ЦНХ)
; Сравниваем текущее время с данными ЦНХ
	LAPZ w_time_corr
	ldi YH, high(dsecond)
	ldi YL, low(dsecond)
	lpm tmp, Z+
	ld tmp1, Y+
	cp tmp, tmp1	; сравниваем доли секунд
	brne t2_no_tcor
	lpm tmp, Z+
	ld tmp1, Y+
	cp tmp, tmp1	; сравниваем секунды	
	brne t2_no_tcor
	lpm tmp, Z+
	ld tmp1, Y+
	cp tmp, tmp1	; сравниваем минуты
	brne t2_no_tcor
	lpm tmp, Z
	ld tmp1, Y
	cp tmp, tmp1	; сравниваем часы
	brne t2_no_tcor
; Сюда попадаем только если все сравнения дали результат "равно", и коррекция еще не делалась (бит 7 регистра refresh = 0) - это значит надо делать коррекцию
	sbrc refresh, 7
	rjmp t2_no_tcor_r
	sbiw YL, 3
	ldi tmp, 0x00	; Устанавливаем время 00:00:00.0
	st Y+, tmp
	st Y+, tmp
	st Y+, tmp
	st Y, tmp
	ori refresh, 0b10000000
	rjmp t2_no_tcor
t2_no_tcor_r:
	andi refresh, 0b01111111
; Определяем, в каком режиме работают часы
t2_no_tcor:
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
	cpi mode, 0x01
	brne tc2_mode2

	rjmp t2_end

tc2_mode2:
; Режим 2 - таймер
	tst led_timer	; подсветка
	breq t2_end
	dec led_timer
	brne t2_end
	LED_OFF

t2_end:
	tst tmp2
	breq t2_out1
	dec tmp2
t2_out1:
	pop YL
	pop YH
	pop ZL
	pop ZH

	pop tmp1
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
LCD_DrawTimer:
	push ZH
	push ZL
	push tmp
	push tmp1

	ldi tmp, 0x02
	mov lcd_mx, tmp
	ldi tmp, 0x02
	mov lcd_my, tmp
	ldi tmp, 10
	mov lcd_x, tmp
	ldi tmp, 20
	mov lcd_y, tmp
	ldi tmp1, 16
	
	LASZ timer_min
	ld tmp, Z
	rcall LCD_DrawBCD7
	push lcd_my
	ldi tmp, 0x04
	mov lcd_my, tmp
	ldi tmp, ':'
	rcall LCD_DrawChar
	pop lcd_my
	add lcd_x, tmp1
	sbiw ZL, 0x01
	ld tmp, Z
	rcall LCD_DrawBCD7

	pop tmp1
	pop tmp
	pop ZL
	pop ZH
	ret
;----------------------
LCD_DrawBattery:
	ldi tmp, 84
	mov lcd_x, tmp
	ldi tmp, 68
	mov lcd_y, tmp
	ldi tmp, 0x01
	mov lcd_mx, tmp
	mov lcd_my, tmp
	ldi tmp, 0b11000001
	sts ADCSRA, tmp
vbat_mw:
	lds tmp, ADCSRA
	sbrs tmp, ADIF
	rjmp vbat_mw
	ldi tmp, 0b10010100
	sts ADCSRA, tmp
	lds tmp, ADCH
	
	cpi tmp, 0x4B
	brsh vbat_nx1
	ldi tmp, 0x2E	; Full
	rjmp vbat_ex
vbat_nx1:
	cpi tmp, 0x50
	brsh vbat_nx2
	ldi tmp, 0x2D	; 60%
	rjmp vbat_ex
vbat_nx2:
	cpi tmp, 0x5A
	brsh vbat_nx3
	ldi tmp, 0x2C	; 30%
	rjmp vbat_ex
vbat_nx3:
	ldi tmp, 0x2B
vbat_ex:
	rcall LCD_DrawChar
	ret
;----------------------
LCD_DrawTime:
	push ZH
	push ZL
	push tmp
	push tmp1

	ldi tmp, 2
	mov lcd_mx, tmp
	cpi style, 1
	brne drt1
	ldi tmp, 2
	rjmp drt2
drt1:
	ldi tmp, 4
drt2:
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
	cpi style, 1
	brne drt3
	rcall LCD_DrawBCD7
	rjmp drt4
drt3:
	rcall LCD_DrawBCD
drt4:
	pop frg_color
	pop bkg_color
	sbrc style, 0
	lsl lcd_my
	ldi tmp,':'
	rcall LCD_DrawChar
	sbrc style, 0
	lsr lcd_my
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
	cpi style, 1
	brne drt5
	rcall LCD_DrawBCD7
	rjmp drt6
drt5:
	rcall LCD_DrawBCD
drt6:
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
	cpi style, 1
	brne drt7
	rcall LCD_DrawBCD7
	rjmp drt8
drt7:
	rcall LCD_DrawBCD
drt8:
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

; делаем задержку на 1 такт таймера TC2 (поправка, т.к. по всем "прикидкам" система считает 32767 тактов в секунду вместо 32768)
; Не энергоэффективно, т.к. в этом куске кода процессор "тупо" ждет пока таймер отсчитает 3 такта
; можно ускорить процесс исключив ожидание вначале появления в регистре счетчика 0х01, и записывая при этом в регистр таймера уже значение 0х01 вместо
; 0х02

tdi_fix_w:
	lds tmp, TCNT2
	cpi tmp, 0x01
	brlo tdi_fix_w
	ldi tmp, 0x02	; записываем в счетчик 0х02, (выполнение кода-поправки займет 3 такта таймера, мы же записали сюда 2, таким образом сделав задержку на такт)
	sts TCNT2, tmp
tdi_fix_w1:
	lds tmp, ASSR
	sbrc tmp, TCN2UB
	rjmp tdi_fix_w1
; ---

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
	push r20

	cbi GPIOR0, 0
	ld tmp1, Z
	add tmp1, tmp
	in r20, SREG
	brhs lsd_correct
	push tmp1
	andi tmp1, 0x0F
	cpi tmp1, 0x0A
	pop tmp1
	brlo msd
lsd_correct:
	push tmp1
	andi tmp1, 0xF0
	cpi tmp1, 0xA0
	pop tmp1
	brlo only_lsd_correct
	rjmp correct_both
only_lsd_correct:
	ldi tmp, 0x06
	add tmp1, tmp
msd:
	sbrc r20, 0
	rjmp msd_correct
	push tmp1
	andi tmp1, 0xF0
	cpi tmp1, 0xA0
	pop tmp1
	brlo bcd_end
msd_correct:
	ldi tmp, 0x60
	add tmp1, tmp
	brcc bcd_end
	sbi GPIOR0, 0 
	rjmp bcd_end
correct_both:
	ldi tmp, 0x66	; correct both
	add tmp1, tmp
	brcc bcd_end
	sbi GPIOR0, 0 
bcd_end:
	st Z, tmp1

	pop r20
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
spi_wait:
	in tmp, SPSR
	sbrs tmp, SPIF
	rjmp spi_wait
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
	ldi tmp2, 16
d100_w:
	cpi tmp2, 0x00
	brne d100_w
	ret
;--------------------
delay_10ms:
	ldi tmp2, 2
d10_w:
	cpi tmp2, 0x00
	brne d10_w
	ret
;--------------------
LCD_DrawDate:
	push ZH
	push ZL
	push tmp
	push tmp1
	push style
	ldi style, 0

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
	pop style
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

	ldi tmp1, 6
	mov lcd_x, tmp1
	ldi tmp1, 60
	mov lcd_y, tmp1

	LAPZ week_day_names
	ldi tmp1, 12
	mul tmp, tmp1
	add ZL, r0
	adc ZH, r1
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
tue:	.db "  ВТОРНИК  ",0x00
wed:	.db "   СРЕДА   ",0x00
thu:	.db "  ЧЕТВЕРГ  ",0x00
fri:	.db "  ПЯТНИЦА  ",0x00
sat:	.db "  СУББОТА  ",0x00
sun:	.db "ВОСКРЕСЕНИЕ",0x00

tim_str: .db "ТАЙМЕР",0x00,0x00

corr_table:
	.dw hour, minute, second, day, day_of_week, month, year

corr_max_value:
	.dw 0x24, 0x60, 0x60, 0x00, 0x07, 0x12, 0x9999

sie_c60_init:
	.db	0x80,0x04,0x8A,0x54,0x45,0x52,0x43,0x02,0x0A,0x15,0x1F,0x28,0x30,0x37,0x3F,0x47,0x4C,0x54,0x65,0x75,0x80,0x85,0x00,0x03,0x05,0x07,0x09,0x0B,0x0D,0x0F,0x00,0x03,0x05,0x07,0x09,0x0B,0x0D,0x0F,0x00,0x05,0x0B,0x0F

w_time_corr:	; Коррекция времени. Когда часы "покажут" это время, программа "сбросит" их в 00:00:00.0 - это коррекция для "убегающих" часов
	.db 0x00,0x00,0x00,0x00 ; доли секунд, секунды, минуты, часы


; запись длительностей звука и пауз для сигнала
; т.к. нет не логично запускать подряд два звука или две паузы, то каждый четный байт (с нуля) - это длительность звука (в долях секунды)
; а каждый нечетный байт - длительность паузы
sound_pattern:
	.db 2,1,2,1,2,1,2,1,2,1	; пробный пи-пи-пи-пи :-)

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

	timer_sec: .db 0x00	; BCD значение таймера (секунды)
	timer_min: .db 0x00	; минуты

;-------- Конец dseg
