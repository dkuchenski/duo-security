#!/bin/bash

backup_dir="/opt/dag_backup"
backup_dir_tmp="/tmp/dag_backup_tmp"
backup_dir_previous="/opt/dag_backup_previous"
config_sync_log="/var/log/dag-config-sync.log"
dag_replication_user="example-user"
dag_replication_dest="dag02.example.com"
#dag_replication_dest="dag02.example.com dag03.example.com"
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

# Delete incremental backup if already exists
if [ -d "$backup_dir_tmp" ]
then
    /bin/rm -r $backup_dir_tmp
fi

# Create incremental backup
/usr/bin/docker cp access-gateway:/data $backup_dir_tmp
if [ $? != 0 ]
then
    echo "$date_format Incremental configuration could not be created in $backup_dir_tmp" >> $config_sync_log
    exit 1
else
    echo "$date_format Incremental configuration backup created in $backup_dir_tmp" >> $config_sync_log
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

# Replicate changes to dest servers if changes are detected
if [ "$config_changed" = true ]
then
    /usr/bin/rsync -a --delete $backup_dir/ $backup_dir_previous/
    /usr/bin/rsync -a --delete $backup_dir_tmp/ $backup_dir/
    for server in $dag_replication_dest
    do
      /usr/bin/rsync -aze ssh --delete $backup_dir_tmp $dag_replication_user@$server:/tmp/
      if [ $? != 0 ]
      then
          echo "$date_format Changes could not be replicated to $server" >> $config_sync_log
      else
          echo "$date_format Changes successfully replicated to $server" >> $config_sync_log
      fi
    done
fi
