#!/usr/bin/env bash

#
# defaults
#

set -o errexit -o errtrace -o nounset -o functrace -o pipefail
shopt -s inherit_errexit 2>/dev/null || true

trap 'echo "exit_code $? line $LINENO linecallfunc $BASH_COMMAND"' ERR

changed_files=${CHANGED_FILES:-unset}
all_files=${ALL_FILES:-unset}

NAME=pre-commit-bash.sh

#
# functions
#

usage(){
I_USAGE="

  Usage:  ${NAME} [OPTIONS]

  Description:

  Github actions inputs:

    To handle running this script via github actions where it can be called from a dispatch, or a commit trigger
    The config is fed through environment variables

  Requirements:

    This script needs to be run in a git checkout directory. For github actions this is done using the actions/checkout step before

  Environment variable options:
    \$CHANGED_FILES - pass in a list of files that have changed
    \$ALL_FILES - pass in true to cause all files to be scanned by pre-commit

"
  echo "$I_USAGE"
  exit
}

#
# args
#

while :
do
  case ${1-default} in
      --*help|-h          ) usage ; exit 0 ;;
      --man               ) usage ; exit 0 ;;
      --) shift ; break ;;
      -*) echo "WARN: Unknown option (ignored): $1" >&2 ; shift ;;
      *)  break ;;
    esac
done

#
# main
#

if [[ "$changed_files" == 'unset' ]];then
  files_arg=""
else
  files_arg="--files $changed_files"
fi

if [[ "$all_files" == 'unset' ]];then
  all_files_arg=""
else
  all_files_arg="--all-files"
fi

pip install pre-commit==3.7.0
pip freeze --local

if pre-commit run ${all_files_arg:+ $all_files_arg}  ${files_arg:+ $files_arg} --show-diff-on-failure --color=always;then
  pre_commit_exit_code="$?"
else
  pre_commit_exit_code="$?"
  if [[ "$pre_commit_exit_code" -eq 1 ]];then
    echo "files changed"
    git config --global user.email "actions@github.com"
    git config --global user.name "github actions"
    git status
    git add -A
    timestamp=$(date -u)
    git commit -m "pre-commit fixes: ${timestamp}"
    git push
    exit 0
  fi
fi
echo "$pre_commit_exit_code"
