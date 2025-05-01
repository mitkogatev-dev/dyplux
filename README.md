# dyplux
Perl Influx Dygraphs Traffic Grahps

---

### Requirements:
- Linux box with perl installed
- MariaDB (mysql) database
- Influx v2 database
- Http server with mod cgi and .htaccess enabled
- [Dygraphs.js](https://dygraphs.com/) (included in js/ folder)
- curl binary (if this method for Influx query is selected from config)

#### For collector:
- influxdb2-client from [here](https://docs.influxdata.com/influxdb/v2/reference/cli/influx/?t=Linux#download-and-install-the-influx-cli) 
- mysql client binary in PATH

### Required Perl modules:

- CGI
- CGI::Carp
- JSON
- Data::Dumper 
- FindBin 1.51
- Net::SNMP
- DBI

---
---
### Install

---

Clone repo in web server folder:

```cd /var/www/ht*```

``` git clone https://github.com/mitkogatev-dev/dyplux.git```

Create mysql(MariaDB) database

``` mysql -u user -p pass -e "CREATE DATABASE your_database" ```

Load sql file in DB

``` cd dyplux/install && mysql -u user -p pass your_database < dyplux.sql```

Go to your Influx database and create new bucket.

Fill your credentials in config.pl.

---
---


