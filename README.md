condecht
========

**Condecht isn't even programmed. I just got the idea some days ago, so I'm just planning, how to run it!**

condecht is a software to deploy and remove configfiles and their depending packages.
You can use it with git or any other versioning system to deploy your config in every system you are administrating.
With a versioning system you get a synchronized config-file base, what you can use on every system.

Main Files
----------

There are 3 Main Files:
* The condecht.sh Executable
* The condecht.conf Configuration-File for condecht
* The hostdef.sh Executable for HostDetection

structure
---------

**ROOT**
* the executable:
  * condecht.sh
  * condecht (link)
* the condecht-config
  * condecht.conf

  * $condechtHOST/
   * $package.d/
    * config-files for $package
    * hooks.sh
      * The following functions have to be defined in the hooks.sh
      * pre/post
      * pkg/config: executed when config or pkg installed/removed
      * install/remove: after installation or remove
      * you can combine these 6 definitions together
      * example: function post-pkg-install {....

### The Tree
~ = CondechtRoot

* ~/condecht.sh
* ~/condecht
* ~/condecht.conf
* ~/hostdef.sh
* ~/$condechtHOST/
* ~/$condechtHOST/$package.d/
* ~/$condechtHOST/$package.d/

execution
---------

condecht COMMAND [OPTIONs] $package
COMMANDs:
You have to combine at least two of those four options together
* -p 	| Install/Remove package & config
* -c	| only deploy/remove config
* -i	| install package/config
* -r	| remove package/config

* -u	| update repository
* -U	| Update Configfiles

OPTIONs:
  * -b --backup			| save the config-file of the destination (overwrites values, specified in the condecht-config)
  * -B --no-backup		| don't backup the config file of the destination (overwrites values, specified in the condecht-config)
  * -a --config $file		| take $file as alternative config-file for condecht
  * -C --check			| check the config-file of condecht for errors (missing files, etc)
  * -h --help			| print help and exit

ConfigFile condecht.conf
----------------------------

View the example-config.conf file in the root of the git repo for information.

HostDetectionScript hostdef.sh 
------------------------------

This script is used to detect on which host you are right now. You have to program it yourself. condecht is aiming to have one repository with configurations on many hosts. This script will get sourced by condecht and you have to get 

It should define at least 6 variables:

* $condechtHOST
* $condechtDIST
* $pkgINS
* $pkgREM
* $repServerUPD
* $repClientUPD


Variables
---------

There are a few variables, which are important:

<table>
<tr>
	<td>$condechtHOST</td>
	<td>This variable defines, which host of your repository you have to use.</td>
</tr>
<tr>
	<td>$condechtDIST</td>
	<td>This variable defines, which distribution condecht has to use to install the right packages. You can say, that every unique host has got every time the same distribution. But the same distribution doesn't say that you have got the same host.</td>
</tr>
<tr>
	<td>$pkgINS</td>
	<td>Defines the command, which get executed to remove a package.</td>
</tr>
<tr>
	<td>$pkgREM</td>
	<td>Same as $pkgINS, used to remove.</td>
</tr>
<tr>
	<td>$repServerUPD</td>
	<td>The command, Update your master repository, to update recent updated files</td>
</tr>
<tr>
	<td>$repClientUPD</td>
	<td>The command, to get the latest version of your master repo.</td>
</tr>
</table>

Brainstorm
----------
* Backup des orginalen config-files
* Wenn hostname nicht eindeutig, aus $datei auslesen
* Conf-dir Prefix

Examples
--------

### Configuration
### Execution
