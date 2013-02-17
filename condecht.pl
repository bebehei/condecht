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
#   You'll find the GPL in the LICENSE file.
#

##LOAD MODULES
use warnings;
use strict;
use lib "./lib";
use Config::IniFiles;
##standard modules
use Getopt::Long;
use Pod::Usage;
use File::Path;
use File::Copy;
##END LOAD MODULES

##DECLARE EMPTY VARIABLES
my $mode;    #decide, whether install/remove config/package
my @syspkgs; #packages for the system packagemanager
my @pkgs;    #packages of condecht to install
my %main;    #the information of the main-section in $config_main
my %files;   #all values of the parameter file at the depending
             #sections to all @pkgs
##DECLARE EMPTY VARIABLES

## DEFAULT VARIABLES
my $config_main = "/etc/condecht";
my $config_pkg = "packages.conf";
##END DEFAULT VARIABLES

##HOOK-Functions
sub hook {
	for my $package (@pkgs){
		if(-x $main{path} . $main{host} . "/" . $package . "/" . $_[0]){
			system $main{path} . $main{host} . "/" . $package . "/" . $_[0];
			if($? != 0){
				warn "The hook $_[0] of $package reported the error-code $?. Do you want to continue? [y/N]";
				unless(<STDIN> =~ /y/i){
					die "Stopped while installing the packages. You may have to fix some errors.";
				}
			}
		}
	}
}
##END USED FUNCTIONS

##READ COMMAND LINE PARAMETERS ##
GetOptions(
	##general options
	"c|config=s"	=> \$config_main,
	"h|host=s"		=> \$main{host},
	"d|dir=s"			=> \$main{home},
	"g|group=s"		=> \$main{group},
	"u|user=s"		=> \$main{user},
	"opt=s%"			=> \%main,
	"check"				=> sub { if(!$mode){ $mode = "cc"; } else { exit(1); }},
	"help"				=> sub { pod2usage(1) },
	##install/remove configs/packages
	"pi=s{,}"			=> sub { if(!$mode or ($mode eq "pi")){ $mode = "pi"; shift(@_); push @pkgs, @_; } else { exit(1); }},
	"pr=s{,}"			=> sub { if(!$mode or ($mode eq "pr")){ $mode = "pr"; shift(@_); push @pkgs, @_; } else { exit(1); }},
	"ci=s{,}"			=> sub { if(!$mode or ($mode eq "ci")){ $mode = "ci"; shift(@_); push @pkgs, @_; } else { exit(1); }},
	"cr=s{,}"			=> sub { if(!$mode or ($mode eq "cr")){ $mode = "cr"; shift(@_); push @pkgs, @_; } else { exit(1); }},
	##list packages
	"lp"					=> sub { if(!$mode){ $mode = "lp"; } else { exit(1); }},
	##backup
	"b|backup"		=> sub { if(!$mode){ $mode = "ba"; } else { exit(1); }},
);
##CHECK PARAMETERS
if(!$mode){
	die "no mode specified!";
}
##END CHECK PARAMETERS

##READ MAIN CONFIG ##
my $cfg = Config::IniFiles->new(-file => $config_main, -nocase => 1) or die "@Config::IniFiles::errors";
if($cfg->SectionExists("main")){
	for(("path", "backup", "host", "dist", "pkgINS", "pkgREM", "repServerUpd", "repClientUpd", "user", "group", "home", "defperm")){
		if(defined $cfg->val("main", $_)){
			##the value of the config file will be written into the $main{$_}
			## only if it is not defined over commandline already
			if(!$main{$_}){
				$main{$_} = $cfg->val("main", $_);
			}
			if($_ eq 'path'){
				##add trailing slash
				unless($main{path} =~ /\/$/){
					$main{path} = $main{path} . "/";
				}
				unless($main{path} =~ /^\//){
					die "Path is no absolute path";
				}
				if(!$main{config_pkg}){
					$main{config_pkg} = $main{path} . $config_pkg;
				}
			}
			if($_ eq 'home'){
				##add trailing slash
				unless($main{home} =~ /\/$/){
					$main{home} = $main{home} . "/";
				}
				unless($main{home} =~ /^\//){
					die "Home is no absolute path";
				}
			}
			if($_ eq "user"){
					$main{uid} = getpwnam($main{user});
			}
			if($_ eq "group"){
					$main{gid} = getgrnam($main{group});
			}
			if($_ eq "defperm"){
				if(length($main{defperm}) == 3){
					$main{defperm} = "0$main{defperm}";
				}
				if(length($main{defperm}) != 4){
					die "permissions in defperm are not valid";
				}
				for my $char (split(//, $main{defperm})){
					die "permissions in defperm are not valid"
						if(!(0 <= $char && $char <= 8));
				}
			}
			if($_ eq "pkgINS" || $_ eq "pkgREM" || $_ eq "repServerUpd" || $_ eq "repClientUpd"){
				unless($main{$_} =~ / $/){
					$main{$_} = $main{$_} . " ";
				}
			}
		}
		##later remove this elsif, when repServer* is implemented
		elsif($_ eq "repServerUpd" || $_ eq "repClientUpd"){
			##these options are not necessary yet
			$main{$_} = "";
		}
		else {
			die "Couldn't find definition of $_ in config-file $config_main";
		}
	}
}
else {
	die "No Section host defined in config-file $config_main";
}
undef $cfg;
##END READ MAIN CONFIG


##INIT PACKAGES-CONFIG
my $pkg = Config::IniFiles->new(-file => $main{config_pkg}, -nocase => 1) or die "@Config::IniFiles::errors";
##END INIT PACKAGES CONFIG

##DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##
if($mode eq "lp"){
	for my $package ($pkg->Groups){
		print "$package\n";
	}
	exit(0);
}
#check config
if($mode eq "cc"){
	die "check config not implemented";
	#checkconfig();
	#brainstorm: what to check;
	# check for installed files
	# check for permissions, owner, group of installed files
	# check config, if all files are in repo
	# check config, if all users are existing, groups too
}

if($mode eq "ba"){
	my ($mday,$mon,$year) = (localtime(time))[3,4,5];
	$year = $year + 1900;
	$mon = $mon + 1;

	#snapshot main config-file
	copy($config_main, "$main{path}backup.d/$main{host}/$mday-$mon-$year/condecht");
	chmod oct($main{defperm}), "$main{path}backup.d/$main{host}/$mday-$mon-$year/condecht";
	chown $main{uid}, $main{gid}, "$main{path}backup.d/$main{host}/$mday-$mon-$year/condecht";

	for my $package ($pkg->Groups){
		for my $file ($pkg->val("$package all", "file"), $pkg->val("$package $main{host}", "file")){

			my ($fdest,$ffile,$fmode,$fowner,$fgroup) = split(",", $file);
			$fdest =~ s/\$home\$\//$main{home}/; ##used to prevent a double slash after home-dir
			$fdest =~ s/\$home\$/$main{home}/;

			mkpath( "$main{path}backup.d/$main{host}/$mday-$mon-$year/$package/",
							{ owner => $main{user}, group => $main{group}, mode => oct($main{defperm}) }
			);
		
			copy($fdest, "$main{path}backup.d/$main{host}/$mday-$mon-$year/$package/$ffile");
			chmod oct($main{defperm}), "$main{path}backup.d/$main{host}/$mday-$mon-$year/$package/$ffile";
			chown $main{uid}, $main{gid}, "$main{path}backup.d/$main{host}/$mday-$mon-$year/$package/$ffile";
		}

		# copy the hook files of the repository to.
		# it is useful if you want to copy your snapshot to your host-directory
		for my $hook ("pre", "pre_pkg_install", "post_pkg_install", "pre_config_remove", "post_config_remove", "pre_pkg_remove", "post_pkg_remove", "pre_config_install", "post_config_install", "post") {
			copy($main{path} . $main{host} . "/" . $package . "/" . $hook, "$main{path}backup.d/$main{host}/$mday-$mon-$year/$package/$hook");
			chmod oct($main{defperm}), "$main{path}backup.d/$main{host}/$mday-$mon-$year/$package/$hook";
			chown $main{uid}, $main{gid}, "$main{path}backup.d/$main{host}/$mday-$mon-$year/$package/$hook";
		}
	}
}
##END DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##

#READ PACKAGE CONFIGS
for my $package (@pkgs){
	unless($pkg->SectionExists("$package all")){
		die "Section [$package all] missing in $main{config_pkg}";
	}
	unless($pkg->SectionExists("$package $main{host}")){
		warn "Section [$package $main{host}] missing in $main{config_pkg}";
	}
	
	for my $note ($pkg->val("$package all", "note"), $pkg->val("$package $main{host}", "note")){
		print "$package: $note\n";
	}

	for my $dist ($pkg->val("$package all", "dist"), $pkg->val("$package $main{host}", "dist")){
		if($dist =~ /^$main{dist}\s*:(.*)/){
			push @syspkgs, split(" ", $1);
		}
	}

	for my $dep ($pkg->val("$package all", "deps"), $pkg->val("$package $main{host}", "deps")){
		for(split(" ", $dep)){
			print "ADDED package $_ as dependency from $package\n";
			push @pkgs, $_;
		}
	}

	for my $file ($pkg->val("$package all", "file"), $pkg->val("$package $main{host}", "file")){
		my ($fdest,$ffile,$fmode,$fuser,$fgroup) = split(",", $file);

		if($files{$fdest}){
			warn "Overwriting\n$files{$ffile}\nwith\n$file\n"
				;#if $main{verbose};
		}

		# replace the strings $home$ $user$ and $group$
		$fdest =~ s/\$home\$\//$main{home}/; ##used to prevent a double slash after home-dir
		$fdest =~ s/\$home\$/$main{home}/;
		$fuser =~ s/\$user\$/$main{user}/;
		$fgroup =~ s/\$group\$/$main{group}/;

		##check if user exists, if yes -> write uid back on $fuser
		if(getpwnam($fuser)){ $fuser = (getpwnam($fuser))[2]; }
		else { die "The user $fuser does not exist"; }
		#same as above, just for the group
		if(getgrnam($fgroup)){ $fgroup = (getgrnam($fgroup))[2]; }
		else { die "The group $fgroup does not exist"; }

		$files{$fdest} = join(",", ($fdest, "$main{path}$main{host}/$package/$ffile", $fmode, $fuser, $fgroup));
	}
}

hook("pre");

if($mode eq "pi"){
	hook("pre_pkg_install");

	system $main{pkgINS} . join(" ", @syspkgs);

	if($? != 0){
		warn "The packagemanager returned the error code $?. Continue installing configfiles? [y/N]";
		unless(<STDIN> =~ /y/i){
			die "Stopped while installing the packages. You may have to fix some errors.";
		}
	}

	hook("post_pkg_install");
}

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
				or warn "Could not backup file $fdest";
			chmod oct($main{defperm}), "$main{path}backup.d/$main{host}/old/$fdest2";
			chown $main{uid}, $main{gid}, "$main{path}backup.d/$main{host}/$fdest2";
		}
		unlink($fdest)
			or warn "Could not remove file $fdest";
	}
	
	hook("post_config_remove");
}
	
if($mode eq "pr"){
	hook("pre_pkg_remove");

	system $main{pkgREM} . @syspkgs;

	if($? != 0){
		warn "The packagemanager returned the error code $?. Continue removing configfiles? [y/N]";
		unless(<STDIN> =~ /y/i){
			die "Stopped while removing the packages. You may have to fix some errors.";
		}
	}
	
	hook("post_pkg_remove");
}
	
if($mode eq "ci" || $mode eq "pi"){
	hook("pre_config_install");
	
	for my $file (values %files){
		my ($fdest,$ffile,$fmode,$fowner,$fgroup) = split(",", $file);

		copy($ffile, $fdest)
			or warn "Could not copy the file to $fdest";
		chmod oct($fmode), $fdest;
		chown $fowner, $fgroup, $fdest;
	}
	
	hook("post_config_install");
}
	
hook("post");

exit(0);

__END__
=head1 NAME

Conf

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
