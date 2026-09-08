#--------------------------
# xebro GmbH - proxy - 2.0.0
#--------------------------
# App-agnostic TLS reverse proxy. App bundles register their own routes:
# <bundle>.install drops a *.conf.template into ${XO_CONFIG_DIR}/proxy/,
# the nginx image renders it via envsubst. Certs + /etc/hosts come from
# core/generate_certs.sh (XO_SERVER_NAME), which runs automatically in
# docker.up.

.PHONY: proxy.help proxy.logs proxy.bash proxy.restart proxy.install proxy.up proxy.down proxy.routes proxy.test proxy.post_start

PROXY_DIR := $(patsubst $(XO_ROOT_DIR)/%,./%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
PROXY_DIR_ABS := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

proxy.help:
	$(call add_help,${PROXY_DIR}Makefile,"proxy")

proxy.logs: ## Show proxy container logs
	@${DOCKER_COMPOSE} logs -f proxy

proxy.bash: ## Open sh inside the proxy container
	@${DOCKER_COMPOSE} exec proxy sh

proxy.restart: ## Restart proxy container (picks up new route snippets)
	@${DOCKER_COMPOSE} restart proxy --no-deps

proxy.up: ## Start proxy container
	@${DOCKER_COMPOSE} up -d proxy

proxy.down: ## Stop proxy container
	@${DOCKER_COMPOSE} stop proxy

proxy.routes: ## List registered route snippets
	@ls -1 ${XO_CONFIG_DIR}/proxy/ 2>/dev/null || echo "no routes registered"

proxy.test: ## Smoke-test the proxy routing (HTTP redirect + HTTPS reachable)
	@curl -ksSo /dev/null -w "http  -> %{http_code} (301 expected)\n" http://${XO_SERVER_NAME}:${XO_PROXY_HTTP_PORT}/
	@curl -ksSo /dev/null -w "https -> %{http_code}\n" https://${XO_SERVER_NAME}:${XO_PROXY_HTTPS_PORT}/

proxy.install:
	$(call headline,"Installing proxy")
	$(call seed_env_vars,".env","${PROXY_DIR}config/.env.seed")
	@mkdir -p ${XO_CONFIG_DIR}/proxy

proxy.post_start:
	@$(call target_name,"proxy")
	@printf "${Purple}Proxy:       ${Yellow}https://${XO_SERVER_NAME}$(if $(filter-out 443,${XO_PROXY_HTTPS_PORT}),:${XO_PROXY_HTTPS_PORT})\n"

help: proxy.help
install: proxy.install
logs: proxy.logs
restart: proxy.restart
post_start: proxy.post_start
