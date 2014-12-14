; Инициализация чипа
	cli
;-------- Инициализация стека
    ldi tmp, high(RAMEND)
    out SPH,tmp
    ldi tmp, low(RAMEND)
    out SPL,tmp
;-------- Отключение Watchdog
	wdr
	clr tmp
	sts WDTCSR, tmp
;-------- Настраиваем асинхронный таймер
	ldi tmp,0b00100000	; Устанавливаем 32кГц источник для TCount2
	sts ASSR, tmp
	
	ldi tmp,0b00000010		; TCount2 вызывает прерывание при сравнении с OCR2A
	sts TIMSK2, tmp

	ldi tmp, OCR2A_val
	sts OCR2A, tmp		; Каждые 4.9 мс (примерно)
wl2:
	lds tmp, ASSR
	sbrc tmp, OCR2AUB
	rjmp wl2

	ldi tmp, 0x01		; TCount2 работает на частоте 32768 Гц
	sts TCCR2B, tmp
wl0:
	lds tmp, ASSR		; Ждем, пока будет обновлен TCCR2B
	sbrc tmp, TCR2BUB
	rjmp wl0

	ldi tmp, 0b00000010	; Режим CTC
	sts TCCR2A, tmp
wl1:
	lds tmp, ASSR
	sbrc tmp, TCR2AUB			; Ждем, пока будет обновлен TCCR2A
	rjmp wl1
;-------- Настраиваем АЦП для измерения опоры относительно напряжения питания
	ldi tmp, 0x00
	sts ADCSRB, tmp
	ldi tmp, 0b01101110	; В качестве опоры - питание на AVCC, в качестве источника для измерения - внутренняя опора 1.1В
						; Данные выравнены влево (ADLAR=1)
	sts ADMUX, tmp
	ldi tmp, 0b10000001	; АЦП включен и работает на частоте 4МГц
	sts ADCSRA, tmp
	ldi tmp, 0x00
	sts DIDR0, tmp
;-------- Настраиваем sleep режим (Power-save mode)
	ldi tmp, 0b00000111
	out SMCR, tmp
;-------- Настраиваем порты
	ldi tmp, 0b00000111	; PORTC - подтяжки включены, PC0, PC1, PC2 - на выход
	out DDRC, tmp
	ldi tmp, 0b01111001	; PC2 - on/off для звука
	out PORTC, tmp

	ldi tmp, 0b00101011
	out DDRB, tmp
	ldi tmp, 0b11010111
	out PORTB, tmp

	ldi tmp, 0b00001100
	out DDRD, tmp
	ldi tmp, 0b11110111
	out PORTD, tmp
;-------- Настраиваем SPI
	ldi tmp, 0b01010000	; Скорость fsck/2, режим 00, мастер
	out SPCR, tmp
	ldi tmp, 0x01
	out SPSR, tmp
	in tmp, SPSR
	in tmp, SPDR
;-------- Настраиваем MCUCR
	ldi tmp, 0x00
	out MCUCR, tmp
;-------- Настраиваем EEPROM
	ldi tmp, 0x00
	out EECR, tmp
;-------- Инициализируем регистры
	clr mode
	clr mode_tmp
	clr sec_part_cnt
	clr r16
	clr r17
	clr r18
	clr r19
	clr r20
	clr r21
	clr r22
	clr r24
	clr r25
	clr r26
	clr r27
	clr r28
	clr r29
	clr r30
	clr r31
	ldi tmp, 0b00111111
	mov kbd, tmp
	mov kbd_prev, tmp
	mov kbd_press, tmp
	mov kbd_release, tmp
	ldi tmp, 0x00
	out GPIOR0, tmp
	ldi refresh, 0b00011111
;-------- Инициализируем значения в памяти
	ldi tmp, 0x00
	LASZ dsecond
	st Z+, tmp
	st Z+, tmp
	ldi tmp, 0x38
	st Z+, tmp
	ldi tmp, 0x16
	st Z+, tmp
	ldi tmp, 0x25
	st Z+, tmp
	ldi tmp, 0x07
	st Z+, tmp
	ldi tmp, 0x14
	st Z+, tmp
	ldi tmp, 0x20
	st Z+, tmp
	ldi tmp, 0x02
	st Z, tmp
	LASZ timer_sec
	ldi tmp, 0x00
	st Z+, tmp
	st Z, tmp

	LAPZ month_len
	ldi YL, low(month_len_ram)
	ldi YH, high(month_len_ram)
	ldi tmp, 12
mlen_cp:
	lpm tmp1, Z+
	st Y+, tmp1
	dec tmp
	brne mlen_cp

;-------- Инициализируем UART для звука
	ldi tmp, 0x00
	sts UBRR0H, tmp
	ldi tmp, 0x33
	sts UBRR0L, tmp
	ldi tmp, 0b01001000
	sts UCSR0B, tmp
	ldi tmp, 0b00000110
	sts UCSR0C, tmp

;-------- Отключаем не используемые модули (TWI, Timer0, Timer1, USART)
	ldi tmp, 0b10101010
	sts PRR, tmp

	sei

	rcall LCD_A70_Init
	rcall LCD_Clear
	LED_OFF
	
	LAPZ music
	rcall play_music
