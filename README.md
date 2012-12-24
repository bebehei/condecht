condecht
========
condecht is a software to deploy and remove configfiles and their depending packages.
You can use it with git or any other versioning system to deploy your config in every system you are administrating.
With a versioning system you get a synchronized config-file base, what you can use on every system.

Main Files
----------
There are 3 Main Files:
* The condecht.pl Executable or the condecht command
* The /etc/condecht Configuration-File for condecht
* The $PATH/packages.conf package-conf-file

structure
---------
**ROOT**
* the executable:
  * condecht (link to condecht.pl)
* the condecht-config
  * $condechtHOST/
   * $package.d/
    * config-files for $package

### The Tree
~ = CondechtRoot

* ~/condecht.pl
* ~/condecht (link to condecht.pl)
* /etc/condecht
* ~/packages.conf
* ~/host-$HOST.d/
* ~/host-$HOST.d/$package.d/
* ~/host-$HOST.d/$package.d/

execution
---------
condecht COMMAND [OPTIONs] $package
COMMANDs:
You have to combine at least two of those four options together
* -pi @packages	| Install @packages & config
* -pr	@packages	| Remove @packages & config
* -ci	@packages	| install config of	@packages
* -cr	@packages	| remove config of @packages

* -u	| update repository
* -U	| Update Configfiles

OPTIONs:
  * -a --config $file		| take $file as alternative config-file for condecht
  *    --check					| check the config-file of condecht for errors (missing files, etc)
  * -h --help						| print help and exit

ConfigFile condecht.conf
----------------------------
View the config-example.conf file in the root of the git repo for information.

Variables
---------
There are a few variables, which are important:

### Host config-section
<table>
<tr>
	<td>host</td>
	<td>This variable defines, which host of your repository you have to use.</td>
</tr>
<tr>
	<td>distro</td>
	<td>This variable defines, which distribution condecht has to use to install the right packages. You can say, that every unique host has got every time the same distribution. But the same distribution doesn't say that you have got the same host.</td>
</tr>
<tr>
	<td>pkgINS</td>
	<td>Defines the command, which get executed to remove a package.</td>
</tr>
<tr>
	<td>pkgREM</td>
	<td>Same as pkgINS, used to remove.</td>
</tr>
<tr>
	<td>repServerUpd</td>
	<td>The command, Update your master repository, to update recent updated files</td>
</tr>
<tr>
	<td>repClientUpd</td>
	<td>The command, to get the latest version of your master repo.</td>
</tr>
</table>

### General config-section
<table>
<tr>
	<td></td>
	<td></td>
</tr>
<tr>
	<td></td>
	<td></td>
</tr>
<tr>
	<td></td>
	<td></td>
</tr>
<tr>
	<td></td>
	<td></td>
</tr>
<tr>
	<td></td>
	<td></td>
</tr>
<tr>
	<td></td>
	<td></td>
</tr>
</table>


### pkg:$package:$hostname config-section
<table>
<tr>
	<td>pkg</td>
	<td>Just a little redundancy to verify the data in the section. It is not necessary yet but maybe later.</td>
</tr>
<tr>
	<td>syspkg</td>
	<td>There are the packages of the system stored, which are going to get installed. A record contains the following data: the distro, followed by a colon, behind it listed the packages.</td>
</tr>
<tr>
	<td></td>
	<td></td>
</tr>
<tr>
	<td></td>
	<td></td>
</tr>
<tr>
	<td></td>
	<td></td>
</tr>
<tr>
	<td></td>
	<td></td>
</tr>
</table>


Brainstorm
----------
* Backup des orginalen config-files -> /etc/condecht->main->backup
	* Getopt muss noch $backup lesen
* Wenn hostname nicht eindeutig, aus $datei auslesen -> /etc/condecht
* Conf-dir Prefix -> path

TODO
----

Examples
--------

### Configuration
### Execution
