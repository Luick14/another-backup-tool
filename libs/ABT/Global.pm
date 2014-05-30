# $Id: Global.pm 700 2014-01-14 16:44:10Z marc@mguyard.com $

package ABT::Global;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(&logfile_name &debugfile_name &parse_config &purge_files &return_code &list_file &file_right $logger $program $dirname $verbose $today $date $logfile %email_result);

use strict;
use warnings;
use Log::Log4perl;
use POSIX;
use XML::Simple;
use Data::Dumper;
use Dir::Purge qw(purgedir_by_age);
use File::Find::Rule;

###################
# Script Variable #
###################

our $program = $FindBin::Script;
our $dirname = $FindBin::Bin;

#####################
# Default arguments #
#####################

our $logfile;
our $debugfile;
our $today = strftime("%Y-%m-%d", localtime);
our $date = strftime("%Y-%m-%d_%H-%M", localtime);
if ( $program =~ /.*\.module$/ ) {
	$logfile = $dirname."/../logs/".$today.".log";
	$debugfile = $dirname."/../logs/".$today.".debug";
} else {
	$logfile = $dirname."/logs/".$today.".log";
	$debugfile = $dirname."/logs/".$today.".debug";
}
our $verbose = '';
our %email_result = ();

###########################
# Logging Configuration   #
###########################

## Function to specify the logfile location
sub logfile_name {
	return $logfile;
}

sub debugfile_name {
	
	return $debugfile;
}

## Log Configuration 
our $log_conf = q(
    log4perl.category = DEBUG, Logfile, DebugFile, Screen 
	
	log4perl.appender.Logfile = Log::Log4perl::Appender::File 
	log4perl.appender.Logfile.filename = sub { ABT::Global::logfile_name(); };
	log4perl.appender.Logfile.layout = Log::Log4perl::Layout::PatternLayout
	log4perl.appender.Logfile.layout.ConversionPattern = %d > [%p -- %F] %m %n
	log4perl.appender.Logfile.Threshold = WARN

    log4perl.appender.DebugFile = Log::Log4perl::Appender::File
    log4perl.appender.DebugFile.filename = sub { ABT::Global::debugfile_name(); };
    log4perl.appender.DebugFile.layout = Log::Log4perl::Layout::PatternLayout
	log4perl.appender.DebugFile.layout.ConversionPattern = %d > [%p -- %F] %m %n
	log4perl.appender.DebugFile.Threshold = DEBUG
	
	log4perl.appender.Screen        = Log::Log4perl::Appender::ScreenColoredLevels 
	log4perl.appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
);
Log::Log4perl::init( \$log_conf );
our $logger = Log::Log4perl::get_logger();

########################
#   Global functions   #
########################

## Function to return a error code
sub return_code {
	my $code = $_[0];
	my $message = $_[1];
	$logger->fatal($message." - (Code : ".$code.")\n\n");
	exit $code;
}

## Function to parse XML Configuration File
sub parse_config {
	my $ConfigFile = $_[0];
	my $xml = new XML::Simple;
	my $data = $xml->XMLin( $ConfigFile, suppressempty => '' );
	$logger->debug("Module XML Dump\n****************\n".Dumper($data)."\n\n\n") if $verbose;
	return $data;
}

## Function to list all file matching the pattern ($_[1]) in the directory ($_[0])
sub list_file {
	my $directory = $_[0];
	my $rule = $_[1];
	my $MySearch =  File::Find::Rule->new;
		$MySearch->file;
		$MySearch->name( $rule );
	my @SearchReturn = sort ( $MySearch->in( $directory ) );
}

## Function to purge old file
sub purge_files {
	my $retention = $_[0];
	my $folder2clear = $_[1];
	my $includePattern = $_[2];
	my $error_verbose;
	if ($verbose) {
		$error_verbose = "99";
	} else {
		$error_verbose = "1";
	}
	my $MySearch =  File::Find::Rule->new;
		$MySearch->file;
		$MySearch->name( qr/$includePattern/ );
	my @SearchReturn = sort ( $MySearch->in( $folder2clear ) );
	if (scalar(@SearchReturn) > $retention ) {
		purgedir_by_age ({keep => $retention, include => qr/$includePattern/, verbose => $error_verbose, test => 0}, $folder2clear);
		if ( $? ne 0 ) {
			$logger->warn("Failed to purge old file with code $?");
		}
	} else {
		$logger->info("No file to purge with pattern ".$includePattern." in directory ".$folder2clear) if $verbose;
	}
}

## Function to manage Linux Right
sub file_right {
	my $user = $_[0];
	my $group = $_[1];
	my $right = $_[2];
	my $file = $_[3];
	if ($file ne "" ) {
		if ($user ne "" ) {
			my $user_uid   = getpwnam($user) || $logger->warn("Unable to retreive UID for user ".$user);
			chown $user_uid, -1, $file || $logger->warn("Failed to change to user ".$user." for file ".$file);
		}
		if ($group ne "" ) {
			my $user_gid   = getgrnam($user) || $logger->warn("Unable to retreive GID for group ".$group);
			chown -1, $user_gid, $file || $logger->warn("Failed to change to group ".$group." for file ".$file);
		}
		if ($right ne "" ) {
			chmod($right,$file) || $logger->warn("Failed to change right to ".$right." for file ".$file);
		}
	}
}

1;
