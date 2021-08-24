# bashmonit

*Server Monitoring tool, based in bash, extensible with custom sensors, and outputing a JSON on a standalone HTTP server (without need of Apache nor nginx). This script has to be exploited with an external webinterface.*

## Getting Started

* Clone the GIT repo
* Make the installer file available for execution (`chmod +x install.sh`)
* At first launch, it will create your configuration files, and will be ready.
* Once launched, visit http://youserverip:8765/?key=XXXXXXX (replace XXXXXXX by the key provided).

### Output example

```json
{{
   "system":{
      "daemon":"bashmonit/1.2.13",
      "generation_date":"Tue 24 Aug 2021 06:39:34 PM CEST"
   },
   "sensors":{
      "apps":{
         "mysql":{
            "status":"online"
         },
         "php":{
            "version":"7.4.22"
         }
      },
      "system":{
         "os":{
            "hostname":"developer",
            "distro":"Debian",
            "distro_version":"11.0",
            "uptime":"10 days, 8 hours, 19 minutes, 3 seconds",
            "uptime_timestamp":1628929200
         },
         "processes":{
            "load_average":"0.00",
            "count":268,
            "biggest":{
               "command":"bash",
               "pid":"3098723",
               "cpu_usage":"2.0%"
            }
         }
      },
      "hardware":{
         "cpu":{
            "model":"Intel(R) Xeon(R) CPU E3-1245 v5 @ 3.50GHz",
            "frequency":"1200",
            "cores":8,
            "usage":"7.04%"
         },
         "mount_points":[
            {
               "mount_point":"/",
               "free":"554GB",
               "total":"936GB",
               "usage":"38%",
               "device":"/dev/md1"
            }
         ],
         "disks":[
            {
               "disk":"/dev/sda",
               "serial":"171416BD40D2",
               "temperature":35,
               "family_model":"Crucial/Micron Client SSDs",
               "model":"Micron_1100_MTFDDAK512TBN",
               "capacity":"512 GB",
               "smart_status":"PASSED"
            },
            {
               "disk":"/dev/sdb",
               "serial":"1711166727CA",
               "temperature":36,
               "family_model":"Crucial/Micron Client SSDs",
               "model":"Micron_1100_MTFDDAK512TBN",
               "capacity":"512 GB",
               "smart_status":"PASSED"
            },
            {
               "disk":"/dev/sdc",
               "serial":"1709160C0DFF",
               "temperature":36,
               "family_model":"Crucial/Micron Client SSDs",
               "model":"Micron_1100_MTFDDAK512TBN",
               "capacity":"512 GB",
               "smart_status":"PASSED"
            }
         ],
         "memory":{
            "used":"5229MB",
            "total":"64104MB",
            "usage":"8.16%"
         },
         "temperatures":{
            "cpu":33
         }
      }
   }
}
```


### Prerequisites

The daemon needs `ROOT` permissions and some packages such as :
* nc
* awk
* net-tools (`netstat`)
* lm-sensors (`sensors`)
* bc
* gawk
* jq
* netcat
* lsblk
* smartmontools (`smartctl`)

At first launch, it will try to install them automatically.

The installation process has been successfully tested on Debian/Ubuntu distributions.

### Installation & First Run

#### Procedure

- Make `install.sh` executable (chmod +x install.sh) and run it (./install.sh). It will copy the executable in `/usr/local/sbin/bashmonit`, and create configuration files in `/etc/bashmonit.d/` (for all sensors) and `/etc/bashmonit.conf` for general purposes
- run by typing `bashmonit`

#### Port configuration

The specified port (by default `8765`) must be free of use. If not, the daemon will display the following message :
`Port 8765 already in use, please free this port or configure another one.`

**3 solutions**
1. Release the port (if 80, it may be Apache or nginx)
2. Change the port in the INI file and relaunch the app
3. Check if a process is using your port by typing `lsof -i :8765` and kill the process if needed
 
**Reminder** the specified port must be accessible from your bashmonit client, so your firewall (such as `iptables`) must keep this port opened.

#### Key Configuration

To avoid unauthorized access to your monitoring system, a key must be specified using GET parameter `key`, such as : http://youserverip:port/?key=XXXXXXX
The key is automatically generated at first launch and stored in your configuration file.

### Advanced onfiguration

After installation, you can edit all sensors parameters by editing `/etc/bashmonit.d/*.conf` files (if any).
Eg. : for `mysql` sensors, you can edit MYSQL credentials in `/etc/bashmonit.d/apps-mysql.conf` 


### Use as a daemon

There's no daemon currently provided. So if you want to use it permanently, many tools provide this feature, such as :
- [Supervisor](http://supervisord.org/)
- [Node.js PM2](https://pm2.keymetrics.io/)
- [Node.js Forever](https://www.npmjs.com/package/forever)

#### Example with PM2

Make sure PM2 is installed (after installing nodejs, type `npm install -g pm2`)
1. type `pm2 --name bashmonit -f start /usr/local/sbin/bashmonit --interpreter=bash` to run the process in background
2. then type `pm2 save` to save this process to a file
3. finally type `pm2 startup` to ensure that the process will be relaunch if server is rebooted.


## Built With

* [netcat web server](https://forums.hak5.org/index.php?/topic/30075-bash-netcat-only-web-server/) - the base of bashttp

## Contributing

Please feel free to contribute by submitting enhancement or new sensors !

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/charlyie/bashmonit/tags). 

### Changelog

* **1.2.13** [aug 2021] : Add physical disk information & smart Status
* **1.2.12** [aug 2021] : Better support of OS Version detection
* **1.2.11** [aug 2021] : uptime in timestamp and sensors output in int while necessary
* **1.2.10** [aug 2021] : fix bad CPU % output
* **1.2.9** [aug 2021] : Enhanced update method
* **1.2.8** [aug 2021] : Changed CPU % usage method
* **1.2.7** [aug 2021] : Bad CPU core detection (not working fine in Containers)
* **1.2.6** [aug 2021] : Add --get-port method to retrieve PORT, and installer update.
* **1.2.5** [aug 2021] : Add --get-key method to retrieve APPKEY
* **1.2.4** [aug 2021] : Installer update
* **1.2.3** [jun 2021] : Distinguished JSON entry for OS version
* **1.2.2** [jun 2021] : changed disk json format
* **1.2.1** [jun 2021] : add cpu model and frequency to CPU sensor
* **1.2.0** [may 2021] : change default port, multiple disk sensor 
* **1.1.1** [nov 2019] : add autoupdate process 
* **1.1.0** [dec 2018] : first official release (published in nov. 2019).
* **1.0.0 - 1.0.9** [aug 2017-dec 2018]: internal releases.

## Authors

**Charles Bourgeaux** - *Initial work* - [reSmush.it](https://resmush.it)
See also the list of [contributors](https://github.com/charlyie/bashmonit/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


