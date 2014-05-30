package ABT::Modules;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(&questions &verify_ip &verify_folder &newest_file &diff_file &write_config &ssh_or_telnet &cleanup);

use strict;
no strict "refs";
use FindBin;
use lib "$FindBin::Bin/../libs";
use ABT::Global;
use warnings;
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use File::DirList;
use Data::Dumper;
use File::Compare;
use Switch;

########################
#   Modules functions  #
########################

## Function who make question for modules
sub questions {
	my $Question = $_[0];
	my $DefaultReply = $_[1];
	my $ResponseNeed = $_[2];
	my $ResponseTest = $_[3];
	my $valid = 0;
	my $Response;
	$logger->debug("Question : ".$Question."\n\t\t\tDefault Reply : ".$DefaultReply."\n\t\t\tResponseNeed : ".$ResponseNeed."\n\t\t\tResponseTest : ".$ResponseTest) if $verbose;
	while ( $valid eq 0 ) {
		# Modidy the question to specify the default reply if exist
		if ( $DefaultReply eq "" ) {
			print "QUESTION : ".$Question." : ";
		} else {
			print "QUESTION : ".$Question." [".$DefaultReply."]: ";
		}
		# Parse $Response
		$Response = <STDIN>;
		chomp($Response);
		# If $Response is empty and defined $DefaultReply then $Reponse = $DefaultReply
		if (( ! $Response )&&( $DefaultReply ne "")) {
			$Response = $DefaultReply
		}
		# If $Response is not empty and $ResponseNeed is defined, the $Response isn't valid
		if ((! $Response )&&($ResponseNeed eq 1)) {
			$logger->error("A response is need");
			$valid = 0;
		# If $ResponseTest is defined, i test it
		} elsif ( $ResponseTest eq "" ) {
			$valid = 1;
			} elsif ( &{$ResponseTest}($Response) ) {
				$valid = 1;
			}
	}
	# Return $Response to module
	$logger->debug("Question : ".$Question." / Response : ".$Response) if $verbose;
	return $Response;
}

sub ssh_or_telnet {
	my $transport = $_[0];
	switch ($transport) {
		case "SSH" { return 1; }
		case "Telnet" { return 1; }
		else {
			$logger->error("The transport type entered (".$transport.") isn't valid (SSH or Telnet)");
			return 0;
		}
	}
}

## Function who verify the IP validity specify in parameter ($_[0])
sub verify_ip {
	my $IP_toverify = $_[0];
	$logger->debug("IP : ".$IP_toverify) if $verbose;
	if ( is_ipv4($IP_toverify) || is_ipv6($IP_toverify) ) {
		return 1;
	} else {
		$logger->error("The IP entered isn't valid");
		return 0;
	}
}

## Function who verify the folder existence specify in parameter ($_[0])
sub verify_folder {
	# to verify storage path is existent and writable
	my $Folder = $_[0];
	if ( -d $Folder && -W $Folder ) {
		return 1
	} else {
		$logger->error("The directory specify isn't a directory or not writtable.");
		return 0
	}
}

## Function who verify the retention
sub verify_retention {
	my $retention = $_[0];
	if ($retention ne "" ) {
		if ( $retention =~ /^\d+$/ ) {
			return 1;
		} else {
			$logger->error("The retention specifiy isn't a valid number.");
			return 0;
		}
	} else {
		return 1;
	}
}

## Function who verify the timeout
sub verify_timeout {
	my $timeout = $_[0];
	if ($timeout ne "" ) {
		if ( $timeout =~ /^\d+$/ ) {
			return 1;
		} else {
			$logger->error("The timeout specifiy isn't a valid number.");
			return 0;
		}
	} else {
		return 1;
	}
}

## Fonction who find the newer file in a folder
sub newest_file {
	my $folder = $_[0];
	my $pattern = $_[1];
	my $newest_file;
	my $valid = 0;
	my @list = File::DirList::list($folder, 'Mn', "1", "1", "0");
	$logger->debug("NewerFile Dump Global\n****************\n".Dumper(@list)."\n\n\n") if $verbose;
	foreach my $tab (@{ $list[0] }) {
			$logger->debug("NewerFile Dump by Elements\n****************\n".Dumper($tab)."\n\n\n") if $verbose;
			my @config = @{$tab};
			if ( ($config[14] eq "0") && ($config[13] =~ /$pattern/) ) {
				$logger->debug("The file (".$config[13].") match pattern ".$pattern) if $verbose;
				$newest_file = $config[13];
				last;
			} else {
				$logger->debug("The file (".$config[13].") don't match pattern ".$pattern) if $verbose;
			}
	}
	return $folder."/".$newest_file if ($newest_file);
}

## Function who diff configuration text
sub diff_file {
	my $ConfigFile = $_[0];
	my $oldfile = $_[1];
	my $newfile = $_[2];
	# On compare les deux fichiers
	if (compare($oldfile,$newfile) == 0) {
		# Les contenu sont les mêmes
		return 0;
	} else {
		# Les contenu sont différents
		return 1;
	}
}

## Function to cleanUP file on failed backup
sub cleanup {
	my $file2cleanup = $_[0];
	if (-e $file2cleanup) {
		unlink($file2cleanup);
		if ( $? ne 0 ) {
			$logger->warn("Failed to cleanup file ".$file2cleanup." with code $?");
		}
	} else {
		$logger->debug("File ".$file2cleanup." don't exist. No need to clean");
	}
}

1;
