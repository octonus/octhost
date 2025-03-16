#!/bin/bash

# Módulo de Instalação de Aplicações para Script OCP
# Copyright (c) 2024 Octonus Cloud Platform (OCP)
# Website: octhost.com.br
# Suporte: suporte@octhost.com.br

# Diretório base para arquivos de configuração
DIR_CONFIG="/etc/ocp"
DIR_COMPOSE="$DIR_CONFIG/compose"

# Função para criar diretórios necessários
criar_diretorios_apps() {
    criar_diretorio_seguro "$DIR_CONFIG"
    criar_diretorio_seguro "$DIR_COMPOSE"
    criar_diretorio_seguro "$DIR_CONFIG/ssl"
    criar_diretorio_seguro "$DIR_CONFIG/traefik"
    criar_diretorio_seguro "$DIR_CONFIG/portainer"
}

# Instalação do Traefik
instalar_traefik() {
    registrar_mensagem "INFO" "Iniciando instalação do Traefik"
    
    # Solicita informações necessárias
    read -p "Digite o domínio para o Traefik (ex: traefik.seudominio.com.br): " dominio_traefik
    read -p "Digite seu email para o Let's Encrypt: " email_ssl
    
    # Valida as entradas
    if ! validar_dominio "$dominio_traefik"; then
        registrar_mensagem "ERRO" "Domínio inválido"
        return 1
    fi
    
    if ! validar_email "$email_ssl"; then
        registrar_mensagem "ERRO" "Email inválido"
        return 1
    fi
    
    # Cria diretórios necessários
    mkdir -p "$DIR_CONFIG/traefik/config"
    mkdir -p "$DIR_CONFIG/traefik/certificates"
    
    # Gera senha para autenticação básica
    local senha_admin=$(gerar_senha_segura 16)
    local hash_senha=$(echo "$senha_admin" | htpasswd -nb admin -)
    
    # Cria arquivo de configuração do Traefik
    cat > "$DIR_CONFIG/traefik/config/traefik.yml" << EOF
api:
  dashboard: true
  debug: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

certificatesResolvers:
  letsencrypt:
    acme:
      email: ${email_ssl}
      storage: /certificates/acme.json
      httpChallenge:
        entryPoint: web

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
  file:
    directory: /config
    watch: true

log:
  level: INFO

accessLog: {}
EOF

    # Cria arquivo de configuração dinâmica
    cat > "$DIR_CONFIG/traefik/config/dynamic.yml" << EOF
http:
  middlewares:
    secureHeaders:
      headers:
        sslRedirect: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
    auth:
      basicAuth:
        users:
          - "${hash_senha}"

tls:
  options:
    default:
      minVersion: VersionTLS12
      cipherSuites:
        - TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
        - TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
        - TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305
        - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305
EOF

    # Cria arquivo docker-compose
    cat > "$DIR_COMPOSE/traefik.yml" << EOF
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - proxy
    ports:
      - 80:80
      - 443:443
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${DIR_CONFIG}/traefik/config:/config
      - ${DIR_CONFIG}/traefik/certificates:/certificates
    command:
      - --global.checkNewVersion=true
      - --global.sendAnonymousUsage=false
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --providers.docker.network=proxy
      - --providers.file.directory=/config
      - --providers.file.watch=true
      - --api.dashboard=true
      - --certificatesresolvers.letsencrypt.acme.httpchallenge=true
      - --certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web
      - --certificatesresolvers.letsencrypt.acme.email=${email_ssl}
      - --certificatesresolvers.letsencrypt.acme.storage=/certificates/acme.json
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.rule=Host(\`${dominio_traefik}\`)"
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
      - "traefik.http.routers.traefik.service=api@internal"
      - "traefik.http.routers.traefik.middlewares=auth,secureHeaders"

networks:
  proxy:
    external: true
EOF

    # Cria rede proxy se não existir
    if ! docker network inspect proxy >/dev/null 2>&1; then
        docker network create proxy
    fi

    # Inicia o Traefik
    cd "$DIR_COMPOSE" && docker-compose -f traefik.yml up -d

    # Verifica se o Traefik está rodando
    if docker ps | grep -q traefik; then
        registrar_mensagem "SUCESSO" "Traefik instalado com sucesso!"
        echo -e "${VERDE}Credenciais de acesso ao dashboard:${SEM_COR}"
        echo "URL: https://${dominio_traefik}"
        echo "Usuário: admin"
        echo "Senha: ${senha_admin}"
        echo -e "${AMARELO}IMPORTANTE: Guarde estas credenciais em um local seguro!${SEM_COR}"
    else
        registrar_mensagem "ERRO" "Falha na instalação do Traefik"
        return 1
    fi
}

# Instalação do Portainer
instalar_portainer() {
    registrar_mensagem "INFO" "Iniciando instalação do Portainer"
    
    read -p "Digite o domínio para o Portainer (ex: portainer.seudominio.com.br): " dominio_portainer
    
    if ! validar_dominio "$dominio_portainer"; then
        registrar_mensagem "ERRO" "Domínio inválido"
        return 1
    fi
    
    # Cria diretório para dados do Portainer
    mkdir -p "$DIR_CONFIG/portainer"
    
    # Cria arquivo docker-compose
    cat > "$DIR_COMPOSE/portainer.yml" << EOF
version: '3.8'

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - proxy
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${DIR_CONFIG}/portainer:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.portainer.entrypoints=websecure"
      - "traefik.http.routers.portainer.rule=Host(\`${dominio_portainer}\`)"
      - "traefik.http.routers.portainer.tls.certresolver=letsencrypt"
      - "traefik.http.routers.portainer.service=portainer"
      - "traefik.http.services.portainer.loadbalancer.server.port=9000"
      - "traefik.http.routers.portainer.middlewares=secureHeaders"

networks:
  proxy:
    external: true
EOF

    # Inicia o Portainer
    cd "$DIR_COMPOSE" && docker-compose -f portainer.yml up -d

    # Verifica se o Portainer está rodando
    if docker ps | grep -q portainer; then
        registrar_mensagem "SUCESSO" "Portainer instalado com sucesso!"
        echo -e "${VERDE}Acesse o Portainer em:${SEM_COR}"
        echo "https://${dominio_portainer}"
        echo -e "${AMARELO}IMPORTANTE: Configure sua senha no primeiro acesso!${SEM_COR}"
    else
        registrar_mensagem "ERRO" "Falha na instalação do Portainer"
        return 1
    fi
}

# Instalação do Stack de Monitoramento (Prometheus + Grafana)
instalar_monitoramento() {
    registrar_mensagem "INFO" "Iniciando instalação do Stack de Monitoramento"
    
    read -p "Digite o domínio para o Grafana (ex: grafana.seudominio.com.br): " dominio_grafana
    
    if ! validar_dominio "$dominio_grafana"; then
        registrar_mensagem "ERRO" "Domínio inválido"
        return 1
    fi
    
    # Cria diretórios necessários
    mkdir -p "$DIR_CONFIG/monitoring/prometheus"
    mkdir -p "$DIR_CONFIG/monitoring/grafana"
    
    # Cria arquivo de configuração do Prometheus
    cat > "$DIR_CONFIG/monitoring/prometheus/prometheus.yml" << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'docker'
    static_configs:
      - targets: ['docker.for.linux.localhost:9323']
EOF

    # Cria arquivo docker-compose
    cat > "$DIR_COMPOSE/monitoring.yml" << EOF
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    restart: unless-stopped
    networks:
      - proxy
    volumes:
      - ${DIR_CONFIG}/monitoring/prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    networks:
      - proxy
    volumes:
      - ${DIR_CONFIG}/monitoring/grafana:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=\${GRAFANA_PASSWORD:-admin}
      - GF_USERS_ALLOW_SIGN_UP=false
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.grafana.entrypoints=websecure"
      - "traefik.http.routers.grafana.rule=Host(\`${dominio_grafana}\`)"
      - "traefik.http.routers.grafana.tls.certresolver=letsencrypt"
      - "traefik.http.services.grafana.loadbalancer.server.port=3000"
      - "traefik.http.routers.grafana.middlewares=secureHeaders"

volumes:
  prometheus_data:

networks:
  proxy:
    external: true
EOF

    # Gera senha aleatória para o Grafana
    local senha_grafana=$(gerar_senha_segura 16)
    export GRAFANA_PASSWORD=$senha_grafana

    # Inicia os serviços
    cd "$DIR_COMPOSE" && docker-compose -f monitoring.yml up -d

    # Verifica se os serviços estão rodando
    if docker ps | grep -q grafana && docker ps | grep -q prometheus; then
        registrar_mensagem "SUCESSO" "Stack de Monitoramento instalado com sucesso!"
        echo -e "${VERDE}Acesse o Grafana em:${SEM_COR}"
        echo "https://${dominio_grafana}"
        echo -e "${VERDE}Credenciais de acesso:${SEM_COR}"
        echo "Usuário: admin"
        echo "Senha: ${senha_grafana}"
        echo -e "${AMARELO}IMPORTANTE: Guarde estas credenciais em um local seguro!${SEM_COR}"
    else
        registrar_mensagem "ERRO" "Falha na instalação do Stack de Monitoramento"
        return 1
    fi
}

# Função para inicializar o módulo
inicializar_apps() {
    criar_diretorios_apps
    registrar_mensagem "INFO" "Módulo de aplicações inicializado"
}
