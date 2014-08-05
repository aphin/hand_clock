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
;-------- ��������� �� ������������ ������ (TWI, Timer0, Timer1, USART, ADC)
	ldi tmp, 0b10101011
	sts PRR, tmp
;-------- ����������� sleep ����� (Power-save mode)
	ldi tmp, 0b00000111
	out SMCR, tmp
;-------- ����������� �����
	ldi tmp, 0b00000011	; PORTC - �������� ��������, PC0, PC1 - �� �����
	out DDRC, tmp
	ldi tmp, 0b01111101
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
	clr r23
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
	out GPIOR1, tmp
;-------- �������������� �������� � ������
	ldi tmp, 0x00
	ldi ZH, high(dsecond)
	ldi ZL, low(dsecond)
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

	ldi ZH, high(sec_duration)
	ldi ZL, low(sec_duration)
;	ldi tmp, sec_dur_eep

;eep_w:
;	sbic EECR, 1
;	rjmp eep_w

;	out EEARL, tmp
;	sbi EECR, 0
;	in tmp, EEDR
	ldi tmp, TimCntVal	; � ���� ������ �������� ������� ����� ����������� ������ 1/7 ������� (� ������)
	st Z, tmp

	ldi tmp1, 0x05
	mov lcd_x, tmp1
	mov lcd_y, tmp1
	ldi tmp1, 0xFF
	mov frg_color, tmp1
	ldi tmp1, 0x00
	mov bkg_color, tmp1
	ldi tmp1, 0x01
	mov lcd_mx, tmp1
	mov lcd_my, tmp1

	sei

	rcall LCD_C60_Init
	CS_HIGH
	rcall LCD_Clear
	LED_OFF