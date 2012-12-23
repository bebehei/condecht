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
		##do nothing
		return 0;
	}
	else {
		die "The Package-Manager returned an error-code!";
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
		$backup = "true";
	}

	for $file (@cfgfiles){
		($ffile,$fdest,$fmode,$fowner,$fgroup) = split(",", $file);
		if($backup){
			move($fdest, $main{"path"} . "/backup/" . $fdest) or die "Backup failed: $!";
		}
		else {
			system "rm -v $fdest";
		}
	}
}
##END FUNCTIONS for REMOVING/INSTALLING PACKAGES ##

##READ COMMAND LINE PARAMETERS ##
GetOptions(
	"backup!" => \$backup,
	"c|config=s" => \$config,
	"check" => \$check_config,

	##deciding mode
	"pi=s@" => sub { if(!$mode){ $mode = "pi"; @pkgs = @_; } else { exit(1); }} ,
	"pr=s@" => sub { if(!$mode){ $mode = "pr"; @pkgs = @_; } else { exit(1); }} ,
	"ci=s@" => sub { if(!$mode){ $mode = "ci"; @pkgs = @_; } else { exit(1); }} ,
	"cr=s@" => sub { if(!$mode){ $mode = "cr"; @pkgs = @_; } else { exit(1); }} ,

	##later
	##updating the repo or the client
	#"Sc" => sub { $sync = "client" },
	#"Ss" => sub { $sync = "server" },

	"help|h" => sub { pod2usage(2) },

	##later
	##list hosts
	#"lh" => sub { if(!$list){ my $list = "hosts"; if($_ != ""){	$mode = $_; } } },
	#"lp" => sub { if(!$list){ my $list = "pkg"; if($_ != ""){	$mode = $_; } } },
);

##CHECK PARAMETERS

##END CHECK PARAMETERS

##READ MAIN CONFIG ##
my $cfg = Config::IniFiles->new(-file => $config_main) or stirb;

#check variables of hostfile
#a check of the variables is necessary here
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
my $pkg = Config::IniFiles->new(-file => $main{"path"} . $config_pkg) or stirb;
##END INIT PACKAGES CONFIG

##DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##
##list packages and hosts
if($list){
	if($list == "hosts"){
		#for($pkg){}
	}
	if($list == "pkg"){
		#for(){}
	}
	exit(0);
}

#Check config, if true -> checkconfig && exit
if($check_config){
	if(checkconfig()){
		exit(0);
	}
}
##END DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##

#PAKETE AUSLESEN, WELCHE GEBRAUCHT WERDEN
##todo
#hier schauen, ob die if-abfrage unnötig ist und @config::inifiles::errors das auch ausgibt!
for $package (@packages){
	if($pkg->val("$main{host} $package", "pkg") or stirb){
		pre_hook();
		if($mode == "pi"){
			pre_install_hook();
		
			post_pkg_install_hook();
		}
		elsif($mode == "pr"){
			pre_pkg_remove_hook();

			post_pkg_remove_hook();
		}
		elsif($mode == "ci"){
			pre_config_install_hook();

			post_config_install_hook();
		}
		elsif($mode == "cr"){
			pre_confif_remove_hook();

			post_config_remove_hook();
		}
		else {
			die "There's a heavy failure in the software: \$mode == $mode.";
		}
		post_hook();
	}
}

if($pkg->Group($main{"host"})){
	for $package (@pkgs){
	##todo
	##verbessern group element
	#$pkg->SectionExists("pkg:" . $pkg . ":" . $host{"host"})){
		for $_ ($pkg->val()){
			if(/$main{"dist"}/){
				if(/:(.*)$/){
					#$packages = "true";
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
		#else {
		#	warn "Config-Section $pkg not found";
		#}
}
else {
	die "There is no group $main{host} definded in $main{config_pkg}!";
}

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
