.PHONY: help secrets up down check test targets

help:
	@echo "make secrets  - generate the Grafana admin password (git-ignored)"
	@echo "make up       - start Prometheus, Alertmanager and Grafana"
	@echo "make down     - stop the stack"
	@echo "make check    - validate Prometheus and Alertmanager configuration"
	@echo "make test     - run the alert rule unit tests"
	@echo "make targets  - regenerate scrape targets from the Ansible inventory"

secrets:
	@test -s secrets/grafana_admin_password || (openssl rand -base64 24 > secrets/grafana_admin_password && chmod 600 secrets/grafana_admin_password)
	@echo "Grafana admin password is in secrets/grafana_admin_password"

up: secrets
	docker compose up -d

down:
	docker compose down

check:
	docker run --rm -v $(PWD)/prometheus:/etc/prometheus:ro --entrypoint promtool prom/prometheus:v3.1.0 check config /etc/prometheus/prometheus.yml
	docker run --rm -v $(PWD)/alertmanager:/etc/alertmanager:ro --entrypoint amtool prom/alertmanager:v0.27.0 check-config /etc/alertmanager/alertmanager.yml

test:
	docker run --rm -v $(PWD)/prometheus:/etc/prometheus:ro -w /etc/prometheus/tests --entrypoint promtool prom/prometheus:v3.1.0 test rules node.test.yml slurm.test.yml gpu.test.yml

targets:
	cd ansible && ansible-playbook playbooks/targets.yml
