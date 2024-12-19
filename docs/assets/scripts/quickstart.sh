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
    mkdir -p ${BIG_BANG_REPO}
    git clone https://repo1.dso.mil/big-bang/bigbang.git ${BIG_BANG_REPO}
    cd ${BIG_BANG_REPO}
    git fetch -a
    if [[ "${version}" == "latest" ]]; then
        version=$(git tag | sort -V | grep -v -- '-rc.' | tail -n 1)
    fi
}

function checkout_pipeline_templates
{
    mkdir -p ~/lib/
    PIPELINE_WAITS_URI="https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates/-/raw/master/scripts/deploy/03_wait_for_helmreleases.sh?ref_type=heads"
    PIPELINE_REPO_LOCATION=${REPO1_LOCATION}/big-bang/pipeline-templates/pipeline-templates
    if [[ ! -d ${PIPELINE_REPO_LOCATION} ]]; then
        mkdir -p ${PIPELINE_REPO_LOCATION}
        git clone https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates.git ${PIPELINE_REPO_LOCATION}
    fi

    # Here we're extracting some methods that are part of our big bang continuous integration and
    # delivery suite, and placing them into a library for us to use. We can't just source the file
    # because the file has toplevel code that would be executed, and we don't want that.
    srcfile=${PIPELINE_REPO_LOCATION}/scripts/deploy/03_wait_for_helmreleases.sh
    dstfile=${PIPELINE_REPO_LOCATION}/library/wait_for_helmreleases.sh
    echo >${dstfile}
    for method in wait_all_hr wait_sts wait_daemonset wait_crd check_if_hr_exist
    do
        sed -n "/^function ${method}()/,/^}/p" ${srcfile} >>${dstfile}
        echo >>${dstfile}
    done
    rm -f ${tmpfile}
}

function download_cmdarg
{
    mkdir -p ~/lib/
    CMDARG_URI=https://raw.githubusercontent.com/akesterson/cmdarg/refs/heads/master/cmdarg.sh
    curl --silent --output ~/lib/cmdarg.sh ${CMDARG_URI}
}

function wait_helmrepositories
{
    # Lifted from 03_wait_for_helmreleases.sh since it can't be sourced or extracted as a method
    
    echo -n "Checking for helm repos to wait on..."
    if [[ -n $(flux get sources helm -A) ]]; then
        echo "found, ⏳ Waiting on HelmRepositories"
        until [[ $(flux get sources helm registry1 -n bigbang | sed -n 2p | awk '{print $3}') == "True" ]]; do
            sleep 10;
            timeElapsed=$(($timeElapsed+10))
            if [[ $timeElapsed -ge 180 ]]; then
                echo "❌ Timed out while waiting for HelmRepository to exist"
                exit 1
            fi
        done
        flux get sources helm -A
    fi
}

function map_values_key_to_hr() {
  valuesKey="$1"
  if [[ ! (-f "$MAPPING_FILE")]]; then
    MAPPING_FILE=${REPO1_LOCATION}/big-bang/pipeline-templates/pipeline-templates/library/package-mapping.yaml
  fi
  export hrName=$(yq e ".[\"${valuesKey}\"].hrName" ${MAPPING_FILE})
  if [[ -z "$hrName" || "$hrName" == "null" ]]; then
    hrName=$valuesKey
  fi
}

function wait_for_bigbang
{
    enabled_packages=$(yq e '(.[],.addons.[]) | select(. | (has("git") or has("helmRepo"))) | path | .[-1]' ${BIG_BANG_REPO}/chart/values.yaml)
    for package in ${enabled_packages}
    do  
        check_if_hr_exist "$package"
    done

    wait_helmrepositories
    echo "⏳ Waiting on helm releases..."
    wait_all_hr
    echo "⏳ Waiting for custom resources..."
    wait_crd

    # In case some helm releases are marked as ready before all objects are live...
    echo "⏳ Waiting on all jobs, deployments, statefulsets, and daemonsets"
    kubectl wait --for=condition=available --timeout 600s -A deployment --all > /dev/null
    wait_sts
    wait_daemonset
    if kubectl get job -A -o jsonpath='{.items[].metadata.name}' &> /dev/null; then
        kubectl wait --for=condition=complete --timeout 300s -A job --all > /dev/null
    fi    
}

function build_k3d_cluster
{
    arg_privateip=""
    arg_hostname=""
    arg_username=""
    arg_keyfile=""
    arg_metallb=""
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

    ${BIG_BANG_REPO}/docs/assets/scripts/developer/k3d-dev.sh \
        -t quickstart \
        -T \
        ${arg_hostname} \
        ${arg_privateip} \
        ${arg_username} \
        ${arg_keyfile} \
        ${arg_metallb}
}

function deploy_flux
{
    ${REPO1_LOCATION}/big-bang/bigbang/scripts/install_flux.sh \
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
    cmdarg 'v' 'verbose' 'Run in verbose mode (lots of output)'
    cmdarg 'C?' 'configfile' 'Big Bang configuration overrides file to use when deploying big bang'
    cmdarg 'R?' 'repolocation' 'Location on your host filesystem where bigbang should be checked out' "${REPO1_LOCATION}"
    cmdarg 'u?' 'registry1-username' "Username for your account on ${REGISTRY1_ENDPOINT}" "${REGISTRY1_USERNAME}"
    cmdarg 't?' 'registry1-token' "Access token for your account on ${REGISTRY1_ENDPOINT}" "${REGISTRY1_TOKEN}"
    cmdarg 'm' 'metallb' "Deploy a MetalLB on k3d"
    cmdarg 'd' 'deploy-only' "Don't attempt to provision the k3d cluster, just deploy bigbang"
    cmdarg_parse "$@"

    export REPO1_LOCATION=${cmdarg_cfg['repolocation']}
    export BIG_BANG_REPO=${REPO1_LOCATION}/big-bang/bigbang
    export REGISTRY1_TOKEN=${cmdarg_cfg['registry1-token']}
    export REGISTRY1_USERNAME=${cmdarg_cfg['registry1-username']}

    checkout_bigbang_repo
    checkout_pipeline_templates
    source ${REPO1_LOCATION}/big-bang/pipeline-templates/pipeline-templates/library/wait_for_helmreleases.sh

    if [[ "${cmdarg_cfg['deploy-only']}" != "true" ]]; then
        build_k3d_cluster
    fi

    if [[ "${cmdarg_cfg['host']}" != "" ]]; then  
        export KUBECONFIG=~/.kube/${cmdarg_cfg['host']}-dev-quickstart-config
    else
        AWSUSERNAME=$( aws sts get-caller-identity --query Arn --output text | cut -f 2 -d '/' )# This is PROBABLY right...
        export KUBECONFIG=~/.kube/${AWSUSERNAME}-dev-quickstart-config
    fi

    deploy_flux

    arg_configfile=""
    if [[ "${cmdarg_cfg['configfile']}" != "" ]]; then
        arg_configfile="-f ${cmdarg_cfg['configfile']}"
    fi
    deploy_bigbang ${arg_configfile}

    wait_for_bigbang
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