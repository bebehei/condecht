#!/usr/bin/env perl

use warnings;
use Getopt::Long;
use Pod::Usage;
use Config::IniFiles;

#sterben, wenn $cfg->... fehlschlägt funktion nur für richtige formatierung
sub stirb {
	print "";
}

my $gethostfile = "/etc/condecht";
my $config = "./condecht.conf";
#array for storing the packages to get installed/uninstalled of the system package manager
my @syspkgs;

#what to do, with wich packages
my $mode;
my @pkgs = ();

#Functions used to install/remove package/config
sub pkginstall {
	system $host->("hostdef", "pkgINS") . " " . @syspkgs;

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
			($ffile,$fdest,$fmode,$fowner,$fgroup) = split(",", $file);
			system "rm -v $fdest";
			system "cp -v $ffile $fdest";
			chmod oct($fmode) $fdest;
			chown $fowner:$fgroup $fdest;
		}
	
}

sub configremove {
		for $file (@cfgfiles){
			($ffile,$fdest,$fmode,$fowner,$fgroup) = split(",", $file);
			system "rm -v $destination";
		}
}
	
#read parameters
GetOptions(	"b|backup!" => \$backup,
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
);

#Check config, if true -> checkconfig && exit
#mhmmm, really?
if($check_config){
	if(checkconfig()){
		exit(0);
	}
}

#read condecht-config
my $cfg = Config::IniFiles->new(-file => $config) or die "@Config::IniFiles::errors";
#read Gethostfile
my $host = Config::IniFiles->new(-file => $gethostfile) or die "@Config::IniFiles::errors";

##DEBUG
#print $host->val("hostdef", "host") or die "@Config::IniFiles::errors";

#check variables of hostfile
if(!$host->SectionExists("hostdef")){
	die "No Section hostdef defined in $gethostfile";
}
for(("host", "dist", "pkgINS", "pkgREM", "repServerUpd", "repClientUpd")){
	if(!$host->val("hostdef", $_)){
		die "Couldn't find variable $_ in $gethostfile";
	}
}
#Programmablauf

#PAKETE AUSLESEN, WELCHE GEBRAUCHT WERDEN
##todo: hier schauen, ob die if-abfrage unnötig ist und @config::inifiles::errors das auch ausgibt!
for $pkg (@pkgs){
	if($cfg->SectionExists("pkg:$pkg:$hostname"){
		push @syspkgs, $cfg->val("pkg:$pkg:$hostname", "dist")  or die "@Config::IniFiles::errors";

		for $_ ($cfg->val("pkg:$pkg:$hostname", "file" or die "@Config::IniFiles::errors"){
			($file) = split(",", $_);
			$_ =~ s/$file/\.\/$hostname\.d\/$soft\.d\/$file/
			push @cfgfiles, "./host-$hostname.d/$pkg.d/$file";
		}
	}
	else {
		warn "Where is the dist-parameter in the Section pkg:$pkg:$hostname?";
	}
}

switch ($mode){
	case "pi" { pkginstall();    }
	case "pr" { pkgremove();     }
	case "ci" { configinstall(); }
	case "cr" { configremove();  }
	else { die "mhmmm, something is coded wrong! It is not your mistake!"; }
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
