#!/usr/bin/env perl

##LOAD MODULES
#use warnings;
#use strict;
use Getopt::Long;
use Pod::Usage;
use Config::IniFiles;
use File::Copy;
##END LOAD MODULES

##DECLARE EMPTY VARIABLES
my $mode;    #decide, whether install/remove config/package
my @syspkgs; #packages for the system packagemanager
my @pkgs;    #packages of condecht to install
my %main;    #the information of the main-section in $config_main
my $host;
##DECLARE EMPTY VARIABLES

## DEFAULT VARIABLES
my $config_main = "/etc/condecht";
my $config_pkg = "packages.conf";
##END DEFAULT VARIABLES

##HOOK-Functions
sub hook {
	print "@_\n";
}
##END USED FUNCTIONS

##READ COMMAND LINE PARAMETERS ##
GetOptions(
	##general options
	"c|config=s" => \$config_main,
	"h|host=s" => \$host,
	"check" => sub { if(!$mode){ $mode = "cc"; } else { exit(1); }},
	"help|h" => sub { pod2usage(2) },
	##install/remove configs/packages
	"pi=s@" => sub { if(!$mode){ $mode = "pi"; @pkgs = @_; shift(@pkgs); } else { exit(1); }},
	"pr=s@" => sub { if(!$mode){ $mode = "pr"; @pkgs = @_; shift(@pkgs); } else { exit(1); }},
	"ci=s@" => sub { if(!$mode){ $mode = "ci"; @pkgs = @_; shift(@pkgs); } else { exit(1); }},
	"cr=s@" => sub { if(!$mode){ $mode = "cr"; @pkgs = @_; shift(@pkgs); } else { exit(1); }},
	##list hosts/packages
	"lh" => sub { if(!$mode){ $mode = "Lh"; } else { exit(1); }},
	"lp" => sub { if(!$mode){ $mode = "Lp"; } else { exit(1); }},
	##updating the repo or the client
	"Sc" => sub { if(!$mode){ $mode = "Sc"; } else { exit(1); }},
	"Ss" => sub { if(!$mode){ $mode = "Sc"; } else { exit(1); }},
);
##CHECK PARAMETERS

##END CHECK PARAMETERS

##READ MAIN CONFIG ##
my $cfg = Config::IniFiles->new(-file => $config_main) or die "@Config::IniFiles::errors";

#check variables of hostfile
#a check of the variables is necessary here

if($cfg->SectionExists("main")){
	for(("path", "backup", "host", "dist", "pkgINS", "pkgREM", "repServerUpd", "repClientUpd")){
		if(defined $cfg->val("main", $_)){
			$main{$_} = $cfg->val("main", $_);

			if(defined $host and $_ eq "host"){
				$main{$_} = $host;
				undef $host;
			}
			if($_ eq 'path'){
				##add trailing slash
				unless($main{path} =~ /\/$/){
					$main{path} = $main{path} . "/";
				}
				$main{"config_pkg"} = $main{path} . $config_pkg;
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
my $pkg = Config::IniFiles->new(-file => $main{config_pkg}) or die "@Config::IniFiles::errors";
##END INIT PACKAGES CONFIG

##DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##
##list hosts
if($mode eq "lh"){
	for $host ($pkg->Groups){
		print "$host\n";
	}
	exit(0);
}
##list packages
if($mode eq "lp"){
	for $member ($pkg->GroupMembers($main{host})){
		print "$member\n";
	}
	exit(0);
}
#check config
if($mode eq "cc"){
	die "check config not implemented";
	checkconfig();
}
if($mode eq "Sc"){
	#update client
	die "update client not implemented yet";
}
if($mode eq "Ss"){
	die "update Server not implemented yet";
}
##END DO OTHER THINGS THAN DEPLOYING/REMOVING PACKAGES ##

#PAKETE AUSLESEN, WELCHE GEBRAUCHT WERDEN
for $package (@pkgs){
	if($pkg->SectionExists("$main{host} $package")){
		if($package eq $pkg->val("$main{host} $package", "pkg")){
			hook("pre");
	
			if($mode eq "pi"){
				hook("pre_pkg_install");
	
				for $dist ($pkg->val("$main{host} $package", "dist")){
					if($dist =~ /^$main{dist}\s*:(.*)/){
						@syspkgs = split(" ", $1);
					}
				}
	
				system $main{pkgINS} . @syspkgs;
	
				if($? != 0){
					print "The packagemanager returned an error code. Continue installing packages? [y/N]";
					unless(<STDIN> =~ /y/i){
						die "Stopped while installing the packages. You may have to fix some errors.";
					}
				}
	
				hook("post_pkg_install");
			}
	
			if($mode eq "cr" || $mode eq "pr"){
				hook("pre_confif_remove");
	
				for $file ($pkg->val("$main{host} $package", "file")){
					($fdest,$fdest) = split(",", $file);
					if($main{backup}){
						system "mv -v $fdest, $main{path}/backup/$fdest" or die "Backup failed: $!";
					}
					else {
						system "rm -v $fdest";
					}
				}
	
				hook("post_config_remove");
			}
	
			if($mode eq "pr"){
				hook("pre_pkg_remove");
	
				for $dist ($pkg->val("$main{host} $package", "dist")){
					if($dist =~ /^$main{dist}\s*:(.*)/){
						@syspkgs = split(" ", $1);
					}
				}
	
				system $main{pkgREM} . @syspkgs;
	
				if($? != 0){
					print "The packagemanager returned an error code. Continue removing packages? [y/N]";
					unless(<STDIN> =~ /y/i){
						die "Stopped while removing the packages. You may have to fix some errors.";
					}
				}
	
				hook("post_pkg_remove");
			}
	
			if($mode eq "ci" || $mode eq "pi"){
				hook("pre_config_install");
				
				for $file ($pkg->val("$main{host} $package", "file")){
					my ($ffile,$fdest,$fmode,$fowner,$fgroup) = split(",", $file);
					$ffile = $main{path} . "host-" . $main{host} . ".d/" . $package . ".d/" . $ffile;
	
					system "cp -v $ffile $fdest";
					system "chown -v $fowner:$fgroup $fdest";
					system "chmod -v $fmode $fdest";
	
					##Alternative 
					##It uses the internal Perl chmod and chown routines
					##a little bit faster, but it is easier to add verbose output with system "ch...
					#my ($fuid,$fuid,$fuid) = getpwnam($fowner) or die "$fowner not in passwd file";
					#my ($fgid,$fgid,$fgid) = getgrnam($fgroup) or die "$fgroup not passwd file";
					#chmod oct($fmode), $fdest;
					#chown $fuid, $fguid, $fdest;
				}
	
				hook("post_config_install");
			}
	
			hook("post");
		}
		else {
			die "The value of pkg in the section [$main{host} $package] is not $package!";
		}
	}
	else {
		die "The section [$main{host} $package] is not defined in the file $main{config_pkg}!";
	}
}

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
