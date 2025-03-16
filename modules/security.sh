#!/bin/bash

# Módulo de Segurança para Script OCP
# Copyright (c) 2024 Octonus Cloud Platform (OCP)
# Website: octhost.com.br
# Suporte: suporte@octhost.com.br

# Configuração do Firewall (UFW)
configurar_firewall() {
    registrar_mensagem "INFO" "Iniciando configuração do firewall"
    
    # Verifica se o UFW está instalado
    if ! command -v ufw &> /dev/null; then
        registrar_mensagem "INFO" "Instalando UFW..."
        apt-get update && apt-get install -y ufw
    fi
    
    # Configuração básica
    ufw default deny incoming
    ufw default allow outgoing
    
    # Permite SSH (antes de ativar o firewall)
    ufw allow ssh
    
    # Permite portas comuns
    ufw allow 80/tcp  # HTTP
    ufw allow 443/tcp # HTTPS
    
    # Menu de configuração
    while true; do
        clear
        echo -e "${BRANCO}Configuração do Firewall${SEM_COR}"
        echo "1) Listar Regras Atuais"
        echo "2) Adicionar Nova Regra"
        echo "3) Remover Regra"
        echo "4) Habilitar Firewall"
        echo "5) Desabilitar Firewall"
        echo "6) Voltar"
        
        read -p "Escolha uma opção: " opcao
        
        case $opcao in
            1) listar_regras_firewall ;;
            2) adicionar_regra_firewall ;;
            3) remover_regra_firewall ;;
            4) habilitar_firewall ;;
            5) desabilitar_firewall ;;
            6) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

listar_regras_firewall() {
    echo -e "${CIANO}Regras do Firewall:${SEM_COR}"
    ufw status numbered
    read -p "Pressione Enter para continuar..."
}

adicionar_regra_firewall() {
    echo -e "${BRANCO}Adicionar Nova Regra${SEM_COR}"
    echo "1) Permitir porta"
    echo "2) Negar porta"
    echo "3) Permitir serviço"
    echo "4) Negar serviço"
    echo "5) Voltar"
    
    read -p "Escolha uma opção: " opcao
    
    case $opcao in
        1)
            read -p "Digite a porta: " porta
            read -p "Protocolo (tcp/udp): " protocolo
            if [[ -n $porta && -n $protocolo ]]; then
                ufw allow $porta/$protocolo
                registrar_mensagem "SUCESSO" "Regra adicionada: permitir porta $porta/$protocolo"
            fi
            ;;
        2)
            read -p "Digite a porta: " porta
            read -p "Protocolo (tcp/udp): " protocolo
            if [[ -n $porta && -n $protocolo ]]; then
                ufw deny $porta/$protocolo
                registrar_mensagem "SUCESSO" "Regra adicionada: negar porta $porta/$protocolo"
            fi
            ;;
        3)
            read -p "Digite o nome do serviço: " servico
            if [[ -n $servico ]]; then
                ufw allow $servico
                registrar_mensagem "SUCESSO" "Regra adicionada: permitir serviço $servico"
            fi
            ;;
        4)
            read -p "Digite o nome do serviço: " servico
            if [[ -n $servico ]]; then
                ufw deny $servico
                registrar_mensagem "SUCESSO" "Regra adicionada: negar serviço $servico"
            fi
            ;;
        5) return ;;
        *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
    esac
}

remover_regra_firewall() {
    echo -e "${CIANO}Regras Atuais:${SEM_COR}"
    ufw status numbered
    read -p "Digite o número da regra para remover: " numero
    
    if [[ -n $numero ]]; then
        if confirmar_acao "Tem certeza que deseja remover a regra $numero?"; then
            ufw delete $numero
            registrar_mensagem "SUCESSO" "Regra $numero removida"
        fi
    fi
}

habilitar_firewall() {
    if confirmar_acao "Tem certeza que deseja habilitar o firewall?"; then
        echo "y" | ufw enable
        registrar_mensagem "SUCESSO" "Firewall habilitado"
    fi
}

desabilitar_firewall() {
    if confirmar_acao "Tem certeza que deseja desabilitar o firewall?"; then
        ufw disable
        registrar_mensagem "SUCESSO" "Firewall desabilitado"
    fi
}

# Gerenciamento de SSL
gerenciar_ssl() {
    while true; do
        clear
        echo -e "${BRANCO}Gerenciamento de SSL${SEM_COR}"
        echo "1) Gerar Certificado Auto-Assinado"
        echo "2) Verificar Certificados"
        echo "3) Renovar Certificados"
        echo "4) Backup de Certificados"
        echo "5) Voltar"
        
        read -p "Escolha uma opção: " opcao
        
        case $opcao in
            1) gerar_certificado_auto_assinado ;;
            2) verificar_certificados ;;
            3) renovar_certificados ;;
            4) backup_certificados ;;
            5) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

gerar_certificado_auto_assinado() {
    read -p "Digite o domínio: " dominio
    read -p "Digite o diretório de destino: " dir_destino
    
    if [[ -n $dominio && -n $dir_destino ]]; then
        mkdir -p "$dir_destino"
        
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "$dir_destino/$dominio.key" \
            -out "$dir_destino/$dominio.crt" \
            -subj "/CN=$dominio"
        
        chmod 600 "$dir_destino/$dominio.key"
        registrar_mensagem "SUCESSO" "Certificado gerado para $dominio"
    fi
}

verificar_certificados() {
    local dir_ssl="/etc/ssl/ocp"
    
    echo -e "${CIANO}Certificados encontrados:${SEM_COR}"
    find "$dir_ssl" -type f -name "*.crt" -o -name "*.pem" | while read cert; do
        echo -e "\nCertificado: $cert"
        openssl x509 -in "$cert" -text -noout | grep -E "Subject:|Not After :"
    done
    
    read -p "Pressione Enter para continuar..."
}

renovar_certificados() {
    registrar_mensagem "INFO" "Verificando certificados para renovação"
    
    # Implementar lógica de renovação específica
    # Por exemplo, para Let's Encrypt:
    if command -v certbot &> /dev/null; then
        certbot renew --quiet
        registrar_mensagem "SUCESSO" "Certificados renovados"
    else
        registrar_mensagem "ERRO" "Certbot não encontrado"
    fi
}

backup_certificados() {
    local dir_ssl="/etc/ssl/ocp"
    local dir_backup="/var/backups/ocp/ssl"
    local data=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$dir_backup"
    
    tar -czf "$dir_backup/ssl_backup_$data.tar.gz" "$dir_ssl"
    
    if [ $? -eq 0 ]; then
        registrar_mensagem "SUCESSO" "Backup de certificados criado em $dir_backup/ssl_backup_$data.tar.gz"
    else
        registrar_mensagem "ERRO" "Falha ao criar backup dos certificados"
    fi
}

# Auditoria de Segurança
auditoria_seguranca() {
    registrar_mensagem "INFO" "Iniciando auditoria de segurança"
    
    echo -e "${BRANCO}Relatório de Auditoria de Segurança${SEM_COR}"
    echo -e "${CIANO}----------------------------------------${SEM_COR}"
    
    # Verifica status do firewall
    echo -e "\n${BRANCO}Status do Firewall:${SEM_COR}"
    ufw status verbose
    
    # Verifica portas abertas
    echo -e "\n${BRANCO}Portas Abertas:${SEM_COR}"
    netstat -tuln
    
    # Verifica processos em execução
    echo -e "\n${BRANCO}Processos em Execução:${SEM_COR}"
    ps aux | grep -v '[p]s aux' | head -n 5
    
    # Verifica últimas tentativas de login
    echo -e "\n${BRANCO}Últimas Tentativas de Login:${SEM_COR}"
    last | head -n 5
    
    # Verifica usuários com acesso SSH
    echo -e "\n${BRANCO}Usuários com Acesso SSH:${SEM_COR}"
    grep "ssh" /etc/group
    
    # Verifica configurações do SSH
    echo -e "\n${BRANCO}Configurações SSH:${SEM_COR}"
    grep -E "^[^#]" /etc/ssh/sshd_config
    
    read -p "Pressione Enter para continuar..."
}

# Gerenciamento de Senhas
gerenciar_senhas() {
    while true; do
        clear
        echo -e "${BRANCO}Gerenciamento de Senhas${SEM_COR}"
        echo "1) Gerar Nova Senha"
        echo "2) Alterar Senha de Usuário"
        echo "3) Verificar Política de Senhas"
        echo "4) Voltar"
        
        read -p "Escolha uma opção: " opcao
        
        case $opcao in
            1) gerar_nova_senha ;;
            2) alterar_senha_usuario ;;
            3) verificar_politica_senhas ;;
            4) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

gerar_nova_senha() {
    read -p "Digite o tamanho da senha (mínimo 12): " tamanho
    
    if [[ $tamanho -lt 12 ]]; then
        tamanho=12
    fi
    
    local senha=$(gerar_senha_segura $tamanho)
    echo -e "${VERDE}Senha gerada: $senha${SEM_COR}"
    read -p "Pressione Enter para continuar..."
}

alterar_senha_usuario() {
    read -p "Digite o nome do usuário: " usuario
    
    if id "$usuario" &>/dev/null; then
        passwd "$usuario"
        registrar_mensagem "SUCESSO" "Senha alterada para o usuário $usuario"
    else
        registrar_mensagem "ERRO" "Usuário $usuario não encontrado"
    fi
}

verificar_politica_senhas() {
    echo -e "${BRANCO}Política de Senhas Atual:${SEM_COR}"
    
    if [ -f "/etc/security/pwquality.conf" ]; then
        grep -E "^[^#]" /etc/security/pwquality.conf
    else
        echo "Arquivo de política de senhas não encontrado"
    fi
    
    read -p "Pressione Enter para continuar..."
}

# Inicialização do módulo
inicializar_seguranca() {
    registrar_mensagem "INFO" "Módulo de segurança inicializado"
    
    # Verifica dependências
    local deps=("ufw" "openssl" "netstat" "certbot")
    local faltando=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            faltando+=("$dep")
        fi
    done
    
    if [ ${#faltando[@]} -ne 0 ]; then
        registrar_mensagem "AVISO" "Dependências faltando: ${faltando[*]}"
        if confirmar_acao "Deseja instalar as dependências faltantes?"; then
            apt-get update && apt-get install -y "${faltando[@]}"
        fi
    fi
}
