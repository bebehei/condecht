#!/usr/bin/env perl

##LOAD MODULES
use warnings;
#use strict;
use Getopt::Long;
use Pod::Usage;
use Config::IniFiles;
use Switch;
use File::Copy;
##END LOAD MODULES

##DECLARE EMPTY VARIABLES
my $mode;    #decide, whether install/remove config/package
my @syspkgs; #packages for the system packagemanager
my @pkgs;    #packages of condecht to install
my %main;    #the information of the main-section in $config_main
##todo
#will we use %pkg?
my %pkg;     #the information of the actual group of the host
##DECLARE EMPTY VARIABLES

## DEFAULT VARIABLES
my $config_main = "/etc/condecht";
my $config_pkg = "packages.conf";
##END DEFAULT VARIABLES

#die if a call on the $cfg obj fails.
#This function will format the errors-array in right way
sub stirb {
	for(@Config::IniFiles::errors){
		chomp();
		warn $_ ."\n";
	}
	die;
}

##READ MAIN CONFIG ##
my $cfg = Config::IniFiles->new(-file => $config_main) or stirb;
#check variables of hostfile

if($cfg->SectionExists("main")){
	for(("path", "backup", "host", "dist", "pkgINS", "pkgREM", "repServerUpd", "repClientUpd")){
		if($cfg->val("host", $_)){
			if($_ == "path"){
				$main{"config_pkg"} = $cfg->val("main", $_) . $config_main;
			}
			else {
				$main{$_} = $cfg->val("main", $_);
			}
		}
		##later remove this else if
		elsif($_ == "repServerUpd" || $_ == "repClientUpd"){
			##these options are not necessary yet
			$main{$_} = "";
		}
		else {
			die "Couldn't find definition of $_ in $config_main";
		}
	}
}
else {
	die "No Section host defined in config-file $config_main";
}
undef $cfg;
##END READ MAIN CONFIG

##INIT PACKAGES-CONFIG
##Reading the $pkg out, will be done later
my $pkg = Config::IniFiles->new(-file => $main{"path"} . $config_pkg) or stirb;
##END INIT PACKAGES CONFIG

##PAKETE AUSLESEN, WELCHE GEBRAUCHT WERDEN
##todo
#hier schauen, ob die if-abfrage unnötig ist und @config::inifiles::errors das auch ausgibt!
if($pkg->Group($main{"host"})){
	for $package (@pkgs){
		for $_ ($pkg->val("","")){
			if(/$main{"dist"}/){
				if(/:(.*)\$/){
					$packages = "true";
					push @syspkgs, split(" ", $1);
				}
				else {
					die "There is no colon, separating the distro and the packages!\nPackage: $pkg!\n";
				}
			}
		}

		##todo
		##verbessern group-> element
		for $_ ($pkg->val("pkg:" . $pkg . ":" . $host{"host"}, "file") or stirb){
			($file) = split(",", $_);
			$_ =~ s/$file/\.\/$host{"host"}\.d\/$soft\.d\/$file/;
			push @cfgfiles, $_;
		}
	}
}
else {
	die "There is no group $main{host} definded in $main{config_pkg}!";
}


