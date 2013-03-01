#!/usr/bin/env perl

# vim set ts=2; 
#
#   Copyright (C) 2013, Benedikt Heine
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#   You'll find the GNU General Public License in the file
#   with the name LICENSE.
#

##LOAD MODULES ##
use warnings;
use strict;
# extra modules
use lib "./lib";
use Config::IniFiles;
# standard modules
use Getopt::Long;
use Pod::Usage;
use File::Path;
use File::Copy;
use File::Basename;
##END LOAD MODULES ##

##DECLARE EMPTY VARIABLES ##
my $mode;    #decide, whether install/remove config/package
my @syspkgs; #packages for the system packagemanager
my @pkgs;    #packages of condecht to install
my %main;    #the information of the main-section in $config_main
my %files;   #all values of the parameter file at the depending
             #sections to all @pkgs
my @notes;   #saves all notes, to print them at the end again
##END DECLARE EMPTY VARIABLES ##

##DEFAULT VARIABLES ##
my $config_main = "/etc/condecht";
my $config_pkg = "packages.conf";
##END DEFAULT VARIABLES ##

##FUNCTIONS ##
sub hook {
	for my $package (@pkgs){
		if(-x $main{path} . $main{host} . "/" . $package . "/" . $_[0]){
			system $main{path} . $main{host} . "/" . $package . "/" . $_[0];
			if($? != 0){
				warn "The hook $_[0] of $package reported the error-code $?. Do you want to continue? [y/N]";
				unless(<STDIN> =~ /y/i){
					die "Stopped while installing the packages. You may have to fix some errors.\n";
				}
			}
		}
	}
}
##END FUNCTIONS ##

##READ COMMAND LINE PARAMETERS ##
GetOptions(
	# general options
	"c|config=s"	=> \$config_main,
	"h|host=s"		=> \$main{host},
	"d|dir=s"			=> \$main{home},
	"g|group=s"		=> \$main{group},
	"u|user=s"		=> \$main{user},
	"v|verbose"		=> \$main{verb},
	"debug"				=> \$main{debug},
	"p|prefix=s"	=> \$main{prefix},
	"opt=s%"			=> \%main,
	"help"				=> sub { pod2usage(1) },
	# install/remove configs/packages
	"pi=s{,}"			=> sub { if(!$mode or ($mode eq "pi")){ $mode = "pi"; shift(@_); push @pkgs, @_; } else { exit(1); }},
	"pr=s{,}"			=> sub { if(!$mode or ($mode eq "pr")){ $mode = "pr"; shift(@_); push @pkgs, @_; } else { exit(1); }},
	"ci=s{,}"			=> sub { if(!$mode or ($mode eq "ci")){ $mode = "ci"; shift(@_); push @pkgs, @_; } else { exit(1); }},
	"cr=s{,}"			=> sub { if(!$mode or ($mode eq "cr")){ $mode = "cr"; shift(@_); push @pkgs, @_; } else { exit(1); }},
	# list packages
	"lp"					=> sub { if(!$mode){ $mode = "lp"; } else { exit(1); }},
	# backup
	"b|backup"		=> sub { if(!$mode){ $mode = "ba"; } else { exit(1); }},
	# check config
	"check"				=> sub { if(!$mode){ $mode = "cc"; } else { exit(1); }},
);
##CHECK PARAMETERS ##
if(!$mode){
	die "No mode specified!\n";
}
if($main{debug}){
	warn "The option debug is not in use yet!\n";
}
if(!$main{prefix}){
	$main{prefix} = "";
}
##END CHECK PARAMETERS ##
##END READ COMMAND LINE PARAMETERS ##

##INIT CONFIG_MAIN ##
my $cfg = Config::IniFiles->new(-file => $config_main, -nocase => 1) or die "@Config::IniFiles::errors";
##END INIT MAIN CONFIG ##

##READ CONFIG_MAIN ##
if($cfg->SectionExists("main")){
	for(("path", "backup", "host", "dist", "pkgINS", "pkgREM", "user", "group", "home", "defperm")){
		if(defined $cfg->val("main", $_)){
			# the value of the config file will be written into the $main{$_}
			# only if it is not defined over commandline already
			if(!$main{$_}){
				$main{$_} = $cfg->val("main", $_);
			}
		}
		else {
			die "Couldn't find definition of $_ in config-file $config_main\n";
		}
	}
}
else {
	die "No Section main defined in config-file $config_main\n";
}
##END READ CONFIG_MAIN ##

##CHECK CONFIG_MAIN ##

#CHECK: values of main config
# add trailing space to execute systemcommand in an appropriate way
$main{pkgINS} = $main{pkgINS} . " "
	unless($main{pkgINS} =~ / $/);
$main{pkgREM} = $main{pkgREM} . " "
	unless($main{pkgREM} =~ / $/);

#CHECK: user and group existence
#  -> if exists write into $main{uid/gid}
if(defined getpwnam($main{user})){
	$main{uid} = (getpwnam($main{user}))[2];
}
else {
	die "MAIN: The user $main{user} does not exist!\n";
}
if(defined getgrnam($main{group})){
	$main{gid} = (getgrnam($main{group}))[2];
}
else {
	die "MAIN: The group $main{group} does not exist!\n";
}

#CHECK: absolute path and trailing shlash of home and path
unless($main{path} =~ /\/$/){
	$main{path} = $main{path} . "/";
}
unless($main{path} =~ /^\//){
	die "CONFIG: definition of path is no absolute path in $config_main\n";
}
unless($main{home} =~ /\/$/){
	$main{home} = $main{home} . "/";
}
unless($main{home} =~ /^\//){
	die "CONFIG: definition of home is no absolute path in $config_main\n";
}

#CHECK: defperm
if(length($main{defperm}) == 3){
	$main{defperm} = "0$main{defperm}";
}
else {
	die "MAIN: permissions in defperm are not valid\n";
}
for my $char (split(//, $main{defperm})){
	die "MAIN: permissions in defperm are not valid\n"
		if(!(0 <= $char && $char <= 7));
}

# set path of packages.conf file
$main{config_pkg} = $main{path} . $config_pkg;
##END CHECK CONFIG_MAIN ##

##INIT PACKAGES-CONFIG ##
my $pkg = Config::IniFiles->new(-file => $main{config_pkg}, -nocase => 1) or die "@Config::IniFiles::errors";
##END INIT PACKAGES CONFIG ##

##DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##
# list packages
if($mode eq "lp"){
	for my $package ($pkg->Groups){
		print "$package\n";
	}
	exit(0);
}

##CHECK CONFIG_PKG ##
if($mode eq "cc"){
	print "packages.conf location: $main{config_pkg}\n";

	# $pkg->Groups: use all packages to check whole config
	for my $package ($pkg->Groups){
		#CHECK: Section Exists
		unless($pkg->SectionExists("$package all")){
			warn "$package: section [$package all] does not exist\n";
			continue;
		}

		#CHECK: Section Exsists for host
		unless($pkg->SectionExists("$package $main{host}")){
			warn "$package: section [$package $main{host}] does not exist\n";
		}

		#PRINT: Every note of Sections
		for my $note ($pkg->val("$package all", "note"), $pkg->val("$package $main{host}", "note")){
			print "$package: note: $note\n";
		}
		
		#CHECK: System packages
		my $count = 0;
		for my $dist ($pkg->val("$package all", "dist"), $pkg->val("$package $main{host}", "dist")){
			if($dist =~ /^$main{dist}\s*:(.*)/){
				push @syspkgs, split(" ", $1);
				$count++;
			}
		}
		warn "$package: No Systempackages are defined for your distribution\n"
			if($count == 0);
	
		#CHECK: Dependencies
		for my $dep ($pkg->val("$package all", "deps"), $pkg->val("$package $main{host}", "deps")){
			for(split(" ", $dep)){
				warn "$package: unresolved dependency $_\n"
					unless($pkg->SectionExists("$_ all"));
			}
		}

		#CHECK: Every File
		for my $file ($pkg->val("$package all", "file"), $pkg->val("$package $main{host}", "file")){
			my ($fdest,$ffile,$fmode,$fuser,$fgroup) = split(",", $file);
			my ($fuid, $fgid);

			# replace the strings $home$ $user$ and $group$
			$fdest =~ s/\$home\$\//$main{home}/; # used to prevent a double slash after home-dir
			$fdest =~ s/\$home\$/$main{home}/;
			$fuser =~ s/\$user\$/$main{user}/;
			$fgroup =~ s/\$group\$/$main{group}/;

			$ffile = "$main{path}$main{host}/$package/$ffile";
			$fdest = $main{prefix} . $fdest;
	
			if($files{$fdest}){
				warn "$package: duplicate definiton of file $fdest\n";
			}

			# check config, if all users are existing, groups too
			# check if user exists, if yes -> write uid to $fuid
			if(defined getpwnam($fuser)){
				$fuid = (getpwnam($fuser))[2];
			}
			else {
				warn "$package: The user $fuser does not exist\n";
			}
			# same as above, just for the group
			if(defined getgrnam($fgroup)){
				$fgid = (getgrnam($fgroup))[2];
			}
			else {
				warn "$package: The group $fgroup does not exist\n";
			}

			$files{$fdest} = join(",", ($fdest, $ffile, $fmode, $fuser, $fuid, $fgroup, $fgid));
			
			#check the file-existence
			# check for installed files
			# check for permissions, owner, group of installed files
			if(-f $fdest){
				#check filemode
				if($fmode != sprintf "%o\n", (stat($fdest))[2] & 07777){
					warn "$package: FILE: File $fdest has not mode $fmode\n";
				}

				#read uid and gid of files
				my ($efuid, $efgid) = (stat($fdest))[4,5];
				#transform uid and gid to usernames
				my $efgroup = getgrgid($efgid);
				my $efowner = getpwuid($efuid);

				#warn if uid and gid are not the same as defined in packages.conf
				warn "$package: FILE: File $fdest has user $efowner($efuid) instead of $fuser($fuid)\n"
					if($fuid != $efuid);
				warn "$package: FILE: File $fdest has group $efgroup($efuid) instead of $fgroup($fgid)\n"
					if($fgid != $efgid);
			}
			else {
				warn "$package: FILE: File $fdest is not available.\n";
			}
			# check config, if all files are in repo
			if(! -f $ffile){
				warn "$package: REPO: File $ffile is not available.\n";
			}
		}
	}
	print "Registered system-packages:\n@syspkgs\n";
}
##END CHECK CONFIG_PKG ##

##BACKUP ##
if($mode eq "ba"){
	# get date of $today
	my ($mday,$mon,$year) = (localtime(time))[3,4,5];
	$year = $year + 1900;
	$mon = $mon + 1;
	my $today = "$mday-$mon-$year";

	#SAVE: $config_main
	copy($config_main, "$main{path}backup.d/$main{host}/$today/condecht");
	chmod oct($main{defperm}), "$main{path}backup.d/$main{host}/$today/condecht";
	chown $main{uid}, $main{gid}, "$main{path}backup.d/$main{host}/$today/condecht";

	for my $package ($pkg->Groups){
		#SAVE: files
		for my $file ($pkg->val("$package all", "file"), $pkg->val("$package $main{host}", "file")){

			my ($fdest,$ffile,$fmode,$fowner,$fgroup) = split(",", $file);
			$fdest =~ s/\$home\$\//$main{home}/; # used to prevent a double slash after home-dir
			$fdest =~ s/\$home\$/$main{home}/;

			# create the full path
			mkpath( "$main{path}backup.d/$main{host}/$today/$package/",
							{ owner => $main{user}, group => $main{group}, mode => oct($main{defperm}) }
			);

			# copy, chmod and chown
			copy($fdest, "$main{path}backup.d/$main{host}/$today/$package/$ffile");
			chmod oct($main{defperm}), "$main{path}backup.d/$main{host}/$today/$package/$ffile";
			chown $main{uid}, $main{gid}, "$main{path}backup.d/$main{host}/$today/$package/$ffile";
		}

		#SAVE: hooks
		for my $hook ("pre", "pre_pkg_install", "post_pkg_install", "pre_config_remove",
									"post_config_remove", "pre_pkg_remove", "post_pkg_remove",
									"pre_config_install", "post_config_install", "post"){
			# check if file available -> create path only, if there are hooks
			if( -f $main{path} . $main{host} . "/" . $package . "/" . $hook){

				# create the full path
				mkpath( "$main{path}backup.d/$main{host}/$today/$package/",
								{ owner => $main{user}, group => $main{group}, mode => oct($main{defperm}) }
				);

				# copy, chmod and chown
				copy($main{path} . $main{host} . "/" . $package . "/" . $hook,
						"$main{path}backup.d/$main{host}/$today/$package/$hook");
				chmod oct($main{defperm}), "$main{path}backup.d/$main{host}/$today/$package/$hook";
				chown $main{uid}, $main{gid}, "$main{path}backup.d/$main{host}/$today/$package/$hook";
			}
		}
	}
}
##END BACKUP ##
##END DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##

##READ CONFIG_PKG ##
for my $package (@pkgs){ #CHECK: Section Exists
	unless($pkg->SectionExists("$package all")){
		die "$package: section [$package all] doesn't exist.\n";
	}

	#CHECK: Section Exsists for host
	unless($pkg->SectionExists("$package $main{host}")){
		warn "$package: section [$package $main{host}] doesn't exist.\n"
				if($main{verbose});
	}
	#PRINT: notes and save them to @notes (will print it at the end again)
	for my $note ($pkg->val("$package all", "note"), $pkg->val("$package $main{host}", "note")){
		print "$package: $note\n";
		push @notes, "$package: $note";
	}

	#READ: systempackages for distribution
	my $count = 0;
	for my $dist ($pkg->val("$package all", "dist"), $pkg->val("$package $main{host}", "dist")){
		if($dist =~ /^$main{dist}\s*:(.*)/){
			push @syspkgs, split(" ", $1);
			$count++;
		}
	}
	warn "$package: No Systempackages are defined for your distribution\n"
		if($count == 0 && $main{verbose});

	#READ: Dependencies
	for my $dep ($pkg->val("$package all", "deps"), $pkg->val("$package $main{host}", "deps")){
		for(split(" ", $dep)){
			print "ADDED package $_ as dependency from $package\n"
				if($main{verbose});
##todo
			warn "$package: unresolved dependency $_\n"
				unless($pkg->SectionExists("$_ all"));
			push @pkgs, $_;
		}
	}

	#READ: Every File
	for my $file ($pkg->val("$package all", "file"), $pkg->val("$package $main{host}", "file")){
		my ($fdest,$ffile,$fmode,$fuser,$fgroup) = split(",", $file);
		my ($fuid, $fgid);

		# replace the strings $home$ $user$ and $group$
		$fdest =~ s/\$home\$\//$main{home}/; # used to prevent a double slash after home-dir
		$fdest =~ s/\$home\$/$main{home}/;
		$fuser =~ s/\$user\$/$main{user}/;
		$fgroup =~ s/\$group\$/$main{group}/;

		$ffile = "$main{path}$main{host}/$package/$ffile";
		$fdest = $main{prefix} . $fdest;

		if($files{$fdest}){
			warn "$package: duplicate definiton of:\n$files{$ffile}\nwith\n$file\n"
				if($main{verbose});
		}

		# check config, if all users are existing, groups too
		# check if user exists, if yes -> write uid to $fuid
		if(defined getpwnam($fuser)){
			$fuid = (getpwnam($fuser))[2];
		}
		else {
			die "$package: The user $fuser does not exist\n";
		}
		# same as above, just for the group
		if(defined getgrnam($fgroup)){
			$fgid = (getgrnam($fgroup))[2];
		}
		else {
			die "$package: The group $fgroup does not exist\n";
		}

		$files{$fdest} = join(",", ($fdest, $ffile, $fmode, $fuser, $fuid, $fgroup, $fgid));
	}
}
##END READ CONFIG_PKG ##

hook("pre");

#MODE: install packages
if($mode eq "pi"){
	hook("pre_pkg_install");

	# execute package install command
	system $main{pkgINS} . join(" ", @syspkgs);

	# catch the error code
	if($? != 0){
		warn "The packagemanager returned the error code $?. Continue installing configfiles? [y/N]";
		unless(<STDIN> =~ /y/i){
			die "Stopped while installing the packages. You may have to fix some errors.\n";
		}
	}

	hook("post_pkg_install");
}

#MODE: remove configs (packages)
if($mode eq "cr" || $mode eq "pr"){
	hook("pre_config_remove");

	for my $file (values %files){
		my ($fdest) = split(",", $file);

		if($main{backup}){
			my $fdest2 = $fdest;
			$fdest2 =~ s/^\///;
			$fdest2 =~ s/\//-/g;
			$fdest2 =~ s/\.//g;
			
			copy($fdest, "$main{path}backup.d/$main{host}/old/$fdest2")
				or warn "Could not backup file $fdest\n";
			chmod oct($main{defperm}), "$main{path}backup.d/$main{host}/old/$fdest2";
			chown $main{uid}, $main{gid}, "$main{path}backup.d/$main{host}/$fdest2";
		}
		unlink($fdest)
			or warn "Could not remove file $fdest\n";
	}
	
	hook("post_config_remove");
}
	
#MODE: remove packages
if($mode eq "pr"){
	hook("pre_pkg_remove");

	# execute package remove command
	system $main{pkgREM} . @syspkgs;

	# catch the error code
	if($? != 0){
		warn "The packagemanager returned the error code $?. Continue removing configfiles? [y/N]";
		unless(<STDIN> =~ /y/i){
			die "Stopped while removing the packages. You may have to fix some errors.\n";
		}
	}
	
	hook("post_pkg_remove");
}
	
#MODE: install configs (packages)
if($mode eq "ci" || $mode eq "pi"){
	hook("pre_config_install");
	
	for my $file (values %files){
		my ($fdest,$ffile,$fmode,$fowner,$fuid,$fgroup,$fgid) = split(",", $file);

		##todo
		# check if $fmode permissions are executable
		#
		if($fmode =~ /^(0|2|4|6)/){
			mkpath(dirname($fdest), 
				{ owner => $fowner, group => $fgroup, mode => oct($fmode + 100) }
			);
		}
		else {
			mkpath(dirname($fdest), 
				{ owner => $fowner, group => $fgroup, mode => oct($fmode) }
			);
		}

		copy($ffile, $fdest)
			or warn "Could not copy the file to $fdest\n";
		chmod oct($fmode), $fdest;
		chown $fuid, $fgid, $fdest;
	}
	
	hook("post_config_install");
}
	
hook("post");

exit(0);

__END__
=head1 NAME

Condecht

=head2 Condecht
Condecht is a config-file distribution software.

=head1 SYNOPSIS

condecht <ACTION> @packages

=over 8

=item B<--help>

Print this help-page.

=item B<--ci>


=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut
