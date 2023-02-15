;Archivo:	Lab4_Vel18352
;Dispositivo:   PIC16F887
;Autor:		Emilio Velasquez 18352
;Compilador:	XC8, MPLABX 5.40
;Programa:      Contador binario de 4 bits que incrementa y decrementa
;		con dos push buttons e interrupciones en el puerto B	
;		y pull up interno del pic.
;Hardware:	4 leds y 2 pulsadores
;Creado:	13/02/2023
;Ultima modificacion: 13/02/2023


// CONFIG1
CONFIG FOSC = INTRC_NOCLKOUT// Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
CONFIG WDTE = OFF       // Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
CONFIG PWRTE = OFF      // Power-up Timer Enable bit (PWRT disabled)
CONFIG MCLRE = OFF      // RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
CONFIG CP = OFF         // Code Protection bit (Program memory code protection is disabled)
CONFIG CPD = OFF        // Data Code Protection bit (Data memory code protection is disabled)
CONFIG BOREN = OFF      // Brown Out Reset Selection bits (BOR disabled)
CONFIG IESO = OFF       // Internal External Switchover bit (Internal/External Switchover mode is disabled)
CONFIG FCMEN = OFF      // Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
CONFIG LVP = OFF       // Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

// CONFIG2
CONFIG BOR4V = BOR21V   // Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
CONFIG WRT = OFF        // Flash Program Memory Self Write Enable bits (Write protection off)

//#pragma CONFIG statements should precede project file includes.
// Use project enums instead of #define for ON and OFF.

PROCESSOR 16F887
#include <xc.inc>
    
    
UP	EQU	6
DOWN	EQU	7   ;Se establece el bit 6 como UP y 7 DOWN
  
PSECT	udata_bank0	;common memory
  cont:	    DS 1    ;1 byte
  cont_2:   DS 1    ;1 byte
  cont_3:   DS 1    ;1 byte
  cont_4:   DS 1    ;1 byte
      
PSECT	udata_shr	;common memory
  W_TEMP:	DS 1	;1 Byte
  STATUS_TEMP:  DS 1	;1 Byte
    
PSECT resVect,	class=code, abs, delta=2
;------------------------- Vector Reset ---------------------------
ORG 00h			;Posicion del reset
resVect:
    PAGESEL main
    GOTO    main
    
PSECT intVect,	class=code, abs, delta=2
;------------------------- Interrupcion de Reset ---------------------------  
ORG 04h			;Posicion para la interrupciones
push:
    movwf   W_TEMP	    ;Se mueve de W a F 
    swapf   STATUS, W	    ;Se hace un swap de status y se almacena en W
    movwf   STATUS_TEMP	    ;Se mueve W a Status Temp
    
isr:			    ;Sub Rutinas de interrupcion
    btfsc   RBIF	    ;Se chequea Interrupcion del puerto B
    call    int_iocb	    ;Se llama funcion de incrementar o decrementar Puerto B
    btfsc   T0IF	    ;Se chequea Interrupcion de Timer0
    call    Contador_1	    ;Se llama funcion de contador display
    
pop:    
    swapf   STATUS_TEMP, W  ;Se hace un swap de STATUS TEMP a W
    movwf   STATUS	    ;se mueve status a F
    swapf   W_TEMP, F	    ;Se hace swap de temp a f
    swapf   W_TEMP, W	    ;se hace swap de temp a w
    retfie		    ;regresa a la interrupcion

;----------------------- SUBRUTINA DE INTERRUPCI?N ----------------------------- 
int_iocb:
    BANKSEL PORTB	    
    BTFSS   PORTB, UP	    ;Se verifica el bit UP para incrementar 
    INCF    PORTB	    ;Incrementa Puerto B    
    BTFSS   PORTB, DOWN	    ;Se verifica el bit DOWN para decrementar
    DECF    PORTB	    ;Decrementa Puerto B
    BCF	    RBIF	    ;Se limpia bandera de interrupcion
    return
    
    
PSECT CODE, DELTA=2, ABS
ORG 100h		    ;Posicion del codigo
;----------------------------- CONFIGURACION -----------------------------------
main:
    call    config_IO
    call    config_reloj
    call    config_iocb
    call    config_int_enable
    call    CONFIG_TMR0		;Se llaman las sub rutinas de conofiguracion 
    
;---------------------------- LOOP PRINCIPAL -----------------------------------
loop:
    
    goto loop	    ;regresa al bucle
    
;----------------------------- SUB RUTINAS -------------------------------------
config_IO:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH	;I/O Digitales
    
;------------ LEDs --------------    
    BANKSEL TRISA
    CLRF    TRISA   ;Salida digital   
    BANKSEL TRISB
    CLRF    TRISB   ;Salida digital	
    BANKSEL TRISC
    CLRF    TRISC   ;Salida digital
    
;------------ PUSH BOTTOM -----------    
    BSF	    TRISB, UP
    BSF	    TRISB, DOWN	    ;Entradas 
    
;---------- HABILITAR PULL-UP INTERNO ------    
    BCF	    OPTION_REG, 7
    BSF	    WPUB, UP
    BSF	    WPUB, DOWN
    
;------------ LIMPIAR PUERTO -------
    BANKSEL PORTA
    movlw   0x3F
    movwf   PORTA   ;Se mueve valor en Hex para mostrar un 0 y se escribe el puerto
    
    BANKSEL PORTB
    CLRF    PORTB   ;Limpiar puerto
     
    BANKSEL PORTC
    movlw   0x3F
    movwf   PORTC   ;Se mueve valor en Hex para mostrar un 0 y se escribe el puerto
    
    movlw   0x00
    movwf   cont    ;Limpiar Contador

;----------- CONFIGURACION DE IOCB -----------
config_iocb:
    BANKSEL TRISB
    BSF	    IOCB, UP
    BSF	    IOCB, DOWN	;Se habilita las interrupciones para cambio de estado en Puerto B
    
    BANKSEL PORTB
    MOVF    PORTB, W	;Terminar mistmatch al terminar
    BCF	    RBIF	;Se limpia la bandera de interrupcion del Puerto B
    return
    
;----------- CONFIGURACION DEL RELOJ ----------    
config_reloj:
    BANKSEL OSCCON
    BSF	    IRCF2
    BSF	    IRCF1
    BCF	    IRCF0	;Frecuencia de 4 MHz
    BSF	    SCS		;Reloj interno
    return

;-------- HABILITACION DE INTERRUPCIONES -------    
config_int_enable:   
    BANKSEL INTCON
    BSF	    GIE	    ;Habilitar interrupciones globales
    BSF	    RBIE    ;Se habilita la interrupcion de Puerto B
    BCF	    RBIF    ;Se limpia la bandera de interrupcion del Puerto B
    BSF	    T0IE    ;Se habilita interrupcion TMR0
    BCF	    T0IF    ;Se limpia bandera de TMR0
    return
    
;----------- CONFIGURACION DEL TIMER0 -----------      
CONFIG_TMR0:
    BANKSEL OPTION_REG	    ;Se cambia de banco
    BCF	    T0CS	    ;TMR0 como temporizador
    BCF	    PSA		    ;Prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BSF	    PS0		    ;PS<2:0> -> 111 prescaler 1 : 256
    
    BANKSEL TMR0	    ;Se cambia de banco
    MOVLW   178
    MOVWF   TMR0	    ;20ms retardo
    BCF	    T0IF	    ;Se limpia bandera de interrupción
    return 
    
;----------- REINICIAR EL TIMER0 -----------    
reinicio_TMR0:		   
    movlw   178	    ;Mover la literal (178) a W
    movwf   TMR0    ;Mover W a F
    bcf	    T0IF    ;Se limpia bandera de interrupcion
    return
    
;----------- CONTADORES DE DISPLAY ----------------------
;----------- CONTADOR 1 ----------------------
Contador_1:
    call reinicio_TMR0	;Se llama el reinicio TRO0
    
    incf    cont	;Incrementa contador
    movf    cont,0	;Se mueve contador a W
    sublw   50		;Se resta 50
 
    btfss   STATUS,2	;Se verifica Bandera Z
    return		;De ser TRUE regresa a rutina anterior
	    
    clrf    STATUS	;Se limpia registro STATUS
    clrf    cont	;Se resetea contador
    incf    cont_2	;Se incrementa contador 2
    
    movlw   0x0A	;Se mueve 10 a W
    XORWF   cont_2,0	;Se realiza un XOR de W con contador 2
    btfsc   STATUS,2	;Se verifica Bandera Z
    clrf    cont_2	;Se limpia contador 2 de ser TRUE
    
    movf    cont_2,0	;Se mueve valor de contador 2 a W
    call    Display	;Se llama a la tabla del display
    movwf   PORTC	;Se muestra valor de contador en display
    call    Contador_2	;Se llama a sub rutina de contador 2
    
    return

;----------- CONTADOR 2 ----------------------    
Contador_2:
    incf    cont_3	;Se incrementa contador 3
    movf    cont_3,0	;Se mueve contador 3 a W
    sublw   10		;Se resta 10 
    
    btfss   STATUS,2	;Se verifica Bandera Z
    return		;De ser True regresa a rutina anterior
    
    clrf    STATUS	;Se limpia registro STATUS
    clrf    cont_3	;Se limpia contador 3
    incf    cont_4	;Incrementa contador 4
    
    movlw   0x06	;Se mueve 10 a W
    XORWF   cont_4,0	;Se realiza XOR de W con contador 4
    btfsc   STATUS,2	;Se verifica Bandera Z
    clrf    cont_4	;Se limpia contador 4 de ser TRUE
    
    movf    cont_4,0	;Se mueve valor de contador 4 a W
    call    Display	;Se llama a la tabla del display
    movwf   PORTA	;Se muestra valor de contador 4 en display
    
    return
   
;----------- Tabla del display -----------      
Display:
    clrf    PCLATH
    bsf	    PCLATH,0
    andlw   0x0F
    addwf   PCL
    retlw   0x3F	;0
    retlw   0x06	;1
    retlw   0x5B	;2
    retlw   0x4F	;3
    retlw   0x66	;4
    retlw   0x6D	;5
    retlw   0x7D	;6
    retlw   0x07	;7
    retlw   0xFF	;8
    retlw   0x6F	;9
    retlw   0x77	;A
    retlw   0x7C	;B
    retlw   0x39	;C
    retlw   0x5E	;D
    retlw   0x79	;E
    retlw   0x71	;F
END    