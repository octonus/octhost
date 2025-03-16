#!/bin/bash

# Módulo de Menu para Script OCP
# Copyright (c) 2024 Octonus Cloud Platform (OCP)
# Website: octhost.com.br
# Suporte: suporte@octhost.com.br

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
        echo
        read -p "Digite o número da opção desejada: " opcao
        
        case $opcao in
            1) atualizar_sistema ;;
            2) configurar_fuso_horario ;;
            3) configurar_hostname ;;
            4) configurar_rede ;;
            5) configurar_firewall ;;
            6) return ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}"; sleep 2 ;;
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
        echo
        read -p "Digite o número da opção desejada: " opcao
        
        case $opcao in
            1) instalar_docker ;;
            2) configurar_docker ;;
            3) gerenciar_conteineres ;;
            4) gerenciar_redes_docker ;;
            5) gerenciar_volumes_docker ;;
            6) atualizar_docker ;;
            7) return ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}"; sleep 2 ;;
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
        echo
        read -p "Digite o número da opção desejada: " opcao
        
        case $opcao in
            1) instalar_traefik ;;
            2) instalar_portainer ;;
            3) instalar_monitoramento ;;
            4) menu_banco_dados ;;
            5) instalar_chatwoot ;;
            6) instalar_n8n ;;
            7) instalar_typebot ;;
            8) return ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}"; sleep 2 ;;
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
        echo
        read -p "Digite o número da opção desejada: " opcao
        
        case $opcao in
            1) instalar_postgresql ;;
            2) instalar_mysql ;;
            3) instalar_redis ;;
            4) instalar_mongodb ;;
            5) return ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}"; sleep 2 ;;
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
        echo
        read -p "Digite o número da opção desejada: " opcao
        
        case $opcao in
            1) configurar_firewall ;;
            2) gerenciar_ssl ;;
            3) configurar_backup_automatico ;;
            4) auditoria_seguranca ;;
            5) gerenciar_senhas ;;
            6) return ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}"; sleep 2 ;;
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
        echo
        read -p "Digite o número da opção desejada: " opcao
        
        case $opcao in
            1) criar_backup ;;
            2) restaurar_backup ;;
            3) configurar_agendamento_backup ;;
            4) listar_backups ;;
            5) limpar_backups_antigos ;;
            6) return ;;
            *) echo -e "${VERMELHO}Opção inválida${SEM_COR}"; sleep 2 ;;
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
