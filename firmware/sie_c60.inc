; Siemens C60 display routines

LCD_DrawBar:
;in: lcd_x, lcd_y - координаты левого верхнего угла
; tmp, tmp1 - ширина и высота
	push tmp
	push tmp1
	push lcd_y
	push r20
	push r21

	mov r20, tmp
	mov r21, tmp1

	CS_LOW
dr_bar_col:
	rcall LCD_GotoXY

	CMD_SET
	ldi tmp, 0x2C
	rcall Send_SPI

	DATA_SET
	mov tmp, frg_color
	push r20
dr_bar_line:
	rcall Send_SPI	
	dec r20
	brne dr_bar_line
	pop r20

	inc lcd_y
	dec r21
	brne dr_bar_col

	CS_HIGH

	pop r21
	pop r20
	pop lcd_y
	pop tmp
	pop tmp1
	ret
;--------------------
LCD_DrawBkgBar:
; in: то же что и DrawBar
	push tmp
	mov tmp, frg_color
	mov frg_color, bkg_color
	mov bkg_color, tmp
	pop tmp
	rcall LCD_DrawBar
	push tmp
	mov tmp, frg_color
	mov frg_color, bkg_color
	mov bkg_color, tmp
	pop tmp
	ret
;--------------------
LCD_IdleOn:
	push tmp
	CS_LOW
	CMD_SET
	ldi tmp, 0x39
	rcall Send_SPI
	CS_HIGH
	pop tmp
	ret
;--------------------
LCD_IdleOff:
	push tmp
	CS_LOW
	CMD_SET
	ldi tmp, 0x38
	rcall Send_SPI
	CS_HIGH
	pop tmp
	ret
;--------------------
LCD_DrawBCD:
;in: tmp - число
	push tmp
	push r20

	mov r20, lcd_mx
	lsl r20
	lsl r20
	lsl r20

	push tmp
	lsr tmp
	lsr tmp
	lsr tmp
	lsr tmp
	subi tmp, 0xD0 ; +0x30
	rcall LCD_DrawChar
	add lcd_x, r20
	pop tmp
	andi tmp, 0x0F
	subi tmp, 0xD0
	rcall LCD_DrawChar
	add lcd_x, r20

	pop r20
	pop tmp
	ret
;--------------------
LCD_DrawStringPM:
; in: Z - строка во flash ASCIIZ
	push tmp
	push ZH
	push ZL
	push r20

	mov r20, lcd_mx ; инкремент по X
	lsl r20
	lsl r20
	lsl r20
drst:
	lpm tmp, Z+
	tst tmp
	breq drst_end
	cpi tmp, 0x80
	brlo dr_ansi
	subi tmp, 0x40	; Перевод из Win-1251 в CP866 для заглавных букв (а других русских и нет тут :-)
dr_ansi:
	rcall LCD_DrawChar
	add lcd_x, r20
	rjmp drst
drst_end:
	pop r20
	pop ZL
	pop ZH
	pop tmp
	ret
;--------------------
LCD_DrawByte:
; in: tmp - байт
	push tmp
	push r20

	mov r20, lcd_mx
	lsl r20
	lsl r20
	lsl r20

	push tmp
	swap tmp
	andi tmp, 0x0F
	cpi tmp, 0x0A
	brlo dr_b09
	subi tmp, (0x100 - 'A' + 0x0A)
	rcall LCD_DrawChar
	rjmp dr_b_lnibble
dr_b09:
	subi tmp, 0xD0
	rcall LCD_DrawChar
dr_b_lnibble:
	add lcd_x, r20
	pop tmp
	andi tmp, 0x0F
	cpi tmp, 0x0A
	brlo dr_b09_1
	subi tmp, (0x100 - 'A' + 0x0A)
	rcall LCD_DrawChar
	rjmp dr_b_end
dr_b09_1:
	subi tmp, 0xD0
	rcall LCD_DrawChar
dr_b_end:
	add lcd_x, r20
	pop r20
	pop tmp
	ret
;--------------------
LCD_DrawWord:
; tmp:tmp1 - слово
	push tmp

	rcall LCD_DrawByte
	mov tmp, tmp1
	rcall LCD_DrawByte

	pop tmp
	ret
;--------------------
LCD_DrawChar:
; in: tmp - ASCII код символа
;	lcd_x, lcd_y - координаты
; lcd_mx - масштаб по x
; lcd_my - масштаб по y

;	cpi tmp, 0x20
;	brlo drw_chr_end
	
	push tmp
	push tmp1
	push ZH
	push ZL
	push lcd_x
	push lcd_y
	push r20	; индекс по y
	push r21	; индекс по x
	
	ldi ZH, high(font8x8<<1)
	ldi ZL, low(font8x8<<1)
	subi tmp, 0x20
	clr tmp1 ; tmp1:tmp * 8
	rol tmp
	rol tmp1
	rol tmp
	rol tmp1
	rol tmp
	rol tmp1 ; tmp1:tmp - смещение
	add ZL, tmp
	adc ZH, tmp1

	ldi r20, 0x08
	CS_LOW
cdrw:
	lpm tmp1, Z+
	push lcd_my
mydrw:
	rcall LCD_GotoXY
	CMD_SET
	ldi tmp, 0x2C
	rcall Send_SPI
	DATA_SET
	ldi r21, 0x08
	push tmp1
ldrw:
	sbrs tmp1, 7
	rjmp drw_bkg
	mov tmp, frg_color
	rjmp drw
drw_bkg:
	mov tmp, bkg_color
drw:
	push lcd_mx
mxdrw:
	rcall Send_SPI
	dec lcd_mx
	brne mxdrw
	pop lcd_mx

	lsl tmp1
	dec r21
	brne ldrw
	pop tmp1
	inc lcd_y
	dec lcd_my
	brne mydrw
	pop lcd_my
	dec r20
	brne cdrw	

	CS_HIGH	

	pop r21
	pop r20
	pop lcd_y
	pop lcd_x
	pop ZL
	pop ZH
	pop tmp1
	pop tmp	
drw_chr_end:
	ret
;--------------------
LCD_GotoXY:
; вход lcd_x, lcd_y
	push tmp
	CMD_SET
	ldi tmp, 0x2A
	rcall Send_SPI
	DATA_SET
	mov tmp, lcd_x
	rcall Send_SPI
	ldi tmp, 100
	rcall Send_SPI
	CMD_SET
	ldi tmp, 0x2B
	rcall Send_SPI
	DATA_SET
	mov tmp, lcd_y
	inc tmp
	rcall Send_SPI
	ldi tmp, 80
	rcall Send_SPI
	pop tmp
	ret
;--------------------
LCD_C60_Init:
	push tmp
;; LCD RESET	
	LCD_RESET_LOW
	rcall delay_100ms
	LCD_RESET_HIGH
	rcall delay_100ms
	rcall delay_100ms
	rcall delay_100ms
	rcall delay_100ms
	rcall delay_100ms
	CS_HIGH
	rcall delay_10us
	CS_LOW

;   Send_to_lcd(CMD,0x01); //reset sw
;   DelayMs(50);
;   Send_to_lcd(CMD,0xc6); //initial escape
;   DelayMs(40);
;   Send_to_lcd(CMD,0xb9); //Refresh set
;   Send_to_lcd(DAT,0x00);
	CMD_SET
	ldi tmp, 0x01
	rcall Send_SPI
	rcall delay_10ms
	rcall delay_10ms
	rcall delay_10ms
	rcall delay_10ms
	rcall delay_10ms
	ldi tmp, 0xC6
	rcall Send_SPI
	rcall delay_10ms
	rcall delay_10ms
	rcall delay_10ms
	rcall delay_10ms
	ldi tmp, 0xB9
	rcall Send_SPI
	DATA_SET
	ldi tmp, 0x00
	rcall Send_SPI
;   Send_to_lcd(CMD,0xb6); //Display control
;   Send_to_lcd(DAT,0x80); //
;   Send_to_lcd(DAT,0x04); //
;   Send_to_lcd(DAT,0x8a); //
;   Send_to_lcd(DAT,0x54); //
;   Send_to_lcd(DAT,0x45); //
;   Send_to_lcd(DAT,0x52); //
;   Send_to_lcd(DAT,0x43); //
	CMD_SET
	ldi tmp, 0xB6
	rcall Send_SPI
	DATA_SET
	ldi tmp, 0x80
	rcall Send_SPI
	ldi tmp, 0x04
	rcall Send_SPI
	ldi tmp, 0x8A
	rcall Send_SPI
	ldi tmp, 0x54
	rcall Send_SPI
	ldi tmp, 0x45
	rcall Send_SPI
	ldi tmp, 0x52
	rcall Send_SPI
	ldi tmp, 0x43
	rcall Send_SPI
;   Send_to_lcd(CMD,0xb3); //Gray scale position set 0
;   Send_to_lcd(DAT,0x02); //
;   Send_to_lcd(DAT,0x0a); //
;   Send_to_lcd(DAT,0x15); //
;   Send_to_lcd(DAT,0x1f); //
;   Send_to_lcd(DAT,0x28); //
;   Send_to_lcd(DAT,0x30); //
;   Send_to_lcd(DAT,0x37); //
;   Send_to_lcd(DAT,0x3f); //
;   Send_to_lcd(DAT,0x47); //
;   Send_to_lcd(DAT,0x4c); //
;   Send_to_lcd(DAT,0x54); //
;   Send_to_lcd(DAT,0x65); //
;   Send_to_lcd(DAT,0x75); //
;   Send_to_lcd(DAT,0x80); //
;   Send_to_lcd(DAT,0x85); //
	CMD_SET
	ldi tmp, 0xb3
	rcall Send_SPI
	DATA_SET
	ldi tmp, 0x02
	rcall Send_SPI
	ldi tmp, 0x0a
	rcall Send_SPI
	ldi tmp, 0x15
	rcall Send_SPI
	ldi tmp, 0x1f
	rcall Send_SPI
	ldi tmp, 0x28
	rcall Send_SPI
	ldi tmp, 0x30
	rcall Send_SPI
	ldi tmp, 0x37
	rcall Send_SPI
	ldi tmp, 0x3F
	rcall Send_SPI
	ldi tmp, 0x47
	rcall Send_SPI
	ldi tmp, 0x4c
	rcall Send_SPI
	ldi tmp, 0x54
	rcall Send_SPI
	ldi tmp, 0x65
	rcall Send_SPI
	ldi tmp, 0x75
	rcall Send_SPI
	ldi tmp, 0x80
	rcall Send_SPI
	ldi tmp, 0x85
	rcall Send_SPI
;   Send_to_lcd(CMD,0xb5); //Gamma curve
;   Send_to_lcd(DAT,0x01); //
	CMD_SET
	ldi tmp, 0xB5
	rcall Send_SPI
	DATA_SET
	ldi tmp, 0x01
	rcall Send_SPI
;   Send_to_lcd(CMD,0xb7); //Temperature gradient
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x00); //
	CMD_SET
	ldi tmp, 0xB7
	rcall Send_SPI
	DATA_SET
	ldi tmp, 0x00
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
	rcall Send_SPI
;   Send_to_lcd(CMD,0xbd); //Common driver output select
;   Send_to_lcd(DAT,0x00); //
	CMD_SET
	ldi tmp, 0xBD
	rcall Send_SPI
	DATA_SET
	ldi tmp, 0x00
	rcall Send_SPI
;   Send_to_lcd(CMD,0x36); //Memory access control
;   Send_to_lcd(DAT,0x48); //
	CMD_SET
	ldi tmp, 0x36
	rcall Send_SPI
	DATA_SET
	ldi tmp, 0b01001000
	rcall Send_SPI
;   Send_to_lcd(CMD,0x2d); //Colour set
;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x03); //
;   Send_to_lcd(DAT,0x05); //
;   Send_to_lcd(DAT,0x07); //
;   Send_to_lcd(DAT,0x09); //
;   Send_to_lcd(DAT,0x0b); //
;   Send_to_lcd(DAT,0x0d); //
;   Send_to_lcd(DAT,0x0f); //

;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x03); //
;   Send_to_lcd(DAT,0x05); //
;   Send_to_lcd(DAT,0x07); //
;   Send_to_lcd(DAT,0x09); //
;   Send_to_lcd(DAT,0x0b); //
;   Send_to_lcd(DAT,0x0d); //
;   Send_to_lcd(DAT,0x0f); //

;   Send_to_lcd(DAT,0x00); //
;   Send_to_lcd(DAT,0x05); //
;   Send_to_lcd(DAT,0x0b); //
;   Send_to_lcd(DAT,0x0f); //
	
	CMD_SET
	ldi tmp, 0x2D
	rcall Send_SPI
	DATA_SET
	ldi tmp, 0x00
	rcall Send_SPI
	ldi tmp, 0x03
	rcall Send_SPI
	ldi tmp, 0x05
	rcall Send_SPI
	ldi tmp, 0x07
	rcall Send_SPI
	ldi tmp, 0x09
	rcall Send_SPI
	ldi tmp, 0x0b
	rcall Send_SPI
	ldi tmp, 0x0d
	rcall Send_SPI
	ldi tmp, 0x0f
	rcall Send_SPI
	ldi tmp, 0x00
	rcall Send_SPI
	ldi tmp, 0x03
	rcall Send_SPI
	ldi tmp, 0x05
	rcall Send_SPI
	ldi tmp, 0x07
	rcall Send_SPI
	ldi tmp, 0x09
	rcall Send_SPI
	ldi tmp, 0x0b
	rcall Send_SPI
	ldi tmp, 0x0d
	rcall Send_SPI
	ldi tmp, 0x0f
	rcall Send_SPI

	ldi tmp, 0x00
	rcall Send_SPI
	ldi tmp, 0x05
	rcall Send_SPI
	ldi tmp, 0x0b
	rcall Send_SPI
	ldi tmp, 0x0f
	rcall Send_SPI

;   Send_to_lcd(CMD,0xba); //Voltage control
;   Send_to_lcd(DAT,0x2f); //
;   Send_to_lcd(DAT,0x03); //
	CMD_SET
	ldi tmp, 0xBA
	rcall Send_SPI
	DATA_SET
	ldi tmp, 0x2F
	rcall Send_SPI
	ldi tmp, 0x03
	rcall Send_SPI
;   Send_to_lcd(CMD,0x25); //Send_to_lcd contrast
;   Send_to_lcd(DAT,0x64); // Стоит поиграться со значением контраста, у меня в примере контраст 100, если больше то на дисплее ничего нет
;   Send_to_lcd(DAT,0x61); //me контраст одинаковый для 0x6e и 0xee
	CMD_SET
	ldi tmp, 0x25
	rcall Send_SPI
	DATA_SET
	ldi tmp, 0x61
	rcall Send_SPI
;   Send_to_lcd(CMD,0xbe); //Power control
;   Send_to_lcd(DAT,0x59); // me
;   Send_to_lcd(DAT,0x58); // У меня пишется в этот регистр значение 0х58
	CMD_SET
	ldi tmp, 0xBE
	rcall Send_SPI
	DATA_SET
	ldi tmp, 0x58
	rcall Send_SPI
;   Send_to_lcd(CMD,0x3a); //interface pixel format
;   Send_to_lcd(DAT,0x02); //me 8-и битный цвет
;   Send_to_lcd(DAT,0x03); //12-и битный цвет
	CMD_SET
	ldi tmp, 0x3A
	rcall Send_SPI
	DATA_SET
	ldi tmp, 0x02
	rcall Send_SPI
	CMD_SET
	ldi tmp, 0x21	// Inverse colors
	rcall Send_SPI
;   Send_to_lcd(CMD,0x03); //Booster voltage ON
;   DelayMs(40);
	ldi tmp, 0x03
	rcall Send_SPI
	rcall delay_10ms
	rcall delay_10ms
	rcall delay_10ms
	rcall delay_10ms
;   Send_to_lcd(CMD,0x11); //sleep out
;   DelayMs(20); //Перед включением ждем 20 миллисекунд 
	ldi tmp, 0x11
	rcall Send_SPI
	rcall delay_10ms
	rcall delay_10ms
;   Send_to_lcd(CMD,0x29); //Display ON
	ldi tmp, 0x29
	rcall Send_SPI

	CS_HIGH
	pop tmp
	ret

;--------------------
LCD_Clear:
	push tmp
	push tmp1	
	push lcd_x
	push lcd_y
	CS_LOW
	clr tmp
	mov lcd_x, tmp
	mov lcd_y, tmp
	rcall LCD_GotoXY

	CMD_SET
	ldi tmp, 0x2C
	rcall Send_SPI
	DATA_SET
	mov tmp, bkg_color
		
	ldi tmp1, 80
cclr:
	push tmp1
	ldi tmp1, 101
lclr:
	rcall Send_SPI
	dec tmp1
	brne lclr
	pop tmp1
	dec tmp1
	brne cclr

	CS_HIGH
	pop lcd_y
	pop lcd_x
	pop tmp1
	pop tmp
	ret


