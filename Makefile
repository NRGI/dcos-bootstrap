AWS_REGION ?= us-east-1

DCOS_CLUSTER_NAME        ?= nrgi-dcos
DCOS_ADMIN_KEY           ?= ~/.ssh/dcos-admin.pem
DCOS_ADMIN_LOCATION      ?= 0.0.0.0/0
DCOS_WORKER_NODES        ?= 3
DCOS_PUBLIC_WORKER_NODES ?= 1
DCOS_CHANNEL             ?= nrgi
DCOS_MASTER_SETUP        ?= single-master

bootstrap: venv
	venv/bin/ansible-playbook -v bootstrap.yml \
		-e aws_region="$(AWS_REGION)" \
		-e dcos_cluster_name="$(DCOS_CLUSTER_NAME)" \
		-e dcos_admin_key="$(DCOS_ADMIN_KEY)" \
		-e dcos_admin_location="$(DCOS_ADMIN_LOCATION)" \
		-e dcos_worker_nodes="$(DCOS_WORKER_NODES)" \
		-e dcos_public_worker_nodes="$(DCOS_PUBLIC_WORKER_NODES)" \
		-e dcos_channel="$(DCOS_CHANNEL)" \
		-e dcos_master_setup="$(DCOS_MASTER_SETUP)"

destroy: venv
	venv/bin/ansible-playbook -v destroy.yml \
		-e dcos_cluster_name="$(DCOS_CLUSTER_NAME)" \
		-e aws_region="$(AWS_REGION)" \
		-e dcos_channel="$(DCOS_CHANNEL)" \
		-e dcos_master_setup="$(DCOS_MASTER_SETUP)"

dependancies: venv
	venv/bin/ansible-playbook -v dependancies.yml
	# kubernetes-env

# kubernetes: bootstrap kubernetes-install kubernetes-env

# kubernetes-env:
# 	@echo KUBERNETES_MASTER=$$(./dcos config show core.dcos_url)/service/kubernetes/api

dashboard:
	@open $$(./dcos config show core.dcos_url)

venv:
	virtualenv venv
	venv/bin/pip install -q -r requirements.txt

clean:
	$(RM) -r tmp venv

TEMPLATES_ROOT_STABLE = https://s3.amazonaws.com/downloads.mesosphere.io/dcos
TEMPLATES_ROOT_EARLY = https://s3-us-west-2.amazonaws.com/downloads.dcos.io/dcos/EarlyAccess/commit/14509fe1e7899f439527fb39867194c7a425c771/cloudformation

sync:
	curl -f -s $(TEMPLATES_ROOT_STABLE)/stable/cloudformation/single-master.cloudformation.json | jq . >cloudformation/stable/single-master.json
	curl -f -s $(TEMPLATES_ROOT_STABLE)/stable/cloudformation/multi-master.cloudformation.json | jq . >cloudformation/stable/multi-master.json
	curl -f -s $(TEMPLATES_ROOT_EARLY)/single-master.cloudformation.json | jq . >cloudformation/earlyaccess/multi-master.json
	curl -f -s $(TEMPLATES_ROOT_EARLY)/multi-master.cloudformation.json | jq . >cloudformation/earlyaccess/multi-master.json
	aws s3 sync ./cloudformation/ s3://nrgi-dcos/dcos-templates

.PHONY: venv
