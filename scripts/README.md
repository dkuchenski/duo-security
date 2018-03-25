# Duo Bash Scripts

## Duo Access Gateway
The [dag-config-sync-src.sh](dag-config-sync-src.sh) and [dag-config-sync-dst.sh](dag-config-sync-dst.sh) scripts can be used with the Ubuntu version of the Duo Access Gateway (DAG) to replicate configuration changes from a "primary" DAG to any number of secondar DAGs.

Installation Steps:
1. Copy dag-config-sync-src.sh to your primary DAG
2. Change any variables if needed, but only two variables are **required**:
   * dag_replication_user: Enter the username of the user that will rsync config files to the secondary server(s). This user must have an SSH key and the ability to rsync files to the /tmp directory.
   * dag_replication_dest: Enter the FQDN of the secondary server. You can enter multiple servers separated by a space.
3. To automate configuration replication, add dag-config-sync-src.sh to a cron job
4. Copy dag-config-sync-dst.sh to your secondary DAG(s)
5. You do not need to change any varibles here
6. Run this script after dag-config-sync-src.sh has run on the primary server. To automate configuration replication, add dag-config-sync-dst.sh to a cron job that runs a couple minutes after the primary server.

All actions are logged by default to /var/log/dag-config-sync.log
