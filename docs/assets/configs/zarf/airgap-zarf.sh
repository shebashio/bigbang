#!/bin/bash

# this script
# - parses the results from zarf tools get-creds and substitutes values in the envsubst file.
# - then creates the zst file
# - then inspects the file to make sure it worked correctly

#% zarf tools get-creds
#
#2025-08-25 14:17:26 INF waiting for cluster connection
#
#     Application          | Username           | Password                                 | Connect               | Get-Creds Key
#     Registry             | zarf-push          | OypipimHt~e0L0TDFcMpUSMb                 | zarf connect registry | registry
#     Registry (read-only) | zarf-pull          | MBd1sg8GIMICq8QlbDLOmKPd                 | zarf connect registry | registry-readonly
#     Git                  | zarf-git-user      | !jO196159n1-YPk3WQnob50L                 | zarf connect git      | git
#     Git (read-only)      | zarf-git-read-user | xPwtiKAw9hreRTdQTgHNGqSd                 | zarf connect git      | git-readonly
#     Artifact Token       | zarf-git-user      | 97b5254e39c1eec884944b18940929ac22494cee | zarf connect git      | artifact

zarf tools get-creds | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' > zarf-tools-get-creds.txt
if [ $? -ne 0 ]; then
    echo "zarf tools get-creds failed."
    return $?
fi

# using pipe delimiter, pull the 3rd column from the row with the username we are looking for
zarf_pull_plus=$(grep "zarf-pull" zarf-tools-get-creds.txt | cut -d'|' -f3)
# trim spaces before and after
ZARF_PULL=$(echo "$zarf_pull_plus" | xargs )

zarf_git_user_plus=$(grep -m 1 "zarf-git-user" zarf-tools-get-creds.txt | cut -d'|' -f3)
ZARF_GIT_USER=$(echo "$zarf_git_user_plus" | xargs )

export ZARF_PULL
export ZARF_GIT_USER
envsubst < bb-zarf-credentials.template.yaml > bb-zarf-credentials.yaml

zarf package create . --confirm
if [ $? -ne 0 ]; then
    echo "zarf package create failed."
    return $?
fi

zarf package inspect definition zarf-package-bigbang-amd64.tar.zst
if [ $? -ne 0 ]; then
    echo "zarf package inspection failed."
    return $?
fi

return 0