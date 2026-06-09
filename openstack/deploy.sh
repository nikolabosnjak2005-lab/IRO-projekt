#!/bin/bash
CSV_FILE=$1
if [ -z "$CSV_FILE" ]; then
    echo "Upotreba: ./deploy.sh korisnici.csv"
    exit 1
fi

source ~/admin-rc

openstack keypair create techsprint-key > techsprint-key.pem 2>/dev/null
chmod 600 techsprint-key.pem

tail -n +2 "$CSV_FILE" | while IFS=',' read -r ime prezime rola; do
    echo ">>> Kreiram: $ime $prezime ($rola)"

    if [ "$rola" == "devops_lead" ]; then
        openstack project create techsprint-devops-lead 2>/dev/null
        openstack user create --password redhat ana-anic 2>/dev/null
        openstack role add --project techsprint-devops-lead --user ana-anic admin
        openstack server create --flavor default-swap --image rhel8 --network net-luka-lukic --key-name techsprint-key vm-devops-lead 2>/dev/null

    elif [ "$rola" == "developer" ]; then
        PROJECT="techsprint-${ime}-${prezime}"

        openstack project create $PROJECT 2>/dev/null
        openstack user create --password redhat ${ime}-${prezime} 2>/dev/null
        openstack role add --project $PROJECT --user ${ime}-${prezime} member

        openstack network create --project $PROJECT net-${ime}-${prezime} 2>/dev/null
        openstack subnet create --project $PROJECT --network net-${ime}-${prezime} --subnet-range 192.168.$RANDOM.0/24 subnet-${ime}-${prezime} 2>/dev/null

        openstack security group create --project $PROJECT sg-${ime}-${prezime} 2>/dev/null
        openstack security group rule create --proto tcp --dst-port 22 sg-${ime}-${prezime} 2>/dev/null
        openstack security group rule create --proto tcp --dst-port 80 sg-${ime}-${prezime} 2>/dev/null

        openstack router create router-${ime}-${prezime} 2>/dev/null
        openstack router set --external-gateway provider-datacentre router-${ime}-${prezime}
        openstack router add subnet router-${ime}-${prezime} subnet-${ime}-${prezime}

        openstack server create --flavor default-swap --image rhel8 --network net-${ime}-${prezime} --security-group sg-${ime}-${prezime} --key-name techsprint-key vm-jumphost-${ime}-${prezime} 2>/dev/null
        openstack server create --flavor default-swap --image rhel8 --network net-${ime}-${prezime} --security-group sg-${ime}-${prezime} --key-name techsprint-key vm-moodle-${ime}-${prezime}-1 2>/dev/null
        openstack server create --flavor default-swap --image rhel8 --network net-${ime}-${prezime} --security-group sg-${ime}-${prezime} --key-name techsprint-key vm-moodle-${ime}-${prezime}-2 2>/dev/null

        echo "Cekam da VM-ovi postanu ACTIVE..."
        sleep 30

        openstack volume create --size 32 vol-${ime}-${prezime}-moodle1 2>/dev/null
        openstack volume create --size 32 vol-${ime}-${prezime}-moodle2 2>/dev/null

        sleep 10

        openstack server add volume vm-moodle-${ime}-${prezime}-1 vol-${ime}-${prezime}-moodle1 2>/dev/null
        openstack server add volume vm-moodle-${ime}-${prezime}-2 vol-${ime}-${prezime}-moodle2 2>/dev/null

        FIP=$(openstack floating ip create provider-datacentre -f value -c floating_ip_address)
        openstack server add floating ip vm-jumphost-${ime}-${prezime} $FIP

        openstack container create moodle-files-${ime}-${prezime} 2>/dev/null
        openstack container create backup-${ime}-${prezime} 2>/dev/null
    fi
done

echo "=== Deployment zavrsen ==="
openstack server list
openstack volume list
openstack network list