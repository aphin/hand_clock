; ������������� ����
	cli
;-------- ������������� �����
    ldi tmp, high(RAMEND)
    out SPH,tmp
    ldi tmp, low(RAMEND)
    out SPL,tmp
;-------- ���������� Watchdog
	wdr
	clr tmp
	sts WDTCSR, tmp
;-------- ����������� ����������� ������
	ldi tmp,0b00100000	; ������������� 32��� �������� ��� TCount2
	sts ASSR, tmp
	
	ldi tmp,0b00000010		; TCount2 �������� ���������� ��� ��������� � OCR2A
	sts TIMSK2, tmp

	ldi tmp, OCR2A_val
	sts OCR2A, tmp		; ������ 4.9 �� (��������)
wl2:
	lds tmp, ASSR
	sbrc tmp, OCR2AUB
	rjmp wl2

	ldi tmp, 0x01		; TCount2 �������� �� ������� 32768 ��
	sts TCCR2B, tmp
wl0:
	lds tmp, ASSR		; ����, ���� ����� �������� TCCR2B
	sbrc tmp, TCR2BUB
	rjmp wl0

	ldi tmp, 0b00000010	; ����� CTC
	sts TCCR2A, tmp
wl1:
	lds tmp, ASSR
	sbrc tmp, TCR2AUB			; ����, ���� ����� �������� TCCR2A
	rjmp wl1
;-------- ����������� ��� ��� ��������� ����� ������������ ���������� �������
	ldi tmp, 0x00
	sts ADCSRB, tmp
	ldi tmp, 0b01101110	; � �������� ����� - ������� �� AVCC, � �������� ��������� ��� ��������� - ���������� ����� 1.1�
						; ������ ��������� ����� (ADLAR=1)
	sts ADMUX, tmp
	ldi tmp, 0b10000001	; ��� ������� � �������� �� ������� 4���
	sts ADCSRA, tmp
	ldi tmp, 0x00
	sts DIDR0, tmp
;-------- ����������� sleep ����� (Power-save mode)
	ldi tmp, 0b00000111
	out SMCR, tmp
;-------- ����������� �����
	ldi tmp, 0b00000111	; PORTC - �������� ��������, PC0, PC1, PC2 - �� �����
	out DDRC, tmp
	ldi tmp, 0b01111001	; PC2 - on/off ��� �����
	out PORTC, tmp

	ldi tmp, 0b00101011
	out DDRB, tmp
	ldi tmp, 0b11010111
	out PORTB, tmp

	ldi tmp, 0b00001100
	out DDRD, tmp
	ldi tmp, 0b11110111
	out PORTD, tmp
;-------- ����������� SPI
	ldi tmp, 0b01010000	; �������� fsck/2, ����� 00, ������
	out SPCR, tmp
	ldi tmp, 0x01
	out SPSR, tmp
	in tmp, SPSR
	in tmp, SPDR
;-------- ����������� MCUCR
	ldi tmp, 0x00
	out MCUCR, tmp
;-------- ����������� EEPROM
	ldi tmp, 0x00
	out EECR, tmp
;-------- �������������� ��������
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
;-------- �������������� �������� � ������
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

;-------- �������������� UART ��� �����
	ldi tmp, 0x00
	sts UBRR0H, tmp
	ldi tmp, 0x33
	sts UBRR0L, tmp
	ldi tmp, 0b01001000
	sts UCSR0B, tmp
	ldi tmp, 0b00000110
	sts UCSR0C, tmp

;-------- ��������� �� ������������ ������ (TWI, Timer0, Timer1, USART)
	ldi tmp, 0b10101010
	sts PRR, tmp

	sei

	rcall LCD_A70_Init
	rcall LCD_Clear
	LED_OFF
	
	LAPZ music
	rcall play_music
