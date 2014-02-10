#!/usr/bin/perl 

###################LOAD PM ##########################
use Device::SerialPort;
use Time::HiRes qw(clock_gettime usleep nanosleep);
use Switch;
use DBI;
use Getopt::Long;
use File::Basename;
use Cwd qw(abs_path);
use CGI;
#################################################
##################DIRS FILE##################
my ($current) = dirname(abs_path(__FILE__));
$dirsfile = $current.'/dirs.pl';
$xbee_subs = $current.'/xbee_subs.pl';
require $dirsfile;
require $xbee_subs;
####################################

###############GET HASHES FROM CONFIG###############
%event_settings = &hash_event_settings();
%xbee_commands = &hash_command_settings();
%frametypes = &hash_frametype();
%serial_settings = &hash_serial_settings();
#####################################

################GET REQUIREMENTS########
my ($rrd_dir) = &get_rrd();
my ($events_config_file) = &get_config_events();
my ($mysql_user) = &get_mysql_user();
my ($mysql_host) = &get_mysql_host();
my ($password) = &get_mysql_login();
my ($mysql_db) = &get_mysql_db();
my ($xbee_commands_file) = &get_xbee_commands();

#######################################

##################FOR MAIN SWITCH##############
$at_response = hex($frametypes{'AT_RESPONSE'});
$remote_at_response = hex($frametypes{'ZGB_REMOTE_AT_RESPONSE'});
$data_io_response = hex($frametypes{'ZGB_RX_IO'});
#########################################################

#######SET TIMEOUT GLOBAL TIMEOUT######################
$global_timeout = 5.0; #wait 5 seconds
$time_passed = 0.0;
#########################################

############SETUP PORT###################
$port = Device::SerialPort->new($serial_settings{'PORT'});
$port->databits($serial_settings{'DATABITS'});
$port->baudrate($serial_settings{'BAUDRATE'});
$port->parity($serial_settings{'PARITY'});
$port->stopbits($serial_settings{'STOPBITS'});
################################################

###############SETUP MYSQL CONNECTION##########
my ($connecting_host) = 'dbi:mysql:'.$mysql_db;
$connect = DBI->connect($connecting_host,$mysql_user,$password);
$network_table = 'network_devices';
$coord_table = 'coordinators';
####################GLOBAL STRUCTURES#############################
my (%RX_DATA);
my (%HASH_RX_DATA);
my ($packets_rx) = 0;
@EVENT_ACTIONS;
$EVENT_COUNT=0;
$EVENT_FLAG=0;
$postcgi = CGI->new();
my %postparams = $postcgi->Vars;
my $postsize = scalar keys %postparams;
	if($postsize > 1){
		&postanalysis(%postparams);
		&exitprog();
	}
#################################################
################SEARCH OPTIONS##################
my ($searchoption) = '';
my ($helpOption) = '';
my ($IDoption) = '';
$constructpacket = '';
$MYSQLwrite = '';
$MYSQLupdate = '';
$getcoord = '';
$RRDcreate = '';
$RRDupdate = '';
$pins = '';
$RRDFLAG = 0;
my ($remoteAToption) = '';
my ($localAToption) = '';
my ($remotedevice) = '';
my ($inputcommand) = '';
my (@parameter) = '';
my ($beverbose) = '';
my ($graphstart) = '';
my ($graphend) = '';
my ($dograph) = '';

	GetOptions ('help' => \$helpOption,'h' => \$helpOption,'packet=s' => \$constructpacket, 'mysqlw' => \$MYSQLwrite, 'mysqlu' => \$MYSQLupdate, 'coord' => \$getcoord, 'RRDcreate' => \$RRDcreate, 'RRDupdate' => \$RRDupdate,'search' => \$searchoption, 'remote' => \$remoteAToption,'device=s' => \$remotedevice, 'command=s' => \$inputcommand, 'param=s{,}'=> \@parameter,'local' => \$localAToption, 'verbose' => \$beverbose, 'start=s' => \$graphstart, 'end=s' => \$graphend, 'graph' => \$dograph, 'pins' => \$pins);
if($helpOption){
	&helpOptions();
	exit;
}

if($dograph){
	&graph_rrd($remotedevice,$inputcommand,$graphstart,$graphend);
	&exitprog();
}

if($pins && $remoteAToption){
	&get_pins($remotedevice);
}

if($searchoption){
	local($packet,$packetlength) = &send_AT_command($xbee_commands{'Search_Network'}[0]);
	local ($hexpacket) = pack("H[$packetlength]",$packet);
	$port->write($hexpacket);
	&exitprog();
}
elsif($localAToption != ''){
	local ($newparam) = '';
        if(scalar(@parameter)>1){
                $newparam = &resolve_param(\@parameter);
        }
        local ($command) = &prepare_command($inputcommand,$newparam);
        local($packet,$packetlength) = &send_AT_command($command);
        local($sendpacket) = &packpacket($packet,$packetlength);
        $port->write($sendpacket);
	&exitprog();
}
elsif($remoteAToption != '' ){
	local ($newparam) = '';
	if(scalar(@parameter)>1){
		$newparam = &resolve_param(\@parameter);
	}
	local ($command) = &prepare_command($inputcommand,$newparam);
	local($packet,$packetlength) = &send_remote_AT_command($remotedevice,$command);
	local($sendpacket) = &packpacket($packet,$packetlength);
	$port->write($sendpacket);
        &exitprog();
}		
elsif($getcoord){
	
=cut	local($packet,$packetlength) = &send_AT_command($xbee_commands{'Serial_High'}[0]);
	local($sendpacket) = &packpacket($packet,$packetlength);	
        $port->write($sendpacket);
	
	($packet,$packetlength) = &send_AT_command($xbee_commands{'Serial_Low'}[0]);
        $sendpacket = &packpacket($packet,$packetlength);
        $port->write($sendpacket);
	
	($packet,$packetlength) = &send_AT_command($xbee_commands{'Node_ID'}[0]);
        $sendpacket = &packpacket($packet,$packetlength);
        $port->write($sendpacket);
	
	($packet,$packetlength) = &send_AT_command($xbee_commands{'Software_Version'}[0]);
        $sendpacket = &packpacket($packet,$packetlength);
        $port->write($sendpacket);
	
	($packet,$packetlength) = &send_AT_command($xbee_commands{'Hardware_Version'}[0]);
        $sendpacket = &packpacket($packet,$packetlength);
     $port->write($sendpacket);
=cut	
	&get_coord();	
	&exitprog();
}
elsif($constructpacket != null){
local($sending) = &packetsend($constructpacket);
$port->write($sending);
&exitprog();
}

else{
	&helpOptions();
	exit;
}

sub packetsend{
	local ($newpacket) = $_[0];
	local ($length) = length($newpacket);
	local ($checksum) = &compute_checksum($newpacket,$length);
	local ($sendlength) = $length+2; #for checksum	
	my ($packettosend) = pack("H[$sendlength]",$newpacket.$checksum);
return $packettosend;
}

sub packpacket{
	local($packet) =$_[0];
	local($length) = $_[1];
	local($packettosend) = pack("H[$length]",$packet);
	return $packettosend;
}

