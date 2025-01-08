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

# This is the instantiation of a dependency library 'cmdarg' that does our argument parsing.
# This is a F/OSS project that lives on a public github.
# P1 was not comfortable sourcing the library from an uncontrolled public github.
# So the library was pulled, gzipped, base64d, and placed here.
# This is https://github.com/akesterson/cmdarg/commit/cdc010720fb12618e50bdbb8dc066436bbb96023
eval "$(echo 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 | base64 -d | gunzip)"

main $@
