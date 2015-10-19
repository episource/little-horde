#!/bin/bash
firstRun=false

if [[ ( ! -f "/etc/apache2/ssl/https.key" ) || ( ! -f "/etc/apache2/ssl/https.crt" ) ]]; then
    echo "Missing https certificate or key.";
    
    if [[ ( -f "/etc/apache2/ssl/https.key" ) || ( -f "/etc/apache2/ssl/https.crt" ) ]]; then
        echo "Either https.key or https.crt already exists, however one of those files is missing. Check your configuration!";
        exit 1
    fi
    
    if [[ ! -t 0 ]]; then
        echo "Run this container once with the argument '-i -t' for an interactive prompt and I will create a certificate for you."
        echo "You could also copy https.key and https.crt to the /etc/apache2/ssl volume."
        exit 1
    fi
    
    setup-https
fi

if [[ ! -f "/etc/horde/horde/conf.php" ]]; then
    cp -rp /etc/.horde/* /etc/horde/
    cp -p /etc/horde/horde/conf.php.dist /etc/horde/horde/conf.php
    
    horde-writable-config
    
    firstRun=true
fi

if [[ ! -f "/srv/sqlite/horde.sqlite" ]]; then
    firstRun=true
fi

if [[ "$firstRun" == true ]]; then
    echo "Applying initial configuration..."

    #temporarily start apache/horde
    /usr/sbin/apache2ctl start
    
    # Initialize configuration
    curl -# 127.0.0.1/admin/config/?action=config > /dev/null
    
    # Initialize database schema (for whatever reasons this must be executed twice: in the first run two application schemas cannot be updated...)
    curl -# 127.0.0.1/admin/config/?action=schema > /dev/null
    curl -# 127.0.0.1/admin/config/?action=schema > /dev/null
    
    # final apache instance needs to be run in foreground and is started by runit
    /usr/sbin/apache2ctl stop 
    sleep 1
    
    echo "... done!"
fi 
