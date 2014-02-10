#!/usr/bin/perl
use warnings;
use File::Basename;
use Cwd qw(abs_path);
#*****************FILE USED TO READ FROM config/CONFIG*****************
#***************UPDATED JUNE 17, 2011 JEFF JENSEN ********************
sub get_dirs{

	local (%returnhash);
	my ($current) = dirname(abs_path(__FILE__));
   	$current=~ s/\/html\/cgi-bin/\//;
	my ($config_file) = $current.'config/CONFIG';
	my ($config) = $current.'config/';
	my ($home) = $current;

	my (@setting_name,@setting_value);
	open(CONFIG,$config_file) or die $!;
	$i=0;
		while(<CONFIG>){
		#SKIP the first line of the configuration file
			if($i != 0){
			 	($setting_name[$i],$setting_value[$i]) = split(/:/,$_);
				$setting_value[$i] = substr($setting_value[$i],0,-1);
			}	

			++$i;
		}
	close(CONFIG) or die $!;
	
	#pop home directory as first entry
	$setting_value[0] = $home;
	$returnhash{'CONFIG'} = $config;
	$returnhash{'CONFIG_FILE'} = $config_file;
	$returnhash{'HOME'} = $setting_value[0];
	
	#GET ALL OTHER SETTINGS
		for($x=1;$x<scalar(@setting_name);++$x){
			$returnhash{$setting_name[$x]} = $setting_value[$x];
		}
		
	return %returnhash;
}

sub get_rrd{

	local (%settings) = &get_dirs();
	local ($rrd_dir) = $settings{'HOME'}.$settings{'RRD_DATABASE'};
	return $rrd_dir or die $!;
}

sub get_errorlog{
	
	local (%settings) = &get_dirs();
        local ($error_log) = $settings{'HOME'}.$settings{'LOG'}.$settings{'ERROR_LOG'};	
	return $error_log or die $!;	
}

sub get_serial{
	local (%settings) = &get_dirs();
	local ($serial_file) = $settings{'CONFIG'}.$settings{'SERIAL'};
	return $serial_file or die $!;
}

sub get_processlog{
	
	local (%settings) = &get_dirs();
        local ($process_log) = $settings{'HOME'}.$settings{'LOG'}.$settings{'PROCESS_LOG'};
        return $process_log;
}



sub get_web{
	
	local (%settings) = &get_dirs();
        local ($web) = $settings{'HOME'}.$settings{'WEB'};
        return $web;
}

sub get_cgi{
	
	local (%settings) = &get_dirs();
        local ($cgi_bin) = $settings{'HOME'}.$settings{'CGIBIN'};
        return $cgi_bin;
}

sub get_mysql_user{
	local (%settings) = &get_dirs();
	return $settings{'MYSQLUSER'};
}

sub get_mysql_host{
	
	local (%settings) = &get_dirs();
        return $settings{'MYSQL_HOST'};
}
sub get_mysql_login{
	
	local (%settings) = &get_dirs();
        return $settings{'MYSQLPASSWD'};

}

sub get_mysql_db{
	
	local (%settings) = &get_dirs();
        return $settings{'MYSQL_DB'};
}

sub get_sql{
	
	local (%settings) = &get_dirs();
        local ($sql_dir) = $settings{'CONFIG'}.$settings{'SQL'};
        return $sql_dir;	
	
}

sub get_graphics{
	
	local (%settings) = &get_dirs();
        local ($graphics) = $settings{'HOME'}.$settings{'GRAPHICS'};
        return $graphics;
}

sub get_graphs{
	
	local (%settings) = &get_dirs();
        local ($graphs) = $settings{'HOME'}.$settings{'GRAPHS'};
        return $graphs;		

}

sub get_config{
	 local (%settings) = &get_dirs();
	return $settings{'CONFIG'};
}

sub get_config_events{
	
	local (%settings) = &get_dirs();
        return $settings{'CONFIG'}.$settings{'EVENTS'};
}

sub get_xbee_commands{
	
	local (%settings) = &get_dirs();
        return $settings{'CONFIG'}.$settings{'XBEECOMMANDS'};

}

sub get_frametype_file{

        local (%settings) = &get_dirs();
        return $settings{'CONFIG'}.$settings{'FRAMETYPE'};

}

sub get_rx_log{
	local (%settings) = &get_dirs();
	return $settings{'HOME'}.$settings{'LOG'}.$settings{'RXLOG'};
}

sub get_frametype_profiles_dir{
	local (%settings) = &get_dirs();
	return $settings{'CONFIG'}.$settings{'FRAMETYPE_PROFILES'};
}

sub get_events_profiles_dir{
	local (%settings) = &get_dirs();
        return $settings{'CONFIG'}.$settings{'EVENT_PROFILES'};
}

sub get_command_profiles_dir{
	local (%settings) = &get_dirs();
        return $settings{'CONFIG'}.$settings{'COMMAND_PROFILES'};
}

sub get_local_config_dir{
	local(%settings) = &get_dirs();
	return $settings{'CONFIG'}.$settings{'LOCAL'};
}
	
1;
