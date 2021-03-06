# Masternode_Manager

<pre>
# Script to manage all masternodes at once and is dupmn aware
# Created by Eddy Erkel
# Version 0.1 31-05-2019
#
# Disclamer:
# This script is provided "as is", without warranty of any kind.
# Use it at your own risk. I assume no liability for damages,
# direct or consequential, that may result from the use of this script.
#
# Dupmn: https://github.com/neo3587/dupmn
#
# Grateful for my work and in a generous mood?
# BTC: 18JNWyGhfAmhkWs7jzuuHn54jEZRPj81Jx
# ETH: 0x067e8b995f7dbaf32081bc32927f6fac29b32055
# LTC: LLqwyRiKiuvxkx76grFmbxEeoChLnxvaKH
#
# This script will manage all your masternodes at once and is dupmn aware.
# 
# Prerequisites:
# - Masternode CLI files are stored in /usr/local/bin/ or /usr/bin/
# - Masternode .service files must exist for each masternode (in /etc/systemd/system/)
# 
# Command options: status, stop, start, restart, enable, disable, list, showconf, backupconf, replace, cli-command(s)
# 
# 
# Usage: mnmanager.sh [command] <option> <option>
# 
# mnmanager.sh help                      : Display help text
# mnmanager.sh status                    : Display masternode services status (nonverbose/compact output)
# mnmanager.sh status verbose            : Display masternode services status (normal/verbose output)
# mnmanager.sh stop                      : Stop masternode services
# mnmanager.sh start                     : Start masternode services, followed by a short delay between masternodes
# mnmanager.sh restart                   : Stop and start masternode services, followed by a short delay between masternodes
# mnmanager.sh enable                    : Enable autostart of masternode services (not recommended with many masternodes on same server)
# mnmanager.sh disable                   : Disable masternode services
# mnmanager.sh list                      : List masternode.service and masternode-cli files
# mnmanager.sh showconf                  : Type contents of masternodename.conf files
# mnmanager.sh backupconf                : Create backups of masternodename.conf to masternodename.conf.yymmdd_hhmmss
# mnmanager.sh backupconf string         : Create backups of masternodename.conf to masternodename.conf.string
# mnmanager.sh replace stringA stringB   : Replace stringA with stringB in masternodename.conf files (a backup copy of masternodenam.conf will be created)
# 
# mnmanager.sh cli-command(s)            : Execute masternode cli commands (like 'mn-cli masternode status', 'mn-cli getinfo')
# mnmanager.sh masternode status         : Execute masternode cli command 'masternode status' (nonverbose/compact output)
# mnmanager.sh masternode status verbose : Execute masternode cli command 'masternode status' (normal/verbose output)
# 
# *** Be carefull, commands are executed for all your masternodes! ***
</pre>
