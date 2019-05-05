#!/usr/bin/env bash 

usage() {
  cat <<-EOF
  Usage: deploy.sh CHARTNAME -n NAMESPACE [command]
  Options:
    -h, --help           output help information
    -c, --chart          chart name to be installed
    -r, --repo           repository to pull chart from
  Commands:
    [command]            list of helm commands and options to be executed subsequently
                         if 'del' command provided all other commands 
EOF

}

abort() {
    echo
    echo "  $@" 1>&2
    echo
    exit 1
}

log () {
    echo 
    echo "  • $@"
}

required_vars() {

    [ -z $NAMESPACE ] && abort "-n NAMESPACE was not provided, aborting deploy..."
    [ -z $CHART ] && abort "-c CHART_NAME was not provided, aborting deploy..."

    start=$(date +%s)

}

helm_deploy() {
    local CMD=$1
    local CHART=$2
    local CHARTNAME=$2
    local NAMESPACE=${3:+"--namespace $3"}
    local GIT_URL=$4
    [[ "install" == *"$CMD"* ]] && local CHARTNAME=${2:+"--name $CHART"}
    [[ "search del" == *"$CMD"* ]] && { NAMESPACE=""; GIT_URL=""; }
    [ "$CMD" == "del" ] && CMD="del --purge"

    log " ---------------------------- HELM $CMD execution ----------------------------"
    log "$HELM $CMD $CHARTNAME $NAMESPACE $GIT_URL $args "
    set +x
    $HELM $CMD $CHARTNAME $NAMESPACE $args $GIT_URL
    [ $? != 0 ] && abort "Helm deployment was not successful."
    set +x
}

helm_pull_chart(){
    local CHART=$1
    local GIT_URL=${2:-https://raw.githubusercontent.com/r00tvvm/$CHART/master/}

    log "Pulling chart $CHART from $GIT_URL"
    set +x
    $HELM repo add $CHART $GIT_URL 
    [ $? != 0 ] && abort "Helm deployment was not successful."
    $HELM repo update
    $HELM search $CHART
    set +x
}

default_namespace() {
    local NAMESPACE=$1
    
    [ -z "$NAMESPACE" ] && {
          NAMESPACE="$(kubectl config view --minify --output 'jsonpath={..namespace}')"
          read -p "NAMESPACE was not defined. Wish to deploy to [${NAMESPACE}] instead?? [y/N]: " input 
          [ "$input" == "y" ] || { abort "Exiting... Please define -n NAMESPACE"; } 
    }
    echo -n $NAMESPACE
}

start=$(date +%s)

CWD="${PWD}"
HELM=$(command -v helm)
KUBECTL=$(command -v kubectl)

[ -z "$HELM" ] && abort "Helm is not installed"
[ -z "$KUBECTL" ] &&  abort "Kubectl is not installed"

log "$HELM"
log "$KUBECTL"
echo 

[ -z "$1" ] && usage && exit

set +x
while true; do
    case $1 in
        -h|--help) usage; exit ;;
        -n|--namespace) ([[ $2 == -* ]] || [ -z "$2" ]) && abort "$1 <- declared but not defined..." || NAMESPACE=$2; shift 2;;
        -c|--chart)     ([[ $2 == -* ]] || [ -z "$2" ]) && abort "$1 <- declared but not defined..." || CHART="$2"; shift 2;;
        -r|--repo)      ([[ $2 == -* ]] || [ -z "$2" ]) && abort "$1 <- declared but not defined..." || GIT_URL="$2"; shift 2;;
        -*) args="${args##*( )} $1 $2"; shift 2;;
        del)
            CMD='del'; shift; continue;
        ;;
        pull) 
            [ -z "$2" ] || { set -- $@ pull; shift; continue; }
            helm_pull_chart $CHART $GIT_URL; 
            break;;
        "") echo ---
            NAMESPACE=$(default_namespace $NAMESPACE)
            required_vars $@
            
            # Pull CHART from GIT_URL and add to local repo
            helm_pull_chart $CHART $GIT_URL

            # Deploy CHART to NAMESPACE
            #log "$HELM ${CMD:-install} $CHART --namespace $NAMESPACE $COMMANDS $args"
            [[ -z $CMD ]] || COMMANDS="$CMD"
            [ -z $CHART ] && { abort ; }
            for cmd in ${COMMANDS:-search}; do 
                helm_deploy $cmd $CHART $NAMESPACE $CHART/$CHART $args
                done                
            break
        ;;
        *) 
           [ -z $CMD ] && COMMANDS="${COMMANDS##*( )} $1"; shift;
        ;;
    esac
done
set +x

end=$(date +%s)

log "Deployment time : $((end-start)) seconds"
set +x
