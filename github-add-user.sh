#!/bin/bash
# Collaborator list, add, remove from a repository
# (c) 2015 miraculixx
# (c) 2019 Mark Gooderum (markfrommn)
# Author: github.com/miraculixx
# Author: github.com/markfrommn
# MIT License, see below

function help {
  echo "Add collaborators to one or more repositories on github"
  echo ""
  echo "Syntax:   $0 -u user -p password [-l] [-D] -r repo1[,repo2] <collaborator id>[,<collaborator id>]"
  echo ""
  echo "          -a <host>     API host (implies Github Enterprise"
  echo "          -c            Create collaborator invitations"
  echo "          -o <org>      Repos from <org>"
  echo "          -u <user>     User to access github" 
  echo "          -p <password> Password (optional, will be promoted otherwise)"
  echo "          -P <pwfile>   Password File (optional, will be promoted otherwise)"
  echo "          -l            List collaborators"
  echo "          -i            List invitations"
  echo "          -r <repos>    Repositories, list as owner/repo[,owner/repo,...]"
  echo "          -D            Remove <collaborator(s)>"
  echo "          -t <push|pull|admin> Access type"
  echo "          id            The collaborator id to add or remove"
}

#set -x

API_HOST=api.github.com
GHE_API_BASE="/api/v3"
GHC_API_BASE=""
API_BASE=$GHC_API_BASE
REPO_BASE="repos"
ORG_URI=""
REQ_BODY=""
CONTENT_LENGTH=0
CT_OPT=""
CT_ARG=""
BODY_OPT=""
PERM_ARG=""
CREATE=""
DELETE=""
METHOD=GET

while getopts "h?u:p:P:r:CDlio:a:t:?" opt; do
    case $opt in
      h|\?)
         help
         exit 0
         ;;
      u)
         GH_USER=$OPTARG
         ;;
      a)
         API_HOST=$OPTARG
	 API_BASE=$GHE_API_BASE
         ;;
      C)
         CREATE=yes
	 METHOD=PUT
         ;;
      D)
         METHOD=DELETE
	 DELETE=yes
         ;;
      p) 
         PASSWORD=$OPTARG
         ;;
      P) 
         PASSWORD=`cat $OPTARG`
         ;;
      r) 
         REPOS=$OPTARG
         ;;
      o) 
         ORG=$OPTARG
	 ORG_URI="$ORG/"
         ;;
      t) 
         PERM=$OPTARG
	 PERM_ARG="?permissions=${PERM}"
	 REQ_BODY="{ \"permissions\" : \"$PERM\" }"
	 CONTENT_LENGTH=${#REQ_BODY}
	 CT_OPT="-H"
	 CT_ARG="Content-Type: application/json"
	 BODY_OPT="--data"
         ;;
      l)
         LIST_C=yes
         CREATE=""
	 ;;
      i)
         LIST_I=yes
         CREATE=""
         ;;
    esac
done

shift $((OPTIND-1))

COL_USER=$1

if [[ -z "$GH_USER" ]]; then
   echo Enter your github user
   read GH_USER
fi

if [[ -z "$PASSWORD" ]]; then
   echo Enter Password
   read -s PASSWORD
fi

if [[ -z "$REPOS" ]]; then
   echo Enter the repositories as repo[,repo]. Multiple repos comma separated.
   read REPOS
fi

if [[ ! -z "$CREATE" ]] || [[ ! -z "$DELETE" ]] ; then
   if [[ -z "$COL_USER" ]]; then
     echo "[WARN] -C/-D require a list of users"
     exit 10
   fi    
else
  if [[ -z "$LIST_I" ]] && [[ -z "$LIST_C" ]] ; then
     echo "[WARN] One of -i/-l must be given if -C/-D not given"
     exit 20
  fi
fi


API_URL="https://${API_HOST}${API_BASE}"

repos=(${REPOS//,/ })

if [[ ! -z "$DELETE" ]] || [[ ! -z "$CREATE" ]]; then
  collaborators=(${COL_USER//,/ })
  for repo in "${repos[@]}"; do 
    REPO_URI="${REPO_BASE}/${ORG_URI}${repo}"
    REPO_URL=$API_URL/$REPO_URI
    for collaborator in "${collaborators[@]}"; do
      outfile=/tmp/gau.$collaborator.$$
      echo "[INFO] $METHOD $collaborator to $REPO_URL"
      curl -i -K - -X $METHOD ${CT_OPT} "${CT_ARG}" ${BODY_OPT} "${REQ_BODY}"  "$REPO_URL/collaborators/${collaborator}" <<EOF > $outfile
-u "$GH_USER:$PASSWORD"
EOF
    done
    if [[ ! -z "$CREATE" ]]; then
      reqid=`egrep '"id"[ ]*:' $outfile | head -1 | sed 's/,/ /' | awk -F: '{print $2}'`
      if [[ -z "$reqid" ]]; then
        echo "[WARN]: Invitation ID not found"
      else
        echo "Invitation ID found - # $reqid"
      fi
    fi
    rm -f $outfile
  done
fi

if [[ ! -z "$LIST_C" ]]; then
  for repo in "${repos[@]}"; do 
    REPO_URI="${REPO_BASE}/${ORG_URI}$repo"
    REPO_URL=$API_URL/$REPO_URI
    echo "[INFO] Current list of collaborators in $repo:"
    curl -i -K - -X GET -d '' "$REPO_URL/collaborators" 2>&1 <<EOF | grep -E 'login|permissions|push|pull|admin'
-u "$GH_USER:$PASSWORD"
EOF
  done
  for repo in "${repos[@]}"; do 
    REPO_URI="${REPO_BASE}/${ORG_URI}$repo"
    REPO_URL=$API_URL/$REPO_URI
    echo "[INFO] Current list of contributors in $repo:"
    curl -i -K - -X GET -d '' "$REPO_URL/contributors" 2>&1 <<EOF | grep -E 'login|permissions|push|pull|admin'

-u "$GH_USER:$PASSWORD"
EOF
  done
fi

if [[ ! -z "$LIST_I" ]]; then
  for repo in "${repos[@]}"; do 
    REPO_URI="${REPO_BASE}/${ORG_URI}$repo"
    REPO_URL=$API_URL/$REPO_URI
    echo "[INFO] Current list of invitations in $repo:"
    curl -i -K - -X GET -d '' "$REPO_URL/invitations" 2>&1 <<EOF | grep -E 'login|permissions|push|pull|admin'
-u "$GH_USER:$PASSWORD"
EOF
  done
fi

exit 0

: <<< 'EOF'
The MIT License (MIT)

Copyright (c) 2016,2019 miraculixx, Mark Gooderum (markfrommn)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
EOF
