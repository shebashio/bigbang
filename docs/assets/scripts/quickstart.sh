#!/bin/bash

REGISTRY1_ENDPOINT=registry1.dso.mil
BIG_BANG_REPO=""
REGISTRY1_USERNAME="${REGISTRY1_USERNAME:-}"
REGISTRY1_TOKEN="${REGISTRY1_TOKEN:-}"
GITLAB_USERNAME=""
REPO1_LOCATION="${REPO1_LOCATION:-}"
KUBECONFIG=""
BB_K3D_PUBLICIP=""
BB_K3D_PRIVATEIP=""

function download_k3d_dev_sh
{
    mkdir -p ~/bin/
    K3D_SCRIPT_URI="https://repo1.dso.mil/big-bang/bigbang/-/raw/2291_quickstart/docs/assets/scripts/developer/k3d-dev.sh?ref_type="
    curl --silent --output ~/bin/k3d-dev.sh ${K3D_SCRIPT_URI}
    chmod +x ~/bin/k3d-dev.sh
}

function download_bigbang_helpers
{
    mkdir -p ~/lib/
    DOTFILES_URI="https://repo1.dso.mil/akesterson/dotfiles/-/raw/main/lib/bigbang.sh?ref_type=heads"
    curl --silent --output ~/lib/bigbang.sh ${DOTFILES_URI}
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

    ~/bin/k3d-dev.sh \
        -t quickstart \
        ${arg_hostname} \
        ${arg_privateip} \
        ${arg_username} \
        ${arg_keyfile} \
        ${arg_metallb}
}

function checkout_bigbang_repo
{
    version=${cmdarg_cfg['version']}
    mkdir -p ${cmdarg_cfg['repolocation']}/big-bang/bigbang
    git clone https://repo1.dso.mil/big-bang/bigbang.git ${cmdarg_cfg['repolocation']}/big-bang/bigbang
    cd ${cmdarg_cfg['repolocation']}/big-bang/bigbang
    git fetch -a
    if [[ "${version}" == "latest" ]]; then
        version=$(git tag | sort -V | grep -v -- '-rc.' | tail -n 1)
    fi
    git checkout ${version}
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
    cmdarg_parse "$@"

    export REPO1_LOCATION=${cmdarg_cfg['repolocation']}
    export BIG_BANG_REPO=${REPO1_LOCATION}/big-bang/bigbang
    export REGISTRY1_TOKEN=${cmdarg_cfg['registry1-token']}
    export REGISTRY1_USERNAME=${cmdarg_cfg['registry1-username']}

    build_k3d_cluster
    if [[ "${cmdarg_cfg['host']}" != "" ]]; then  
        export KUBECONFIG=~/.kube/${cmdarg_cfg['host']}-dev-quickstart-config
        export BB_K3D_PUBLICIP=${cmdarg_cfg['host']}
        export BB_K3D_PRIVATEIP=${cmdarg_cfg['privateip']}
    else
        eval "$(bb_k3d_shellprofile quickstart)"
    fi

    checkout_bigbang_repo

    bb_deploy_flux

    arg_configfile=""
    if [[ "${cmdarg_cfg['configfile']}" != "" ]]; then
        arg_configfile="-f ${cmdarg_cfg['configfile']}"
    fi
    bb_k3d_deploy ${arg_configfile}
    set +e
}

function cleanup
{
    rm -f ${cmdarglib} ${helpers} ${k3d_dev_script}
}

trap cleanup EXIT

download_k3d_dev_sh
download_cmdarg
download_bigbang_helpers
source ~/lib/cmdarg.sh
source ~/lib/bigbang.sh >/dev/null 2>&1

main $@