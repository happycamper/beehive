#!/usr/bin/perl
use CGI;
use Time::HiRes qw(clock_gettime usleep nanosleep);
use Switch;
use DBI;
use Getopt::Long;
use File::Basename;
use Cwd qw(abs_path);
#################################################
##################DIRS FILE##################
my ($current) = dirname(abs_path(__FILE__));
$dirsfile = $current.'/dirs.pl';
$xbee_subs = $current.'/xbee_subs.pl';
require $dirsfile;
require $xbee_subs;
$rrd_dir = &get_rrd();
$graphs_dir = &get_graphs();
#########################################
$networkpage = "p=2";
$cgi = CGI->new();

$page = $cgi->url_param('p');

print "Content-Type: text/html \n\n";
print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
   \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">";
print "<LINK href=\"../css/beehive.css\" rel=\"stylesheet\" type=\"text/css\">";

print "\n<html>";
print "\n<body>";
print "\n<div class=header>&nbsp";
print "\n</div>";
print "\n<div class=sidebar>";
&div_sideoption("Home","?p=home");
&div_sideoption("Network","?p=2");
&div_sideoption("Config","?p=5");
	if(&check_process()){
		print "<div class=running>RX Running</div>";
	}else{
		print "<div class=down>RX Stopped</div>";
	}
print "\n</div>";
print "\n<div class=main>";



	switch($page){

		case 2 {
			&load_network();
		}
		case 3 {
			print "\n<div class=banner>";

			&div_banneroption("Events","?p=3");
			&div_banneroption("Network","?p=2");
			&div_banneroption("Help","?p=4");


			print "\n</div>";
			&load_events_page();
		}
		case 4 {
			print "\n<div class=banner>";

			&div_banneroption("Events","?p=3");
			&div_banneroption("Network","?p=2");
			&div_banneroption("Help","?p=4");


			print "\n</div>";
			&load_help();
		}
		case 5 {
			print "\n<div class=banner>";

			&div_banneroption("Events","?p=3");
			&div_banneroption("Network","?p=2");
			&div_banneroption("Help","?p=4");


			print "\n</div>";
			&load_config_page();
		}
		default {
			print "\n<div class=banner>";

			&div_banneroption("Events","?p=3");
			&div_banneroption("Network","?p=2");
			&div_banneroption("Help","?p=4");


			print "\n</div>";
			&load_home();
		}
	}
	




print "\n</div></div>"; #for main info box div after load functions

















print "\n</body>";
print "\n</html>";


sub div_sideoption{
	local ($word) = $_[0];
	local ($url) = $_[1];
	print "\n<div class=sideoption><a class=sideoption href=\"$url\">$word</a></div>";
}

sub div_banneroption{
	local ($word) = $_[0];
        local ($url) = $_[1];
        print "\n<div class=banneroption><a class=banneroption href=\"$url\">$word</a></div>";
	}

sub load_network{
	local (%network) = &get_mysql_xbee_network();
	local ($name);
	local ($qparam) = "q";
	local ($xbeepage) = '';
	local ($evt,$mon,$cfg) = ("evt","mon","cfg");
	local ($evtpage) = "$qparam=$evt";
	local ($monpage) = "$qparam=$mon";
	local ($cfgpage) = "$qparam=$cfg";
		if($cgi->url_param('bee')){
			local ($SL) = $cgi->url_param('bee');
				if($SL ne "Local"){
					$name = $network{$SL}[4];
					$xbeepage = "bee=$SL";
			}else{
				$name = "Connected USB";
			}
			print "\n<div class=banner>";

			&div_banneroption("Events","?$networkpage&$xbeepage&$evtpage");
			&div_banneroption("Monitoring","?$networkpage&$xbeepage&$monpage");
			&div_banneroption("Config","?$networkpage&$xbeepage&$cfgpage");


			print "\n</div>";
			&infobox();
			print "\n<div class=xbeeinfo><div class=xbeeinfotext>";
				switch($cgi->url_param($qparam)){
					
					case "$evt" {
						&load_events($SL);
						}
					case "$mon" {
						&load_monitoring($SL);
					}
					case "$cfg" {
						&load_configurations($SL);
					}
					default{
						if($SL eq "Local"){
							print "<img src=\"../css/xbee.png\"><h1 class=xbeetextinfo>$name - $SL</h1>";
							&localinfo();
						}else{
							print "<img src=\"../css/xbee.png\">";
							&pinsbox($SL);
							print "<h1 class=xbeetextinfo>$name - $SL</h1>";
							&xbeeinfo($SL);
						}
					}
				}
		print "</div></div>";
		}else{
			print "\n<div class=banner>";

			&div_banneroption("Events","?p=3");
			&div_banneroption("Network","?p=2");
			&div_banneroption("Help","?p=4");


			print "\n</div>";
			&infobox();
			&networkbuttons();
	print "\n<div class=coordinator><br /><br /><a class=coordinator href=\"?p=2&bee=Local\">Coordinator</a></div>";
		foreach $key (sort(keys %network)){
			local ($name) = $network{$key}[4];
			local ($addr) = $network{$key}[2];	
			print "\n<div class=router><br /><a class=router href=\"?p=2&bee=$key\">Router</a><div class=routertext>$name<br />SL:$key<br>ADDR:$addr</div></div>";
			}
		}


}

sub load_events_page{
	&infobox();
	print "\n<div class=infotext>This is the events page</div>";
}

sub load_help{
	&infobox();
	print "\n<div class=infotext>This is the help page</div>";
}

sub load_config_page{
	&infobox();
	print "\n<div class=infotextFB><img src=\"../css/xbee.png\" height=50px width=50px> &nbsp Hello, just thought I would show you your water usage and how you compare to college station!</div>";
}

sub load_home{
	&infobox();
	print "\n<div class=infotext><p font size:\"6\">Welcome to Beehive V 1.1</p><br><br>Beehive is a way for you to manage a sensor network no matter your skill or experience level with WSNs.  This tool offers a web enabled graphical view and configuration tool; however, you can take better advantage of all the features using the command line<br /><br>Beehive takes advantage of PERLs powerful scripting ability and lets you dynamically manage a network with ease through means of .bee profiles.<br>Beehive also takes advantage of Tobias Oetikers RRDtool which can make graphs like this<br /><br><img src=\"../css/rrdexample.png\"<br /><br>Please see the help page on examples and how to use the tool, otherwise feel free to explore.  This is the first version, so all the kinks aren't quite out yet.<br />Thanks, and Happy Buzzing!</div>";
}

sub infobox{
	print "\n<div class=infobox>";
}
sub xbeeinfo{
	local ($SL) = $_[0];
	local (%hash) = &get_mysql_xbee_network();;
	print '<br />Serial High: '.$hash{$SL}[0].'<br />Serial Low: '.$hash{$SL}[1].'<br />Network Address: '.$hash{$SL}[2].'<br />Device Type: '.$hash{$SL}[3].'<br />Node ID: '.$hash{$SL}[4].'<br />Parent Address: '.$hash{$SL}[5].'<br />Profile ID: '.$hash{$SL}[6].'<br />Manufacturer ID: '.$hash{$SL}[7].'<br />Active Status: '.$hash{$SL}[8];
}

sub localinfo{
	local (%hash) = &local_command_contents();
	foreach $key (sort(keys %hash)){
		print '<br />'.$hash{$key}[0].' : '.$hash{$key}[2];
	}
}

sub pinsbox{
	local ($SL) = $_[0];
	local (%hash) = &get_pins_config($SL);
	local ($count) = 0;
	print "<div class=pinsbox><form METHOD=POST action=\"tx.pl\"><input type=hidden name=fromweb.na.na.na><table class=pins><tr>";
	
	foreach $key (sort(keys %hash)){
		print "<td class=pins>";
		local ($disable) = 'R.'.$SL.'.'.$key.'.0x00.';
		local ($analog) = 'R.'.$SL.'.'.$key.'.0x02.';
		local ($high) = 'R.'.$SL.'.'.$key.'.0x05.';
		local ($low) = 'R.'.$SL.'.'.$key.'.0x04.';
		local ($name) = $hash{$key}[0];
		local ($value) = $hash{$key}[1];

		print "\n<table>\n<tr>\n<td><input class=xbeebutton type=submit name=$disable value=\"Disable\"></td>\n<td><input class=xbeebutton type=submit name=$analog value=\"A2D\">\n</td>\n</tr>\n<tr>\n<td colspan=2>$name - $key<br />Current State: $value</td>\n</tr>\n<tr>\n<td><input class=offbutton type=submit name=$low value=\"OFF\">\n</td>\n<td>\n<input class=onbutton type=submit name=$high value=\"ON\"></td></tr></table>";
	++$count;
	print "\n</td>";
		if($count == 3){
			print "\n</tr><tr>";
		}
	}
	print "\n</tr></table><input class=xbeebutton type=submit name=R.$SL.updatepins.na value=\"Update Pins\"></form></div><br />";
}

sub networkbuttons{
	print "\n<form method=POST action=\"tx.pl\"><input type=hidden name=fromweb><input class=networksearch type=submit name=L.L.search.mysqlu value=\"Update Current Network\"><input class=networksearch2 type=submit name=L.L.search.mysqlw value=\"Add new Sensors\"></form>";
}

sub load_events{
	local ($SL) = $_[0];
	print "These are the events and history for $SL";
}

sub load_monitoring{
	local ($SL) = $_[0];
	local ($qparam) = "q";
	local ($xbeepage) = "bee=$SL";
	local ($evt,$mon,$cfg,$cmd) = ("evt","mon","cfg","c");
	local ($evtpage) = "$qparam=$evt";
	local ($monpage) = "$qparam=$mon";
	local ($cfgpage) = "$qparam=$cfg";
		if($cgi->url_param($cmd)){
			local ($command) = $cgi->url_param($cmd);
			&graph_rrd($SL,$command,"now-1h","now");
			print "<div class=monitorlist><br>$command</div>";
			local ($image) = '../css/graphics/graphs/'.$SL.'/'.$command.'_'.$SL.'.png';
			print "<br /><img src=\"$image\"><br><br>Poll for Data<form method=POST action=\"tx.pl\"><input type=hidden name=fromweb><input class=xbeebutton type=submit name=L.$SL.rrd.update value=\"Poll\"></form>";
		}else{
	print "<div class=rrdcreate>Don't see what you want?<br>Choose command and Create Database<br>";
	local (@dircontents) = &get_command_profiles_contents($SL);
	print "<form method=POST action=\"tx.pl\"><input type=hidden name=fromweb><select name=L.$SL.rrd.create>";
		foreach $option (@dircontents){
				$option =~ s/\n//;
				if($option =~ m/\.bee/){
				($option,$other) = split(/\./,$option);
			print "<option value=\"$option\">$option</option>";
				}
		}
	print "</select><br><input class=xbeebutton type=submit name=RRDCREATE.L.L.L value=\"Create DB\"></form>";
	local ($filepath) = $rrd_dir.$SL.'/';
	if(-e $filepath){
		local (@mons) = `ls $filepath`;
			if(scalar(@mons) == 1){
				print "No Current Monitoring databases have been created for $SL";
			}
		foreach $i (@mons){
			if($i =~ m/\.rrd/){
				($i,$a) = split(/\_/,$i);
				print "<div class=monitorlist><a class=monitorlist href=\"?$networkpage&$xbeepage&$monpage&$cmd=$i\"><br>$i</a></div>";
			}
		}
	}
	} #for the cgi url param else
	}
sub load_configurations{
	local ($SL) = $_[0];
	local ($qparam) = "q";
	local ($xbeepage) = "bee=$SL";
	local ($evt,$mon,$cfg,$cmd) = ("evt","mon","cfg","c");
	local ($evtpage) = "$qparam=$evt";
	local ($monpage) = "$qparam=$mon";
	local ($cfgpage) = "$qparam=$cfg";
		if($cgi->url_param($cmd)){
			local ($command) = $cgi->url_param($cmd);
			print "<div class=monitorlist><br>$command</div>";
			local (@filecontents) = &read_bee_file($SL,$command);
			print "<h1 class=xbeetextinfo>Current Command Configuration</h1>";
			foreach $i (@filecontents){
				print '<br>'.$i;
			}
		}else{
		local (@dircontents) = &get_command_profiles_contents($SL);
		local ($ending);
		local ($count) = 0;
			foreach $content (@dircontents){
				if($content =~ m/\.bee/){
					($content,$ending) = split(/\./,$content);
					print "<a class=monitorlist href=\"?$networkpage&$xbeepage&$cfgpage&$cmd=$content\"><br>$content</a>";
				}
			}
	} #for the cgi url param else
	
	}
