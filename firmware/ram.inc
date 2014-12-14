; Дата-время (BCD)
	dsecond:	.byte 1
	second:	.byte 1
	minute:	.byte 1
	hour:	.byte 1
	day:	.byte 1
	month:	.byte 1
	year:	.byte 2
	day_of_week:	.byte 1

	timer_sec:	.byte 1	; BCD значение таймера (секунды)
	timer_min:	.byte 1	; минуты

	bud_min:	.byte 1	; для будильника
	bud_hr:	.byte 1
	
	month_len_ram: .byte 12

	bv_1: .byte 1	; Напряжение аккумулятора - целая часть BCD
	bv_2: .byte 1	; Дробная часть BCD

	music_pointer_l: .byte 1	; Указатель на текущий музыкальный сэмпл
	music_pointer_h: .byte 1
