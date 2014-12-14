; Фирмварь для наручных часов на ATMEGA48PA, дисплей Siemens A70, 6 кнопок
; TODO
; 1. Запилить многоканальный таймер и будильник по дням недели

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
	
main:
	sbrc wflags, 3	; Если звук работает - в сон не уходим (пока что это костыль)
	rjmp m_no_sleep
	
	sleep	; Здоровый сон :-)

; Ждем обновления TC2 как в апп-нотах по RTC
	ldi tmp, 0x00
	sts OCR2B, tmp
wtr:
	lds tmp, ASSR
	sbrc tmp, OCR2BUB
	rjmp wtr

m_no_sleep:
	sbrs wflags, 4	; если прерывание RTC сработало - продолжаем (проверка нужна, т.к. контроллер не спит при геренации звука)
	rjmp main
	andi wflags, 0b11101111

; обработка таймера
m_tdr:
	sbrs refresh, 6 ; таймер запущен
	rjmp m_music
	sbis GPIOR0, 3
	rjmp m_music
	LASZ timer_sec
	ld tmp, Z+
	cpi tmp, 0x00
	brne m_tdr1
	ld tmp, Z
	cpi tmp, 0x00
	breq m_tdr_stop
m_tdr1:
	sbiw ZL, 0x01
;	ldi tmp, 0x99
;	rcall BCD_Add	; BCD_Dec
	rcall BCD_Dec
	ld tmp, Z
	cpi tmp, 0x60
	brlo m_tdr_ref
	ldi tmp, 0x59
	st Z+, tmp
;	ldi tmp, 0x99
;	rcall BCD_Add	; BCD_Dec
	rcall BCD_Dec
	ld tmp, Z
m_tdr_ref:
	ori refresh, 0b00100000
	rjmp m_music
m_tdr_stop:
	ldi tmp, 0x00
	st Z, tmp
	andi refresh, 0b10111111
	ori refresh, 0b00100000

; Играем музыку
	LAPZ music
	rcall play_music

m_music:
; обработка музыки
	sbrs wflags, 5
	rjmp m_alarm
	sbrc wflags, 3
	rjmp m_alarm
	LASZ music_pointer_l
	ld tmp, Z+
	ld tmp1, Z
	mov ZL, tmp
	mov ZH, tmp1
	lpm tmp, Z+
	lpm snd_delay_l, Z+
	cpi snd_delay_l, 0x00
	brne music_cont
	andi wflags, 0b11011111	; музыка остановлена
	rjmp m_alarm
music_cont:
	cpi tmp, 0x00
	breq music_pause
	rcall sound_freq  ; играем сэмпл
	beep_on
	rjmp music_out
music_pause: ; делаем паузу
	beep_off
	ori wflags, 0b00001000	; звук выключен, но таймер отсчитает паузу
music_out:
	mov tmp, ZH	; Сохраняем значение указателя в памяти
	mov tmp1, ZL
	LASZ music_pointer_l
	st Z+, tmp1
	st Z, tmp
; Обработка будильника
m_alarm:
	sbrs wflags, 6
	rjmp m_cont
	sbis GPIOR0, 3	; выполняем проверку каждую секунду
	rjmp m_cont
	LASZ bud_min
	ldi YL, low(minute)
	ldi YH, high(minute)
	ld tmp, Z+
	ld tmp1, Y+
	cp tmp, tmp1
	brne m_cont
	ld tmp, Z
	ld tmp1, Y
	cp tmp, tmp1
	brne m_cont
; есть совпадение - играем музыку, и так целую минуту :-)
	sbrc wflags, 5
	rjmp m_cont
	LAPZ music
	rcall play_music

m_cont:					; обработка режимов
	cpi mode, 0x00
	brne m_mode1

; Режим 0 - рисуем часы, подсветка 5 секунд по нажатию
	sbis GPIOR0, 3	; Выполняем рисование каждую секунду
	rjmp kbd_hand

m_draw_dt:
	ldi lcd_x, 3
	ldi lcd_y, 2
	rcall LCD_DrawTime
	rcall LCD_DrawDate
	rcall LCD_DrawBattery
	ldi lcd_x, 3
	ldi lcd_y, 2

	rjmp kbd_hand

; Режим 1 - рисуем дату-время, подсветка включена, рисуем с интервалом 0.1 сек
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
	mov tmp, kbd_press
	ori tmp, 0b11000000
	cpi tmp, 0xFF
	brne kbd_hcont
	rjmp main

kbd_hcont:
; звук при нажатии на кнопки
	ldi snd_delay_l, 5
	beep_on
; обработчики для разных режимов
	cpi mode, 0x00
	brne m_kbd_mode1
; Обработчик кнопок режима 0
	sbrc kbd_press, 3
	rjmp nx_b
	LED_ON
	ldi tmp, 40
	mov led_timer, tmp
nx_b:
	sbrc kbd_press, 5
	rjmp nx_b1
	inc mode
	rcall LCD_Clear
	ori refresh, 0b00011111
	LED_ON
nx_b1:
	sbrc kbd_press, 1	; включаем режим таймера
	rjmp nx_b2
	ldi mode, 0x02
nx_b1_b:				; для таймера и будильника
	rcall LCD_Clear
	ldi lcd_x, 26
	ldi lcd_y, 0
	scale1x
	cpi mode, 0x02
	brne nx_b1_drb
	LAPZ tim_str
	rjmp nx_b1_dr
nx_b1_drb:
	LAPZ bud_str
	ldi lcd_x, 15
nx_b1_dr:
	rcall LCD_DrawStringPM
	ori refresh, 0b00100000
nx_b2:
	sbrc kbd_press, 0	; Включаем режим будильника
	rjmp nx_b3
	ldi mode, 0x03
	rjmp nx_b1_b
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
;	ldi tmp, 0x99
;	rcall BCD_Add	; аналогично BCD_Dec
	rcall BCD_Dec
val_check:
	ld tmp, Z	; в tmp число после модификации
	cpi mode_tmp, 0x02
	breq sec_corr
	cpi mode_tmp, 0x03
	breq day_corr
	cpi mode_tmp, 0x06
	breq no_corr
hr_mn_mo:
; для часов, минут и месяца
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
	push tmp
	rcall TimeDate_mlen_calc
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
; Обработчик кнопок режима 2 (таймер) и 3 (будильник)
	sbrc kbd_press, 1
	rjmp nx_b_m2
	cpi mode, 0x02
	brne kb1_m2_bud
nx_b0_m2_out:
	clr mode
	rcall LCD_Clear
	ori refresh, 0b00011111
	rjmp main
mode2_out:
	ori refresh, 0b00100000
	rjmp main
kb1_m2_bud:	; инкремент минут будильника
	LASZ bud_min
	rcall BCD_Inc
	rjmp nx_b4_m2_cnt
nx_b_m2:
	sbrc kbd_press, 3	; подсветка в режиме таймера
	rjmp nx_b1_m2
	LED_ON
	ldi tmp, 40
	mov led_timer, tmp
nx_b1_m2:
	sbrc kbd_press, 0 ; старт/стоп таймера
	rjmp nx_b2_m2
	cpi mode, 0x03	; или выход из режима будильника, но если включена подсветка, то включение/выключение будильника
	breq nx_b1_check
	ldi tmp, 0b01000000
	eor refresh, tmp
	rjmp main
nx_b1_check:
	tst led_timer	; Если подсветка выключена (led_timer = 0) то выход из режима будильника
	breq nx_b0_m2_out
	ldi tmp, 0b01000000
	eor wflags, tmp	; В противном случае вкл/выкл будильника
	ori refresh, 0b00100000
	rjmp main
nx_b2_m2:
	sbrc kbd_press, 4 ; инкремент минут (только если таймер остановлен)
	rjmp nx_b3_m2
	cpi mode, 0x02
	brne nx_b2_m2_bud
	sbrc refresh, 6
	rjmp main
	LASZ timer_min
	rcall BCD_Inc
	rjmp mode2_out
nx_b2_m2_bud:	; инкремент часов для будильника
	LASZ bud_hr
	rcall BCD_Inc
	ld tmp, Z
	cpi tmp, 0x24
	brne mode2_out
	ldi tmp, 0x00
	st Z, tmp
	rjmp mode2_out 
nx_b3_m2:
	sbrc kbd_press, 5 ; декремент минут (тоже только если таймер остановлен)
	rjmp nx_b4_m2
	cpi mode, 0x02
	brne nx_b3_m2_bud
	sbrc refresh, 6
	rjmp main
	LASZ timer_min
;	ldi tmp, 0x99
;	rcall BCD_Add
	rcall BCD_Dec
	rjmp mode2_out
nx_b3_m2_bud:	; декремент часов для будильника
	LASZ bud_hr
;	ldi tmp, 0x99
;	rcall BCD_Add
	rcall BCD_Dec
	ld tmp, Z
	cpi tmp, 0x99
	brne mode2_out
	ldi tmp, 0x23
	st Z, tmp
	rjmp mode2_out
nx_b4_m2:
	sbrc kbd_press, 2 ; инкремент секунд (так же если таймер остановлен)
	rjmp main
	cpi mode, 0x02
	brne nx_b4_m2_bud
	sbrc refresh, 6
	rjmp main
	LASZ timer_sec
	rcall BCD_Inc
nx_b4_m2_cnt:
	ld tmp, Z
	cpi tmp, 0x60
	brne b4_m2_end
	ldi tmp, 0x00
	st Z, tmp
b4_m2_end:	
	rjmp mode2_out
nx_b4_m2_bud:	; декремент минут будильника
	LASZ bud_min
;	ldi tmp, 0x99
;	rcall BCD_Add
	rcall BCD_Dec
	ld tmp, Z
	cpi tmp, 0x99
	brne b4_m2_end
	ldi tmp, 0x59
	st Z, tmp
	rjmp mode2_out
	
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
AnalogDC:
EE_RDY:
AnalogCMP:
TWI:
SPM_RDY:
	reti

USART_TX:	; Используется для генерации звука. Как только передача завершена, а флаг генерации еще установлен - начинает новую передачу
	push tmp
	ldi tmp, 0x00
	sts UDR0, tmp
	pop tmp
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

T2_COMPA:		; обработчик прерывания от таймера RTC, примерно каждые 5 мс
	push tmp
	in tmp, SREG
	push tmp
	push tmp1

	push ZH
	push ZL
	push YH
	push YL

	ori wflags, 0b00010000	

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
	cpi snd_delay_l, 0x00	; обработчик звука
	breq t2_out
t2_snd_cont:
	dec snd_delay_l
	brne t2_out
t2_no_sound:
	beep_off
t2_out:
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
.include "bcd.inc"
.include "Sie_A70.inc"	; Siemens A70 routines
.include "sound.inc" ; Звук
.include "time_date.inc" ; Для даты и времени

;-------- Данные

.include "symbols.inc"	; 8x8 font
.include "data.inc"


;-------- Конец cseg

.dseg ; Сегмент данных ОЗУ
.org 0x100

.include "ram.inc"

;-------- Конец dseg
