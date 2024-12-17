#!/bin/bash

REGISTRY1_ENDPOINT=registry1.dso.mil
BIG_BANG_REPO=""
REGISTRY1_USERNAME="${REGISTRY1_USERNAME:-}"
REGISTRY1_TOKEN="${REGISTRY1_TOKEN:-}"
GITLAB_USERNAME=""
REPO1_LOCATION="${REPO1_LOCATION:-}"
KUBECONFIG="${KUBECONFIG:-}"
BB_K3D_PUBLICIP=""
BB_K3D_PRIVATEIP=""

function checkout_bigbang_repo
{
    version=${cmdarg_cfg['version']}
    if [[ ! -f ${BIG_BANG_REPO} ]]; then
        mkdir -p ${BIG_BANG_REPO}
        git clone https://repo1.dso.mil/big-bang/bigbang.git ${BIG_BANG_REPO}
        cd ${BIG_BANG_REPO}
    else 
        cd ${BIG_BANG_REPO}
        git reset --hard
        git clean -df
    fi
    git fetch -a
    if [[ "${version}" == "latest" ]]; then
        version=$(git tag | sort -V | grep -v -- '-rc.' | tail -n 1)
    fi
    git checkout ${version}
}

function checkout_pipeline_templates
{
    PIPELINE_REPO_LOCATION=${REPO1_LOCATION}/big-bang/pipeline-templates/pipeline-templates
    if [[ ! -d ${PIPELINE_REPO_LOCATION} ]]; then
        mkdir -p ${PIPELINE_REPO_LOCATION}
        git clone https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates.git ${PIPELINE_REPO_LOCATION}
        cd ${PIPELINE_REPO_LOCATION}
    else 
        cd ${PIPELINE_REPO_LOCATION}
        git reset --hard
        git clean -df
    fi
    git fetch -a
    git checkout ${cmdarg_cfg['pipeline-templates-version']}
}

function download_cmdarg
{
    mkdir -p ~/lib/
    CMDARG_URI=https://raw.githubusercontent.com/akesterson/cmdarg/refs/heads/master/cmdarg.sh
    curl --silent --output ~/lib/cmdarg.sh ${CMDARG_URI}
}

function build_k3d_cluster
{
    arg_privateip=""
    arg_hostname=""
    arg_username=""
    arg_keyfile=""
    arg_metallb=""
    arg_cloud=""
    if [[ "${cmdarg_cfg['privateip']}" != "" ]]; then
        arg_privateip="-P ${cmdarg_cfg['privateip']}"
    fi
    if [[ "${cmdarg_cfg['host']}" != "" ]]; then
        arg_hostname="-H ${cmdarg_cfg['host']}"
    fi
    if [[ "${cmdarg_cfg['username']}" != "" ]]; then
        arg_username="-U ${cmdarg_cfg['username']}"
    fi
    if [[ "${cmdarg_cfg['keyfile']}" != "" ]]; then
        arg_keyfile="-k ${cmdarg_cfg['keyfile']}"
    fi
    if [[ "${cmdarg_cfg['metallb']}" == "true" ]]; then
        arg_metallb="-m"
    fi
    if [[ "${cmdarg_cfg['cloud-provider']}" != "" ]]; then
        arg_cloud="-c ${cmdarg_cfg['cloud-provider']}"
    fi

    ${BIG_BANG_REPO}/docs/assets/scripts/developer/k3d-dev.sh \
        -t quickstart \
        -T \
        ${arg_hostname} \
        ${arg_privateip} \
        ${arg_username} \
        ${arg_keyfile} \
        ${arg_metallb} \
        ${arg_cloud}
}

function deploy_flux
{
    KUBECONFIG=${KUBECONFIG} ${REPO1_LOCATION}/big-bang/bigbang/scripts/install_flux.sh \
        -u ${REGISTRY1_USERNAME} \
        -p ${REGISTRY1_TOKEN} \
        -w 900
}

function deploy_bigbang
{
    cd ${BIG_BANG_REPO} && \
    helm upgrade -i bigbang \
        ${BIG_BANG_REPO}/chart \
        -n bigbang \
        --create-namespace \
        --set registryCredentials.username=${REGISTRY1_USERNAME} \
        --set registryCredentials.password=${REGISTRY1_TOKEN} \
        $@ \
        -f ${BIG_BANG_REPO}/chart/ingress-certs.yaml \
        -f ${BIG_BANG_REPO}/docs/assets/configs/example/dev-sso-values.yaml \
        -f ${BIG_BANG_REPO}/docs/assets/configs/example/policy-overrides-k3d.yaml
}

function check_for_tools
{
    missing=0
    for tool in jq yq kubectl helm git sed awk
    do
        if [[ ! -x $(which ${tool} 2>/dev/null) ]]; then
            missing=1
            echo "Required tool ${tool} missing, please fix and run again" >&2
        fi
    done
    if [[ $missing -gt 0 ]]; then
        exit 1
    fi
}

function main
{
    set -e

    cmdarg_info "header" "PlatformOne Big Bang quickstart : Quickly deploy a development bigbang cluster on a VM"
    cmdarg_info "author" "PlatformOne Big Bang team"
    cmdarg_info "copyright" "(C) 2025"

    cmdarg 'H?' 'host' 'IP or Hostname of the VM to operate on'
    cmdarg 'P?' 'privateip' 'If your VM has a separate private IP in addition to the public host, provide it here'
    cmdarg 'U?' 'username' 'Username to use when SSHing into the target VM'
    cmdarg 'K?' 'keyfile' 'SSH Key file to use when SSHing into the target VM'
    cmdarg 'V?' 'version' 'Big Bang version to deploy' 'latest'
    cmdarg 'v?' 'pipeline-templates-version' 'Version of the bigbang pipeline-templates to use' 'master'
    cmdarg 'R?' 'repolocation' 'Location on your host filesystem where bigbang should be checked out' "${REPO1_LOCATION}"
    cmdarg 'u?' 'registry1-username' "Username for your account on ${REGISTRY1_ENDPOINT}" "${REGISTRY1_USERNAME}"
    cmdarg 't?' 'registry1-token' "Access token for your account on ${REGISTRY1_ENDPOINT}" "${REGISTRY1_TOKEN}"
    cmdarg 'c?' 'cloud-provider' "If using cloud provisioning, which cloud provider should be used" "aws"
    cmdarg 'm' 'metallb' "Deploy a MetalLB on k3d"
    cmdarg 'p' 'provision' "Provision the k3d cluster (implied)"
    cmdarg 'd' 'deploy' "Deploy bigbang (implied)"
    cmdarg 'w' 'wait' "Wait for bigbang (implied by --deploy)"
    cmdarg_parse "$@" || exit 1

    actions="provision deploy wait"
    user_actions=""
    if [[ "${cmdarg_cfg['provision']}" == "true" ]]; then
        user_actions="provision"
    fi

    if [[ "${cmdarg_cfg['deploy']}" == "true" ]]; then
        user_actions="${user_actions} deploy"
        # --deploy implies --wait
        cmdarg_cfg['wait']="true"
    fi

    if [[ "${cmdarg_cfg['wait']}" == "true" ]]; then
        user_actions="${user_actions} wait"
    fi

    if [[ "$user_actions" != "" ]]; then
        actions="$user_actions"
    fi

    export REPO1_LOCATION=${cmdarg_cfg['repolocation']}
    export BIG_BANG_REPO=${REPO1_LOCATION}/big-bang/bigbang
    export REGISTRY1_TOKEN=${cmdarg_cfg['registry1-token']}
    export REGISTRY1_USERNAME=${cmdarg_cfg['registry1-username']}

    checkout_bigbang_repo
    checkout_pipeline_templates

    if [[ "${actions}" =~ "provision" ]]; then
        build_k3d_cluster
    fi

    if [[ "${cmdarg_cfg['host']}" != "" ]]; then  
        export KUBECONFIG=~/.kube/${cmdarg_cfg['host']}-dev-quickstart-config
    else
        AWSUSERNAME=$( aws sts get-caller-identity --query Arn --output text | cut -f 2 -d '/' )
        export KUBECONFIG=~/.kube/${AWSUSERNAME}-dev-quickstart-config
        instanceid=$(aws ec2 describe-instances \
            --output text \
            --query "Reservations[].Instances[].InstanceId" \
            --filters "Name=tag:Name,Values=${AWSUSERNAME}-dev" "Name=tag:Project,Values=quickstart" "Name=instance-state-name,Values=running")
        cmdarg_cfg['host']=$(aws ec2 describe-instances --output text --no-cli-pager --instance-id ${instanceid} --query "Reservations[].Instances[].PublicIpAddress")
        cmdarg_cfg['privateip']=$(aws ec2 describe-instances --output json --no-cli-pager --instance-ids ${instanceid} | jq -r '.Reservations[0].Instances[0].PrivateIpAddress')
        cmdarg_cfg['keyfile']="~/.ssh/${AWSUSERNAME}-dev-quickstart.pem"
        cmdarg_cfg['username']="ubuntu"
    fi

    if [[ "${actions}" =~ "deploy" ]]; then
        deploy_flux

        deploy_bigbang ${cmdarg_argv[@]}
    fi

    if [[ "${actions}" =~ "wait" ]]; then
        export PIPELINE_REPO_DESTINATION=${REPO1_LOCATION}/big-bang/pipeline-templates/pipeline-templates
        export CI_VALUES_FILE=${BIG_BANG_REPO}/chart/values.yaml
        export VALUES_FILE=${BIG_BANG_REPO}/chart/values.yaml
        ${REPO1_LOCATION}/big-bang/pipeline-templates/pipeline-templates/scripts/deploy/03_wait_for_helmreleases.sh
    fi

    services=$(kubectl get virtualservices -A -o json | jq -r .items[].spec.hosts[0] | tr "\n" "\t")
    echo "=================================================================================="
    echo "                          INSTALLATION   COMPLETE"
    echo ""
    echo "To access your kubernetes cluster via kubectl, export this variable in your shell:"
    echo
    echo "    export KUBECONFIG=${KUBECONFIG}"
    echo
    echo "To access your kubernetes cluster in your browser, add this line to your hosts file:"
    echo
    echo "    ${cmdarg_cfg['host']}        ${services}"
    echo
    echo "To SSH to the instance running your cluster, use this command:"
    echo
    echo "    ssh -i ${cmdarg_cfg['keyfile']} -o StrictHostKeyChecking=no -o IdentitiesOnly=yes ${cmdarg_cfg['username']}@${cmdarg_cfg['host']}"
    echo "=================================================================================="    
    set +e
}

function cleanup
{
    rm -f ${cmdarglib}
}

trap cleanup EXIT

check_for_tools
download_cmdarg
source ~/lib/cmdarg.sh

main $@