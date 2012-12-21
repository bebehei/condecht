#!/usr/bin/env perl

##LOAD MODULES
use warnings;
#use strict;

use Getopt::Long;
use Pod::Usage;
use Config::IniFiles;
use Switch;
##END LOAD MODULES

##DECLARE EMPTY VARIABLES
my $mode;    #decide, whether install/remove config/package
my @syspkgs; #packages for the system packagemanager
my @pkgs;    #packages of condecht to install
my %host;    #the information of the host-section in $config_main
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


##FUNCTIONS for REMOVING/INSTALLING PACKAGES ##
sub pkginstall {
	system $host->("host", "pkgINS") . " " . @syspkgs;

	if($? == 0){
		configinstall();
	}
	else {
		print "The packagemanager returned an error code. Continue installing packages? [y/N]";
		if(<STDIN> =~ /y/i){
			configinstall();
		}
		else {
			die "Stopped while installing the packages. You may have to fix some errors.";
		}
	}
}

sub pkgremove {
	configremove();
	
	system $host->("hostdef", "pkgREM") . " " . @syspkgs;

	if($? == 0){
		configremove();
	}
	else {
		print "The packagemanager returned an error code. Continue removing packages? [y/N]";
		if(<STDIN> =~ /y/i){
			configremove();
		}
		else {
			die "Stopped while removing the packages. You may have to fix some errors.";
		}
	}
}

sub configinstall {
	for $file (@cfgfiles){
		my ($ffile,$fdest,$fmode,$fowner,$fgroup) = split(",", $file);
		my (,,$fuid,$fgid) = getpwnam($fowner) or die "$fowner not in passwd file";
		system "rm -v $fdest";
		system "cp -v $ffile $fdest";
		chmod oct($fmode), $fdest;
		chown $fuid, $fguid, $fdest;
	}
}

sub configremove {
#todo backup
		print "Should there be a backup of the config-files? [y/N]";
		if(<STDIN> =~ /y/i){
			for
		for $file (@cfgfiles){
			($ffile,$fdest,$fmode,$fowner,$fgroup) = split(",", $file);
			system "rm -v $destination";
		}
}
##END FUNCTIONS for REMOVING/INSTALLING PACKAGES ##

#read parameters
GetOptions(
	"b|backup!" => \$backup,
	"B" => sub { $backup = "false" }, "c=s" => \$config,
	"config=s" => \$config,
	"C" => \$check_config,
	"pi=s@" => sub { if(!$mode){ $mode = "pi"; @pkgs = @_; } else { exit(1); }} ,
	"pr=s@" => sub { if(!$mode){ $mode = "pr"; @pkgs = @_; } else { exit(1); }} ,
	"ci=s@" => sub { if(!$mode){ $mode = "ci"; @pkgs = @_; } else { exit(1); }} ,
	"cr=s@" => sub { if(!$mode){ $mode = "cr"; @pkgs = @_; } else { exit(1); }} ,
	"Sc" => sub { $sync = "client" },
	"Ss" => sub { $sync = "server" },
	"help|h" => sub { pod2usage(2) },

	#list hosts
	"lh" => sub { if(!$list){ my $list = "hosts"; if($_ != ""){	$mode = $_; } } },
	"lp" => sub { if(!$list){ my $list = "pkg"; if($_ != ""){	$mode = $_; } } },
);



#read main config
my $host = Config::IniFiles->new(-file => $config_main) or stirb;
#check variables of hostfile
if($host->SectionExists("host")){
	for(("host", "dist", "pkgINS", "pkgREM", "repServerUpd", "repClientUpd")){
		if($host->val("host", $_)){
			$host{$_} = $host->val("host", $_);
		}
		else {
			die "Couldn't find definition of $_ in $config_host";
		}
	}
}
else {
	die "No Section host defined in config-file $config_host";
}
undef $host;

#read condecht-config
my $pkg = Config::IniFiles->new(-file => $cfg->val("main", "path")) or stirb;

##DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##
##list packages and hosts
if($list){
	if($list == "hosts"){
		for($pkg
	exit(0);
}

#Check config, if true -> checkconfig && exit
#mhmmm, really?
if($check_config){
	if(checkconfig()){
		exit(0);
	}
}
##END DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##

#PAKETE AUSLESEN, WELCHE GEBRAUCHT WERDEN
##todo
#hier schauen, ob die if-abfrage unnötig ist und @config::inifiles::errors das auch ausgibt!
for $pkg (@pkgs){
	if($cfg->SectionExists("pkg:" . $pkg . ":" . $host{"host"})){
		
		push @syspkgs, $cfg->val("pkg:" . $pkg . ":" . $host{"host"}, "dist")  or stirb;

		for $_ ($cfg->val("pkg:" . $pkg . ":" . $host{"host"}, "file") or stirb){
			($file) = split(",", $_);
			$_ =~ s/$file/\.\/$host{"host"}\.d\/$soft\.d\/$file/;
			push @cfgfiles, "./host-" . $host{"host"} . ".d/$pkg.d/$file";
		}
	}
	else {
		warn "Where is the dist-parameter in the Section pkg:" . $pkg . ":" . $host{"host"} . "?";
	}
}
##todo
#modify syspkgs-array, filter packages only from current distro

## REMOVE/DEPLOY PACKAGES ##
switch ($mode){
	case "pi" { pkginstall();    }
	case "pr" { pkgremove();     }
	case "ci" { configinstall(); }
	case "cr" { configremove();  }
	else { die "mhmmm, something is coded wrong! It is not your mistake!"; }
}
##END REMOVE/DEPLOY PACKAGES ##

__END__
=head1 NAME

Conf

=head1 SYNOPSIS

Synopsis-part

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will read the given input file(s) and do something
useful with the contents thereof.

=cut
