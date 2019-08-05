#!/bin/sh
## a.limagilberto@gibati.com.br /a.limagilberto@gmail.com
## Resumo:
#
# script ira realizar stop/start de todas instancias ec2 da aws
# o log sera gerado em /var/log/syslog
# ex:
# sudo tail -f /var/log/syslog | grep stop_start_all_ec2_aws.sh
#
########################

# variaveis padrao
script_name="$(basename $0)"
main_dir="$(dirname $0)"
awsregion=us-east-1
awsprofile="gibaaws"
########################

log ()
{
 local message
 message=$*
  logger -p syslog.6 -t $0 ${message}
}

validate ()
{
 if [ ! $return -eq 0 ]; then
   log "[ERROR]- Falha ao realizar stop/start da instancia $ec2_instance_name"
 else
   log "[INFO]- Sucesso ao realizar stop/start da instancia $ec2_instance_name"
 fi
}

turnon ()
{
 aws ec2 start-instances --region "${awsregion}" --instance-ids "$i" --profile $awsprofile >/dev/null 2>&1
 return=$(echo $?)
 validate
}

turnoff ()
{
 aws ec2 stop-instances --region "${awsregion}" --instance-ids "$i" --profile $awsprofile >/dev/null 2>&1
 return=$(echo $?)
 validate
}

usage ()
{
 echo "usage: $0 [stop|start]"
 exit 1
}

# coleta ec2 pelo nome
for i in $(aws ec2 describe-instances --profile $awsprofile| jq -r '.Reservations[].Instances[].InstanceId'); do
  ec2_instance_name=$(aws ec2 describe-instances --instance-id $i --profile $awsprofile |jq '.Reservations[].Instances[].Tags[] | select(.Key == "Name").Value')
  if [ $# = 1 ]; then
    if [ $(echo $1 | grep -i "stop") ];then
      turnoff
    elif [ $(echo $1 |grep -i "start") ];then
      turnon
    else
      usage
    fi
  else
    usage
  fi
done
