LOCAL_DIR=$(shell pwd)
BUILD_DIR=${LOCAL_DIR}/build
HPC_DIR=${LOCAL_DIR}/hpc-toolkit
DEPLOY_CLUSTER=sep-devel
DEPLOY_DISK=sep-build
NETWORK_DIR=${BUILD_DIR}/network-filestore-dep/primary
DISK_DIR=${BUILD_DIR}/sep-build/primary
CLUSTER_DIR=${BUILD_DIR}/sep-devel/primary
WEB_DIR=${LOCAL_DIR}/web/terraform

run_toolkit_network: 
	cd ${BUILD_DIR} &&\
	ghpc  create -w ${HPC_DIR}/network-filestore.yaml


run_toolkit_cluster: 
	cd ${BUILD_DIR} &&\
	ghpc  create -w ${HPC_DIR}/sep-devel.yaml


run_toolkit_disk:
	cd ${BUILD_DIR} &&\
	ghpc  create -w ${HPC_DIR}/build-disk.yaml


build_network:	run_toolkit_network
	terraform  -chdir=${NETWORK_DIR} init
	terraform  -chdir=${NETWORK_DIR} validate
	terraform  -chdir=${NETWORK_DIR} apply --auto-approve
	python3 grab_filestore.py sep_shared_disk ./hpc-toolkit/sep-devel.yaml.in ./hpc-toolkit/sep-devel.yaml

# Deploy the network for packer (1) and generate the startup script (2)
build_disk: run_toolkit_disk
	terraform -chdir=${DISK_DIR} init &&\
	terraform -chdir=${DISK_DIR} validate &&\
	terraform -chdir=${DISK_DIR} apply  


# Provide startup script to Packer
build_image: build_disk
	terraform -chdir=${DISK_DIR} output \
      -raw startup_script_scripts_for_image > \
       ${DISK_DIR}/../packer/custom-image/startup_script.sh
	cd ${DISK_DIR}/../packer/custom-image &&\
	packer init . &&\
	packer validate -var startup_script_file=startup_script.sh . &&\
	packer build -var startup_script_file=startup_script.sh .

build_cluster: run_toolkit_cluster
	terraform -chdir=${CLUSTER_DIR} init  &&\
	terraform -chdir=${CLUSTER_DIR} validate &&\
	terraform -chdir=${CLUSTER_DIR} apply  --auto-approve

build_web:
	terraform -chdir=${WEB_DIR} init  &&\
	terraform -chdir=${WEB_DIR} validate &&\
	terraform -chdir=${WEB_DIR} apply  --auto-approve

destroy_cluster:
	terraform -chdir=${CLUSTER_DIR} destroy --auto-approve 
destroy_builder:
	terraform -chdir=${DISK_DIR} destroy --auto-approve
destroy_network:
	terraform -chdir=${NETWORK_DIR} destroy --auto-approve
destroy_web:
	terraform -chdir=${WEB_DIR} destroy --auto-approve
