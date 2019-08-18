#!/bin/bash
# Script to manage all masternodes at once and is dupmn aware
# Created by Eddy Erkel
# Version 0.2 18-08-2019
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



# Check for argument, if not provided, type help text and exit.
echo
if [[ -z "$1" ]] || [[ "$1" == "help" ]] || [[ "$1" == "--help" ]]
then
    echo
	echo "This script will manage all your masternodes at once and is dupmn aware."
    echo
	echo "Prerequisites:"
    echo "- Masternode CLI files are stored in /usr/local/bin/ or /usr/bin/"
    echo "- Masternode .service files must exist for each masternode (in /etc/systemd/system/)"
    echo
	echo "Command options: status, stop, start, restart, enable, disable, list, showconf, backupconf, replace, <cli-command(s)>"
	echo
    echo
	echo "Usage: mnmanager.sh [command] <option> <option>"
	echo
    echo "mnmanager.sh help                      : Display help text"
    echo "mnmanager.sh status                    : Display masternode services status (nonverbose/compact output)"
    echo "mnmanager.sh status verbose            : Display masternode services status (normal/verbose output)"
    echo "mnmanager.sh stop                      : Stop masternode services"
    echo "mnmanager.sh start                     : Start masternode services, followed by a short delay between masternodes"
    echo "mnmanager.sh restart                   : Stop and start masternode services, followed by a short delay between masternodes"
    echo "mnmanager.sh enable                    : Enable autostart of masternode services (not recommended with many masternodes on same server)" 
    echo "mnmanager.sh disable                   : Disable masternode services"
    echo "mnmanager.sh list                      : List masternode.service and masternode-cli files"
    echo "mnmanager.sh showconf                  : Type contents of masternodename.conf files"    
    echo "mnmanager.sh backupconf                : Create backups of masternodename.conf to masternodename.conf.yymmdd_hhmmss"
    echo "mnmanager.sh backupconf string         : Create backups of masternodename.conf to masternodename.conf.string"
    echo "mnmanager.sh replace stringA stringB   : Replace stringA with stringB in masternodename.conf files (a backup copy of masternodenam.conf will be created)"
    echo
    echo "mnmanager.sh <cli-command(s)>          : Execute masternode cli commands (like 'mn-cli masternode status', 'mn-cli getinfo')"
    echo "mnmanager.sh masternode status         : Execute masternode cli command 'masternode status' (nonverbose/compact output)"
    echo "mnmanager.sh masternode status verbose : Execute masternode cli command 'masternode status' (normal/verbose output)"
    echo
    echo "*** Be carefull, commands are executed for all your masternodes! ***"
    echo
	exit 1
fi



# Set variables
date=$(date +"%Y%m%d_%H%M%S")	# set date variable
delay=5                         # set delay variable, used so masternodes start sequentially
maxwait=180                     # set maximum time to wait for a masternode to start, continue to next if maxwait is reached
retry=3                         # number of times to check before continuing to next masternode
command=$1                      # first input parameter             
option=$2                       # second input parameter



if [[ "${command}" == @(status|stop|start|restart|enable|disable|list|showconf|backupconf|replace) ]]
then
    if [[ "${command}" == @(stop|enable|disable) ]]
    then
        for service in $(ls --file /etc/systemd/system/*.service | grep -v @ | xargs -n 1 basename | sort -V )
        do
            echo
            echo -e "\e[92msystemctl ${command} ${service}\e[0m"
            systemctl ${command} ${service}
            systemctl status ${service} | egrep "Active: inactive|Active: failed"
        done
    fi

    
    if [[ "${command}" == "status" ]]
    then
        echo
        for service in $(ls --file /etc/systemd/system/*.service | grep -v @ | xargs -n 1 basename | sort -V )
        do
            if [[ "${option}" == "verbose" ]]
            then
                echo
                echo -e "\e[92msystemctl ${command} ${service}\e[0m"
                systemctl status ${service}
             else
                echo -en "\e[92m${service}\t:\e[0m"
                systemctl status ${service} | grep Active:
            fi
        done       
    fi


    
    if [[ "${command}" == "start" ]]
    then
        for service in $(ls --file /etc/systemd/system/*.service | grep -v @ | xargs -n 1 basename | sort -V )
        do
            mncli=$(cat /etc/systemd/system/${service} | grep ExecStop | sed -e 's/ExecStop=//' -e 's/ stop//')
            echo
            echo -e "\e[92msystemctl start ${service}\e[0m" 
            result=$(systemctl status ${service} | egrep "Active: inactive|Active: failed")
            if [ "$?" -eq 0 ]
            then
                systemctl start ${service} 2>&1 >/dev/null
                
                errorlevel=1
                while [ $errorlevel -gt 0 ]
                do
                    for ((i=$delay; i>=0; i--)); do echo -ne "."; sleep 1; done;
                    result=$(eval $mncli masternode status 2>&1 >/dev/null | egrep "Loading|error" | egrep "couldn't connect to server|no response from server|capable masternode")
                    
                    # error: {"code":-28,"message":"Verifying wallet..."}
                    # error: {"code":-28,"message":"Loading block index..."}
                    # error: {"code":-1,"message":"Masternode not found in the list of available masternodes. Current status: Node just started, not yet activated"}
                    # error: {"code":-1,"message":"Masternode not found in the list of available masternodes. Current status: Not capable masternode: Hot node, waiting for remote activation."}
                    # error: couldn't connect to server
                    # error: no response from server
                    
                    errorlevel=$?
                    if [ $errorlevel -eq 0 ]
                    then
                        # Double check
                        sleep 2
                        result=$(eval $mncli masternode status 2>&1 >/dev/null | egrep "Loading|error" | egrep "couldn't connect to server|no response from server|capable masternode")
                        errorlevel=$?
                    fi
                    maxwait=$((maxwait-$delay))
                    if [ $maxwait -le 0 ]; then errorlevel=0; fi
                done
                echo -en "\\r"
                systemctl status ${service} | egrep "Active: inactive|Active: failed|Active: active"
                result=$(eval ${mncli} masternode status 2>&1 | egrep 'error|message|capable' | sed "s/^[ \t]*//" )
                                            
                if [[ -z $result  ]]
                then 
                    result=$(eval ${mncli} ${command} ${option} 2>&1 | grep 'status' | sed "s/^[ \t]*//" )
                fi
                            
                echo "   ${result}"
             else
                systemctl status ${service} | grep "Active: active"
                result=$(eval ${mncli} masternode status 2>&1 | egrep 'error|message|capable' | sed "s/^[ \t]*//" )
                                                            
                if [[ -z $result  ]]
                then 
                    result=$(eval ${mncli} ${command} ${option} 2>&1 | grep 'status' | sed "s/^[ \t]*//" )
                fi
                 
                echo "   ${result}"
            fi
        done
    fi


    
    if [[ "${command}" == "restart" ]]
    then
        for service in $(ls --file /etc/systemd/system/*.service | grep -v @ | xargs -n 1 basename | sort -V )
        do
            mncli=$(cat /etc/systemd/system/${service} | grep ExecStop | sed -e 's/ExecStop=//' -e 's/ stop//')
            echo
            echo -e "\e[92msystemctl stop ${service}\e[0m"
            systemctl stop ${service}
            
            echo -e "\e[92msystemctl start ${service}\e[0m"
            systemctl start ${service} 2>&1 >/dev/null
            
            #errorlevel=1
            #while [ $errorlevel -gt 0 ]
            #do
            #    for ((i=$delay; i>=0; i--)); do echo -ne "."; sleep 1; done;
            #    result=$(eval $mncli masternode status)
            #    errorlevel=$?
            #    maxwait=$((maxwait-$delay))
             #   if [ $maxwait -le 0 ]; then errorlevel=0; fi
            #done
            
            errorlevel=1
            while [ $errorlevel -gt 0 ]
            do
                for ((i=$delay; i>=0; i--)); do echo -ne "."; sleep 1; done;
                result=$(eval $mncli masternode status 2>&1 >/dev/null | egrep "Loading|error" | egrep "couldn't connect to server|no response from server|capable masternode")
                
                # error: {"code":-28,"message":"Verifying wallet..."}
                # error: {"code":-28,"message":"Loading block index..."}
                # error: {"code":-1,"message":"Masternode not found in the list of available masternodes. Current status: Node just started, not yet activated"}
                # error: {"code":-1,"message":"Masternode not found in the list of available masternodes. Current status: Not capable masternode: Hot node, waiting for remote activation."}
                # error: couldn't connect to server
                # error: no response from server
                
                errorlevel=$?
                if [ $errorlevel -eq 0 ]
                then
                    # Double check
                    sleep 2
                    result=$(eval $mncli masternode status 2>&1 >/dev/null | egrep "Loading|error" | egrep "couldn't connect to server|no response from server|capable masternode")
                    errorlevel=$?
                fi
                maxwait=$((maxwait-$delay))
                if [ $maxwait -le 0 ]; then errorlevel=0; fi
            done
            
            
            
            
            echo -en "\\r"
            systemctl status ${service} | egrep "Active: inactive|Active: failed|Active: active"
            result=$(eval ${mncli} masternode status 2>&1 | egrep 'error|message|capable' | sed "s/^[ \t]*//" )
                            
            if [[ -z $result  ]]
            then 
                result=$(eval ${mncli} ${command} ${option} 2>&1 | grep 'status' | sed "s/^[ \t]*//" )
            fi
            
            echo "   ${result}"
        done
    fi

    
    
    if [[ "${command}" == "list" ]]
    then
        ls --file /etc/systemd/system/*.service | grep -v @ | sort -V
        echo
        
        mncli=$(ls --file /usr/bin/*-cli-*; ls --file /usr/local/bin/*-cli)
        echo ${mncli[@]} | tr " " "\n" | sort -V
        echo
        for conf in $(find /home/ -name '*.conf' | egrep -v 'masternode|dupmn' | sort -V)
        do
            echo ${conf}
        done
        
        for conf in $(find /root/ -name '*.conf' | egrep -v 'masternode|dupmn' | sort -V)
        do
            echo ${conf}
        done
        echo
    fi
    
    
    
    if [[ "${command}" == "showconf" ]]
    then
        for conf in $(find /home/ -name '*.conf' | egrep -v 'masternode|dupmn' | sort -V)
        do
            echo -e "\e[92mcat ${conf}\e[0m"
            cat ${conf}
            echo
        done
    for conf in $(find /root/ -name '*.conf' | egrep -v 'masternode|dupmn' | sort -V)
        do
            echo -e "\e[92mcat ${conf}\e[0m"
            cat ${conf}
            echo
        done
    fi

    
    
    if [[ "${command}" == "backupconf" ]]
    then
        if [[ -z "$2" ]]
        then
            for conf in $(find /home/ -name '*.conf' | egrep -v 'masternode|dupmn' | sort)
            do
                echo -e "\e[92mcp ${conf} ${conf}.$date\e[0m"
                cp ${conf} ${conf}.$date
            done
            
            for conf in $(find /root/ -name '*.conf' | egrep -v 'masternode|dupmn' | sort)
            do 
                echo -e "\e[92mcp ${conf} ${conf}.$date\e[0m"
                cp ${conf} ${conf}.$date
            done
        else
            for conf in $(find /home/ -name '*.conf' | egrep -v 'masternode|dupmn' | sort)
            do
                echo -e "\e[92mcp ${conf} ${conf}.${option}\e[0m"
                cp ${conf} ${conf}.${option}
            done
            
            for conf in $(find /root/ -name '*.conf' | egrep -v 'masternode|dupmn' | sort)
            do
                echo -e "\e[92mcp ${conf} ${conf}.${option}\e[0m"
                cp ${conf} ${conf}.${option}
            done
        fi
    fi



    if [[ "${command}" == "replace" ]]
    then
        if [[ -z "$2" ]] || [[ -z "$3" ]]
        then
            echo "Provide search and replace variable value."
            echo
            echo "Example: mnmanager.sh replace 12.34.56.78 98.76.54.32"
            echo
            echo
            exit 1
        fi
        
        search=$2
        replace=$3

        for conf in $(find /home/ -name '*.conf' | egrep -v 'masternode|dupmn' | sort -V)
        do
            cp ${conf} ${conf}.$date
            sed -i "s/${search}/${replace}/g" ${conf}
        done        
        
        for conf in $(find /root/ -name '*.conf' | egrep -v 'masternode|dupmn' | sort -V)
        do
            cp ${conf} ${conf}.$date
            sed -i "s/${search}/${replace}/g" ${conf}
        done

    fi

    
    
else
    mncli=$(ls --file /usr/bin/*-cli-* | egrep -v 'cli-0|cli-all' | xargs -n 1 basename; ls --file /usr/local/bin/*-cli | grep -v all | xargs -n 1 basename)
    mncli=($(echo ${mncli[@]} | tr " " "\n" | sort -V))  

    if [[ "${command}" == "masternode" && "${option}" == "status" ]]    
    then
        for cli in "${mncli[@]}"
        do
            if [[ "${3}" == "verbose" ]]
            then
                echo
                echo -e "\e[92m${cli} ${command} ${option}\e[0m"
                eval ${cli} ${command} ${option}
            else
                result=$(eval ${cli} ${command} ${option} 2>&1 | egrep 'error|message|capable' | sed "s/^[ \t]*//" )
                
                if [[ -z $result  ]]
                then 
                    result=$(eval ${cli} ${command} ${option} 2>&1 | grep 'status' | sed "s/^[ \t]*//" )
                fi
               
                printf '\e[1;92m%-40s\e[0m %s\n' "${cli} ${command} ${option}" "${result}"
            fi
        done
    else
        for cli in "${mncli[@]}"
        do 
            echo -e "\e[92m${cli} $@\e[0m"
            eval ${cli} $@
            echo
        done
    fi
fi
echo
echo
