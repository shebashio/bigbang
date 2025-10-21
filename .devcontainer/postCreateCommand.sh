#!/bin/bash

echo "[INFO] postCreateCommand script"

# source a minimal color terminal
cat .devcontainer/minimal-terminal-prompt.sh >> /root/.bashrc
source /root/.bashrc

# set KUBECONFIG env variable
CONFIG_FILE=$(find /root/.kube -maxdepth 1 -name "*-dev-default-config" -print -quit)

if [ -n "$CONFIG_FILE" ]; then
	echo "export KUBECONFIG=$CONFIG_FILE" >> /root/.bashrc
else
	echo "[WARN] no kubeconfig file matching *-dev-default-config found in /root/.kube" >> /root/.bashrc
fi

# set common alias
echo 'alias k=kubectl' >> /root/.bashrc

# add configuration variables from users $HOME/.config/bigbang/pipeline.conf to bashrc
while IFS= read -r line;
do
	if [[ "$line" != "" ]]; then
		echo export $line >> /root/.bashrc
	fi
done < /root/.config/bigbang/pipeline.conf
# source .bashrc so we can use it in our clone operations below (expires at end of postCreateCommand)
source /root/.bashrc

# if we are in pipeline-templates, clone bigbang
# if we are in bigbang, clone pipeline-templates
# else (packages) get both
PIPELINE_TEMPLATES_GIT_REPO="https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates.git"
BIGBANG_UMBRELLA_GIT_REPO="https://repo1.dso.mil/big-bang/bigbang.git"

REMOTE=$(git remote -v | grep "fetch" | awk '{print $2}')
if [[ "$REMOTE" == $PIPELINE_TEMPLATES_GIT_REPO ]]; then
	git clone $BIGBANG_UMBRELLA_GIT_REPO /workspaces/bigbang --branch ${BIGBANG_REPO_BRANCH:-master}
	echo "export PIPELINE_REPO_DESTINATION=$(pwd)" >> /root/.bashrc
elif [[ "$REMOTE" == "$BIGBANG_UMBRELLA_GIT_REPO" ]]; then
	git clone $PIPELINE_TEMPLATES_GIT_REPO /workspaces/pipeline-templates --branch ${PIPELINE_REPO_BRANCH:-master}
	echo 'export PIPELINE_REPO_DESTINATION=/workspaces/pipeline-templates' >> /root/.bashrc
else
	git clone $BIGBANG_UMBRELLA_GIT_REPO /workspaces/bigbang
	git clone $PIPELINE_TEMPLATES_GIT_REPO /workspaces/pipeline-templates  --branch ${PIPELINE_REPO_BRANCH:-master}
	echo 'export PIPELINE_REPO_DESTINATION=/workspaces/pipeline-templates' >> /root/.bashrc
fi

# since we are running locally, always set BIGBANG_REPO_DIR
echo 'export BIGBANG_REPO_DIR=/workspaces/bigbang' >> /root/.bashrc


