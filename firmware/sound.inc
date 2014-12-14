; Подпрограммы для звука

sound_on:
	push tmp
	lds tmp, PRR
	andi tmp, 0b11111101
	sts PRR, tmp ; включаем USART
	ldi tmp, 0x00
	sts UDR0, tmp
	ori wflags, 0b00001000
	pop tmp
	ret

sound_off:
	push tmp
	lds tmp, PRR
	ori tmp, 0b00000010
	sts PRR, tmp	; выключаем USART
	andi wflags, 0b11110111
	pop tmp
	ret

sound_freq:
;in: tmp - UBRR0L
	cli
	push tmp
	lds tmp, PRR
	andi tmp, 0b11111101
	sts PRR, tmp ; включаем USART
	ldi tmp, 0
	sts UBRR0H, tmp
	pop tmp
	sts UBRR0L, tmp
	sei
	ret

play_music:
;in: Z - указатель на музыкальную последовательность
	push YL
	push YH
	ldi YL, low(music_pointer_l)
	ldi YH, high(music_pointer_l)
	st Y+, ZL
	st Y, ZH
	pop YH
	pop YL
	ori wflags, 0b00100000
	ret
