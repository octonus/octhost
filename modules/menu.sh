#!/bin/bash

# Módulo de Menu para Script OCP
# Copyright (c) 2024 Octonus Cloud Platform (OCP)
# Website: octhost.com.br
# Suporte: suporte@octhost.com.br

mostrar_menu_principal() {
    while true; do
        clear
        mostrar_banner
        
        echo -e "${BRANCO}Menu Principal${SEM_COR}"
        echo "1) Configuração do Sistema"
        echo "2) Gerenciamento Docker" 
        echo "3) Instalação de Aplicações"
        echo "4) Configuração de Segurança"
        echo "5) Backup e Restauração"
        echo "6) Status do Sistema"
        echo "7) Sair"
        
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) menu_configuracao_sistema ;;
            2) menu_docker ;;
            3) menu_instalacao_apps ;;
            4) menu_seguranca ;;
            5) menu_backup ;;
            6) mostrar_status_sistema ;;
            7) 
                echo -e "${VERDE}Encerrando o script. Obrigado por usar OCP!${SEM_COR}"
                exit 0 
                ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

menu_configuracao_sistema() {
    while true; do
        clear
        echo -e "${BRANCO}Configuração do Sistema${SEM_COR}"
        echo "1) Atualizar Sistema"
        echo "2) Configurar Fuso Horário"
        echo "3) Configurar Nome do Host"
        echo "4) Configurar Rede"
        echo "5) Configurar Firewall"
        echo "6) Voltar ao Menu Principal"
        
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) atualizar_sistema ;;
            2) configurar_fuso_horario ;;
            3) configurar_hostname ;;
            4) configurar_rede ;;
            5) configurar_firewall ;;
            6) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

menu_docker() {
    while true; do
        clear
        echo -e "${BRANCO}Gerenciamento Docker${SEM_COR}"
        echo "1) Instalar Docker"
        echo "2) Configurar Docker"
        echo "3) Gerenciar Contêineres"
        echo "4) Gerenciar Redes"
        echo "5) Gerenciar Volumes"
        echo "6) Atualizar Docker"
        echo "7) Voltar ao Menu Principal"
        
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) instalar_docker ;;
            2) configurar_docker ;;
            3) gerenciar_conteineres ;;
            4) gerenciar_redes_docker ;;
            5) gerenciar_volumes_docker ;;
            6) atualizar_docker ;;
            7) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

menu_instalacao_apps() {
    while true; do
        clear
        echo -e "${BRANCO}Instalação de Aplicações${SEM_COR}"
        echo "1) Instalar Traefik"
        echo "2) Instalar Portainer"
        echo "3) Instalar Stack de Monitoramento"
        echo "4) Instalar Banco de Dados"
        echo "5) Instalar Chatwoot"
        echo "6) Instalar N8N"
        echo "7) Instalar TypeBot"
        echo "8) Voltar ao Menu Principal"
        
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) instalar_traefik ;;
            2) instalar_portainer ;;
            3) instalar_monitoramento ;;
            4) menu_banco_dados ;;
            5) instalar_chatwoot ;;
            6) instalar_n8n ;;
            7) instalar_typebot ;;
            8) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

menu_banco_dados() {
    while true; do
        clear
        echo -e "${BRANCO}Instalação de Banco de Dados${SEM_COR}"
        echo "1) Instalar PostgreSQL"
        echo "2) Instalar MySQL"
        echo "3) Instalar Redis"
        echo "4) Instalar MongoDB"
        echo "5) Voltar ao Menu de Instalação"
        
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) instalar_postgresql ;;
            2) instalar_mysql ;;
            3) instalar_redis ;;
            4) instalar_mongodb ;;
            5) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

menu_seguranca() {
    while true; do
        clear
        echo -e "${BRANCO}Configuração de Segurança${SEM_COR}"
        echo "1) Configurar Firewall"
        echo "2) Gerenciar Certificados SSL"
        echo "3) Configurar Backup Automático"
        echo "4) Auditoria de Segurança"
        echo "5) Gerenciar Senhas"
        echo "6) Voltar ao Menu Principal"
        
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) configurar_firewall ;;
            2) gerenciar_ssl ;;
            3) configurar_backup_automatico ;;
            4) auditoria_seguranca ;;
            5) gerenciar_senhas ;;
            6) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

menu_backup() {
    while true; do
        clear
        echo -e "${BRANCO}Backup e Restauração${SEM_COR}"
        echo "1) Criar Backup"
        echo "2) Restaurar Backup"
        echo "3) Configurar Agendamento"
        echo "4) Listar Backups"
        echo "5) Limpar Backups Antigos"
        echo "6) Voltar ao Menu Principal"
        
        read -p "Selecione uma opção: " opcao
        
        case $opcao in
            1) criar_backup ;;
            2) restaurar_backup ;;
            3) configurar_agendamento_backup ;;
            4) listar_backups ;;
            5) limpar_backups_antigos ;;
            6) break ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}" ;;
        esac
    done
}

mostrar_status_sistema() {
    clear
    echo -e "${BRANCO}Status do Sistema${SEM_COR}"
    echo -e "${CIANO}----------------------------------------${SEM_COR}"
    echo -e "Uso de CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    echo -e "Uso de Memória: $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')"
    echo -e "Uso de Disco: $(df -h / | awk 'NR==2{print $5}')"
    echo -e "Status do Docker: $(systemctl is-active docker)"
    echo -e "Contêineres Ativos: $(docker ps -q | wc -l 2>/dev/null || echo 'Docker não instalado')"
    echo -e "${CIANO}----------------------------------------${SEM_COR}"
    
    read -p "Pressione Enter para continuar..."
}

# Função para mostrar progresso
mostrar_progresso() {
    local descricao=$1
    local duracao=$2
    local progresso=0
    
    echo -ne "${CIANO}$descricao: [${SEM_COR}"
    while [ $progresso -lt 100 ]; do
        echo -ne "${VERDE}#${SEM_COR}"
        progresso=$((progresso + 2))
        sleep $(echo "scale=4; $duracao/50" | bc)
    done
    echo -e "${CIANO}] Concluído!${SEM_COR}"
}

# Função para confirmar ação
confirmar_acao() {
    local mensagem=$1
    local confirmacao
    
    echo -e "${AMARELO}$mensagem${SEM_COR}"
    read -p "Deseja continuar? (s/N): " confirmacao
    
    if [[ ${confirmacao,,} != "s" ]]; then
        return 1
    fi
    return 0
}
