Zabbix role
=========

Installation steps:

1. Download Zabbix repository
2. Install Zabbix repository .deb file
3. Install PostgreSQL
4. Install Zabbix
5. Create PostgreSQL zabbix user
6. Import database schema
7. Change DBPassword zabbix_server.conf
8. Uncomment Zabbix `listen` and `server_name` in nginx.conf
9. Restart services, `zabbix-server`, `zabbix-agent`, `nginx`, `php-fpm`
