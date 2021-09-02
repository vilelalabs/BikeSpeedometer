;################################################################################
;			     Projeto Bike speedometer										#
;			     	                      										#
; Arquivo com as diretivas, defini��es de vari�veis e inicializa��o do hardware #
;			     	                      										#
;						      Por: Henrique Leal Vilela 						#
;################################################################################

;-----------------------------Diretivas de Compila��o----------------------------

	list p=16f84a
	radix dec
	include <p16f84a.inc>
	__config _xt_osc & _cp_off & _wdt_off & _pwrte_on

	;#define simula	; comentar quando compilar o programa final

;-----------------------------------Variaveis------------------------------------

;--- mapeamento da RAM----------------------------------
t1ms	equ	0Ch	 ; para gerar 1 milissegundo						
t100ms	equ	0Dh	 ; para gerar 100 milissegundo						
t1s	equ	0Eh	 ; para gerar 1 segundo						
txms	equ	0Fh	 ; para gerar valores diferentes de delay nas fun��es do LCD						
pulsos	equ	10h	 ; Guarda o numero de pulsos recebidos no Timer 0						
inicial	equ	11h	 ; Essa variavel receber� o valor de "pulsos"						
respl	equ	12h	 ; Byte mais baixo no resultado final da convers�o (simula 16 bits)						
resph	equ	13h	 ; Byte mais alto no resultado final da convers�o (simula 16 bits)						
final	equ	14h	 ; Resultado final j� convertido e arredondado para 8bits						
numero	equ	15h	 ; Recebe valor de "final" e � processada para separar decimal de unidade						
dec	equ	16h	 ; Guarda o algarismo representante da unidade e depois o mesmo valor em ASCII
uni	equ	17h	 ; Guarda o algarismo representante da unidade e depois o mesmo valor em ASCII						
valor	equ	18h	 ; valor que vai para a tela em ASCII						


;----------------------------inicializa��o do Hardaware--------------------------
	bsf	status,rp0	;vai para banco 1 da RAM
	
	bcf	option_reg,4	; Regula Timer 0 para incrementar da porta RA4/T0CKI:
				; Bit5 = 1 (sel. RA4), Bit4 = 0 (incr. na subida)

	clrf	trisa		; PORTA � todo sa�da...
	bsf	trisa,4		; ...exceto bit4 que ser� usado como entrada pelo Timer0

	clrf	trisb		; Rb0 e Rb1 ser�o usados como sa�da, os outros
				; n�o s�o utilizados, tamb�m setados como saida
	
	bcf	status,rp0	; volta ao banco 0 da RAM

	clrf	pulsos		; zera os pulsos para o inicio do programa

;       -------------------------INICIA LCD------------------------------
	call lcd_reset		; inicio obrigatorio para o display
	call ini_lcd		;inicia display de cristal liquido
	call ini_txt		;coloca texto fixo na tela
	
	goto LOOP
	


;--------------------------------------------------------------------------------

;################################################################################
;################################################################################
;	    		        ROTINAS DO SENSOR
;################################################################################
;################################################################################

verifica_sensor:
	; TMR0 contar�
	clrf 	TMR0		 ;  zera TMR0
	
	call 	delay1s		 ; espera contar durante 1s.

	;******************** DEBUG *****************************************
	
	;movlw	8
	;movwf	tmr0

	; coment�rio na chamada de 1s  (call delay1s)tamb�m faz parte do DEBUG, 
	; tirar coment�rio no programa final

	; parece que pode-se deixar 5ms inv�s de 100ms ap�s escrita de caractere
	; testar com hardware e se funcionar, modificar na fun��o lcd_txt e atualiza_lcd
	
	;********************************************************************

	movf	tmr0,w		 ; transfere contagem do timer para

	xorwf	pulsos		 ; v� se o valor � igual, se for n�o precisa continuar, o display nao muda
	btfsc	status,z	 ; se Z = 0 � pq o XOR n�o zerou ou seja, n�o � igual o numero, ent�o pula
	  goto    verifica_sensor; se deu igual ent�o pega novo valor, at� qeu seja diferente
				 ; se diferente, coloca novo valor na vari�vel
	movwf	pulsos  	 ; coloca valor obtido na vari�vel para tratamento posterior

	return

;----------------------SA�DA: Valor na vari�vel "pulsos" ------------------------

;################################################################################
;################################################################################
;	    		      	  ROTINAS DE DELAY
;################################################################################
;################################################################################
;----- inicio da rotina de 1 segundo

delay1s:

	#ifdef simula	; para pular a espera de tempo na simula��o
	   return
	#endif

	movlw   10
	movwf	t1s		; At� aqui incluindo o call gastaram-se 4 us.

ms100:
	movlw   100		; 1 us Carrega milisegundo com 100
	movwf	t100ms		; 1 us

ms1:				
	movlw	249		; carrega x com o valor 249 (decimal)
	movwf	t1ms		; 2 us ( 1 do movlw e 1 do movwf )
ms2:
	nop			; + 1 us
	decfsz	t1ms		; + 1 us (no �ltimo eh 2 e pula p/ decfsz seg)
	goto	ms2		; + 2 us, total 4us.(no �ltimo n�o passa aqui) 
				; (4 us x 249)-1  totaliza 995 us
	decfsz	t100ms		; +1 us (na �ltima pasagem 2 us)
	goto	ms1		; +2 us (na �ltima passagem pula) 
				; total ms1 (1000 x 100)-1 = 99999
	decfsz	t1s		; + 1 us (no �ltimo eh 2 e pula p/ return)
	goto	ms100		; +2 us (na �ltima passagem pula) 

				; Total antes do return: 4us (inicio) +10 X 100004 
				; {(1 do movlw100 + 1 do movwf milisegundo + 99999 da
				; rotina ms1 + 1 do decfsz seg + 2 do goto)}- 1 da 
				; �ltima passagem Total = 1000043 us
	return			; + 2 us retorna da sub-rotina apos 1.000.045 us
				; aproximadamente 1 segundo

;-----fim da rotina de 1s
;-------------------- inicio da rotina de 1 milissegundo--------------------------
delay_ms:

	#ifdef simula	; para pular a espera de tempo na simula��o
	   return
	#else

	movwf	txms	;pega valor de tempo setado antes de call delay_ms

	#endif
ms11:
	movlw	249		; carrega x com o valor 249 (decimal)
	movwf	t1ms
ms22:				; Ate aqui incluindo o call gastaram-se 4 us.
	nop			; + 1 us
	decfsz	t1ms		; + 1 us (no �ltimo eh 2 e pula p/ return)
	goto	ms22		; + 2 us, total 4us.(no �ltimo n�o passa aqui) 
				; 4 us do inicio + (4 us x 248) + 3us do �ltimo
				; totaliza 999 us

	decfsz	txms		; faz decrementos de acordo com o valor escolhido
	 goto	ms11		;

	return			; + 2 us retorna da sub-rotina apos 1,001ms por rodada
				; aproximadamente 1 ms
;-----fim da rotina de 1ms

;################################################################################
;################################################################################
;    		      	    ROTINA DE CONVERS�O PARA M/S
;################################################################################
;################################################################################

math:	
	; ver algoritmo no arquivo de documenta��o do projeto

	; zera vari�veis relacionadas	
	bcf	status, DC	; apaga carry (digit carry ativa quando decimal � obtido)
	clrf 	respl		; zera variavel de resposta
	clrf	resph		; result(low,high) = 0
	
	; VALOR DE W � A VARI�VEL PULSOS (PEGO NO PROG. PRINCIPAL)

	movwf	inicial		; valor guardado
	
	movf	inicial		;
	
	addwf   resph		;result+x
	rrf	resph		;>>1
	rrf	respl		; shift o low de resp

	addwf   resph		;result+x
	rrf	resph		;>>1
	rrf	respl		

	rrf	resph		;>>1
	rrf	respl		

	rrf	resph		;>>1
	rrf	respl		

	addwf   resph		;result+x
	rrf	resph		;>>1
	rrf	respl		

	addwf   resph		;result+x
	rrf	resph		;>>1
	rrf	respl		

	addwf   resph		;result+x
	rlf	respl
	rlf	resph		;<<1

	; para arredondar:
	btfsc respl,7
		call arredonda

	movf	resph,w
	movwf final
		
	return
;----------------------sub rotina para arredondar valor ---------------
arredonda:
	movlw	1
	addwf resph
	return

;----------------------SA�DA: Valor na vari�vel "final" ------------------------

;################################################################################
;################################################################################
;    		      	    ROTINA DE CONVERS�O ASCII
;################################################################################
;################################################################################
get_ascii:
	
	movwf	numero	;(pega n�mero que veio de W de uma fun��o externa) (final)	

	;inicia variaveis
	clrf	dec
	clrf	uni

;-------------------------------------------------------------------------------------
; fazer loop. subtraindo de 10 em 10... quando bit7 der 1 � pq o num � negativo
; ou seja, a ultima subtra��o, subtraiu unidades.
; recuperar o valor e guardart as unidades que restaram em outra vari�vel

acha_dec_uni
	 movlw	10
	 subwf	numero
	 btfss	numero,7	; testa se deu negativo
	  call aumenta_dec
	btfss	numero,7	; se ainda for positivo testa novamente
	  goto acha_dec_uni

	movlw	10		; recupera temp_anterior
	addwf	numero		; ficando apenas com as unidades
	movf	numero,w
	movwf 	uni		; unidade obtida!


	movf	dec,w		; converte DEC para ASCII
	call	ascii_format	
	movwf	dec		;valor convertido que ir� para o LCD

	movf	uni,w		; converte UNI para ASCII
	call	ascii_format	
	movwf	uni		;valor convertido que ir� para o LCD
	return

aumenta_dec
	movlw 1
	addwf dec
	return
;---------------------forma tabela com poss�veis valores ASCII----------------------

ascii_format:
	addwf PCL		;adicina valor dec ou uni ao PCL para achar o 
				;ASCII correspondente
				
			;retornar� W com um dos valores seguintes:
	retlw	'0'
	retlw	'1'
	retlw	'2'
	retlw	'3'
	retlw	'4'
	retlw	'5'
	retlw	'6'
	retlw	'7'
	retlw	'8'
	retlw	'9'



;################################################################################
;################################################################################
;	    		      	  ROTINAS DO LCD
;################################################################################
;################################################################################

;**************************** INICIALIZA��O DO LCD ******************************

ini_lcd:
	movlw	30	; aguarda 30ms
	call	delay_ms

	movlw 	0x28	; LCD 16x2 - 4 bits de dados
	call 	cmd_lcd	;
	movlw	0x0e	; display com F = cursor piscante (E = CURSOR INVISIVEL) ver se funciona, se n�o voltar F (E) xxxxxxxxxxxxxxxxxxxxx
	call 	cmd_lcd	;
	movlw	0x06	; cursor desloca a direita
	call 	cmd_lcd	;
	movlw	0x01	; limpa todo o display
	call 	cmd_lcd	;

	return

;************************* ESCRITA DE COMANDO NO LCD ****************************

cmd_lcd:
	movwf	valor	; pega valor que est� em W e salva na variavel
	swapf	valor	; troca nibbles para mandar o nibble mais significativo primeiro
	movf	valor,w	; joga valor para W
	movwf   porta	; coloca valor no porta (so ir�o os bits em Ra0 a Ra3)
	bcf	portb,1	; seleciona escrita no LCD (Ra4 = 0 -> Instru��o)
	nop
	bsf	portb,0	; Rb0 (Chip Enable) = 1 -> habilita chip
	movlw	1	;
	call 	delay_ms; leva 1ms para "escrever" a instru��o no chiip do display
	bcf	portb,0	; Rb0 (Chip Enable) = 0 -> desabilita chip
	movlw	3	;
	call delay_ms	; 3ms de delay para desabilita��o e continuar
	
	swapf	valor	; destroca o nibble (agora mandar� o menos significativo)
	movf	valor,w	;
	movwf	porta	; coloca bits na sa�da
	bcf	portb,1	; seleciona escrita de instru��o
	nop
	bsf	portb,0	; C. Enable = 1
	movlw	1	;
	call delay_ms	;
	bcf	portb,0	; C, Enable off (= 0)
	movlw	3	;
	call delay_ms	;
	return

;************************* ESCRITA DE CARACTERE NO LCD ****************************

wr_lcd:
	movwf	valor	;guarda valor em W na vari�vel "valor"
	swapf	valor	;troca nibbles para mandar mais signif. primeiro
	movf	valor,w	;
	movwf	porta	; coloca valor em portA
	bsf	portb,1	; seleciona escrita no LCD (Ra4 = 1 -> Dados)
	bsf	portb,0	; habilita Chip
	movlw	1	;
	call 	delay_ms;
	bcf	portb,0	; desabilita chip
	movlw	1	;
	call 	delay_ms;
	swapf	valor	; destroca nibbles, para enviar menos signf.
	movf	valor,w	;
	movwf	porta	; coloca no porta
	bsf	portb,1	; habilita escrita de dados no LCD
	bsf	portb,0	; Chip Enable = 1
	movlw	1	;
	call 	delay_ms;
	bcf	portb,0	; Chip Enable = 0
	movlw	1	;
	call 	delay_ms;


	return

;********************************************************************************
;*		Rotina obrigat�ria de reset do LCD ao ligar o Sistema		*
;*			(recomendada pelos fabricantes de LCD)			*
;********************************************************************************

lcd_reset:
	movlw	30		;tempo de delay ants de resetar o LCD
	call 	delay_ms

	movlw	b'00000011'	; coloca dados na Porta A=00011, onde:
	bcf	portb,1	
	movwf 	porta		; Ra0=b4, Ra1=b5, ra2=b6, Ra3=b7, Ra4=C/D, Rb0=CS
				; C/D = Command/Data, CS = Chip Select

	bsf	portb,0		;reseta LCD habilitando 5ms-hi e 1ms-low rb0(CS)
	movlw	5
	call 	delay_ms
	bcf 	portb,0
	movlw 	1
	call 	delay_ms

	bsf	portb,0		; mais 1ms em alto e 1ms em baixo
	movlw	1
	call 	delay_ms
	bcf 	portb,0
	movlw 	1
	call 	delay_ms

	bsf	portb,0		; mais 1ms em alto e 1ms em baixo
	movlw	1
	call 	delay_ms
	bcf 	portb,0
	movlw 	1
	call 	delay_ms

	movlw	b'00000010'	;reseta LCD: PORTA=00010
	bcf	portb,1	
	movwf	porta	
	
	bsf	portb,0		; mais 1ms em alto e 1ms em baixo no RB0
	movlw	1
	call 	delay_ms
	bcf 	portb,0
	movlw 	1
	call 	delay_ms

	return

;*************************** FIM DA ROTINA OBRIGAT�RIA **************************



ini_txt:
; --------------------------- ESCREVE TEXTO FIXO NA TELA -----------------------------

	;	Velocidade
	;	  00Km/h

	movlw 	0x83		; posi��o inicial da escrita no display 80H->83H 
				; inicial para centralizar "Velocidade"
	
	call 	cmd_lcd		;

	movlw	'V'		; caractete 1
	call	wr_lcd		; WRite LCD
	movlw 	5		; coloca 100 em W que far� com que ms gaste
	call delay_ms		; 100ms

	movlw	'e'		; caractete 2
	call 	wr_lcd		;
	movlw 	5		;
	call delay_ms		;

	movlw	'l'		; caractete 3
	call 	wr_lcd		;
	movlw 	5		;
	call delay_ms		;

	movlw	'o'		; caractete 4
	call 	wr_lcd		;
	movlw 	5		;
	call delay_ms		;

	movlw	'c'		; caractete 5
	call 	wr_lcd		;
	movlw 	5		;
	call delay_ms		;

	movlw	'i'		; caractete 6
	call 	wr_lcd		;
	movlw 5		;
	call delay_ms		;

	movlw	'd'		; caractete 7
	call 	wr_lcd		;
	movlw 	5		;
	call delay_ms		;

	movlw	'a'		; caractete 8
	call 	wr_lcd		;
	movlw 	5		;
	call delay_ms		;

	movlw	'd'		; caractete 9
	call 	wr_lcd		;
	movlw 	5		;
	call delay_ms		;

	movlw	'e'		; caractete 10
	call 	wr_lcd		;
	movlw 	5		;
	call delay_ms		;


	movlw	0xC5;		; escreve a partir da segunda linha em C0->C5 para
	call	cmd_lcd		; para centralizar o texto "nnKm/k"

	movlw '0'		; caractere 1 (linha 2)
	call wr_lcd
	movlw 5
	call delay_ms

	movlw '0'		; caractere 2 (linha 2)
	call wr_lcd
	movlw 5
	call delay_ms

	movlw 'K'		; caractere 3 (linha 2)
	call wr_lcd
	movlw 5
	call delay_ms

	movlw 'm'		; caractere 4 (linha 2)
	call wr_lcd
	movlw 5
	call delay_ms

	movlw '/'		; caractere 5 (linha 2)
	call wr_lcd
	movlw 100
	call delay_ms

	movlw 'h'		; caractere 6 (linha 2)
	call wr_lcd
	movlw 100
	call delay_ms

	movlw 250
	call delay_ms

	return


;------------------- ATUALIZA TELA DO LCD COM NOVOS VALORES ---------------------
atualiza_tela:

; ---------------------------- ATUALIZA VALORES NO LCD-----------------------------
	movlw	0xC5;		; escreve no endere�o onde est�o os n�meros C5 e C6
	call	cmd_lcd		;-------------------------------------------------

	movf dec,w		; caractere 1 VALOR PEGO DA FUN��O GET_ASCII "DEC"
	call wr_lcd
	movlw 10
	call delay_ms

	movf uni,w		; caractere 2 VALOR PEGO DA FUN��O GET_ASCII "UNI"
	call wr_lcd
	movlw 10
	call delay_ms

	movlw	0xCF;		; joga cursor no ultimo caractere (para sair da frente do "K")
	call	cmd_lcd		;

;;;;;;; retirado pois era para dar tempo de mostrar na tela, porem s� o sensor j� gasta 1s ;;;;;;;
;	movlw 250		; espera um tempo na tela antes de atualizar o valor
;	call delay_ms		; pode ser tirado, se colocar o tempo de espera do sensor

	return

;-------------------------------------------------------------------------------------------------
