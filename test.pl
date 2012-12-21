#!/usr/bin/perl -w

use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;
use Config::IniFiles;

my $gethostfile = "/etc/condecht";
my $config = "./condecht.conf";
#array for storing the packages to get installed/uninstalled of the system package manager
my @syspkgs;

#what to do, with wich packages
my $mode;
my @pkgs = ();

GetOptions(
	"b|backup!" => \$backup,
	#"B" => sub { $backup = "false" },
	"c=s" => \$config,
	"config=s" => \$config,
	#"C" => \$check_config,
	"pi=s@" => sub { if(!$mode){ $mode = "pi"; @pkgs = @_; } else { exit(1); }} ,
	"pr=s@" => sub { if(!$mode){ $mode = "pr"; @pkgs = @_; } else { exit(1); }} ,
	"ci=s@" => sub { if(!$mode){ $mode = "ci"; @pkgs = @_; } else { exit(1); }} ,
	"cr=s@" => sub { if(!$mode){ $mode = "cr"; @pkgs = @_; } else { exit(1); }} ,
	"Sc" => sub { $sync = "client" },
	"Ss" => sub { $sync = "server" },
	"help|h" => sub { pod2usage(2) },
);

print $backup;

#read condecht-config
my $cfg = Config::IniFiles->new(-file => $config) or die "@Config::IniFiles::errors";
#read Gethostfile
my $host = Config::IniFiles->new(-file => $gethostfile) or die "@Config::IniFiles::errors";

