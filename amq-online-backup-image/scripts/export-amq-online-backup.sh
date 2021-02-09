#!/bin/bash
#set -x

export AMQ_ONLINE_NAMESPACE=${AMQ_ONLINE_NAMESPACE:-"amq-online-infra"}
export NAMESPACES_LIST=${NAMESPACES_LIST:-"amq-online-infra,products-catalog"}
export BACKUP_FOLDER=${BACKUP_FOLDER:-"/opt/amq-online-backup/backup"}



function get_addresses_in_namespace () {
	for NAMESPACE in $(echo $NAMESPACES_LIST | sed "s/,/ /g")
	do
	    # call your procedure/other scripts here below
			local ADDRESS_NAME_LIST=$(oc get address --output=name -n "$NAMESPACE")
			echo "at line 12 ADDRESS_NAME_LIST=$ADDRESS_NAME_LIST"
			if [ -z "$ADDRESS_NAME_LIST" ]
				then
						echo "\$ADDRESS_NAME_LIST is empty"
						continue
				else
						get_pods_of_address "$ADDRESS_NAME_LIST" "$NAMESPACE"

					#get_pods_of_address "$ADDRESS_NAME_LIST" "$NAMESPACE"
			fi
	done
}

function get_pods_of_address () {
	local ADDRESS_NAME_LIST=$1
	local NAMESPACE=$2

	while IFS= read -r ADDRESS_NAME ;
		do
			ADDRESS_SPACE_NAME="$(cut -d'.' -f1 <<<$(cut -d"/" -f2 <<<"$ADDRESS_NAME"))"

			BROKER_POD_NAME_LIST=$(oc get $ADDRESS_NAME -n $NAMESPACE -o jsonpath="{.status.brokerStatuses[*].containerId}")

			USER_NAME=$(oc get secret -n $AMQ_ONLINE_NAMESPACE broker-support-$(oc get addressspace $ADDRESS_SPACE_NAME -n $NAMESPACE -o jsonpath='{.metadata.annotations.enmasse\.io/infra-uuid}')  --template='{{.data.username}}' | base64 --decode)
			PASSWORD=$(oc get secret -n $AMQ_ONLINE_NAMESPACE broker-support-$(oc get addressspace $ADDRESS_SPACE_NAME -n $NAMESPACE -o jsonpath='{.metadata.annotations.enmasse\.io/infra-uuid}')  --template='{{.data.password}}' | base64 --decode)

			backup_pod_list "$BROKER_POD_NAME_LIST" "$NAMESPACE" "$USER_NAME" "$PASSWORD" "$ADDRESS_NAME"

		done <<< "$ADDRESS_NAME_LIST"
}

function backup_pod_list () {
	local BROKER_POD_NAME_LIST=$1
	local NAMESPACE=$2
	local USER_NAME=$3
	local PASSWORD=$4
	local ADDRESS_NAME="$(cut -d'.' -f2 <<<$(cut -d"/" -f2 <<<"$5"))"

	while IFS= read -r BROKER_POD_NAME ;
		do
			# either use ./artemis data exp > /tmp/export.xml or just gzip and copy the data folder
			oc exec $BROKER_POD_NAME -n $AMQ_ONLINE_NAMESPACE -- tar -cvzf /tmp/"$ADDRESS_NAME.$BROKER_POD_NAME.tar.gz" /var/run/artemis/split-1/broker/data
			oc rsync -n $AMQ_ONLINE_NAMESPACE $BROKER_POD_NAME:/tmp/"$ADDRESS_NAME.$BROKER_POD_NAME.tar.gz" "${BACKUP_FOLDER}"
			oc exec $BROKER_POD_NAME -n $AMQ_ONLINE_NAMESPACE -- rm /tmp/"$ADDRESS_NAME.$BROKER_POD_NAME.tar.gz"

			# With --f option, This will allow certain tools like print-data to be
      #      performed ignoring any running servers. WARNING: Changing data
      #      concurrently with a running broker may damage your data. Be careful
      #      with this option.
			#oc exec $BROKER_POD_NAME -n $AMQ_ONLINE_NAMESPACE -- /var/run/artemis/split-1/broker/bin/artemis data exp --f  --output "/tmp/$ADDRESS_NAME.$BROKER_POD_NAME.xml"
			#oc rsync -n $AMQ_ONLINE_NAMESPACE $BROKER_POD_NAME:/tmp/"$ADDRESS_NAME.$BROKER_POD_NAME.xml" .
			# oc exec $BROKER_POD_NAME -n $AMQ_ONLINE_NAMESPACE -- rm /tmp/"$ADDRESS_NAME.$BROKER_POD_NAME.xml"
		done <<< "$BROKER_POD_NAME_LIST"
}

main () {
  # import  private key and public key
  get_addresses_in_namespace

}

main
