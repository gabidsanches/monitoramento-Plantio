.data
    MSG_INICIO:     .asciiz "\n=== ESTUFA INTELIGENTE ===\n"
    MSG_LEITURA:    .asciiz "\n--------------------------\n>>> INICIANDO LEITURA #"
    MSG_FIM_LEITURA:.asciiz "\n--------------------------\n"
    ASK_UMID:       .asciiz "\nDigite a UMIDADE do solo (0-100): "
    ASK_TEMP:       .asciiz "Digite a TEMPERATURA (C): "
    ASK_PH:         .asciiz "Digite o pH do solo (0-14): "
    MSG_VALORES:    .asciiz "\n[DADOS LIDOS] Umidade: "
    SEPARADOR:      .asciiz " | Temp: "
    SEPARADOR_PH:   .asciiz " | pH: "
    QUEBRA_LINHA:   .asciiz "\n"
    ALERTA_SECO:    .asciiz "   [ALERTA] Solo Seco! (Bomba Ligada)\n"
    ALERTA_QUENTE:  .asciiz "   [ALERTA] Temperatura Alta! (Ventoinha Ligada)\n"
    ALERTA_ACIDO:   .asciiz "   [ALERTA] pH muito Acido!\n"
    ALERTA_BASICO:  .asciiz "   [ALERTA] pH muito Basico!\n"
    STATUS_OK:      .asciiz "   [STATUS] Sistema Estavel!\n"
    
    MSG_VETOR_FINAL:.asciiz "\n\n=== HISTORICO FINAL DE UMIDADE (5 LEITURAS) ===\nValores: "
    SPACE:          .asciiz "  "
    
    # Vetor inicializado com 0 para vermos o preenchimento
    historico_umid: .word 0, 0, 0, 0, 0 
    indice_atual:   .word 0
    tam_vetor:      .word 5
    LIMITE_SECO:    .word 40
    LIMITE_TEMP:    .word 30
    PH_MIN:         .word 6
    PH_MAX:         .word 8

.text
.globl main

main:
    li $v0, 4
    la $a0, MSG_INICIO
    syscall

    # === INICIALIZACAO DO CONTADOR DO LOOP PRINCIPAL ===
    li $s7, 0           # $s7 sera nosso contador (i = 0)
    li $s6, 5           # $s6 é o limite (5 vezes mas da pra imaginarmos que sera infinito)

# Para simular o main loop da um embarcado
main_loop:
    beq $s7, $s6, fim_loop_principal # Se contador == 5, sai do loop

    # Imprime numero da leitura
    li $v0, 4
    la $a0, MSG_LEITURA
    syscall
    
    li $v0, 1
    addi $t0, $s7, 1    # Imprime i + 1 para ficar bonito (Leitura 1, 2...)
    move $a0, $t0
    syscall

    # --- 1. ENTRADA DE DADOS ---
    li $v0, 4
    la $a0, ASK_UMID
    syscall
    li $v0, 5
    syscall
    move $s0, $v0       # $s0 = Umidade

    li $v0, 4
    la $a0, ASK_TEMP
    syscall
    li $v0, 5
    syscall
    move $s1, $v0       # $s1 = Temperatura

    li $v0, 4
    la $a0, ASK_PH
    syscall
    li $v0, 5
    syscall
    move $s2, $v0       # $s2 = pH

    # --- 2. ECHO DOS VALORES ---
    li $v0, 4
    la $a0, MSG_VALORES
    syscall
    li $v0, 1
    move $a0, $s0
    syscall
    li $v0, 4
    la $a0, SEPARADOR
    syscall
    li $v0, 1
    move $a0, $s1
    syscall
    li $v0, 4
    la $a0, SEPARADOR_PH
    syscall
    li $v0, 1
    move $a0, $s2
    syscall
    li $v0, 4
    la $a0, QUEBRA_LINHA
    syscall

    # --- 3. ARMAZENAMENTO NO VETOR ---
    lw $t0, indice_atual
    mul $t1, $t0, 4             # offset = indice * 4 bytes
    la $t2, historico_umid
    add $t2, $t2, $t1           # Endereço base + offset
    sw $s0, 0($t2)              # Salva a umidade lida no vetor

    # Atualiza Indice Circular
    addi $t0, $t0, 1
    lw $t3, tam_vetor
    div $t0, $t3
    mfhi $t0                    # Resto da divisao (0..4)
    sw $t0, indice_atual

    # --- 4. ANALISE DE ALERTAS ---
    li $t9, 0                   # Flag (0 = ok, 1 = alerta)

    # Check Umidade
    lw $t0, LIMITE_SECO
    bge $s0, $t0, check_temp
    li $v0, 4
    la $a0, ALERTA_SECO
    syscall
    li $t9, 1

check_temp:
    lw $t0, LIMITE_TEMP
    ble $s1, $t0, check_ph
    li $v0, 4
    la $a0, ALERTA_QUENTE
    syscall
    li $t9, 1

check_ph:
    lw $t0, PH_MIN
    lw $t1, PH_MAX
    blt $s2, $t0, aviso_acido
    bgt $s2, $t1, aviso_basico
    j fim_analise

aviso_acido:
    li $v0, 4
    la $a0, ALERTA_ACIDO
    syscall
    li $t9, 1
    j fim_analise

aviso_basico:
    li $v0, 4
    la $a0, ALERTA_BASICO
    syscall
    li $t9, 1

fim_analise:
    bne $t9, $zero, proxima_iteracao
    li $v0, 4
    la $a0, STATUS_OK
    syscall

proxima_iteracao:
    # Incrementa contador do loop principal
    addi $s7, $s7, 1
    j main_loop

# === FIM DAS 5 LEITURAS, IMPRIME VETOR ===
fim_loop_principal:

    li $v0, 4
    la $a0, MSG_VETOR_FINAL
    syscall

    li $t5, 0           # Contador para impressao
    lw $t6, tam_vetor

loop_print:
    beq $t5, $t6, encerrar_programa
    
    mul $t7, $t5, 4
    la $t8, historico_umid
    add $t8, $t8, $t7
    lw $a0, 0($t8)
    
    li $v0, 1
    syscall
    
    li $v0, 4
    la $a0, SPACE
    syscall

    addi $t5, $t5, 1
    j loop_print

encerrar_programa:
    li $v0, 4
    la $a0, QUEBRA_LINHA
    syscall
    li $v0, 10     
    syscall