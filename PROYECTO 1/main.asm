;
; PROYECTO 1.asm
;
; Created: 13/03/2025 13:43:46
; Author : Daniela Alexandra Moreira Cruz
;Descripción: Separé la parte del display del proyecto para descartar factores no correspondientes a la subrutina. 

.include "M328PDEF.inc"
//definición de variables útiles 
.equ	T0VALUE = 6 ;numero en el que debe empezar a contar T0
.equ	T1VALUE = 0x0BCD ;numero en el que debe empezar a contar T0
.equ	MAX_UNI = 9 ;numero para el overflow unidades 
.equ	MAX_DEC = 5 ;numero para el overflow decenas 
.equ	MAXT0	= 5
.equ	MODOS = 6 ; número máximo de modos 
.equ	CICLO = 1 ; número de ciclos del timer 1 que deben cumplirse 
.def	CONTADORT0= R17; contador para llevar el registro de los transistores de los display 
.def	MODO	= R18 ; variable para el contdor de los modos 
.def	CONTADORT1L= R19
.def	S_DISPLAY = R20
.def	CONTADOR_TIEMPO = R21  
.def	DISPLAYS = R22
.def	CONTADOR_BOTONES= R23
.dseg 
.org	SRAM_START 
MINUTO:		.byte	1 ; para registar que ya paso un min y debe cambiar umin 
UMIN:		.byte	1 ; la variable que guarda el conteo de unidades de minutos 
DMIN:		.byte	1 ; la variable que guarda el conteo de decenas de minutos 
UHORAS:		.byte	1 ; la variable que guarda la unidades el conteo de horas 
DHORAS:		.byte	1 ; la varible que guarda las decenas en el conteo de horas 
DISPLAY1:	.byte	1 ;variables para guardar lo que mostrará el display según el modo
DISPLAY2:	.byte	1 ;variables para guardar lo que mostrará el display según el modo
DISPLAY3:	.byte	1 ;variables para guardar lo que mostrará el display según el modo
DISPLAY4:	.byte	1 ;variables para guardar lo que mostrará el display según el modo
BOTON:		.byte	1 ; variable para el contador de l botón 
U_D:		.byte	1 ; variable para selecciónar entre configuración de horas/meses o min/días 
UD_U_H:		.byte	1 ;variable para configurar las	unidades de minutos
UD_D_H:		.byte	1 ;variable para condigurar las	decenas de minutos 
UD_C_H:		.byte	1 ;variable para condigurar las	unidades de horas
UD_M_H:		.byte	1 ;variable para condigurar las	decenas de horas 

UD_U_F:		.byte	1 ;variable para configurar las	unidades de minutos
UD_D_F:		.byte	1 ;variable para condigurar las	decenas de minutos 
UD_C_F:		.byte	1 ;variable para condigurar las	unidades de horas
UD_M_F:		.byte	1 ;variable para condigurar las	decenas de horas 

.cseg
.org 0x0000
    RJMP SETUP  
.org PCI1addr // para el pin change
    JMP ISR_PCINT1
.org	0x001A
	RJMP	TMR1_ISR ; para el timer 1 
.org OVF0addr // Para el timer 0 
	JMP TMR0_ISR ; interrupción del Timer 0 


// Configuración de la pila
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

// Configuración MCU
SETUP:
    CLI 
	/**************COFIGURACION DE PRESCALER********/
	// Configuración de prescaler inicial
    LDI		R16, (1 << CLKPCE)
    STS		CLKPR, R16 // Habilitar cambio de PRESCALER
    LDI		R16, 0b00000100
    STS		CLKPR, R16 // Configurar Prescaler en 1MHz

	/*************COFIGURACION DE PINES ********/
    // Configurar PB como salidas
    LDI		R16, 0xFF
    OUT		DDRB, R16       // Puerto B como salida
    LDI		R16, 0x00
    OUT		PORTB, R16      // El puerto B conduce cero lógico.

	//Configurar el puerto D como salidas, estabecerlo en apagado
	LDI		R16, 0xFF
	OUT		DDRD, R16 // Setear puerto D como salida
	LDI		R16, 0x00
	OUT		PORTD, R16 //Todos los bits en apagado 


	// Configurar PC3 y PC5 como salidas, PC0-PC2 como entradas
    LDI R16, 0b00101000       ; 00011000 - PC3 y PC5 como salidas, el resto entradas
    OUT DDRC, R16      ; Escribir en el registro DDRC

    // Activar pull-ups en PC0, PC1, PC2 y PC3
    LDI R16, 0b00010111      ; 00000111 - Habilita pull-ups en PC0, PC1, PC2 y PC4
    OUT PORTC, R16     ; Escribir en el registro PORTC

	/************** HABILITAR EL TIMER   ********/
	CALL	INIT_TMR0 
	CALL	INIT_TMR1
	/************** INTERRUPCIONES  ********/
	//timer 0
	LDI		R16, (1 << TOIE0)
    STS		TIMSK0, R16 
	//timer 1 
	LDI		R16, (1<<TOIE1)
	STS		TIMSK1, R16 


	// Habilitar las interrupciones para el antirebote
    LDI R16, (1<<PCINT8) | (1<<PCINT9) | (1<<PCINT10) | (1<<PCINT12) // Habilitar pin 0, pin 1 y pin 2
    STS PCMSK1, R16       // Cargar a PCMSK1
    LDI R16, (1 << PCIE1) // Habilitar interrupciones para el pin C 
    STS PCICR, R16

	/************** INCIALIZAR VARIABLES  ********/
	CLR		CONTADORT0 
	CLR		MODO
	CLR		CONTADORT1L
	CLR		DISPLAYS
	CLR		CONTADOR_TIEMPO 
	CLR		CONTADOR_BOTONES
	LDI		R16, 0x00
	STS		UMIN, R16	
	STS		DMIN, R16	
	STS		UHORAS, R16 
	STS		DHORAS, R16
	STS		MINUTO, R16
	STS		DISPLAY1, R16	
	STS		DISPLAY2, R16	
	STS		DISPLAY3, R16 
	STS		DISPLAY4, R16	
	STS		U_D, R16
	STS		UD_U_H, R16	
	STS		UD_D_H, R16 
	STS		UD_C_H, R16
	STS		UD_M_H, R16
	STS		UD_U_F, R16	
	STS		UD_D_F, R16 
	STS		UD_C_F, R16
	STS		UD_M_F, R16
//	CLR		ACCION

	/************** ACTIVAR LAS INTERRUPCIONES GLOBALES ********/ 
	SEI 

	/************** DESACTIVAR EL SERIAL  ********/
	LDI		R16, 0x00
	STS		UCSR0B, R16 

/************** MAINLOOP  ********/
MAIN:  
	//OUT		PORTB, CONTADOR // mostrar el valor de el contador en el puerto B
	//SBI		PORTD, 2   
	CPI		MODO, 0x00 
	BREQ	HORA
	CPI		MODO, 0x01 
	BREQ	FECHA
	CPI		MODO, 0x02
	BREQ	C_HORA
	CPI		MODO, 0x03 
	BREQ	C_FECHA
	CPI		MODO, 0x04 
	BREQ	C_ALARMA
	CPI		MODO, 0x05
	BREQ	APAGAR_ALARMA
	
    RJMP	MAIN

/*************** MODOS ***********************/
HORA:
	SBI		PORTB, 0
	CBI		PORTB, 1
	LDS     CONTADOR_TIEMPO, UMIN  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY1, CONTADOR_TIEMPO ; tomar el valor del registro y guardarlo en el valor que tendrá el display 1
	LDS     CONTADOR_TIEMPO, DMIN ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY2, CONTADOR_TIEMPO ; tomar el valor del registro y guardarlo en el valor que tendrá el display2
	LDS     CONTADOR_TIEMPO, UHORAS ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY3, CONTADOR_TIEMPO ; tomar el valor del registro y guardarlo en el valor que tendrá el display3
	LDS     CONTADOR_TIEMPO, DHORAS ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY4, CONTADOR_TIEMPO ; tomar el valor del registro y guardarlo en el valor que tendrá el display4

	RJMP	MAIN

FECHA:
	CBI		PORTB, 0
	CBI		PORTB, 1
	CBI		PORTC, 3
	LDI		R16, 0x09
	STS		DISPLAY1, R16
	RJMP	MAIN

C_HORA:
	SBI		PORTB, 0
	CBI		PORTB, 1
	CBI		PORTC, 3
	//Suma y resta de los botones 
	LDS     CONTADOR_BOTONES, UD_U_H  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY1, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 1
	LDS     CONTADOR_BOTONES, UD_D_H  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY2, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 2
	LDS     CONTADOR_BOTONES, UD_C_H  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY3, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 3
	LDS     CONTADOR_BOTONES, UD_M_H  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY4, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 1
	RJMP	MAIN

C_FECHA:
	CBI		PORTB, 0
	SBI		PORTB, 1
	CBI		PORTC, 3
	RJMP	MAIN

C_ALARMA:
	CBI		PORTB, 0
	CBI		PORTB, 1
	SBI		PORTC, 4
	RJMP	MAIN

APAGAR_ALARMA:
	CBI		PORTB, 0
	CBI		PORTB, 1
	CBI		PORTC, 3
	RJMP	MAIN
/************** INTERRUPCIONES PIN CHANGE  ********/
ISR_PCINT1: 
    PUSH	R16
    IN		R16, SREG
    PUSH	R16
	//Para el botón de modos 
    SBIS	PINC, PC2	 // Leer si el botón de cambio de modo está en set, si lo está saltar la siguiente linea
	JMP		BOTONMODO
	SBIS	PINC, PC0
	JMP		BOTON_SUMA
	SBIS	PINC, PC1
	JMP		BOTON_RESTA
	SBIS	PINC, PC4
	JMP		UNIDADES_DECENAS
    JMP		F_ISR
BOTONMODO:
	INC		MODO
	LDI		R16, MODOS
	CPSE	MODO, R16 //Saltar si son iguales 
	JMP		F_ISR
	CLR		MODO ; Si el modo se pasó del limite limpiarlo y comenzar el 0 
	JMP		F_ISR
BOTON_SUMA:
	CPI		MODO, 0x02 ;si el botón de suma fue el que se presionó comparar en que modo se está 
	BREQ	SUMA_HORA 
	CPI		MODO,0x03
	BREQ	SUMA_FECHA
	JMP		F_ISR
SUMA_HORA:
	LDS     CONTADOR_BOTONES, U_D
	CPI		CONTADOR_BOTONES, 0x00 ;si el botón de suma fue el que se presionó comparar en que modo se está 
	BREQ	SUMA_HORA_UNIDADES 
	CPI		CONTADOR_BOTONES, 0x01
	BREQ	SUMA_HORA_DECENAS
	JMP		F_ISR
SUMA_HORA_UNIDADES:
	//Para solo modificar en un solo modo 
	LDS     CONTADOR_BOTONES, UD_U_H
	//Ahora se le suma el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,MAX_UNI
	BREQ	OFUC
	INC		CONTADOR_BOTONES		; incrementa la variable
    STS     UD_U_H, CONTADOR_BOTONES
	JMP		F_ISR
OFUC:
	LDI		CONTADOR_BOTONES, 0x00
	STS     UD_U_H, CONTADOR_BOTONES ; Limpiar las unidades
	LDS     CONTADOR_BOTONES, UD_D_H
	INC		CONTADOR_BOTONES
	STS     UD_D_H, CONTADOR_BOTONES
	LDI		R16, 0x06
	CPSE	CONTADOR_BOTONES, R16 ; Saltar la siguiente linea si son iguales 
	JMP		F_ISR
	CLR		CONTADOR_BOTONES
	STS     UD_D_H, CONTADOR_BOTONES
	JMP		F_ISR
	
SUMA_HORA_DECENAS:
	LDS     CONTADOR_BOTONES, UD_C_H
	//Ahora se le suma el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,MAX_UNI
	BREQ	OFDC
	INC		CONTADOR_BOTONES		; incrementa la variable
    STS     UD_C_H, CONTADOR_BOTONES
	JMP		F_ISR
OFDC:
	LDI		CONTADOR_BOTONES, 0x00
	STS     UD_C_H, CONTADOR_BOTONES ; Limpiar las unidades
	LDS     CONTADOR_BOTONES, UD_M_H
	INC		CONTADOR_BOTONES
	STS     UD_M_H, CONTADOR_BOTONES
	LDI		R16, 0x06
	CPSE	CONTADOR_BOTONES, R16 ; Saltar la siguiente linea si son iguales 
	JMP		F_ISR
	CLR		CONTADOR_BOTONES
	STS     UD_M_H, CONTADOR_BOTONES
	JMP		F_ISR
SUMA_FECHA:
	JMP		F_ISR
BOTON_RESTA:
	CPI		MODO, 0x02 ;si el botón de suma fue el que se presionó comparar en que modo se está 
	JMP		RESTA_HORA 
	CPI		MODO,0x03
	JMP		RESTA_FECHA
	JMP		F_ISR

RESTA_HORA:
	LDS     CONTADOR_BOTONES, U_D
	CPI		CONTADOR_BOTONES, 0x00 ;si el botón de suma fue el que se presionó comparar en que modo se está 
	BREQ	RESTA_HORA_UNIDADES 
	CPI		CONTADOR_BOTONES, 0x01
	BREQ	RESTA_HORA_DECENAS
	JMP		F_ISR
RESTA_HORA_UNIDADES:
	//Para solo modificar en un solo modo 
	LDS     CONTADOR_BOTONES, UD_U_H
	//Ahora se le RESTA el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,0x00
	BREQ	OUFU
	DEC		CONTADOR_BOTONES		; incrementa la variable
    STS     UD_U_H, CONTADOR_BOTONES
	JMP		F_ISR
OUFU:
	LDI		CONTADOR_BOTONES, 0x09
	STS     UD_U_H, CONTADOR_BOTONES ; Limpiar las unidades
	LDS     CONTADOR_BOTONES, UD_D_H
	CPI		CONTADOR_BOTONES, 0x00
	BREQ	OUFU2
	DEC		CONTADOR_BOTONES
	STS     UD_D_H, CONTADOR_BOTONES
	JMP		F_ISR
OUFU2:
	LDS     CONTADOR_BOTONES, UD_D_H
	LDI		CONTADOR_BOTONES, 0x05
	STS     UD_D_H, CONTADOR_BOTONES
	JMP		F_ISR
RESTA_HORA_DECENAS:
	//Para solo modificar en un solo modo 
	LDS     CONTADOR_BOTONES, UD_C_H
	//Ahora se le RESTA el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,0x00
	BREQ	OUFD
	DEC		CONTADOR_BOTONES		; incrementa la variable
    STS     UD_C_H, CONTADOR_BOTONES
	JMP		F_ISR
OUFD:
	LDI		CONTADOR_BOTONES, 0x09
	STS     UD_C_H, CONTADOR_BOTONES ; Limpiar las unidades
	LDS     CONTADOR_BOTONES, UD_M_H
	CPI		CONTADOR_BOTONES, 0x00
	BREQ	OUFD2
	DEC		CONTADOR_BOTONES
	STS     UD_M_H, CONTADOR_BOTONES
	JMP		F_ISR
OUFD2:
	LDS     CONTADOR_BOTONES, UD_M_H
	LDI		CONTADOR_BOTONES, 0x05
	STS     UD_M_H, CONTADOR_BOTONES
	JMP		F_ISR

UNIDADES_DECENAS: 
	LDS     CONTADOR_BOTONES, U_D
	INC		CONTADOR_BOTONES
	STS     U_D, CONTADOR_BOTONES
	LDI		R16, 0x02
	CPSE	CONTADOR_BOTONES, R16 //Saltar si son iguales
	JMP		F_ISR
	CLR		CONTADOR_BOTONES
	STS     U_D, CONTADOR_BOTONES
	JMP		F_ISR
RESTA_FECHA:
	JMP		F_ISR	
F_ISR:
    POP R16
    OUT SREG, R16
    POP R16
    RETI
/************************************* INTERRUPCIONES DEL T0******************************************/ 
TMR0_ISR:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16
	//Establecer los leds en apagado inicialmente 
	CBI		PORTB, 2
	CBI		PORTB, 3
	CBI		PORTB, 4
	CBI		PORTB, 5
	INC		CONTADORT0
	//VERIFICAR QUE NO HAYA EXEDIDO EL LÍMITE 
	LDI		R16, MAXT0
	CPSE	CONTADORT0, R16 //Saltar si son iguales 
	JMP		MUX
	LDI		CONTADORT0, 0x00
	JMP		FIN_T0
MUX: 
	CPI		CONTADORT0, 0x01           ; PB2
    BREQ	DISPLAY_1
    CPI		CONTADORT0, 0x02           ; PB3
    BREQ	DISPLAY_2
    CPI		CONTADORT0, 0x03          ; PB4
    BREQ	DISPLAY_3
    CPI		CONTADORT0, 0x04           ; PB5
    BREQ	DISPLAY_4
	JMP		FIN_T0
DISPLAY_1:
	//ENCENDER SOLO EL TRANSISTOR NECESARIO 
	SBI		PORTB, 2
	LDS		DISPLAYS, DISPLAY1 ; El registro de display tiene la salida de display 1 según el modo
	//SOLO PARA PROBAR QUE EL MUX FUNCIONE    
	LDI		ZH, HIGH(TABLA<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADD		ZL, DISPLAYS
    LPM		S_DISPLAY, Z
    OUT		PORTD, S_DISPLAY
	JMP		FIN_T0
DISPLAY_2:
	//ENCENDER SOLO EL TRANSISTOR NECESARIO 
	SBI		PORTB, 3
	LDS		DISPLAYS, DISPLAY2
	//SOLO PARA PROBAR QUE EL MUX FUNCIONE 
	LDI		ZH, HIGH(TABLA<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADD		ZL, DISPLAYS 
    LPM		S_DISPLAY, Z
    OUT		PORTD, S_DISPLAY
	JMP		FIN_T0
DISPLAY_3:
	//ENCENDER SOLO EL TRANSISTOR NECESARIO 
	SBI		PORTB, 4
	LDS		DISPLAYS, DISPLAY3
	//SOLO PARA PROBAR QUE EL MUX FUNCIONE 
	LDI		ZH, HIGH(TABLA<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADD		ZL, DISPLAYS
    LPM		S_DISPLAY, Z
    OUT		PORTD, S_DISPLAY
	JMP		FIN_T0
DISPLAY_4:
	//ENCENDER SOLO EL TRANSISTOR NECESARIO 
	SBI		PORTB, 5
	LDS		DISPLAYS, DISPLAY4
	//SOLO PARA PROBAR QUE EL MUX FUNCIONE 
	LDI		ZH, HIGH(TABLA<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADD		ZL, DISPLAYS
    LPM		S_DISPLAY, Z
    OUT		PORTD, S_DISPLAY
	JMP		FIN_T0
FIN_T0:
    POP R16
    OUT SREG, R16
    POP R16
    RETI

/*************** INTERRUPCIONES DEL T1************/ 
TMR1_ISR:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16
	LDI		R16, 0b00000100
	//PAPADEO DE LOS LEDS 
	EOR		S_DISPLAY, R16
	OUT		PORTD, S_DISPLAY

	//Conteo de Tiempo 
	LDS     CONTADOR_TIEMPO, MINUTO
    INC     CONTADOR_TIEMPO
    STS     MINUTO, CONTADOR_TIEMPO

    ; Verificar si ya pasó el tiempo necesario 
    CPI     CONTADOR_TIEMPO, CICLO	
    BRNE    FIN_TMR1  ; Si no ha llegado salir
	CLR		CONTADOR_TIEMPO
	STS     MINUTO, CONTADOR_TIEMPO 
	// SUMAR A UMIN 
	LDS     CONTADOR_TIEMPO, UMIN 
	CPI		CONTADOR_TIEMPO, MAX_UNI ; COMPARAR PARA VER SI SUPERO UNIDADES 
	BREQ	OFU
	INC		CONTADOR_TIEMPO
	STS		UMIN, CONTADOR_TIEMPO 

	JMP		FIN_TMR1
FIN_TMR1: 
	//CBI		PORTD, 2
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI
OFU: 
    LDI     CONTADOR_TIEMPO, 0x00        ; Reiniciar unidades de minutos
    STS     UMIN, CONTADOR_TIEMPO
    LDS     CONTADOR_TIEMPO, DMIN        ; Cargar decenas de minutos
    CPI     CONTADOR_TIEMPO, MAX_DEC     ; Verificar si DMIN == 5
    BREQ    OFUD                         ; Si es 5, reiniciar decenas y unidades
    INC     CONTADOR_TIEMPO              ; Si no, incrementar DMIN
    STS     DMIN, CONTADOR_TIEMPO
    JMP     FIN_TMR1

OFUD: 
    LDI     CONTADOR_TIEMPO, 0x00        ; Reiniciar unidades de minutos
    STS     UMIN, CONTADOR_TIEMPO
    STS     DMIN, CONTADOR_TIEMPO        ; Reiniciar decenas de minutos

    ; Incrementar horas
    LDS     CONTADOR_TIEMPO, UHORAS      ; Cargar unidades de horas
    CPI     CONTADOR_TIEMPO, MAX_UNI     ; Verificar si UHORAS == 9
    BREQ    OFDH                         ; Si es 9, reiniciar UHORAS e incrementar DHORAS
    INC     CONTADOR_TIEMPO              ; Si no, incrementar UHORAS
    STS     UHORAS, CONTADOR_TIEMPO
    JMP     FIN_TMR1

OFDH:
    LDI     CONTADOR_TIEMPO, 0x00        ; Reiniciar unidades de horas
    STS     UHORAS, CONTADOR_TIEMPO
    LDS     CONTADOR_TIEMPO, DHORAS      ; Cargar decenas de horas
    CPI     CONTADOR_TIEMPO, 0x02        ; Verificar si DHORAS == 2
    BREQ    OFT                          ; Si es 2, verificar si UHORAS == 4 (24 horas)
    INC     CONTADOR_TIEMPO              ; Si no, incrementar DHORAS
    STS     DHORAS, CONTADOR_TIEMPO
    JMP     FIN_TMR1

OFT: 
    LDS     CONTADOR_TIEMPO, UHORAS      ; Cargar unidades de horas
    CPI     CONTADOR_TIEMPO, 0x04        ; Verificar si UHORAS == 4
    BRNE    FIN_TMR1                     ; Si no es 4, salir
    LDS     CONTADOR_TIEMPO, DHORAS      ; Cargar decenas de horas
    CPI     CONTADOR_TIEMPO, 0x02        ; Verificar si DHORAS == 2
    BRNE    FIN_TMR1                     ; Si no es 2, salir

    ; Reiniciar todas las variables de tiempo (24 horas)
    LDI     CONTADOR_TIEMPO, 0x00        ; Cargar 0 en el registro
    STS     UMIN, CONTADOR_TIEMPO        ; Reiniciar unidades de minutos
    STS     DMIN, CONTADOR_TIEMPO        ; Reiniciar decenas de minutos
    STS     UHORAS, CONTADOR_TIEMPO      ; Reiniciar unidades de horas
    STS     DHORAS, CONTADOR_TIEMPO      ; Reiniciar decenas de horas
    JMP     FIN_TMR1                     ; Salir de la interrupción
/************ CONFIGURACIÓN T0 *********/ 
INIT_TMR0:
	LDI R16, (1<<CS01)//Configurar el prescales en 64 bits
    OUT TCCR0B, R16																																					
    LDI R16, T0VALUE // Valor inicial de TCNT0 para un delay de 2 ms 
    OUT TCNT0, R16
   	RET																																																																																																				
INIT_TMR1:
	LDI R16, HIGH(T1VALUE)
	STS	TCNT1H, R16
	LDI R16, LOW(T1VALUE)
	STS	TCNT1L, R16

	LDI	R16, 0x00
	STS	TCCR1A, R16
	LDI R16, (1<<CS01) // configuración para el prescaler de 8 
    STS TCCR1B, R16																																					

   	RET	
	
// Tabla para 7 segmentos 
TABLA: .DB 0x7B, 0x0A, 0xB3, 0x9B, 0xCA, 0xD9, 0xF9, 0x0B, 0xFB, 0xDB, 0xEB, 0xF8, 0x71, 0xB4, 0xF1, 0xE1							 																																																																																																																																																																																																																																																																																																																																																																																																								