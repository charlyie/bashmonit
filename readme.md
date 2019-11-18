# bashmonit

*Server Monitoring tool, based in bash, extensible with custom sensors, and outputing a JSON on a standalone HTTP server (without need of Apache nor nginx). This script has to be exploited with an external webinterface.*

## Getting Started

* After downloading from GIT repo, place it, for example, in your /opt folder. 
* Make the bashmonit.sh file available for execution (`chmod +x bashmonit.sh`)
* At first launch, it will create your INI configuration file, and will be ready.
* Once launched, visit http://youserverip:80/?key=XXXXXXX (replace XXXXXXX by the key provided).


### Prerequisites

The daemon needs `ROOT` permissions and some packages such as :
* nc
* awk
* netstat
* sensors
* bc
At first launch, it will try to install them automatically.


### First Run

#### Port configuration

The specified port (by default `80`) must be free of use. If not, the daemon will display the following message :
`Port 80 already in use, please free this port or configure another one.`
**2 solutions**
1. Release the port (if 80, it may be Apache or nginx)
2. Change the port in the INI file and relaunch the app
 
**Reminder** the specified port must be accessible from your bashmonit client, so your firewall (such as `iptables`) must keep this port opened.

#### Key Configuration

To avoid unauthorized access to your monitoring system, a key must be specified using GET parameter `key`, such as : http://youserverip:port/?key=XXXXXXX
The key is automatically generated at first launch and stored in your INI configuration file.


#### Output example
```json
{
    "system": {
        "daemon": "bashmonit/1.0.8",
        "generation_date": "Thu Sep  7 15:21:06 CEST 2017"
    },
    "sensors": {
        "hardware": {
            "cpu": {
                "usage": "41%",
                "cores": "2"
            },
            "disk": {
                "free": "33G",
                "total": "39G",
                "usage": "12%"
            },
            "memory": {
                "used": "405MB",
                "total": "2000MB",
                "usage": "20.25%"
            },
            "temperatures": {
                "cpu": "35"
            }
        },
        "apps": {
            "mysql": {
                "status": "online"
            },
            "php": {
                "version": "7.1.8-2+ubuntu16.04.1+deb.sury.org+4"
            }
        },
        "system": {
            "os": {
                "hostname": "developer",
                "distro": "Ubuntu 16.04",
                "uptime": "1 days, 22 hours, 12 minutes, 48 seconds"
            },
            "processes": {
                "load_average": "0.06",
                "count": "160",
                "biggest": {
                    "command": "[kworker/0:2]",
                    "pid": "6328",
                    "cpu_usage": "0.8%"
                }
            }
        }
    }
}
```


## Built With

* [bashttp](http://www.dropwizard.io/1.0.2/docs/) - The base http shell script
* [netcat web server](https://forums.hak5.org/index.php?/topic/30075-bash-netcat-only-web-server/) - the base of bashttp

## Contributing

Please feel free to contribute by submitting enhancement or new sensors !

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/charlyie/bashmonit/tags). 

### Changelog
* **1.1.0** [dec 2018] : first official release.
* **1.0.0 - 1.0.9** [aug 2017-dec 2018]: internal releases.

## Authors

**Charles Bourgeaux** - *Initial work* - [PurpleBooth](https://resmush.it)
See also the list of [contributors](https://github.com/charlyie/bashmonit/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


