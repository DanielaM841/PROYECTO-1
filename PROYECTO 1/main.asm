;
; PROYECTO 1.asm
;
; Created: 13/03/2025 13:43:46
; Author : Daniela Alexandra Moreira Cruz
;Descripci�n: Separ� la parte del display del proyecto para descartar factores no correspondientes a la subrutina. 

.include "M328PDEF.inc"
//definici�n de variables �tiles 
.equ	T0VALUE = 6 ;numero en el que debe empezar a contar T0
.equ	T1VALUE = 0x0BCD ;numero en el que debe empezar a contar T0
.equ	MAX_UNI = 9 ;numero para el overflow unidades 
.equ	MAX_DEC = 5 ;numero para el overflow decenas 
.equ	MAXT0	= 5
.equ	MODOS = 6 ; n�mero m�ximo de modos 
.equ	CICLO = 1 ; n�mero de ciclos del timer 1 que deben cumplirse 
.def	CONTADORT0= R17; contador para llevar el registro de los transistores de los display 
.def	MODO	= R18 ; variable para el contdor de los modos 
.def	CONTADORT1L= R19
.def	S_DISPLAY = R20
.def	CONTADOR_TIEMPO = R21  
.def	DISPLAYS = R22
.def	CONTADOR_BOTONES= R23
.def	ACCION = R24 
.dseg 
.org	SRAM_START 
MINUTO:		.byte	1 ; para registar que ya paso un min y debe cambiar umin 
UMIN:		.byte	1 ; la variable que guarda el conteo de unidades de minutos 
DMIN:		.byte	1 ; la variable que guarda el conteo de decenas de minutos 
UHORAS:		.byte	1 ; la variable que guarda la unidades el conteo de horas 
DHORAS:		.byte	1 ; la varible que guarda las decenas en el conteo de horas 
DISPLAY1:	.byte	1 ;variables para guardar lo que mostrar� el display seg�n el modo
DISPLAY2:	.byte	1 ;variables para guardar lo que mostrar� el display seg�n el modo
DISPLAY3:	.byte	1 ;variables para guardar lo que mostrar� el display seg�n el modo
DISPLAY4:	.byte	1 ;variables para guardar lo que mostrar� el display seg�n el modo
BOTON:		.byte	1 ; variable para el contador de l bot�n 
U_D:		.byte	1 ; variable para selecci�nar entre configuraci�n de horas/meses o min/d�as 
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
	JMP TMR0_ISR ; interrupci�n del Timer 0 


// Configuraci�n de la pila
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

// Configuraci�n MCU
SETUP:
    CLI 
	/**************COFIGURACION DE PRESCALER********/
	// Configuraci�n de prescaler inicial
    LDI		R16, (1 << CLKPCE)
    STS		CLKPR, R16 // Habilitar cambio de PRESCALER
    LDI		R16, 0b00000100
    STS		CLKPR, R16 // Configurar Prescaler en 1MHz

	/*************COFIGURACION DE PINES ********/
    // Configurar PB como salidas
    LDI		R16, 0xFF
    OUT		DDRB, R16       // Puerto B como salida
    LDI		R16, 0x00
    OUT		PORTB, R16      // El puerto B conduce cero l�gico.

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
	LDI		R16, 0x00
	STS		UHORAS, R16
	LDI		R16, 0x00 
	STS		DHORAS, R16
	LDI		R16, 0x00
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
	CLR		ACCION

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
	JMP		C_ALARMA
	CPI		MODO, 0x05
	JMP		APAGAR_ALARMA
	
    RJMP	MAIN

/*************** MODOS ***********************/
HORA:
	SBRC	ACCION, 0
	CALL	INC_UMIN
	SBI		PORTB, 0
	CBI		PORTB, 1
	LDS     CONTADOR_TIEMPO, UMIN  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY1, CONTADOR_TIEMPO ; tomar el valor del registro y guardarlo en el valor que tendr� el display 1
	LDS     CONTADOR_TIEMPO, DMIN ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY2, CONTADOR_TIEMPO ; tomar el valor del registro y guardarlo en el valor que tendr� el display2
	LDS     CONTADOR_TIEMPO, UHORAS ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY3, CONTADOR_TIEMPO ; tomar el valor del registro y guardarlo en el valor que tendr� el display3
	LDS     CONTADOR_TIEMPO, DHORAS ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY4, CONTADOR_TIEMPO ; tomar el valor del registro y guardarlo en el valor que tendr� el display4

	RJMP	MAIN

FECHA:
	CBI		PORTB, 0
	CBI		PORTB, 1
	CBI		PORTC, 3
	LDI		R16, 0x09
	STS		DISPLAY1, R16
	RJMP	MAIN

C_HORA:
	SBRC	ACCION, 1
	CALL	SUMA 
	SBRC	ACCION, 2
	CALL	RESTA
	SBI		PORTB, 0
	CBI		PORTB, 1
	CBI		PORTC, 3
	//Suma y resta de los botones 
	LDS     CONTADOR_BOTONES, UD_U_H  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY1, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendr� el display 1
	LDS     CONTADOR_BOTONES, UD_D_H  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY2, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendr� el display 2
	LDS     CONTADOR_BOTONES, UD_C_H  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY3, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendr� el display 3
	LDS     CONTADOR_BOTONES, UD_M_H  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY4, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendr� el display 1
	RJMP	MAIN

C_FECHA:
	CBI		PORTB, 0
	SBI		PORTB, 1
	CBI		PORTC, 3
	SBRC	ACCION, 1
	CALL	SUMA 
	SBRC	ACCION, 2
	CALL	RESTA
	//Suma y resta de los botones 
	LDS     CONTADOR_BOTONES, UD_U_F  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY1, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendr� el display 1
	LDS     CONTADOR_BOTONES, UD_D_F  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY2, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendr� el display 2
	LDS     CONTADOR_BOTONES, UD_C_F  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY3, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendr� el display 3
	LDS     CONTADOR_BOTONES, UD_M_F  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY4, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendr� el display 1
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
	//Para el bot�n de modos 
    SBIS	PINC, PC2					//Leer si el bot�n de cambio de modo est� en set, si lo est� saltar la siguiente linea
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
	CLR		MODO ; Si el modo se pas� del limite limpiarlo y comenzar el 0 
	JMP		F_ISR
BOTON_SUMA:
	LDI		R16, 0b00000010
	EOR		ACCION, R16
	JMP		F_ISR
BOTON_RESTA:
	LDI		R16, 0b00000100
	EOR		ACCION, R16
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
//FIN DE LA INTERRUPCI�N 
F_ISR:
    POP R16
    OUT SREG, R16
    POP R16
    RETI
//SUBRUTINAS PARA EL BOT�N DE SUMA 
SUMA:    
    LDI     R16, 0b00000010   ; Cargar el valor en R16
    EOR     ACCION, R16       ; Alternar el bit correspondiente en ACCION
    
    ; Comprobar si MODO == 0x02
    CPI     MODO, 0x02
    BRNE    VERIFICAR_FECHA1   ; Si no es igual, verificar la siguiente condici�n
    JMP     SUMA_HORA         ; Si es igual, saltar a SUMA_HORA

VERIFICAR_FECHA1:
    ; Comprobar si MODO == 0x03
    CPI     MODO, 0x03
    BRNE    LLAMAR_RETORNO    ; Si no es igual, saltar a retorno largo
    JMP     SUMA_FECHA        ; Si es igual, saltar a SUMA_FECHA

LLAMAR_RETORNO:
    JMP     RETORNO_BOTON     ; Usar JMP para saltar a cualquier parte del c�digo
SUMA_HORA:
	LDS     CONTADOR_BOTONES, U_D
	CPI		CONTADOR_BOTONES, 0x00 ;si el bot�n de suma fue el que se presion� comparar en que modo se est� 
	BREQ	SUMA_HORA_UNIDADES 
	CPI		CONTADOR_BOTONES, 0x01
	BREQ	SUMA_HORA_DECENAS
	JMP		RETORNO_BOTON
SUMA_HORA_UNIDADES:
	//Para solo modificar en un solo modo 
	LDS     CONTADOR_BOTONES, UD_U_H
	//Ahora se le suma el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,MAX_UNI
	BREQ	OFUC
	INC		CONTADOR_BOTONES		; incrementa la variable
    STS     UD_U_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
OFUC:
	LDI		CONTADOR_BOTONES, 0x00
	STS     UD_U_H, CONTADOR_BOTONES ; Limpiar las unidades
	LDS     CONTADOR_BOTONES, UD_D_H
	INC		CONTADOR_BOTONES
	STS     UD_D_H, CONTADOR_BOTONES
	LDI		R16, 0x06
	CPSE	CONTADOR_BOTONES, R16 ; Saltar la siguiente linea si son iguales 
	JMP		RETORNO_BOTON
	CLR		CONTADOR_BOTONES
	STS     UD_D_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
	
SUMA_HORA_DECENAS:
	LDS     CONTADOR_BOTONES, UD_M_H     ; Cargar decenas de horas
    CPI     CONTADOR_BOTONES, 0x02        ; Verificar si DHORAS == 2
    BRNE	OFT_C		  ; Si es 2, verificar si UHORAS == 4 (24 horas)
	LDS     CONTADOR_BOTONES, UD_C_H
    CPI		CONTADOR_BOTONES,  0x04
	BRNE    MAX_FIN_DIA_C ; MIENTRAS NO SEA 4 IR A LA FUNCION 
	CLR		CONTADOR_BOTONES
	STS     UD_U_H, CONTADOR_BOTONES
	STS     UD_D_H, CONTADOR_BOTONES
	STS     UD_C_H, CONTADOR_BOTONES
	STS     UD_M_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

OFT_C: 
    // Incrementar decenas 
	LDS     CONTADOR_BOTONES, UD_C_H
	//Ahora se le suma el contador a las unidades de los min
	CPI		CONTADOR_BOTONES, MAX_UNI
	BREQ	MAX_D_TIEMPO_C
	INC		CONTADOR_BOTONES 		; incrementa la variable
    STS     UD_C_H, CONTADOR_BOTONES
	JMP     RETORNO_BOTON 
MAX_D_TIEMPO_C: 
	LDI     CONTADOR_BOTONES, 0x00
    STS     UD_C_H, CONTADOR_BOTONES ;LIMPIAR UNIDADES 
    LDS     CONTADOR_BOTONES,  UD_M_H
	INC		CONTADOR_BOTONES 
	STS     UD_M_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
MAX_FIN_DIA_C:
	LDS     CONTADOR_BOTONES, UD_C_H
	INC		CONTADOR_BOTONES
	STS     UD_C_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON




SUMA_FECHA:
	LDS     CONTADOR_BOTONES, U_D
	CPI		CONTADOR_BOTONES, 0x00 ;si el bot�n de suma fue el que se presion� comparar en que modo se est� 
	BREQ	SUMA_FECHA_UNIDADES 
	CPI		CONTADOR_BOTONES, 0x01
	BREQ	SUMA_FECHA_DECENAS
	JMP		RETORNO_BOTON
SUMA_FECHA_UNIDADES:
	//Para solo modificar en un solo modo 
	LDS     CONTADOR_BOTONES, UD_D_F
    CPI		CONTADOR_BOTONES, 0x01
    BRNE    OFU_MESES
	LDS     CONTADOR_BOTONES, UD_U_F
    CPI		CONTADOR_BOTONES, 0x02
	BRNE    MAX_FIN
	CLR		CONTADOR_BOTONES
	STS     UD_U_F, CONTADOR_BOTONES
	STS     UD_D_F, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
	
OFU_MESES: 
    // Incrementar decenas Y VERIFICA SI NO ES 1 
	LDS     CONTADOR_BOTONES, UD_U_F
	//Ahora se le suma el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,MAX_UNI
	BREQ	MAX_D
	INC		CONTADOR_BOTONES		; incrementa la variable
    STS     UD_U_F, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

	
MAX_FIN: 
	LDS     CONTADOR_BOTONES, UD_U_F
	INC		CONTADOR_BOTONES
	STS     UD_U_F, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
MAX_D:
	LDI     CONTADOR_BOTONES, 0x00
    STS     UD_U_F, CONTADOR_BOTONES ;LIMPIAR UNIDADES 
    LDS     CONTADOR_BOTONES, UD_D_F
	INC		CONTADOR_BOTONES
	STS     UD_D_F, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

SUMA_FECHA_DECENAS: 
	JMP		RETORNO_BOTON 
	
//Retorno, se coloc� aqu� para lograr hacer los saltos con JMP y BRNE 
RETORNO_BOTON:
	RET
//SUBRUTINAS PARA EL BOT�N DE RESTA 

RESTA:    
    LDI     R16, 0b00000100      ; Cargar el valor en R16
    EOR     ACCION, R16          ; Alternar el bit correspondiente en ACCION
    JMP     VERIFICAR_MODO       ; Saltar a la l�gica de comparaci�n

VERIFICAR_MODO:
    ; Comprobar si MODO == 0x02
    CPI     MODO, 0x02           
    BRNE    VERIFICAR_FECHA      ; Si no es igual, verificar la siguiente condici�n
    JMP     RESTA_HORA           ; Si es igual, saltar a RESTA_HORA

VERIFICAR_FECHA:
    ; Comprobar si MODO == 0x03
    CPI     MODO, 0x03
    BRNE    RETORNO_BOTON        ; Si no es igual, regresar
    JMP     RESTA_FECHA          ; Si es igual, saltar a RESTA_FECHA

RESTA_HORA:
	LDS     CONTADOR_BOTONES, U_D
	CPI		CONTADOR_BOTONES, 0x00 ;si el bot�n de suma fue el que se presion� comparar en que modo se est� 
	BREQ	RESTA_HORA_UNIDADES 
	CPI		CONTADOR_BOTONES, 0x01
	BREQ	RESTA_HORA_DECENAS
	JMP		RETORNO_BOTON
RESTA_HORA_UNIDADES:
	//Para solo modificar en un solo modo 
	LDS     CONTADOR_BOTONES, UD_U_H
	//Ahora se le RESTA el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,0x00
	BREQ	OUFU
	DEC		CONTADOR_BOTONES		; incrementa la variable
    STS     UD_U_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
OUFU:
	LDI		CONTADOR_BOTONES, 0x09
	STS     UD_U_H, CONTADOR_BOTONES ; Limpiar las unidades
	LDS     CONTADOR_BOTONES, UD_D_H
	CPI		CONTADOR_BOTONES, 0x00
	BREQ	OUFU2
	DEC		CONTADOR_BOTONES
	STS     UD_D_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
OUFU2:
	LDS     CONTADOR_BOTONES, UD_D_H
	LDI		CONTADOR_BOTONES, 0x05
	STS     UD_D_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
RESTA_HORA_DECENAS:
	//Para solo modificar en un solo modo 
	LDS     CONTADOR_BOTONES, UD_C_H
	//Ahora se le RESTA el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,0x00
	BREQ	OUFD
	DEC		CONTADOR_BOTONES		; incrementa la variable
    STS     UD_C_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
OUFD:
	LDI		CONTADOR_BOTONES, 0x04
	STS     UD_C_H, CONTADOR_BOTONES ; Limpiar las unidades
	LDS     CONTADOR_BOTONES, UD_M_H
	CPI		CONTADOR_BOTONES, 0x00
	BREQ	OUFD2
	DEC		CONTADOR_BOTONES
	STS     UD_M_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
OUFD2:
	LDS     CONTADOR_BOTONES, UD_M_H
	LDI		CONTADOR_BOTONES, 0x02
	STS     UD_M_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

RESTA_FECHA:
	JMP		RETORNO_BOTON	

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
	//VERIFICAR QUE NO HAYA EXEDIDO EL L�MITE 
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
	LDS		DISPLAYS, DISPLAY1 ; El registro de display tiene la salida de display 1 seg�n el modo
	//SOLO PARA PROBAR QUE EL MUX FUNCIONE    
	LDI		ZH, HIGH(TABLA<<1)  // Carga la parte alta de la direcci�n de tabla en ZH
    LDI		ZL, LOW(TABLA<<1)   // Carga la parte baja de la direcci�n de la tabla en ZL
    ADD		ZL, DISPLAYS
    LPM		S_DISPLAY, Z
    OUT		PORTD, S_DISPLAY
	JMP		FIN_T0
DISPLAY_2:
	//ENCENDER SOLO EL TRANSISTOR NECESARIO 
	SBI		PORTB, 3
	LDS		DISPLAYS, DISPLAY2
	//SOLO PARA PROBAR QUE EL MUX FUNCIONE 
	LDI		ZH, HIGH(TABLA<<1)  // Carga la parte alta de la direcci�n de tabla en ZH
    LDI		ZL, LOW(TABLA<<1)   // Carga la parte baja de la direcci�n de la tabla en ZL
    ADD		ZL, DISPLAYS 
    LPM		S_DISPLAY, Z
    OUT		PORTD, S_DISPLAY
	JMP		FIN_T0
DISPLAY_3:
	//ENCENDER SOLO EL TRANSISTOR NECESARIO 
	SBI		PORTB, 4
	LDS		DISPLAYS, DISPLAY3
	//SOLO PARA PROBAR QUE EL MUX FUNCIONE 
	LDI		ZH, HIGH(TABLA<<1)  // Carga la parte alta de la direcci�n de tabla en ZH
    LDI		ZL, LOW(TABLA<<1)   // Carga la parte baja de la direcci�n de la tabla en ZL
    ADD		ZL, DISPLAYS
    LPM		S_DISPLAY, Z
    OUT		PORTD, S_DISPLAY
	JMP		FIN_T0
DISPLAY_4:
	//ENCENDER SOLO EL TRANSISTOR NECESARIO 
	SBI		PORTB, 5
	LDS		DISPLAYS, DISPLAY4
	//SOLO PARA PROBAR QUE EL MUX FUNCIONE 
	LDI		ZH, HIGH(TABLA<<1)  // Carga la parte alta de la direcci�n de tabla en ZH
    LDI		ZL, LOW(TABLA<<1)   // Carga la parte baja de la direcci�n de la tabla en ZL
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

    ; Verificar si ya pas� el tiempo necesario 
    CPI     CONTADOR_TIEMPO, CICLO	
    BRNE    FIN_TMR1  ; Si no ha llegado salir
	CLR		CONTADOR_TIEMPO
	STS     MINUTO, CONTADOR_TIEMPO 
	//Resetear la bandera
	LDI		R16, 0x01
	EOR		ACCION, R16
	JMP		FIN_TMR1
FIN_TMR1: 
	POP		R16
	OUT		SREG, R16
	POP		R16
	RETI

INC_UMIN: 
	//Resetear la bandera
	LDI		R16, 0x01
	EOR		ACCION, R16
	// SUMAR A UMIN 
	LDS     CONTADOR_TIEMPO, UMIN 
	CPI		CONTADOR_TIEMPO, MAX_UNI ; COMPARAR PARA VER SI SUPERO UNIDADES 
	BREQ	OFU
	INC		CONTADOR_TIEMPO
	STS		UMIN, CONTADOR_TIEMPO 
	JMP     RETORNOH

OFU: 
    LDI     CONTADOR_TIEMPO, 0x00        ; Reiniciar unidades de minutos
    STS     UMIN, CONTADOR_TIEMPO
    LDS     CONTADOR_TIEMPO, DMIN        ; Cargar decenas de minutos
    CPI     CONTADOR_TIEMPO, MAX_DEC     ; Verificar si DMIN == 5
    BREQ    OFDH                         ; Si es 5, reiniciar decenas y unidades
    INC     CONTADOR_TIEMPO              ; Si no, incrementar DMIN
    STS     DMIN, CONTADOR_TIEMPO
    JMP     RETORNOH
OFDH:
    LDI     CONTADOR_TIEMPO, 0x00        ; Reiniciar unidades de minutos
    STS     UMIN, CONTADOR_TIEMPO
    STS     DMIN, CONTADOR_TIEMPO        ; Reiniciar decenas de minutos
    LDS     CONTADOR_TIEMPO, DHORAS      ; Cargar decenas de horas
    CPI     CONTADOR_TIEMPO, 0x02        ; Verificar si DHORAS == 2
    BRNE	OFT		  ; Si es 2, verificar si UHORAS == 4 (24 horas)
	LDS     CONTADOR_TIEMPO, UHORAS
    CPI		CONTADOR_TIEMPO,  0x03
	BRNE    MAX_FIN_DIA ; MIENTRAS NO SEA 4 IR A LA FUNCION 
	CLR		CONTADOR_TIEMPO
	STS     UMIN, CONTADOR_TIEMPO
	STS     DMIN, CONTADOR_TIEMPO
	STS     UHORAS, CONTADOR_TIEMPO
	STS     DHORAS, CONTADOR_TIEMPO
    JMP     RETORNOH

OFT: 
    // Incrementar decenas 
	LDS     CONTADOR_TIEMPO, UHORAS
	//Ahora se le suma el contador a las unidades de los min
	CPI		CONTADOR_TIEMPO, MAX_UNI
	BREQ	MAX_D_TIEMPO
	INC		CONTADOR_TIEMPO 		; incrementa la variable
    STS     UHORAS, CONTADOR_TIEMPO
	JMP     RETORNOH
MAX_D_TIEMPO: 
	LDI     CONTADOR_TIEMPO, 0x00
    STS     UHORAS, CONTADOR_TIEMPO ;LIMPIAR UNIDADES 
    LDS     CONTADOR_TIEMPO,  DHORAS
	INC		CONTADOR_TIEMPO 
	STS     DHORAS, CONTADOR_TIEMPO
	JMP		RETORNOH
MAX_FIN_DIA:
	LDS     CONTADOR_TIEMPO, UHORAS
	INC		CONTADOR_TIEMPO
	STS     UHORAS, CONTADOR_TIEMPO
	JMP		RETORNOH

RETORNOH:
	RET
/************ CONFIGURACI�N T0 *********/ 
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
	LDI R16, (1<<CS01) // configuraci�n para el prescaler de 8 
    STS TCCR1B, R16																																					

   	RET	
	
// Tabla para 7 segmentos 
TABLA: .DB 0x7B, 0x0A, 0xB3, 0x9B, 0xCA, 0xD9, 0xF9, 0x0B, 0xFB, 0xDB, 0xEB, 0xF8, 0x71, 0xB4, 0xF1, 0xE1							 																																																																																																																																																																																																																																																																																																																																																																																																								