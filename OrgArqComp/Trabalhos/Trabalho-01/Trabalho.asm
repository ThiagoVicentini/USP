name "TrabalhoFosorio"

org 100h

main:
   ;procedures que escrevem as informacoes principais na tela
    call estadoAndarAtual
    call estadoPorta    
    call estadoMovimento  
    call reqExt
    call reqInt
    
    mov flagReset, 0 ; volta a energia 
    mov flagAlarme, 0; desliga o alarme
    
   ;pula duas linhas
    mov AH, 09h
    mov DX, offset \n
    int 21h
    int 21h  
    
   ;checa por keystroke 
    mov AH, 01h  
    int 16h              
    je moveElevador  ;se nao tiver tecla reinicia o loop
    
    ;se tiver tecla, continua aqui o tratamento   
    mov teclaTemp, AL  ;passar o valor da tecla para a variavei "teclaTemp" 
    mov AH, 0Ch         ;limpa o buffer   
    int 21h                                                    
    
    cmp teclaTemp, 56
    jle insereIntpExt
    
    cmp teclaTemp, 83; S: porta desobstruida
    je  desobstruir 
    
    cmp teclaTemp, 104
    jle insereIntpInt
    
    cmp teclaTemp, 120; x: reset/falta energia
    je  reset;------------------------------------------------------------
    
    cmp teclaTemp, 112; p: parada/bloqueio
    je parada;------------------------------------------------------------
    
    cmp teclaTemp, 122; z: sound/SOS
    je alarme;-----------------------------------------------------------
    
    cmp teclaTemp, 111; o: open door
    je abrePorta;--------------------------------------------------------
    
    cmp teclaTemp, 108; l: lock door   
    je fechaPorta; -----------------------------------------------------
    
    cmp teclaTemp, 115; s: porta obstruida
    je obstruir
    
    jmp moveElevador
    
    insereIntpInt:              ;insere requisicao interna no vetor de requisicoes internas
        sub teclaTemp, 96
        mov BL, teclaTemp
        mov [BX], BL
        mov reqsInt[BX], 1
        jmp moveElevador
        
    insereIntpExt:              ;insere requisicao externa no vetor de requisicoes externas
        sub teclaTemp, 48
        mov BL, teclaTemp
        mov [BX], BL
        mov reqsExt[BX], 1 
    
        
moveElevador:
    cmp flagPortaObstruida, 1   ;se a porta estiver obstruida o elevador nao move
    je main 
    
    cmp flagReset, 1            ;se estiver sem energia o elevador nao move
    je main 
    
    cmp destino, 1 ; verifica se nao chegou no andar destinado
    je  nao_chegou_destino   
    
    call criaVetor; procedure que cria um vetor binario de 8 unidades indicando quais sao as requisicoes e qual o proximo andar q deve ir
    lea SI, reqs  ; SI retem conteudo do vetor criado
    
    mov CX, 8      
    loop_elevador:
        cmp [SI], 1 ; se valor do espaco do vetor for 1 pula para label "seleciona"
        je seleciona
            
        inc SI
        loop loop_elevador  
        
    jmp main; reinicia o loop se nao tiver requisicoes
        
    seleciona:
        mov BX, 8
        sub BX, CX
        mov andarDestino, BL; recebe indice do vetor cujo valor eh 1 => andarDestino
    
    nao_chegou_destino:
        
        mov destino, 1; seta flag de destino inconcluido
        mov BL, andarAtual
        
        cmp BL, andarDestino; compara andarAtual com andarDestino, se for menor, chama a label "sobe"
        jl sobe 
    
        cmp BL, andarDestino; compara andarAtual com andarDestino, se for igual, chama a label "para"
        je  para 
        
        ;checa se a porta esta fechada para mover o elevador 
        cmp flagEstadoPorta, 1
        je  fechaPorta
        
        ;altera flag de movimento para descendo (1) e descrementa o andar
        mov flagEstadoElevador, 1
        dec andarAtual     
        
        ;checa se esta no primeiro andar
        mov BL, andarAtual
        cmp BL, 1
        jne condicao_parada_terreo    
        
        ;Codigo para printar que esta na base do predio
        ;------------------------------------------          
            mov flagTerreo, 1
            
            mov AH, 09h
            mov DX, offset msgPrimeiroAndar
            int 21h                               
        ;------------------------------------------
        
        ;checa se apos a descida, chegou ao andar de destino       
        condicao_parada_terreo:
            mov AL, andarAtual
            cmp AL, andarDestino
            je para ;se chegou no andar destino, chama label para parar o elevador
              
        jmp main
          
        sobe:
            ;checa se a porta esta fechada para mover o elevador
            cmp flagEstadoPorta, 1
            je  fechaPorta
            
            ;altera flag de movimento para subindo (2) e incrementa o andar
            mov flagEstadoElevador, 2
            inc andarAtual
            
            ;checa se esta no ultimo andar          
            mov BL, andarAtual
            cmp BL, 8
            jne  condicao_parada  
                                   
            ;Codigo para printar que esta no topo do predio                                  
            ;------------------------------------------     
                mov flagUltimo, 1    
                        
                mov AH, 09h
                mov DX, offset msgUltimoAndar
                int 21h
            ;------------------------------------------
             
            ;checa se apos a subida, chegou ao andar de destino
            condicao_parada:
                mov AL, andarAtual
                cmp AL, andarDestino
                je para; se chegou no andar destino, chama label para parar o elevador
            
            jmp main; recomeca o loop
            
        para:                     
            mov flagEstadoElevador, 0
            mov flagEstadoPorta, 1 
            mov destino, 0
            
            mov BL, andarAtual
            mov [BX], BL
            mov reqsInt[BX], 0
            
            mov BL, andarAtual
            mov [BX], BL
            mov reqsExt[BX], 0
            
            jmp main 
   
alarme:
    mov AH, 09h
    
    mov DX, offset \n
    int 21h
    int 21h
    
    mov DX, offset msgAlarme
    int 21h
    
    ;codigo ultra-hiper-mega-secreto para realizar "beeps"
    mov AH, 6
    mov DL, 07
    int 21h
    int 21h
             
    mov AH, 09h
    mov DX, offset \n
    int 21h
    int 21h
    
    jmp moveElevador 
                               
parada:
    jmp main
    
abrePorta:
    mov flagEstadoPorta, 1
    jmp main
        
fechaPorta:
    mov flagEstadoPorta, 0        
    jmp main       
        
desobstruir: ;porta desobstruida, apertou S
    mov flagPortaObstruida, 0
    
    jmp main
    
obstruir:    ;porta obstruida, apertou s
    mov flagPortaObstruida, 1 
    
    jmp main
       
reset:       ;acabou a luz, apertou x                                            
    mov BL, andarAtual
    mov andarTemp, BL
    mov andarAtual, 15          ;andar "?"
    mov flagEstadoElevador, 0   ;seta flag de estado para 0 => elevador parado
    mov flagReset, 1            ;seta flag de reset para 1 => acabou a luz         
    jmp main
  
criaVetor PROC  
    lea SI, reqs
    lea DI, reqsInt
    lea BP, reqsExt
    
    mov CX, 8
    
    cria:
        mov AL, [DI]
        mov BL, [BP]
        
        or [SI], AL
        or [SI], BL
        
        inc SI
        inc DI
        inc BP
        
        loop cria   
    
    ret    
criaVetor ENDP  
    

;procedure para printar o andar atual
estadoAndarAtual PROC            
    mov AH, 09h
    mov DX, offset msgAndarAtual
    int 21h
    
    mov AH, 02h                              
    mov DL, andarAtual
    add DL, 48                                                     
    int 21h
    
    mov AH, 09h
    mov DX, offset \n
    int 21h
    
    ret
estadoAndarAtual ENDP
    

;procedure para printar o estado da porta (aberta, fechada ou bloqueada)
estadoPorta PROC
    mov AH, 09h
    
    cmp flagPortaObstruida, 1       ;Checa se a porta esta obstruida
    je  portaObstruida
                              
    cmp flagEstadoPorta, 0          ;Checa se a porta esta fechada
    je  portaFechada
    
   ;portaAberta:
    mov DX, offset msgPortaA
    int 21h                
    mov DX, offset \n
    int 21h                  
    
    jmp f1
    
    portaFechada:      
        mov DX, offset msgPortaF
        int 21h
        mov DX, offset \n
        int 21h
        
        jmp f1
        
    portaObstruida:
        mov DX, offset msgPortaO
        int 21h
        mov DX, offset \n
        int 21h         
    
    f1:
        ret
estadoPorta ENDP
 

;procedure para printar o andar atual  
estadoMovimento PROC
    mov AH, 09h   
    
    cmp flagReset, 1                ;checa se o elevador esta com energia
    je  semLuz
    
    cmp flagEstadoElevador, 0       ;checa se o elevador esta parado
    je  parado
    
    cmp flagEstadoElevador, 2       ;checa se o elevador esta subindo
    je subindo
    
    mov DX, offset msgDescendo   
    int 21h
    mov DX, offset \n
    int 21h
        
    jmp fim_estadoMovimento
    
    subindo:
        mov DX, offset msgSubindo   
        int 21h
        mov DX, offset \n
        int 21h
        
        jmp fim_estadoMovimento 
    
    parado:   
        mov DX, offset msgParado
        int 21h       
        mov DX, offset \n
        int 21h
    
        jmp fim_estadoMovimento
        
    semLuz:
        mov DX, offset msgSemLuz
        int 21h       
        mov DX, offset \n
        int 21h
        
    fim_estadoMovimento:
        ret
       
estadoMovimento ENDP
  
;procedure para mostrar as requiscoes externas  
reqExt PROC              
    mov AH, 09h 
    
    cmp flagReset, 1                ;checa se o elevador esta sem energia
    je fim_reqExt                   ;se sim, nao exibe mensagem
    
    mov DX, offset msgReqExt
    int 21h            
    
    mov CX, 8
    mov AH, 02h
    lea SI, reqsExt
    
    printa_reqExt:
        cmp [SI], 1
        je existe
        jmp nao_existe
        
        existe: 
            mov BX, 8
            sub BX, CX
            add BX, 48 
            mov DX, BX
            int 21h
            
            mov DX, " "
            int 21h  
        
        nao_existe:
            inc SI
            loop printa_reqExt
        
    mov AH, 09h
    mov DX, offset \n
    int 21h
    
    fim_reqExt:
        ret
        
reqExt ENDP 

;procedure para mostrar as requiscoes internas
reqInt PROC              
    mov AH, 09h 
    
    cmp flagReset, 1                ;checa se o elevador esta sem energia
    je fim_reqInt                   ;se sim, nao exibe mensagem
    
    mov DX, offset msgReqInt
    int 21h            
    
    mov CX, 8
    mov AH, 02h
    lea SI, reqsInt
    
    printa_reqInt:
        cmp [SI], 1
        je  int_existe
        jmp int_nao_existe
        
        int_existe: 
            mov BX, 8
            sub BX, CX
            add BX, 48 
            mov DX, BX
            int 21h
            
            mov DX, " "
            int 21h
        
        int_nao_existe:
            inc SI
            loop printa_reqInt
    
    mov AH, 09h    
    mov DX, offset \n
    int 21h    
    
    fim_reqInt:
        ret
        
reqInt ENDP  

ret
                        

 
;MENSAGENS
msgAndarAtual db "Andar atual: $"
msgUltimoAndar db "Topo do predio atingido: ultimo andar.$"
msgPrimeiroAndar db "Base do predio atingida: terro.$"

msgPortaF db "Porta fechada. $"           
msgPortaA db "Porta aberta. $"
msgPortaO db "Porta bloqueada. $"

msgSemLuz db "Elevador sem energia $"
msgParado db "Elevador parado $"
msgSubindo db "Elevador subindo $"
msgDescendo db "Elevador descendo $"

msgReqExt db "Requisicoes externas: $"
msgReqInt db "Requisicoes internas: $"

msgAlarme db "WOOOOOOWWW WOOOOOOWW$"

\n db 0Ah, 0Dh,"$"     
 
 
;VARIAVEIS
andarTemp db 0;
andarDestino db 1; armazena o andar destino 
destino db 0; 0 se ja chegou no destino, 1 se nao ja chegou no destino
teclaTemp db 96; armaze temporariamente a tecla do buffer                     
andarAtual db 1; comeca no terreo, ? se sofreu um reset/falta de luz
flagTerreo db 0; 0 se nao esta no terreo, 1 se esta no terreo
flagUltimo db 0; 0 se nao esta no ultimo andar, 1 se esta no ultimo andar
flagEstadoPorta db 0; 0 se a porta estiver fechada, 1 se estiver aberta
flagEstadoElevador db 0; 0 se estiver parado, 1 se estiver descendo, 2 se estiver subindo
flagPortaObstruida db 0; 0 se nao estiver obstruida, 1 se estiver obstruida 
flagReset db 0; 0 se estiver okay, 1 se faltar luz                                       
flagAlarme  db 0; 0 se nao estiver tocando alarm, 1 se estiver tocando o alarme
reqs db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h                       
reqsExt db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
reqsInt db 00h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
;========================================================================================

