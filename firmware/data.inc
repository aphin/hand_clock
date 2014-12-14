; Данные на flash
month_len:
	.db 0x32,0x29,0x32,0x31,0x32,0x31,0x32,0x32,0x31,0x32,0x31,0x32

; Символьные константы
month_names:
	.db iA,N,V,ZER
	.db F,E,V,ZER
	.db M,A,R,ZER
	.db A,P,R,ZER
	.db M,A,iI,ZER
	.db I,iU,N,ZER
	.db I,iU,L,ZER
	.db A,V,G,ZER
	.db S,E,N,ZER
	.db O,K,T,ZER
	.db N,O,iA,ZER
	.db D,E,K,ZER

week_day_names:
mon:	.db P,O,N,E,D,E,L,mZn,N,I,K,ZER
tue:	.db SPC,SPC,V,T,O,R,N,I,K,SPC,SPC,ZER
wed:	.db SPC,SPC,SPC,S,R,E,D,A,SPC,SPC,SPC,ZER
thu:	.db SPC,SPC,Ch,E,T,V,E,R,G,SPC,SPC,ZER
fri:	.db SPC,SPC,P,iA,T,N,I,C,A,SPC,SPC,ZER
sat:	.db SPC,SPC,S,U,B,B,O,T,A,SPC,SPC,ZER
sun:	.db V,O,S,K,R,E,S,E,N,I,E,ZER

tim_str: .db T,A,iI,M,E,R,ZER,0x00
bud_str: .db B,U,D,I,L,mZn,N,I,K,ZER

corr_table:
	.dw hour, minute, second, day, day_of_week, month, year

corr_max_value:
	.dw 0x24, 0x60, 0x60, 0x00, 0x07, 0x12, 0x9999

sie_a70_init:
	.db 0x21, 0x14, 0x0A, 0x05, 0xCC, 0x20, 0x11, 0x0C

w_time_corr:	; Коррекция времени. Когда часы "покажут" это время, программа "сбросит" их в 00:00:00.0 - это коррекция для "убегающих" часов
	.db 0x00,0x00,0x00,0x00 ; доли секунд, секунды, минуты, часы

; Звуковая последовательность. Первый байт - частота, второй - длительность (5 мс интервалы). Если частота задана как 0,
; то это означает паузу. Если длительность задана как 0, то это означает конец последовательности
; Частота - константы для UBRR0
music: .db o5A,T1_4,o5E,T1_4,o5A,T1_4,o5E,T1_4,o5A,T1_4,o5Gd,T1_4,o5Gd,T1_2,0x00,t1_8,o5Gd,T1_4,o5E,T1_4,o5Gd,T1_4,o5E,T1_4,o5Gd,T1_4,o5A,T1_4,o5A,T1_2,0x00,t1_8,0x00,0x00
