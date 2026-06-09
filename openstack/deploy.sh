#!/bin/bash
CSV_FILE=$1
if [ -z "$CSV_FILE" ]; then
    echo "Upotreba: ./deploy.sh korisnici.csv"
    exit 1
fi
source ~/admin-rc
tail -n +2 "$CSV_FILE" | while IFS=',' read -r ime prezime rola; do
    if [ "$rola" == "devops_lead" ]; then
        openstack project create techsprint-devops-lead
    elif [ "$rola" == "developer" ]; then
        PROJECT="techsprint-${ime}-${prezime}"
        openstack project create $PROJECT
        openstack network create --project $PROJECT net-${ime}-${prezime}
        openstack subnet create --project $PROJECT --network net-${ime}-${prezime} --subnet-range 192.168.1.0/24 subnet-${ime}-${prezime}
        openstack security group create --project $PROJECT sg-${ime}-${prezime}
        openstack security group rule create --proto tcp --dst-port 22 sg-${ime}-${prezime}
        openstack router create router-${ime}-${prezime}
        openstack router set --external-gateway provider-datacentre router-${ime}-${prezime}
        openstack router add subnet router-${ime}-${prezime} subnet-${ime}-${prezime}
        openstack server create --flavor default-swap --image rhel8 --network net-${ime}-${prezime} --key-name techsprint-key vm-jumphost-${ime}-${prezime}
        openstack server create --flavor default-swap --image rhel8 --network net-${ime}-${prezime} --key-name techsprint-key vm-moodle-${ime}-${prezime}-1
        openstack server create --flavor default-swap --image rhel8 --network net-${ime}-${prezime} --key-name techsprint-key vm-moodle-${ime}-${prezime}-2
        openstack volume create --size 32 vol-${ime}-${prezime}-moodle1
        openstack volume create --size 32 vol-${ime}-${prezime}-moodle2
        openstack server add volume vm-moodle-${ime}-${prezime}-1 vol-${ime}-${prezime}-moodle1
        openstack server add volume vm-moodle-${ime}-${prezime}-2 vol-${ime}-${prezime}-moodle2
        FIP1=$(openstack floating ip create provider-datacentre -f value -c floating_ip_address)
        openstack server add floating ip vm-jumphost-${ime}-${prezime} $FIP1
        openstack user create --password redhat ${ime}-${prezime}
        openstack role add --project $PROJECT --user ${ime}-${prezime} member
        openstack container create moodle-files-${ime}-${prezime}
        openstack container create backup-${ime}-${prezime}
    fi
done
openstack user create --password redhat ana-anic
openstack role add --project techsprint-devops-lead --user ana-anic admin
echo "Deployment zavrsen!"