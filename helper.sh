# export HOST_IP=$(ipconfig getifaddr en0)

function c1_kctx {
    kubectl config use-context cluster-1
}

function setup-boundary {
    export BOUNDARY_RECOVERY_CONFIG=./manifests/boundary/recovery.hcl
    export BOUNDARY_ADDR=http://127.0.0.1:9200
}

# PATH TO YOUR HOSTS FILE
ETC_HOSTS=/etc/hosts
function removehost() {
    HOSTNAME=$1
    if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
    then
        echo "$HOSTNAME Found in your $ETC_HOSTS, Removing now...";
        sudo sed -i".bak" "/$HOSTNAME/d" $ETC_HOSTS
    else
        echo "$HOSTNAME was not found in your $ETC_HOSTS";
    fi
}

function addhost() {
    HOSTNAME=$1
    IP=$2
    HOSTS_LINE="$IP\t$HOSTNAME"
    if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
        then
            echo "$HOSTNAME already exists : $(grep $HOSTNAME $ETC_HOSTS)"
        else
            echo "Adding $HOSTNAME to your $ETC_HOSTS";
            sudo -- sh -c -e "echo '$HOSTS_LINE' >> /etc/hosts";

            if [ -n "$(grep $HOSTNAME /etc/hosts)" ]
                then
                    echo "$HOSTNAME was added succesfully \n $(grep $HOSTNAME /etc/hosts)";
                else
                    echo "Failed to Add $HOSTNAME, Try again!";
            fi
    fi
}
