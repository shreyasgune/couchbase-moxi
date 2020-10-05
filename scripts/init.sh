#!/bin/bash

sed -i "s/{COUCHBASE_USER}/${COUCHBASE_USER}/g" /opt/moxi/etc/moxi.cfg
sed -i "s/{COUCHBASE_PASS}/${COUCHBASE_PASS}/g" /opt/moxi/etc/moxi.cfg
sed -i "s/{COUCHBASE_BUCKET}/${COUCHBASE_BUCKET}/g" /opt/moxi/etc/moxi.cfg


CB_HOSTS=($COUCHBASE_HOSTS)
CB_Length=${#CB_HOSTS[@]}
CB_LAST=$((CB_Length - 1))

for (( i=0; i<${CB_Length}; i++));
do
  if [ ${CB_Length} = 1 ]
  then
    printf "url=http://%s:8091/pools/default/bucketsStreaming/%s\n" "${CB_HOSTS[0]}" "${COUCHBASE_BUCKET}" >> /opt/moxi/etc/moxi-cluster.cfg
  elif [ $i = 0 ]
  then
    printf "url=http://%s:8091/pools/default/bucketsStreaming/%s|" "${CB_HOSTS[0]}" "${COUCHBASE_BUCKET}" >> /opt/moxi/etc/moxi-cluster.cfg
  elif [ $i = ${CB_LAST} ]
  then
    printf "http://%s:8091/pools/default/bucketsStreaming/%s\n" "${CB_HOSTS[$i]}" "${COUCHBASE_BUCKET}" >> /opt/moxi/etc/moxi-cluster.cfg
  else
    printf "http://%s:8091/pools/default/bucketsStreaming/%s|" "${CB_HOSTS[$i]}" "${COUCHBASE_BUCKET}" >> /opt/moxi/etc/moxi-cluster.cfg
  fi
done

/opt/moxi/bin/moxi -r -Z /opt/moxi/etc/moxi.cfg -z /opt/moxi/etc/moxi-cluster.cfg
