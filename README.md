condecht
========

condecht is a software to deploy and remove configfiles and their depending packages. You can save all your configfiles of all hosts in one central place and distinguish all files the same time time. With a main database of 
With condecht you can store configurations of all your hosts in one (git/svn/bzr/whatever)-repository 
With a versioning system you get a synchronized config-file base, what you can use on every system.

Dependencies
------------

You have to install these perl-module:
* Config::IniFiles

Install it with `sudo cpan -i "Config::IniFiles"`

There modules Getopt::Long and Pod::Usage should be included in a standard perl installation. If not install them with `sudo cpan -i Getopt::Long Pod::Usage`.

Here is a list of all used modules:
* Config::IniFiles;
* Getopt::Long;
* Pod::Usage;
* File::Path;
* File::Copy;

I'm new and i wanna start right now!
------------------------------------

Go into the HOWTO-directory. Read the textfile HOWTO.

Main Files
----------
There are 3 Main Files:
* The condecht.pl Executable or the condecht command
* The /etc/condecht Configuration-File for condecht
* The packages.conf package-conf-file located at the root of your repo

condecht tree-structure
-----------------------
**ROOT**
* the executable:
  * condecht (link to condecht.pl)
  * condecht.pl
* the condecht-config
  * $condechthost/
   * $package/
    * config-files for $package

### The Tree
~ = CondechtRoot (defined in /etc/condecht)

* /etc/condecht
* ~/condecht.pl
* ~/condecht (link to condecht.pl)
* ~/packages.conf
* ~/$host/
* ~/$host/$package/
* ~/$host/$package/$config-file1
* ~/$host/$package/$config-file2
* ~/$host/$package/$config-fileX

USAGE
-----
condecht [OPTIONs] COMMAND $package

COMMANDs:
You have to combine at least two of those four options together
  * --pi @packages | Install @packages & config
  * --pr @packages | Remove @packages & config
  * --ci @packages | install config of @packages
  * --cr @packages | remove config of @packages

  * --lp | list the packages, configured in your packages.conf
	* --ba | backup all configuration files to $condechtPATH/backup.d/$host/$date/$package/$file

OPTIONs:
  * -c --config $file | take $file as alternative config-file for condecht
  *    --check        | check the config-file of condecht for errors (missing files, etc)
  *    --host $host   | Pretend to be on $host
  * -h --help         | print help and exit

ConfigFile condecht.conf
----------------------------
View the config-example.conf file in the root of the git repo for information.

Config-Sections
---------------
There are a few variables, which are important:

### /etc/condecht config-section
<table>
<tr>
	<th>Parameter</th>
	<th>Description</th>
</tr>
<tr>
	<td>host</td>
	<td>Defines, which host of your repository you have to use.</td>
</tr>
<tr>
	<td>dist</td>
	<td>This variable defines, which distribution condecht has to use to install the right packages. You can say, that every unique host has got every time the same distribution. But the same distribution doesn't say that you have got the same host.</td>
</tr>
<tr>
	<td>pkgINS</td>
	<td>Defines the command, which gets executed to remove a package.</td>
</tr>
<tr>
	<td>pkgREM</td>
	<td>Same as pkgINS, used to remove.</td>
</tr>
<tr>
	<td colspan=2>These Parameters are not used yet!</td>
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

###packages.conf config-section
<table>
<tr>
	<th>Parameter</th>
	<th>Description</th>
</tr>
<tr>
	<td>dist</td>
	<td>There are the packages of the system stored, which are going to get installed. A record contains the following data: the distro, followed by a colon, behind it listed the packages.</td>
</tr>
<tr>
	<td>file</td>
	<td>It describes the config-files, where they are stored, what name they have, which group/owner and the mode. For more, check out the sample packages.conf file.</td>
</tr>
<tr>
	<td>note</td>
	<td>This field will be displayed while installation. When you want to get reminded of sth, for example copy the keys to a specific place use it.</td>
</tr>
</table>

LICENSE
-------
Copyright 2013 by Benedikt Heine
Condecht is free software, you can distribute it and modify it under the terms of the GPL. You'll find it in the file LICENSE or at http://www.gnu.org/licenses/.

# LICENSE of the ./lib directory
The ./lib directory contains the Config::IniFile module, which is distributed under the same terms of perl (GPL). The copyright of the whole ./lib directory is at its different owners.

TODO
----
* Write some examples

Examples
--------

\#Empty
### Configuration
### Execution
