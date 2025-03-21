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
.def	ACCION = R24
.def	ALARMA_V = R25 
.dseg 
.org	SRAM_START 
MINUTO:				.byte	1 ; para registar que ya paso un min y debe cambiar umin 
UMIN:				.byte	1 ; la variable que guarda el conteo de unidades de minutos 
DMIN:				.byte	1 ; la variable que guarda el conteo de decenas de minutos 
UHORAS:				.byte	1 ; la variable que guarda la unidades el conteo de horas 
DHORAS:				.byte	1 ; la varible que guarda las decenas en el conteo de horas 
DISPLAY1:			.byte	1 ;variables para guardar lo que mostrará el display según el modo
DISPLAY2:			.byte	1 ;variables para guardar lo que mostrará el display según el modo
DISPLAY3:			.byte	1 ;variables para guardar lo que mostrará el display según el modo
DISPLAY4:			.byte	1 ;variables para guardar lo que mostrará el display según el modo
BOTON:				.byte	1 ; variable para el contador de l botón 
U_D:				.byte	1 ; variable para selecciónar entre configuración de horas/meses o min/días 
UD_U_H:				.byte	1 ;variable para configurar las	unidades de minutos
UD_D_H:				.byte	1 ;variable para condigurar las	decenas de minutos 
UD_C_H:				.byte	1 ;variable para condigurar las	unidades de horas
UD_M_H:				.byte	1 ;variable para condigurar las	decenas de horas 

UD_U_F:				.byte	1 ;variable para configurar las	unidades de minutos
UD_D_F:				.byte	1 ;variable para condigurar las	decenas de minutos 
UD_C_F:				.byte	1 ;variable para condigurar las	unidades de horas
UD_M_F:				.byte	1 ;variable para condigurar las	decenas de horas 

UD_U_A:				.byte	1 ;variable para configurar las	unidades de minutos
UD_D_A:				.byte	1 ;variable para condigurar las	decenas de minutos 
UD_C_A:				.byte	1 ;variable para condigurar las	unidades de horas
UD_M_A:				.byte	1 ;variable para condigurar las	decenas de horas 

LIMITE_U:			.byte	1 ;variable para condigurar las	decenas de horas 
LIMITE_D:			.byte	1 ;variable para condigurar las	decenas de horas 
CONTEO_MESES:		.byte	1 ;variable para condigurar las	decenas de horas

DIAS:				.byte	1 ; la variable que guarda el conteo de unidades de minutos 
D_DIAS:				.byte	1 ; la variable que guarda el conteo de decenas de minutos 
MESES:				.byte	1 ; la variable que guarda la unidades el conteo de horas 
D_MESES:			.byte	1 ; la varible que guarda las decenas en el conteo de horas 

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
	LDI		MODO, 0x02
	CLR		CONTADORT1L
	CLR		DISPLAYS
	CLR		CONTADOR_TIEMPO 
	CLR		CONTADOR_BOTONES
	CLR		ALARMA_V
	CLR		ACCION
	LDI		R16, 0x00
	STS		UMIN, R16	
	STS		DMIN, R16	
	LDI		R16, 0x00
	STS		UHORAS, R16
	LDI		R16, 0x00 
	STS		DHORAS, R16
	LDI		R16, 0x00
	STS		MINUTO, R16
	//VARIABLES PARA SALIDA DEL DISPLAY
	STS		DISPLAY1, R16	
	STS		DISPLAY2, R16	
	STS		DISPLAY3, R16 
	STS		DISPLAY4, R16	
	//VARIABLES PARA LOS BOTONES 
	STS		U_D, R16
	//COFIGURACIÓN HORA 
	STS		UD_U_H, R16	
	STS		UD_D_H, R16 
	STS		UD_C_H, R16
	STS		UD_M_H, R16
	//COFIGURACIÓN ALARMA
	STS		UD_U_A, R16	
	STS		UD_D_A, R16 
	STS		UD_C_A, R16
	STS		UD_M_A, R16
	//COFIGURACIÓN FECHA
	LDI		R16, 0x01
	STS		UD_U_F, R16	
	LDI		R16, 0x00
	STS		UD_D_F, R16 
	LDI		R16, 0x01
	STS		UD_C_F, R16
	LDI		R16, 0x00
	STS		UD_M_F, R16
	STS		LIMITE_U, R16
	STS		LIMITE_D, R16
	STS		CONTEO_MESES, R16
	LDI		R16, 0x01
	STS		DIAS, R16
	LDI		R16, 0x00	
	STS		D_DIAS, R16	
	LDI		R16, 0x01
	STS		MESES, R16
	LDI		R16, 0x00 
	STS		D_MESES, R16

	/************** ACTIVAR LAS INTERRUPCIONES GLOBALES ********/ 
	SEI 

	/************** DESACTIVAR EL SERIAL  ********/
	LDI		R16, 0x00
	STS		UCSR0B, R16 

/************** MAINLOOP  ********/
MAIN:  
	//OUT		PORTB, CONTADOR // mostrar el valor de el contador en el puerto B
	//SBI		PORTD, 2  
	CPI		MODO, 0x05
	BREQ	APAGAR_ALARMA_S 
	CPI		MODO, 0x00 
	BREQ	HORA_S
	CPI		MODO, 0x01 
	BREQ	FECHA_S
	CPI		MODO, 0x02
	BREQ	C_HORA_S
	CPI		MODO, 0x03 
	BREQ	C_FECHA_S
	CPI		MODO, 0x04 
	JMP		C_ALARMA_S
	CPI		MODO, 0x05
	BREQ	APAGAR_ALARMA_S
    RJMP	MAIN


/***************** FUNCIONES PARA SALTOS MÁS LARGOS*****************/
HORA_S:
	JMP		HORA
FECHA_S:
	JMP		FECHA
C_HORA_S:
	JMP		C_HORA
C_FECHA_S:
	JMP		C_FECHA
C_ALARMA_S:
	JMP		C_ALARMA
APAGAR_ALARMA_S:
	JMP		APAGAR_ALARMA
/*************** MODOS ***********************/
HORA:
	SBRC	ACCION, 0
	CALL	INC_UMIN
	SBI		PORTB, 0
	CBI		PORTB, 1
	SBI		PORTC, 3
	CALL	ACTIVAR_ALARMA
	//CONFIGURACIÓN DE FECHA:

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
	SBI		PORTB, 1
	SBI		PORTC, 3
	SBRC	ACCION, 0
	CALL	INC_UMIN
	SBRC	ACCION, 3
	CALL	AUMENTO_DIAS 
	SBRC	ACCION, 4
	CALL	AUMENTO_MESES
	//CONFIGURACIÓN DE FECHA:
	LDS     CONTADOR_TIEMPO, MESES  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY1, CONTADOR_TIEMPO ; tomar el valor del registro y guardarlo en el valor que tendrá el display 1
	LDS     CONTADOR_TIEMPO, D_MESES ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY2, CONTADOR_TIEMPO ; tomar el valor del registro y guardarlo en el valor que tendrá el display2
	LDS     CONTADOR_TIEMPO, DIAS ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY3, CONTADOR_TIEMPO ; tomar el valor del registro y guardarlo en el valor que tendrá el display3
	LDS     CONTADOR_TIEMPO, D_DIAS ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY4, CONTADOR_TIEMPO ; tomar el valor del registro y guardarlo en el valor que tendrá el display4
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
	STS		DISPLAY1, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 1
	LDS     CONTADOR_BOTONES, UD_D_H  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY2, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 2
	LDS     CONTADOR_BOTONES, UD_C_H  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY3, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 3
	LDS     CONTADOR_BOTONES, UD_M_H  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY4, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 1
	//Establecer el inicio en los valores de configuración de hora 
	LDS     CONTADOR_TIEMPO, UD_U_H 
	STS		UMIN, CONTADOR_TIEMPO
	LDS     CONTADOR_TIEMPO, UD_D_H 
	STS		DMIN, CONTADOR_TIEMPO
	LDS     CONTADOR_TIEMPO, UD_C_H 
	STS		UHORAS, CONTADOR_TIEMPO
	LDS     CONTADOR_TIEMPO, UD_M_H 
	STS		DHORAS, CONTADOR_TIEMPO
	RJMP	MAIN

C_FECHA:
	CBI		PORTB, 0
	SBI		PORTB, 1
	CBI		PORTC, 3
	SBRC	ACCION, 1
	CALL	SUMA 
	SBRC	ACCION, 2
	CALL	RESTA
	SBRC	ACCION, 0
	CALL	INC_UMIN

	//Suma y resta de los botones 
	LDS     CONTADOR_BOTONES, UD_U_F  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY1, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 1
	LDS     CONTADOR_BOTONES, UD_D_F  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY2, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 2
	LDS     CONTADOR_BOTONES, UD_C_F  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY3, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 3
	LDS     CONTADOR_BOTONES, UD_M_F  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY4, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 1
	//CARGAR LOS VALORES DE CONFIGURACIÓN DE FECHA
	LDS     CONTADOR_TIEMPO, UD_U_F 
	STS		MESES, CONTADOR_TIEMPO
	LDS     CONTADOR_TIEMPO, UD_D_F 
	STS		D_MESES, CONTADOR_TIEMPO
	LDS     CONTADOR_TIEMPO, UD_C_F 
	STS		DIAS, CONTADOR_TIEMPO
	LDS     CONTADOR_TIEMPO, UD_M_F 
	STS		D_DIAS, CONTADOR_TIEMPO
	RJMP	MAIN
C_ALARMA:
	SBRC	ACCION, 0
	CALL	INC_UMIN
	SBRC	ACCION, 1
	CALL	SUMA 
	SBRC	ACCION, 2
	CALL	RESTA
	CBI		PORTB, 0
	CBI		PORTB, 1
	SBI		PORTC, 3
	//Suma y resta de los botones 
	LDS     CONTADOR_BOTONES, UD_U_A  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY1, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 1
	LDS     CONTADOR_BOTONES, UD_D_A  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY2, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 2
	LDS     CONTADOR_BOTONES, UD_C_A  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY3, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 3
	LDS     CONTADOR_BOTONES, UD_M_A  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY4, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 1
	RJMP	MAIN

APAGAR_ALARMA:
	LDS     CONTADOR_BOTONES, UD_U_A  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY1, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 1
	LDS     CONTADOR_BOTONES, UD_D_A  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY2, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 2
	LDS     CONTADOR_BOTONES, UD_C_A  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY3, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 3
	LDS     CONTADOR_BOTONES, UD_M_A  ; Tomar el valor de unidades y guardarlo en el registro 
	STS		DISPLAY4, CONTADOR_BOTONES ; tomar el valor del registro y guardarlo en el valor que tendrá el display 1
	SBRC	ACCION, 0
	CALL	INC_UMIN
	CBI		PORTB, 0
	CBI		PORTB, 1
	CBI		PORTC, 3
	CBI		PORTC, 5
	RJMP	MAIN
/********************************************SUBRUTINAS PARA CARGAR VALORES*********************************/
CONF_HORA:
	LDS     CONTADOR_TIEMPO, UD_U_H 
	STS		UMIN, CONTADOR_TIEMPO
	LDS     CONTADOR_TIEMPO, UD_D_H 
	STS		DMIN, CONTADOR_TIEMPO
	LDS     CONTADOR_TIEMPO, UD_C_H 
	STS		UHORAS, CONTADOR_TIEMPO
	LDS     CONTADOR_TIEMPO, UD_M_H 
	STS		DHORAS, CONTADOR_TIEMPO
	RET 
CONF_FECHA: 
	LDS     CONTADOR_TIEMPO, UD_U_F 
	STS		MESES, CONTADOR_TIEMPO
	LDS     CONTADOR_TIEMPO, UD_D_F 
	STS		D_MESES, CONTADOR_TIEMPO
	LDS     CONTADOR_TIEMPO, UD_C_F 
	STS		DIAS, CONTADOR_TIEMPO
	LDS     CONTADOR_TIEMPO, UD_M_F 
	STS		D_DIAS, CONTADOR_TIEMPO
	RET 
/************** INTERRUPCIONES PIN CHANGE  ********/
ISR_PCINT1: 
    PUSH	R16
    IN		R16, SREG
    PUSH	R16
	//Para el botón de modos 
    SBIS	PINC, PC2					//Leer si el botón de cambio de modo está en set, si lo está saltar la siguiente linea
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
//FIN DE LA INTERRUPCIÓN 
F_ISR:
    POP R16
    OUT SREG, R16
    POP R16
    RETI
/***********************************************SUBRUTINAS PARA EL BOTÓN DE SUMA *************************************************************/
SUMA:    
    LDI     R16, 0b00000010   ; Cargar el valor en R16
    EOR     ACCION, R16       ; Alternar el bit correspondiente en ACCION
    
    ; Comprobar si MODO == 0x02
    CPI     MODO, 0x02
    BRNE    VERIFICAR_FECHA1   ; Si no es igual, verificar la siguiente condición
    JMP     SUMA_HORA         ; Si es igual, saltar a SUMA_HORA

VERIFICAR_FECHA1:
    ; Comprobar si MODO == 0x03
    CPI     MODO, 0x03
    BRNE    VERIFICAR_ALARMA   ; Si no es igual, saltar a retorno largo
    JMP     SUMA_FECHA        ; Si es igual, saltar a SUMA_FECHA
VERIFICAR_ALARMA: 
	CPI     MODO, 0x04
    BRNE    LLAMAR_RETORNO   ; Si no es igual, saltar a retorno largo
    JMP     SUMA_ALARMA        ; Si es igual, saltar a SUMA_ALARMA 

LLAMAR_RETORNO:
    JMP     RETORNO_BOTON     ; Usar JMP para saltar a cualquier parte del código
/************************************************************SUBRUTINAS PARA EL BOTÓN DE SUMA EN MODO HORA *****************************/
SUMA_HORA:
	LDS     CONTADOR_BOTONES, U_D
	CPI		CONTADOR_BOTONES, 0x00 ;si el botón de suma fue el que se presionó comparar en que modo se está 
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
    CPI		CONTADOR_BOTONES,  0x03
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



/************************************************************SUBRUTINAS PARA EL BOTÓN DE SUMA EN MODO FECHA *****************************/
SUMA_FECHA:
	LDS     CONTADOR_BOTONES, U_D
	CPI		CONTADOR_BOTONES, 0x00 ;si el botón de suma fue el que se presionó comparar en que modo se está 
	BREQ	SUMA_FECHA_UNIDADES_C 
	CPI		CONTADOR_BOTONES, 0x01
	BREQ	SUMA_FECHA_DECENAS
	JMP		RETORNO_BOTON
SUMA_FECHA_UNIDADES_C:
	//Para incrementar la variable que usaremos en días
	LDS     CONTADOR_BOTONES, CONTEO_MESES
	CPI		CONTADOR_BOTONES, 12
	BREQ	CONTEO_MESES_CLR
	INC		CONTADOR_BOTONES
	STS		CONTEO_MESES, CONTADOR_BOTONES
	JMP		SUMA_FECHA_UNIDADES
CONTEO_MESES_CLR: 
	LDI		CONTADOR_BOTONES, 0x00
	STS		CONTEO_MESES, CONTADOR_BOTONES
	JMP		SUMA_FECHA_UNIDADES
SUMA_FECHA_UNIDADES:	
	//Para solo modificar en un solo modo 
	LDS     CONTADOR_BOTONES, UD_D_F
    CPI		CONTADOR_BOTONES, 0x01
    BRNE    OFU_MESES
	LDS     CONTADOR_BOTONES, UD_U_F
    CPI		CONTADOR_BOTONES, 0x02
	BRNE    MAX_FIN
	LDI		CONTADOR_BOTONES,0x1
	STS     UD_U_F, CONTADOR_BOTONES
	CLR		CONTADOR_BOTONES
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
	//CARGAR EL VALOR DE LIMITE PARA UNIDADES
	LDS		CONTADOR_BOTONES, CONTEO_MESES
	LDI		ZH, HIGH(TABLA_DIAS_U<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA_DIAS_U<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADD		ZL, CONTADOR_BOTONES //Sumar la posición del contador de meses
	LPM		R16, Z
	STS		LIMITE_U, R16
	//CARGAR EL VALOR DEL LIMITE PARA LAS DECENAS 
	LDS		CONTADOR_BOTONES, CONTEO_MESES
	LDI		ZH, HIGH(TABLA_DIAS_D<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA_DIAS_D<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADD		ZL, CONTADOR_BOTONES //Sumar la posición del contador de meses
	LPM		R16, Z
	STS		LIMITE_D, R16
	//LÓGICA DE COMPARACIÓN 
	LDS     CONTADOR_BOTONES, UD_M_F
	LDS		R16, LIMITE_D
    CP		CONTADOR_BOTONES, R16 //Comparar con el límite de las decenas 
    BRNE    MES_N
	LDS		R16, LIMITE_U
	LDS     CONTADOR_BOTONES, UD_C_F
    CP		CONTADOR_BOTONES, R16 //COMPARAR CON EL LIMITE DE UNIDADES 
	BRNE    MAX_FIN_MESES
	LDI		CONTADOR_BOTONES, 0x01
	STS     UD_C_F, CONTADOR_BOTONES
	CLR		CONTADOR_BOTONES
	STS     UD_M_F, CONTADOR_BOTONES
	JMP		RETORNO_BOTON	
	
MES_N: 
    // Incrementa las decenas y verificar si no ha exedido unidades 
	LDS     CONTADOR_BOTONES, UD_C_F
	//Ahora se le suma el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,MAX_UNI //verifica si no es 9
	BREQ	MAX_DM
	INC		CONTADOR_BOTONES		; incrementa la variable
    STS     UD_C_F, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

MAX_DM:
	LDI     CONTADOR_BOTONES, 0x00
    STS     UD_C_F, CONTADOR_BOTONES ;LIMPIAR UNIDADES 
    LDS     CONTADOR_BOTONES, UD_M_F
	INC		CONTADOR_BOTONES ; SUMAR EN DECENAS
	STS     UD_M_F, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

MAX_FIN_MESES:
	LDS     CONTADOR_BOTONES, UD_C_F
	INC		CONTADOR_BOTONES
	STS     UD_C_F, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

/************************************************************SUBRUTINAS PARA EL BOTÓN DE SUMA EN MODO CONFIGURACIÓN DE ALARMA *****************************/
SUMA_ALARMA: 
	LDS     CONTADOR_BOTONES, U_D
	CPI		CONTADOR_BOTONES, 0x00 ;si el botón de suma fue el que se presionó comparar en que modo se está 
	BREQ	SUMA_ALARMA_UNIDADES 
	CPI		CONTADOR_BOTONES, 0x01
	BREQ	SUMA_ALARMA_DECENAS
	JMP		RETORNO_BOTON

SUMA_ALARMA_UNIDADES:
	//Para solo modificar en un solo modo 
	LDS     CONTADOR_BOTONES, UD_U_A
	//Ahora se le suma el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,MAX_UNI
	BREQ	OFUC_ALARMA
	INC		CONTADOR_BOTONES		; incrementa la variable
    STS     UD_U_A, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
OFUC_ALARMA:
	LDI		CONTADOR_BOTONES, 0x00
	STS     UD_U_A, CONTADOR_BOTONES ; Limpiar las unidades
	LDS     CONTADOR_BOTONES, UD_D_A
	INC		CONTADOR_BOTONES
	STS     UD_D_A, CONTADOR_BOTONES
	LDI		R16, 0x06
	CPSE	CONTADOR_BOTONES, R16 ; Saltar la siguiente linea si son iguales 
	JMP		RETORNO_BOTON
	CLR		CONTADOR_BOTONES
	STS     UD_D_A, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
	
SUMA_ALARMA_DECENAS:
	LDS     CONTADOR_BOTONES, UD_M_A     ; Cargar decenas de horas
    CPI     CONTADOR_BOTONES, 0x02        ; Verificar si DHORAS == 2
    BRNE	OFT_ALARMA		  ; Si es 2, verificar si UHORAS == 4 (24 horas)
	LDS     CONTADOR_BOTONES, UD_C_A
    CPI		CONTADOR_BOTONES,  0x03
	BRNE    MAX_FIN_ALARMA ; MIENTRAS NO SEA 4 IR A LA FUNCION 
	CLR		CONTADOR_BOTONES
	STS     UD_U_A, CONTADOR_BOTONES
	STS     UD_D_A, CONTADOR_BOTONES
	STS     UD_C_A, CONTADOR_BOTONES
	STS     UD_M_A, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

OFT_ALARMA: 
    // Incrementar decenas 
	LDS     CONTADOR_BOTONES, UD_C_A
	//Ahora se le suma el contador a las unidades de los min
	CPI		CONTADOR_BOTONES, MAX_UNI
	BREQ	MAX_D_ALARMA
	INC		CONTADOR_BOTONES 		; incrementa la variable
    STS     UD_C_A, CONTADOR_BOTONES
	JMP     RETORNO_BOTON 
MAX_D_ALARMA: 
	LDI     CONTADOR_BOTONES, 0x00
    STS     UD_C_A, CONTADOR_BOTONES ;LIMPIAR UNIDADES 
    LDS     CONTADOR_BOTONES,  UD_M_A
	INC		CONTADOR_BOTONES 
	STS     UD_M_A, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
MAX_FIN_ALARMA:
	LDS     CONTADOR_BOTONES, UD_C_A
	INC		CONTADOR_BOTONES
	STS     UD_C_A, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
//Retorno, se colocó aquí para lograr hacer los saltos con JMP y BRNE 
RETORNO_BOTON:
	RET
/***********************************************SUBRUTINAS PARA EL BOTÓN DE RESTA ***********************************************************************************/

RESTA:    
    LDI     R16, 0b00000100      ; Cargar el valor en R16
    EOR     ACCION, R16          ; Alternar el bit correspondiente en ACCION
    JMP     VERIFICAR_MODO       ; Saltar a la lógica de comparación

VERIFICAR_MODO:
    ; Comprobar si MODO == 0x02
    CPI     MODO, 0x02           
    BRNE    VERIFICAR_FECHA      ; Si no es igual, verificar la siguiente condición
    JMP     RESTA_HORA           ; Si es igual, saltar a RESTA_HORA

VERIFICAR_FECHA:
    ; Comprobar si MODO == 0x03
    CPI     MODO, 0x03
    BRNE    VERIFICAR_ALARMA_R       ; Si no es igual, regresar
    JMP     RESTA_FECHA          ; Si es igual, saltar a RESTA_FECHA

VERIFICAR_ALARMA_R:
    ; Comprobar si MODO == 0x04
    CPI     MODO, 0x04
    BRNE    LLAMAR_R        ; Si no es igual, regresar
    JMP     RESTA_ALARMA          ; Si es igual, saltar a RESTA_FECHA
LLAMAR_R: 
	JMP		RETORNO_BOTON
/************************************************************SUBRUTINAS PARA EL BOTÓN DE RESTA EN MODO CONFIGURACIÓN DE HORA *****************************/
RESTA_HORA:
	LDS     CONTADOR_BOTONES, U_D
	CPI		CONTADOR_BOTONES, 0x00 ;si el botón de suma fue el que se presionó comparar en que modo se está 
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
	LDS     CONTADOR_BOTONES, UD_M_H
	CPI     CONTADOR_BOTONES, 0x00
	BRNE    UFU_HORAS  // Salta si no es el primer caso
	LDS     CONTADOR_BOTONES, UD_C_H  
    CPI		CONTADOR_BOTONES, 0x00    
	BRNE    DECREMENTAR_UNI         // si es 0 saltar 
	// si los dos son 0 establecer el contador en 24
	LDI		CONTADOR_BOTONES, 0x03
	STS		UD_C_H, CONTADOR_BOTONES   
	LDI		CONTADOR_BOTONES, 0x02
	STS		UD_M_H, CONTADOR_BOTONES  
	JMP		RETORNO_BOTON
UFU_HORAS: 
	LDS     CONTADOR_BOTONES, UD_C_H // Si las decenas no son 0 d
	CPI		CONTADOR_BOTONES, 0x00 // comparar con 0
	BREQ	DECREMENTAR_DEC // si es 0 saltar 
	DEC		CONTADOR_BOTONES // si no es o decrementar las unidades normalmente. 
	STS     UD_C_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

DECREMENTAR_DEC:
    // Si las unidades son 0, decrementa las decenas
	LDS     CONTADOR_BOTONES, UD_M_H
	DEC		CONTADOR_BOTONES
	STS     UD_M_H, CONTADOR_BOTONES
	// establecer las unidades en 9 
	LDI     CONTADOR_BOTONES, 0x09
	STS     UD_C_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
DECREMENTAR_UNI:
    // Si las unidades no son 0, solo decrementarlas
	LDS     CONTADOR_BOTONES, UD_C_H
	DEC		CONTADOR_BOTONES
	STS     UD_C_H, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

/************************************************************SUBRUTINAS PARA EL BOTÓN DE RESTA EN MODO FECHA UNIDADES *****************************/
RESTA_FECHA:
    LDS     CONTADOR_BOTONES, U_D
    CPI     CONTADOR_BOTONES, 0x00  
    BREQ    RESTA_FECHA_UNIDADES_C   
    CPI     CONTADOR_BOTONES, 0x01   
    BREQ    RESTA_FECHA_DECENAS
    JMP     RETORNO_BOTON

RESTA_FECHA_UNIDADES_C:
    ; Para decrementar los meses
    LDS     CONTADOR_BOTONES, CONTEO_MESES
    CPI     CONTADOR_BOTONES, 0x00   
    BREQ    CONTEO_MESES_CLR_R       ; Si es 0, reinicia a 12
    DEC     CONTADOR_BOTONES        
    STS     CONTEO_MESES, CONTADOR_BOTONES
    JMP     RESTA_FECHA_UNIDADES

CONTEO_MESES_CLR_R:
    ; Si llega a 0, reiniciar a 12
    LDI     CONTADOR_BOTONES, 0x12
    STS     CONTEO_MESES, CONTADOR_BOTONES
    JMP     RETORNO_BOTON

RESTA_FECHA_UNIDADES:
    ; Para restar en las unidades de los meses 
    LDS     CONTADOR_BOTONES, UD_D_F
    CPI     CONTADOR_BOTONES, 0x00   ; saltar y seguir decenas sean 0
    BRNE    UFU_MESES_R              ; Si no, sigue con las unidades

    ; Si decenas es 0, verificar unidades
    LDS     CONTADOR_BOTONES, UD_U_F
    CPI     CONTADOR_BOTONES, 0x01   ; si las unidades son 1 saltar 
    BREQ    RESTA_A_12               ; Si sí, reiniciar a 12


UFU_MESES_R:
    ; Si las decenas no son 0, decrementar unidades
    LDS     CONTADOR_BOTONES, UD_U_F
    CPI     CONTADOR_BOTONES, 0x00   
    BREQ    DECREMENTAR_DEC_R        ; Si es 0 saltar 

    ; Decrementar unidades normalmente
    DEC     CONTADOR_BOTONES
    STS     UD_U_F, CONTADOR_BOTONES
    JMP     RETORNO_BOTON

DECREMENTAR_DEC_R:
    ; Si las unidades llegan a 0, decrementar las decenas
    LDS     CONTADOR_BOTONES, UD_D_F
    DEC     CONTADOR_BOTONES
    STS     UD_D_F, CONTADOR_BOTONES
    LDI     CONTADOR_BOTONES, 0x09
    STS     UD_U_F, CONTADOR_BOTONES

    // Si decenas llegan a 0, volver a 12
    CPI     CONTADOR_BOTONES, 0x00
    BREQ    RESTA_A_12

    JMP     RETORNO_BOTON

RESTA_A_12:
    LDI     CONTADOR_BOTONES, 0x02
    STS     UD_U_F, CONTADOR_BOTONES
    LDI     CONTADOR_BOTONES, 0x01
    STS     UD_D_F, CONTADOR_BOTONES
    JMP     RETORNO_BOTON
/************************************************************SUBRUTINAS PARA EL BOTÓN DE RESTA EN MODO FECHA DECENAS *****************************/
RESTA_FECHA_DECENAS:
//CARGAR EL VALOR DE LIMITE PARA UNIDADES
	LDS		CONTADOR_BOTONES, CONTEO_MESES
	LDI		ZH, HIGH(TABLA_DIAS_U<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA_DIAS_U<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADD		ZL, CONTADOR_BOTONES //Sumar la posición del contador de meses
	LPM		R16, Z
	STS		LIMITE_U, R16
	//CARGAR EL VALOR DEL LIMITE PARA LAS DECENAS 
	LDS		CONTADOR_BOTONES, CONTEO_MESES
	LDI		ZH, HIGH(TABLA_DIAS_D<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA_DIAS_D<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADD		ZL, CONTADOR_BOTONES //Sumar la posición del contador de meses
	LPM		R16, Z
	STS		LIMITE_D, R16
	//LÓGICA DE COMPARACIÓN 
	LDS     CONTADOR_BOTONES, UD_M_F
	CPI     CONTADOR_BOTONES, 0x00
	BRNE    UFU_MESES_D   // Salta si no es el primer caso
	LDS     CONTADOR_BOTONES, UD_C_F  
    CPI		CONTADOR_BOTONES, 0x01    
	BRNE    DECREMENTAR_UNI_D         // si es 0 saltar 
	// si los dos son 0 establecer el contador en en los limites de la tabla
	LDS		CONTADOR_BOTONES, LIMITE_U
	STS		UD_C_F, CONTADOR_BOTONES   
	LDS		CONTADOR_BOTONES, LIMITE_D
	STS		UD_M_F, CONTADOR_BOTONES  
	JMP		RETORNO_BOTON
UFU_MESES_D: 
	LDS     CONTADOR_BOTONES, UD_C_F // Si las decenas no son 0 d
	CPI		CONTADOR_BOTONES, 0x00 // comparar con 0
	BREQ	DECREMENTAR_DEC_D // si es 0 saltar 
	DEC		CONTADOR_BOTONES // si no es o decrementar las unidades normalmente. 
	STS     UD_C_F, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

DECREMENTAR_DEC_D:
    // Si las unidades son 0, decrementa las decenas
	LDS     CONTADOR_BOTONES, UD_M_F
	DEC		CONTADOR_BOTONES
	STS     UD_M_F, CONTADOR_BOTONES
	// establecer las unidades en 9 
	LDI     CONTADOR_BOTONES, 0x09
	STS     UD_C_F, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

DECREMENTAR_UNI_D:
    // Si las unidades no son 0, solo decrementarlas
	LDS     CONTADOR_BOTONES, UD_C_F
	DEC		CONTADOR_BOTONES
	STS     UD_C_F, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
/************************************************************SUBRUTINAS PARA EL BOTÓN DE RESTA EN MODO CONFIGURACIÓN DE ALARMA *****************************/
RESTA_ALARMA:
	LDS     CONTADOR_BOTONES, U_D
	CPI		CONTADOR_BOTONES, 0x00 ;si el botón de suma fue el que se presionó comparar en que modo se está 
	BREQ	RESTA_ALARMA_UNIDADES 
	CPI		CONTADOR_BOTONES, 0x01
	BREQ	RESTA_ALARMA_DECENAS
	JMP		RETORNO_BOTON
RESTA_ALARMA_UNIDADES:
	//Para solo modificar en un solo modo 
	LDS     CONTADOR_BOTONES, UD_U_A
	//Ahora se le RESTA el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,0x00
	BREQ	OUFU_A
	DEC		CONTADOR_BOTONES		; incrementa la variable
    STS     UD_U_A, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
OUFU_A:
	LDI		CONTADOR_BOTONES, 0x09
	STS     UD_U_A, CONTADOR_BOTONES ; Limpiar las unidades
	LDS     CONTADOR_BOTONES, UD_D_A
	CPI		CONTADOR_BOTONES, 0x00
	BREQ	OUFU2_A
	DEC		CONTADOR_BOTONES
	STS     UD_D_A, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
OUFU2_A:
	LDS     CONTADOR_BOTONES, UD_D_A
	LDI		CONTADOR_BOTONES, 0x05
	STS     UD_D_A, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

RESTA_ALARMA_DECENAS:
	LDS     CONTADOR_BOTONES, UD_M_A
	CPI     CONTADOR_BOTONES, 0x00
	BRNE    UFU_ALARMA  // Salta si no es el primer caso
	LDS     CONTADOR_BOTONES, UD_C_A  
    CPI		CONTADOR_BOTONES, 0x00    
	BRNE    DECREMENTAR_UNI_ALARMA         // si es 0 saltar 
	// si los dos son 0 establecer el contador en 24
	LDI		CONTADOR_BOTONES, 0x03
	STS		UD_C_A, CONTADOR_BOTONES   
	LDI		CONTADOR_BOTONES, 0x02
	STS		UD_M_A, CONTADOR_BOTONES  
	JMP		RETORNO_BOTON
UFU_ALARMA: 
	LDS     CONTADOR_BOTONES, UD_C_A // Si las decenas no son 0 d
	CPI		CONTADOR_BOTONES, 0x00 // comparar con 0
	BREQ	DECREMENTAR_ALARMA // si es 0 saltar 
	DEC		CONTADOR_BOTONES // si no es o decrementar las unidades normalmente. 
	STS     UD_C_A, CONTADOR_BOTONES
	JMP		RETORNO_BOTON

DECREMENTAR_ALARMA:
    // Si las unidades son 0, decrementa las decenas
	LDS     CONTADOR_BOTONES, UD_M_A
	DEC		CONTADOR_BOTONES
	STS     UD_M_A, CONTADOR_BOTONES
	// establecer las unidades en 9 
	LDI     CONTADOR_BOTONES, 0x09
	STS     UD_C_A, CONTADOR_BOTONES
	JMP		RETORNO_BOTON
DECREMENTAR_UNI_ALARMA:
    // Si las unidades no son 0, solo decrementarlas
	LDS     CONTADOR_BOTONES, UD_C_A
	DEC		CONTADOR_BOTONES
	STS     UD_C_A, CONTADOR_BOTONES
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
	LDI		R16, 0b00001000 
	EOR		ACCION, R16
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

AUMENTO_DIAS:
	LDI		R16, 0b00001000 
	EOR		ACCION, R16
	//LÓGICA DEL AUMENTO
	LDS		CONTADOR_BOTONES, CONTEO_MESES
	LDI		ZH, HIGH(TABLA_DIAS_U<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA_DIAS_U<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADD		ZL, CONTADOR_BOTONES //Sumar la posición del contador de meses
	LPM		R16, Z
	STS		LIMITE_U, R16
	//CARGAR EL VALOR DEL LIMITE PARA LAS DECENAS 
	LDS		CONTADOR_BOTONES, CONTEO_MESES
	LDI		ZH, HIGH(TABLA_DIAS_D<<1)  // Carga la parte alta de la dirección de tabla en ZH
    LDI		ZL, LOW(TABLA_DIAS_D<<1)   // Carga la parte baja de la dirección de la tabla en ZL
    ADD		ZL, CONTADOR_BOTONES //Sumar la posición del contador de meses
	LPM		R16, Z
	STS		LIMITE_D, R16
	//LÓGICA DE COMPARACIÓN 
	LDS     CONTADOR_BOTONES, D_DIAS
	LDS		R16, LIMITE_D
    CP		CONTADOR_BOTONES, R16 //Comparar con el límite de las decenas 
    BRNE    MES_A
	LDS		R16, LIMITE_U
	LDS     CONTADOR_BOTONES, DIAS
    CP		CONTADOR_BOTONES, R16 //COMPARAR CON EL LIMITE DE UNIDADES 
	BRNE    MAX_FIN_MESES_A
	LDI		CONTADOR_BOTONES, 0x01
	STS     DIAS, CONTADOR_BOTONES
	CLR		CONTADOR_BOTONES
	STS     D_DIAS, CONTADOR_BOTONES
	LDI		R16, 0b00010000 
	EOR		ACCION, R16
	JMP		RETORNOH
MES_A: 
    // Incrementa las decenas y verificar si no ha exedido unidades 
	LDS     CONTADOR_BOTONES, DIAS
	//Ahora se le suma el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,MAX_UNI //verifica si no es 9
	BREQ	MAX_DM_A
	INC		CONTADOR_BOTONES		; incrementa la variable
    STS     DIAS, CONTADOR_BOTONES
	JMP		RETORNOH

MAX_DM_A:
	LDI     CONTADOR_BOTONES, 0x00
    STS     DIAS, CONTADOR_BOTONES ;LIMPIAR UNIDADES 
    LDS     CONTADOR_BOTONES, D_DIAS
	INC		CONTADOR_BOTONES ; SUMAR EN DECENAS
	STS     D_DIAS, CONTADOR_BOTONES
	JMP		RETORNOH

MAX_FIN_MESES_A:
	LDS     CONTADOR_BOTONES, D_DIAS
	INC		CONTADOR_BOTONES
	STS     D_DIAS, CONTADOR_BOTONES
	JMP		RETORNOH	
AUMENTO_MESES:
	LDI		R16, 0b00010000 
	EOR		ACCION, R16
	//LÓGICA DE AUMENTO DE MESES
	LDS     CONTADOR_BOTONES, D_MESES
    CPI		CONTADOR_BOTONES, 0x01
    BRNE    OFU_MESES_A
	LDS     CONTADOR_BOTONES, MESES
    CPI		CONTADOR_BOTONES, 0x02
	BRNE    MAX_FIN_A
	LDI		CONTADOR_BOTONES,0x1
	STS     MESES, CONTADOR_BOTONES
	CLR		CONTADOR_BOTONES
	STS     D_MESES, CONTADOR_BOTONES
	JMP		RETORNOH
	
OFU_MESES_A: 
    // Incrementar decenas Y VERIFICA SI NO ES 1 
	LDS     CONTADOR_BOTONES, MESES
	//Ahora se le suma el contador a las unidades de los min
	CPI		CONTADOR_BOTONES,MAX_UNI
	BREQ	MAX_D_A
	INC		CONTADOR_BOTONES		; incrementa la variable
    STS     MESES, CONTADOR_BOTONES
	JMP		RETORNOH

	
MAX_FIN_A: 
	LDS     CONTADOR_BOTONES, MESES
	INC		CONTADOR_BOTONES
	STS     MESES, CONTADOR_BOTONES
	JMP		RETORNOH
MAX_D_A:
	LDI     CONTADOR_BOTONES, 0x00
    STS     MESES, CONTADOR_BOTONES ;LIMPIAR UNIDADES 
    LDS     CONTADOR_BOTONES, D_MESES
	INC		CONTADOR_BOTONES
	STS     D_MESES, CONTADOR_BOTONES
	JMP		RETORNOH
RETORNOH:
	RET
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
/*********************************************FUNCIONES PARA ENCENDER LA ALARMA**********************************************/
ACTIVAR_ALARMA:	
	LDS		R16, DHORAS
	LDS		ALARMA_V, UD_M_A
	CP		R16, ALARMA_V	
	BREQ	VERIFICAR_UHORAS
	JMP		RETORNO_ALARMA
VERIFICAR_UHORAS: 
	LDS		R16, UHORAS
	LDS		ALARMA_V, UD_C_A
	CP		R16, ALARMA_V	
	BREQ	VERIFICAR_DMIN
	JMP		RETORNO_ALARMA
VERIFICAR_DMIN: 
	LDS		R16, DMIN
	LDS		ALARMA_V, UD_D_A
	CP		R16, ALARMA_V	
	BREQ	VERIFICAR_UMIN
	JMP		RETORNO_ALARMA
VERIFICAR_UMIN: 
	LDS		R16, UMIN
	LDS		ALARMA_V, UD_U_A
	CP		R16, ALARMA_V	
	BREQ	SONAR_ALARMA
	JMP		RETORNO_ALARMA
SONAR_ALARMA:
	SBI		PORTC, 5
	JMP		RETORNO_ALARMA
RETORNO_ALARMA:
	RET
// Tabla para 7 segmentos 
TABLA: .DB 0x7B, 0x0A, 0xB3, 0x9B, 0xCA, 0xD9, 0xF9, 0x0B, 0xFB, 0xDB, 0xEB, 0xF8, 0x71, 0xB4, 0xF1, 0xE1	
TABLA_DIAS_U: .DB 0x01, 0x08, 0x01, 0x00, 0x01, 0x00, 0x01, 0x01, 0x00, 0x01, 0x00, 0x01	
TABLA_DIAS_D: .DB 0x03, 0x02, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03							 																																																																																																																																																																																																																																																																																																																																																																																																								