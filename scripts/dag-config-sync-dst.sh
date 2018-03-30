#!/bin/bash

backup_dir="/opt/dag_backup"
backup_dir_tmp="/tmp/dag_backup_tmp"
backup_dir_previous="/opt/dag_backup_previous"
config_sync_log="/var/log/dag-config-sync.log"
date_format=$(date "+%FT%T")

diff_function () {
  DIFF=$(diff -rq $backup_dir/$1/ $backup_dir_tmp/$1/)
  if [ "$DIFF" != "" ]
  then
      config_changed=true
      echo "$date_format Configuration change detected in $backup_dir_tmp/$1" >> $config_sync_log
  fi
}

# Create original backup if needed
if [ ! -d "$backup_dir" ]
then
    /usr/bin/docker cp access-gateway:/data $backup_dir
    echo "$date_format First configuration backup created in $backup_dir" >> $config_sync_log
fi

# Diff the directories in the backup
if [ -d "$backup_dir_tmp" ]
then
    diff_function cert
    diff_function config
    diff_function metadata
else
    echo "$date_format Cannot diff config files, folder not found in $backup_dir_tmp" >> $config_sync_log
fi

# Copy config to access-gateway docker instance if changes are detected
if [ "$config_changed" = true ]
then
    /usr/bin/docker cp $backup_dir_tmp/. access-gateway:data
    if [ $? != 0 ]
    then
      echo "$date_format Could not copy configuration data to access-gateway" >> $config_sync_log
      exit 1
    fi
    /usr/bin/docker exec -i --user=0 access-gateway chown -R www-data:www-data /data
    if [ $? != 0 ]
    then
      echo "$date_format Could not chown -R www-data:www-data /data in access-gateway" >> $config_sync_log
      exit 1
    fi
    /usr/bin/rsync -a --delete $backup_dir/ $backup_dir_previous/
    /usr/bin/rsync -a --delete $backup_dir_tmp/ $backup_dir/
    echo "$date_format Configuration changes copied to access-gateway" >> $config_sync_log
fi
