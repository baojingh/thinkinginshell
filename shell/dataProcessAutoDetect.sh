# /bin/sh

dps=`docker ps  -a | grep  process | grep Exited`
if [[ $dps =~ "Exited" ]]
then
    echo `date` "data_process container Exited"
    docker restart $(docker ps  -a | grep  process | grep Exited | awk '{print $1}')
    echo `date` "restart data_process container success"
fi