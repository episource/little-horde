0. Install Docker


1. Build Docker Image
   a. cd to directory containing Dockerfile
   b. # docker build --tag="episource/little-horde" .


2. Prepare Host
   a. Persistant configuration data
      - choose a directory for persistant configuration data
        Note: /srv/horde/config is just an example
        # mkdir -p /srv/horde/config
     
   b. Database storage (sqlite)
      - choose a directory for the sqlite database file(s)
        Note: /srv/horde/sqlite is just an example
        # mkdir -p /srv/horde/sqlite
      - adjust permissions
        Note: UID/GID 33 is www-data inside the container
        # chown 33:33 /srv/horde/sqlite

   c. SSL Certificate and Key
      - create a directory for storing the ssl key and certificate
        Note: /srv/horde/ssl is just an example
        # mkdir -p /srv/horde/ssl
      - create key and certificate
        (a) either copy an existing certificate and key to 
            /srv/horde/ssl/https.crt (certificate) and
            /srv/horde/ssl/https.key (key)
        (b) or create a new certificate by running
            # docker run -v /srv/horde/ssl:/etc/apache2/ssl -i -t episource/little-horde setup-https
            and answering the interactive dialog 
            (note: Common Name must match the domain name or the ip used for accessing the horde installation!)
            
    d. Optional: Network interface
        Horde should be exposed using default http (80) and https (443) port. If horde is
        the only web server running on your machine you can skip this step. Otherwise
        you should add another ip to your network interface to be used exclusively for
        horde groupware. This also means that you must reconfigure the existing web server
        not to bind to that newly created interface.
        
        This can be done temporarily using the command
        # ip addr add 192.168.1.30/24 dev eth0
        
        Note: 192.168.1.30 is just an arbitrary example!        
        
        Consult the documentation of your linux distribution for a description of how to
        persist this change.
        
        Example: Arch Linux using a static network configuration
          Just add the new ip to the list of IPs in your current profile:
          ~~~~ /etc/netcfg/eth0-static ~~~~
          Interface=eth0
          Connection=ethernet
          IP=static
          Address=('192.168.1.30/24' '192.168.1.31/24')
          Gateway='192.168.1.1'
          DNS=('192.168.1.1')

          ## For IPv6 autoconfiguration
          TimeoutDAD=30
          IP6=stateless
          ~~~~     
                
3. Start Horde for the first time
    a. If you skipped (2.d) use the following command
       # docker run -v /srv/horde/config:/etc/horde -v /srv/horde/ssl:/etc/apache2/ssl -v /srv/horde/sqlite:/srv/sqlite -p 80:80 -p 443:443 episource/little-horde
    b. If you did not skip(2.d) use the following command
       # docker run -v /srv/horde/config:/etc/horde -v /srv/horde/ssl:/etc/apache2/ssl -v /srv/horde/sqlite:/srv/sqlite -p 192.168.1.30:80:80 -p 192.168.1.30:443:443 episource/little-horde

4. Configure Horde
    a. Visit http://192.168.1.30/ in your webbrowser (note: check that https://192.168.1.30/ is working, too, after
        accepting the self signed certificate)
    b. If authentication has already been setup login using your admin credentials - else you will be logged in as
        Administrator automatically
    c. In the top menu move your mouse over the gear, select Administration and click on Configuration
       
5. Configure Horde: Authentication
  Note: Per default there's not authentication required. Everyone is treated as Administrator.
  Note: Enter the configuration menu as described in step 4.
    a. Click on "Horde (horde)" for configuring the main horde application
    b. Select the tab "Authentication" 
    c. If you want to use sync mails using ActiveSync and/or want to use the richt web mail client imp
        it's best to delegate authentication to an  imap server. Nevertheless this might be a good decision,
        too, if you don't intend to use mail synchronization.
      I  ) change $conf[auth][driver] to "IMAP authentification"
      II ) enter the name or ip of your IMAP server: $conf[auth][params][hostspec]
      III) enter the port of your IMAP server: $conf[auth][params][port]
           example: 143
      IV ) select the appropriate encryption mechanism: $conf[auth][params][port][secure]
           note: I think tls means "STARTTLS" where as ssl means transport encryption using SSL/TLS      
      V  ) Remember to adjust $conf[auth][admins]!
        
    d. A simple alternative is using the Horde's Sql Authentification which uses the sql data tables
       to store user credentials:
      I  ) change $conf[auth][driver] to "SQL authentication"
      II ) put the name of the admin user into $conf[auth][admins] - you can also leave the default value "Administrator"
      III) save your changes by clicking "Generate Horde Configuration" at the bottom of the page
           note: for a basic working configuration there's nothing else to change here
      IV ) Select "Users" in the left menu
      V  ) Add at least the user you configured in step (II)
           note: user names are case sensitive!
    e. Click "Generate Horde Configuration"
        
6. Configure Horde: Grant authenticated users the right to use active sync
    Note: Enter the configuration menu as described in step 4.
    a. Select "Permissions" in the left menu
    b. At the "All Permissions" node click "+", add "Horde (horde)"
    c. At the newly created "Horde (horde)" node click the pencil and grant authenticated users the rights "Show" and "Read"
    d. At the newly created "Horde (horde)" node click "+", add "ActiveSync (activesync)"
    e. At the newly created "ActiveSync (activesync)" node click the pencil and grant authenticated users the unnamed right (there's just a single checkbox without description)
    f. At the newly created "ActiveSync (activesync)" node click "+", add "Provisioning (provisioning)"
    g. At the newly created "Provisioning (provisioning)" node click the pencil and select "Allow" for authenticated users
    
7. Make the docker container start automatically
    notes: for this to work the docker daemon must be configured to start at system boot
    a. First Option: Restart policies
       I  ) If you skipped (2.d) use the following command
            # docker run --restart=always -v /srv/horde/config:/etc/horde -v /srv/horde/ssl:/etc/apache2/ssl -v /srv/horde/sqlite:/srv/sqlite -p 80:80 -p 443:443 episource/little-horde
       II ) If you did not skip (2.d) use the following command
            # docker run --restart=always -v /srv/horde/config:/etc/horde -v /srv/horde/ssl:/etc/apache2/ssl -v /srv/horde/sqlite:/srv/sqlite -p 192.168.1.30:80:80 -p 192.168.1.30:443:443 episource/little-horde
       see also: https://docs.docker.com/reference/commandline/cli/#restart-policies
    b. Second Option: Use a process manager
       see: https://docs.docker.com/articles/host_integration/
    
8. You now have a basic working horde setup that is ready for synchronising contacts and calendars. You can connect any device or software supporting active sync (Windows 8.1, Windows Phone, Android, Thunderbird with Plugins) to your horde instance.
  Note: You might need to change how the activesync user name is derived from an mail adress (Configuration > Horde > Active Sync > $conf[activesync][autodiscovery]) - default is "Use only the username" - when authenticating against an external mail provider this must be changed to "Use the full email address as the username")
  Note: For connecting a Windows 8.1 Mail and contacts to horde you need to tweak the group policy "Administrative Templates > Windows Components > App runtime > Allow Microsoft accounts to be optional" to "Enabled"
  
9. Using Active Sync as Push Mail Service
   Note: consider imap authentication - step (5.c)
   a. Goto Configuration > Horde > Active Sync
   b. $conf[activesync][emailsync] = enabled
   c. $conf[activesync][outlookdiscovery] = Yes
   d. Configure $conf[activesync][hosts][imap/pop/smtp] according to your needs
   e. Create a file "/etc/horde/imp/backends.local.php" with the following content:
   ~~~~ backends.local.php ~~~~
   <?php
   $servers['imap']['hostspec'] = '<your imap server>';
   $servers['imap']['port'] = <appropriate port>;
   $servers['imap']['secure'] = <false/'ssl'/'tls'>;
   
   // try to reuse horde authentification
   $servers['imap']['hordeauth'] = true;
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   
  
A. Misc
  - When using imap authentication there seem to be problems when the passwort contains the character "%"
  - You need to backup /srv/horde/config and /srv/horde/sqlite
  - You might want to restrict access to /srv/horde
  - You might need to adjust iptables/firewall rules
  - The basic configuration described above might not be secure! Only use in a trusted environment!
 
