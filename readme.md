# bashmonit

*Server Monitoring tool, based in bash, extensible with custom sensors, and outputing a JSON on a standalone HTTP server (without need of Apache nor nginx). This script has to be exploited with an external webinterface.*

## Getting Started

* Clone the GIT repo
* Make the installer file available for execution (`chmod +x install.sh`)
* At first launch, it will create your configuration files, and will be ready.
* Once launched, visit http://youserverip:8765/?key=XXXXXXX (replace XXXXXXX by the key provided).

### Output example

```json
{
   "system":{
      "daemon":"bashmonit/1.2.1",
      "generation_date":"Mon May  24 18:21:06 CEST 2021"
   },
   "sensors":{
      "hardware":{
         "cpu":{
            "model": "AMD Opteron(tm) Processor 4386",
            "frequency": "3400",
            "cores":"8",
            "usage":"41%"
         },
         "disks":{
            "/":{
               "free":"4.0G",
               "total":"37G",
               "usage":"90%",
               "device":"/dev/sda2"
            },
            "/srv":{
               "free":"2.0T",
               "total":"37T",
               "usage":"95%",
               "device":"/dev/sda3"
            }
         },
         "memory":{
            "used":"405MB",
            "total":"2000MB",
            "usage":"20.25%"
         },
         "temperatures":{
            "cpu":"35"
         }
      },
      "apps":{
         "mysql":{
            "status":"online"
         },
         "php":{
            "version":"7.1.8-2+ubuntu16.04.1+deb.sury.org+4"
         }
      },
      "system":{
         "os":{
            "hostname":"developer",
            "distro":"Ubuntu 16.04",
            "uptime":"1 days, 22 hours, 12 minutes, 48 seconds"
         },
         "processes":{
            "load_average":"0.06",
            "count":"160",
            "biggest":{
               "command":"[kworker/0:2]",
               "pid":"6328",
               "cpu_usage":"0.8%"
            }
         }
      }
   }
}
```


### Prerequisites

The daemon needs `ROOT` permissions and some packages such as :
* nc
* awk
* netstat
* sensors
* bc
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
* **1.2.0** [may 2021] : add cpu model and frequency to CPU sensor
* **1.2.0** [may 2021] : change default port, multiple disk sensor 
* **1.1.1** [nov 2019] : add autoupdate process 
* **1.1.0** [dec 2018] : first official release (published in nov. 2019).
* **1.0.0 - 1.0.9** [aug 2017-dec 2018]: internal releases.

## Authors

**Charles Bourgeaux** - *Initial work* - [reSmush.it](https://resmush.it)
See also the list of [contributors](https://github.com/charlyie/bashmonit/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


