#!/bin/sh
if [ -e terraform/terraform.tfstate ]; then
    ip=`cat terraform/terraform.tfstate | jq '.modules[].outputs[].value' | cut -d '"' -f 2`
    cat << EOS
{
    "cloud_servers"  : [ $ip ]
}
EOS
fi
