; Siemens A70 display routines

LCD_A70_Init:
	push r20
	push tmp
	push zh
	push zl

	;LCD reset
	rcall delay_10us
	CMD_SET
	rcall delay_10us
	LCD_RESET_HIGH
	rcall delay_10us
	CS_LOW
	rcall delay_10us
	LCD_RESET_LOW
	rcall delay_10us
	LCD_RESET_HIGH
	CS_HIGH
	rcall delay_10us
	rcall delay_10us
	rcall delay_10us
	rcall delay_10us

;  SendCommand(0x21);  // Function set: extended instruction set
;  SendCommand(0x14);  // Bias System
;  SendCommand(0x0A);  // HV-gen stages
;  SendCommand(0x05);  // Temperature Control
;  SendCommand(0xCC);  // Contrast: 204
;  SendCommand(0x20);  // Function set: standard instruction set
;  SendCommand(0x11);  // VLCD programming range: high
;  SendCommand(0x0C);  // Display control: normal (inverted = 0x0D) 	

	CS_LOW
	LAPZ sie_a70_init
	ldi r20, 8
a70_inlp:
	lpm tmp, Z+
	rcall Send_SPI
	dec r20
	brne a70_inlp

	CS_HIGH

	pop zl
	pop zh
	pop tmp
	pop r20

	ret

LCD_GotoXY:
; вход lcd_x, lcd_y
	push tmp
	CMD_SET
  	ldi tmp, 0b00100000	; H = 0, V = 0, PD = 0
	rcall SPI_send
	mov tmp, lcd_y
	andi tmp, 0b01111111
	ori tmp, 0b01000000
	rcall SPI_send
	mov tmp, lcd_x
	ori tmp, 0b10000000
	rcall SPI_send
	pop tmp
	ret
;----------------------
LCD_Clear:
	push r20
	push tmp1
	push tmp
	
	CS_LOW

	ldi lcd_x, 0x00
	ldi lcd_y, 0x00
	rcall LCD_GotoXY

	DATA_SET
	ldi tmp1, 8
	ldi tmp, 0x00
lcl_lp1:
	ldi r20, 101
lcl_lp:
	rcall SPI_send
	dec r20
	brne lcl_lp
	dec tmp1
	brne lcl_lp1

	CS_HIGH

	pop tmp
	pop tmp1
	pop r20
	ret
;----------------------
r20_lcd_mx:
	ldi r20, 8
	sbrc wflags, 0
	lsl r20
	ret
;----------------------
LCD_DrawStringPM:
; in: Z - строка во flash ASCIIZ
	push tmp
	push ZH
	push ZL
	push r20

	rcall r20_lcd_mx
drst:
	lpm tmp, Z+
	cpi tmp, ZER
	breq drst_end
	rcall LCD_DrawChar
	add lcd_x, r20
	rjmp drst
drst_end:
	pop r20
	pop ZL
	pop ZH
	pop tmp
	ret
;----------------------
LCD_DrawBCD:
;in: tmp - число
	push tmp
	push r20
	push tmp1

	rcall r20_lcd_mx

	ldi tmp1, n0

	push tmp
	swap tmp
	andi tmp, 0x0F
	add tmp, tmp1
	rcall LCD_DrawChar
	add lcd_x, r20
	pop tmp
	andi tmp, 0x0F
	add tmp, tmp1
	rcall LCD_DrawChar
	add lcd_x, r20

	pop tmp1
	pop r20
	pop tmp
	ret
;----------------------
LCD_DrawBCD7:	; рисует BCD число в стиле 7-ми сегментного индикатора
; tmp - число
	push tmp
	push tmp1
	push r20
	push ZL
	push ZH

	rcall r20_lcd_mx

	LAPZ seg7_dig

	ldi tmp1, 1
	sbrc wflags, 0
	lsl tmp1	

	push tmp
	swap tmp
	andi tmp, 0x0F
	lsl tmp
	add ZL, tmp
	clr tmp
	adc ZH, tmp
	lpm tmp, Z+
	rcall LCD_DrawChar
	add lcd_y, tmp1
	lpm tmp, Z
	ori wflags, 0b00000010
	rcall LCD_DrawChar
	andi wflags, 0b11111101
	pop tmp
	add lcd_x, r20
	sub lcd_y, tmp1
	andi tmp, 0x0F
	lsl tmp
	LAPZ seg7_dig
	add ZL, tmp
	clr tmp
	adc ZH, tmp
	lpm tmp, Z+
	rcall LCD_DrawChar
	add lcd_y, tmp1
	lpm tmp, Z
	ori wflags, 0b00000010
	rcall LCD_DrawChar
	andi wflags, 0b11111101
	add lcd_x, r20
	sub lcd_y, tmp1

	pop ZH
	pop ZL
	pop r20
	pop tmp1
	pop tmp
	ret
;----------------------
LCD_DrawChar:
; in: tmp - код символа
;	lcd_x, lcd_y - координаты
	push tmp
	push r20
	push lcd_y
	push lcd_x
	push ZL
	push ZH

	LAPZ font8x8

	ldi r20, 0x08
	mul tmp, r20
	mov r20, r1
	mov tmp, r0

	add ZL, tmp
	adc ZH, r20

	ldi tmp, 101	;Костыль
	rcall r20_lcd_mx;Костыль
	sub tmp, r20	;Костыль
	sub tmp, lcd_x	;Костыль
	mov lcd_x, tmp	;Костыль

	ldi r20, 0x08


	CS_LOW
	rcall LCD_GotoXY
	DATA_SET

	sbrc wflags, 0
	rjmp cdr_scale

cdrw:	; Без масштабирования
	lpm tmp, Z+
	sbic GPIOR0, 7
	com tmp
	rcall SPI_send
	dec r20
	brne cdrw
	rjmp cdr_end
cdr_scale:	; Рисование с масштабированием
	ori wflags, 0b00000100	; устанавливаем флаг
cdr_s1:
	lpm tmp, Z+
	sbic GPIOR0, 7
	com tmp
	sbrc wflags, 1
	lsl tmp
	sbrc wflags, 2
	swap tmp
	rcall scale2x_tmp
	rcall SPI_Send
	rcall SPI_Send
	dec r20
	brne cdr_s1

	sbrs wflags, 2
	rjmp cdr_end
	inc lcd_y
	rcall LCD_GotoXY
	DATA_SET
	ldi r20, 8
	andi wflags, 0b11111011 ; сбрасываем флаг
	sbiw ZL, 8
	rjmp cdr_s1
cdr_end:
	CS_HIGH
	pop ZH
	pop ZL
	pop lcd_x
	pop lcd_y
	pop r20
	pop tmp
	ret

scale2x_tmp:
	bst tmp, 3
	bld tmp, 7
	bld tmp, 6
	bst tmp, 2
	bld tmp, 5
	bld tmp, 4
	bst tmp, 1
	bld tmp, 3
	bld tmp, 2
	bst tmp, 0
	bld tmp, 1
	ret

;----------------------
LCD_DrawTimer:
	push ZH
	push ZL
	push tmp

	scale2x
	ldi lcd_x, 10
	ldi lcd_y, 2
	
	cpi mode, 0x02
	brne dt_bud
	LASZ timer_min
	rjmp dt_cnt
dt_bud:
	LASZ bud_hr
	ldi lcd_x, 17
dt_cnt:
	ld tmp, Z
	rcall LCD_DrawBCD7
	ldi tmp, p2
	inc lcd_y
	rcall LCD_DrawChar
	dec lcd_y
	subi lcd_x, 0xF0 ; lcd_x += 16
	sbiw ZL, 0x01
	ld tmp, Z
	rcall LCD_DrawBCD7
	cpi mode, 0x03
	brne dr_tim_out
	ldi lcd_x, 0
	ldi lcd_y, 3
	sbrs wflags, 6
	rjmp dr_tim_bud_off
; будильник включен
	ldi tmp, Snd0
	rcall LCD_DrawChar
	rjmp dr_tim_out
dr_tim_bud_off:
; будильник выключен
	ldi tmp, Snd1
	rcall LCD_DrawChar
dr_tim_out:
	pop tmp
	pop ZL
	pop ZH
	ret
;----------------------
LCD_DrawBattery:
	push tmp
	push tmp1

	ldi lcd_x, 83
	ldi lcd_y, 6
	scale1x
	ldi tmp, 0b11000001
	sts ADCSRA, tmp
vbat_mw:
	lds tmp, ADCSRA
	sbrs tmp, ADIF
	rjmp vbat_mw
	ldi tmp, 0b10010100
	sts ADCSRA, tmp
	lds tmp, ADCH
	rcall ADC_Div ; Находим 2816/tmp
; делим результат на 10, причем заведомо tmp больше 10, т.к. в нормальных условиях напряжение на аккумуляторе не упадет ниже 2.5В
	mov tmp1, tmp
	ldi tmp, 0x00
vbat_div10:
	subi tmp1, 10
	cpi tmp1, 10
	brlo vbat_div10e
	inc tmp
	rjmp vbat_div10
vbat_div10e:
; теперь в tmp1 дробная часть напряжения, а в tmp - целая
; делаем поправку на дрейф нуля
	subi tmp1, (0x100 - 8)	; tmp1 += 8, поправка - 0.8В
	cpi tmp1, 10
	brlo vbat_no_cor
	subi tmp1, 10
	inc tmp
vbat_no_cor:
	subi tmp, (0x100-n0)
	rcall LCD_DrawChar
	subi lcd_x, (0x100-10)
	mov tmp, tmp1
	subi tmp, (0x100-n0)
	rcall LCD_DrawChar 
	DATA_SET ; Рисуем точку
	CS_LOW
	ldi tmp, 0b00000011
	rcall SPI_Send
	rcall SPI_Send
	CS_HIGH

	pop tmp1
	pop tmp
	ret
;----------------------
ADC_Div:
; Делит 2816 (256*11) на tmp на цело, т.к. точности более 1 знака после запятной не нужно
; Целая часть в tmp (это справедливо только для измерения напряжения батареи, в этом случае результат не вылезет за рамки 1 байта).
	push r20
	push r2
	ldi tmp1, 0x00	; младшая часть делимого
	ldi r20, 0x0B ; старшая часть делимого
	clr r2
	cpi tmp, 0	; исключаем деление на 0
	breq adiv_end
adiv_lp:
	sub tmp1, tmp
	sbci r20, 0x00
	cpi r20, 0
	breq adiv_nx
	inc r2
	rjmp adiv_lp
adiv_nx:
	inc r2
adiv_lp1:
	sub tmp1, tmp
	cp tmp1, tmp
	brlo adiv_end
	inc r2
	rjmp adiv_lp1
adiv_end:
	mov tmp, r2
	pop r2
	pop r20
	ret
;----------------------
LCD_DrawTime:
	push ZH
	push ZL
	push tmp

	scale2x

	ldi lcd_x, 2
	ldi lcd_y, 2

	sbrs refresh, 1
	rjmp drw_clk_minute_skip
	andi refresh, 0b11111101
	LASZ hour	; рисуем часы
	ld tmp, Z

	cpi mode, 0x01
	brne drw_clk_hrd
	cpi mode_tmp, 0x00
	brne drw_clk_hrd
	INVCOL
drw_clk_hrd:
	rcall LCD_DrawBCD7
	NORMCOL
	inc lcd_y
	ldi tmp, p2	; ':'
	rcall LCD_DrawChar
	dec lcd_y
	rjmp drw_clk_minute
drw_clk_minute_skip:
	subi lcd_x, 0xE0	; lcd_x += 32
drw_clk_minute:
	sbrs refresh, 0
	rjmp drw_clk_sec_skip
	andi refresh, 0b11111110
	subi lcd_x, 0xF0 ; lcd_x += 16
	LASZ minute
	ld tmp, Z
	cpi mode, 0x01
	brne drw_clk_mnd
	cpi mode_tmp, 0x01
	brne drw_clk_mnd
	INVCOL
drw_clk_mnd:
	rcall LCD_DrawBCD7
	NORMCOL
	rjmp drw_clk_sec
drw_clk_sec_skip:
	subi lcd_x, 0xD0 ; lcd_x += 48
drw_clk_sec:	; рисуем секунды
	scale1x
	inc lcd_y

	LASZ second
	ld tmp, Z
	cpi mode, 0x01
	brne drw_clk_sed
	cpi mode_tmp, 0x02
	brne drw_clk_sed
	INVCOL
drw_clk_sed:
	rcall LCD_DrawBCD7
	NORMCOL
	
	pop tmp
	pop ZL
	pop ZH
	ret
;----------------------
LCD_DrawDate:
	push ZH
	push ZL
	push tmp

	scale1x

	ldi lcd_y, 0

	LASZ day

	sbrs refresh, 2
	rjmp drw_dat_end	; если не надо обновить день, то и "автоматом" не надо обновить год, месяц и день недели

	andi refresh, 0b11111011
	ldi lcd_x, 5 ; риусем число
	ld tmp, Z


	cpi mode, 0x01
	brne drw_dat_day
	cpi mode_tmp, 0x03
	brne drw_dat_day
	INVCOL
drw_dat_day:
	rcall LCD_DrawBCD
	NORMCOL

	cpi mode, 0x01
	brne drw_dat_dayw
	cpi mode_tmp, 0x04
	brne drw_dat_dayw
	INVCOL
drw_dat_dayw:
	rcall LCD_DrawDayOfWeek
	NORMCOL
	
	ldi lcd_y, 0
	LASZ day

	sbrs refresh, 3
	rjmp drw_dat_end

	andi refresh, 0b11110111
	ldi lcd_x, 0x05+(0x08*3)

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

	cpi mode, 0x01
	brne drw_dat_mon
	cpi mode_tmp, 0x05
	brne drw_dat_mon
	INVCOL
drw_dat_mon:
	rcall LCD_DrawStringPM
	NORMCOL
	pop ZL
	pop ZH

	sbrs refresh, 4
	rjmp drw_dat_end

	andi refresh, 0b11101111
	ldi lcd_x, 0x05+(0x08*7)
	adiw ZL, 0x01
	ld tmp, Z

	cpi mode, 0x01
	brne drw_dat_year
	cpi mode_tmp, 0x06
	brne drw_dat_year
	INVCOL
drw_dat_year:
	rcall LCD_DrawBCD
	sbiw ZL, 0x01
	ld tmp, Z
	rcall LCD_DrawBCD
	NORMCOL
drw_dat_end:
	pop tmp
	pop ZL
	pop ZH
	ret
;--------------------
LCD_DrawDayOfWeek:
	push tmp1
	LASZ day_of_week 	; Рисуем день недели
	ld tmp, Z

	ldi lcd_x, 6
	ldi lcd_y, 7

	LAPZ week_day_names
	ldi tmp1, 12
	mul tmp, tmp1
	add ZL, r0
	adc ZH, r1
	rcall LCD_DrawStringPM
	pop tmp1
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
