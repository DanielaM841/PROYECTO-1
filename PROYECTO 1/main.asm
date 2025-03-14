;
; PROYECTO 1.asm
;
; Created: 13/03/2025 13:43:46
; Author : Daniela Alexandra Moreira Cruz
;Descripción: Separé la parte del display del proyecto para descartar factores no correspondientes a la subrutina. 

.include "M328PDEF.inc"
//definición de variables útiles 
.equ T0VALUE = 217 ;numero en el que debe empezar a contar T0
.equ MAX_UNI = 10 ;numero para el overflow unidades 
.equ MAX_DEC = 6 ;numero para el overflow decenas 
.def CONTADOR = R21; contador para llevar el registro de los numeros 

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

	// Configurar PB como salidas
    LDI		R16, 0xFF // Pines como salidas 
    OUT		DDRB, R16       // Puerto B como salida
    LDI		R16, 0x00
    OUT		PORTB, R16      // El puerto B conduce cero lógico.

	// Configurar PC como entrada
    LDI R16, 0x00
    OUT DDRC, R16
    LDI R16, 0xFF
    OUT PORTC, R16      // Pull-up

	/************** HABILITAR EL TIMER   ********/
	//CALL	INIT_TMR0 

	/************** INTERRUPCIONES  *******
	LDI		R16, (1 << TOIE0)
    STS		TIMSK0, R16 */

	/************** INCIALIZAR VARIABLES  ********/
	CLR		CONTADOR 
	CLR		MODO
	CLR		ACCION

	/************** ACTIVAR LAS INTERRUPCIONES GLOBALES ********/ 
	SEI 

	/************** DESACTIVAR EL SERIAL  ********/
	LDI		R16, 0x00
	STS		UCSR0B, R16 

/************** MAINLOOP  ********/
MAIN:     
    RJMP MAIN

/************** INTERRUPCIONES PIN CHANGE  ********/
ISR_PCINT1: 
    PUSH R16
    IN R16, SREG
    PUSH R16

    IN BOTON, PINC // Leer el estado de los botones 

    SBRS BOTON, 2  // Saltar si el bit 2 está en set 
    JMP SUMA

    SBRS BOTON, 3  // Saltar si el bit 3 está en set
    JMP RESTA

F_ISR:
    POP R16
    OUT SREG, R16
    POP R16
    RETI