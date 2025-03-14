;
; PROYECTO 1.asm
;
; Created: 13/03/2025 13:43:46
; Author : Daniela Alexandra Moreira Cruz
;Descripción: Separé la parte del display del proyecto para descartar factores no correspondientes a la subrutina. 

.include "M328PDEF.inc"
//definición de variables útiles 
.equ	T0VALUE = 6 ;numero en el que debe empezar a contar T0
.equ	MAX_UNI = 10 ;numero para el overflow unidades 
.equ	MAX_DEC = 6 ;numero para el overflow decenas 
.equ	MAXT0	= 5
.equ	MODOS = 6 ; número máximo de modos 
.def	CONTADORT0= R21; contador para llevar el registro de los transistores de los display 
.def	MODO	= R20 ; variable para el contdor de los modos 
.def	S_DISPLAY = R19
.dseg 
.org	SRAM_START 
UMIN:	.byte	1 ; la variable que guarda el conteo de unidades de segundos 
DMIN:	.byte	1 ; la variable que guarda el conteo de decenas de segundos 

.cseg
.org 0x0000
    RJMP SETUP  
.org PCI1addr
    JMP ISR_PCINT1
	   
;Aquí debería estar la interrupción del pinchange para no causar interferencia 
.org OVF0addr
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


	// Configurar PC3 y PC4 como salidas, PC0-PC2 como entradas
    LDI R16, 0x18      ; 00011000 - PC3 y PC4 como salidas, el resto entradas
    OUT DDRC, R16      ; Escribir en el registro DDRC

    // Activar pull-ups en PC0, PC1 y PC2
    LDI R16, 0x07      ; 00000111 - Habilita pull-ups en PC0, PC1 y PC2
    OUT PORTC, R16     ; Escribir en el registro PORTC

	/************** HABILITAR EL TIMER   ********/
	CALL	INIT_TMR0 

	/************** INTERRUPCIONES  ********/
	LDI		R16, (1 << TOIE0)
    STS		TIMSK0, R16 

	// Habilitar las interrupciones para el antirebote
    LDI R16, (1<<PCINT8) | (1<<PCINT9) | (1<<PCINT10) // Habilitar pin 0, pin 1 y pin 2
    STS PCMSK1, R16       // Cargar a PCMSK1
    LDI R16, (1 << PCIE1) // Habilitar interrupciones para el pin C 
    STS PCICR, R16

	/************** INCIALIZAR VARIABLES  ********/
	CLR		CONTADORT0 
	CLR		MODO
//	CLR		ACCION

	/************** ACTIVAR LAS INTERRUPCIONES GLOBALES ********/ 
	SEI 

	/************** DESACTIVAR EL SERIAL  ********/
	LDI		R16, 0x00
	STS		UCSR0B, R16 

/************** MAINLOOP  ********/
MAIN:  
	//OUT		PORTB, CONTADOR // mostrar el valor de el contador en el puerto B   
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
	CBI		PORTB, 0
	CBI		PORTB, 1
	RJMP	MAIN

FECHA:
	CBI		PORTB, 0
	CBI		PORTB, 1
	CBI		PORTC, 3
	RJMP	MAIN

C_HORA:
	SBI		PORTB, 0
	CBI		PORTB, 1
	CBI		PORTC, 3
	RJMP	MAIN

C_FECHA:
	CBI		PORTB, 0
	SBI		PORTB, 1
	CBI		PORTC, 3
	RJMP	MAIN

C_ALARMA:
	CBI		PORTB, 0
	CBI		PORTB, 1
	SBI		PORTC, 3
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

    SBIS	PINC, PC2	 // Leer si el botón de cambio de modo está en set, si lo está saltar la siguiente 
	INC		MODO
	LDI		R16, MODOS
	CPSE	MODO, R16 //Saltar si son iguales 
	JMP		F_ISR
	CLR		MODO
    JMP		F_ISR

F_ISR:
    POP R16
    OUT SREG, R16
    POP R16
    RETI
/*************** INTERRUPCIONES DEL T0************/ 
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
	//SOLO PARA PROBAR QUE EL MUX FUNCIONE    
	LDI		ZH, HIGH(TABLA<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADIW 	ZL, 1
    LPM		S_DISPLAY, Z
    OUT		PORTD, S_DISPLAY
	JMP		FIN_T0
DISPLAY_2:
	//ENCENDER SOLO EL TRANSISTOR NECESARIO 
	SBI		PORTB, 3
	//SOLO PARA PROBAR QUE EL MUX FUNCIONE 
	LDI		ZH, HIGH(TABLA<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADIW 	ZL, 2
    LPM		S_DISPLAY, Z
    OUT		PORTD, S_DISPLAY
	JMP		FIN_T0
DISPLAY_3:
	//ENCENDER SOLO EL TRANSISTOR NECESARIO 
	SBI		PORTB, 4
	//SOLO PARA PROBAR QUE EL MUX FUNCIONE 
	LDI		ZH, HIGH(TABLA<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADIW 	ZL, 3
    LPM		S_DISPLAY, Z
    OUT		PORTD, S_DISPLAY
	JMP		FIN_T0
DISPLAY_4:
	//ENCENDER SOLO EL TRANSISTOR NECESARIO 
	SBI		PORTB, 5
	//SOLO PARA PROBAR QUE EL MUX FUNCIONE 
	LDI		ZH, HIGH(TABLA<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADIW 	ZL, 4
    LPM		S_DISPLAY, Z
    OUT		PORTD, S_DISPLAY
	JMP		FIN_T0
FIN_T0:
    POP R16
    OUT SREG, R16
    POP R16
    RETI


/************ CONFIGURACIÓN T0 *********/ 
INIT_TMR0:
	LDI R16, (1<<CS01)// Configurar el prescaler en 8 
    OUT TCCR0B, R16																																					
    LDI R16, T0VALUE // Valor inicial de TCNT0 para un delay de 2 ms 
    OUT TCNT0, R16
   	RET																																																																																																				
	
	
// Tabla para 7 segmentos 
TABLA: .DB 0x7B, 0x0A, 0xB3, 0x9B, 0xCA, 0xD9, 0xF9, 0x0B, 0xFB, 0xDB, 0xEB, 0xF8, 0x71, 0xB4, 0xF1, 0xE1																																																																																																																																																																																																																																																																																																																																																																																																															