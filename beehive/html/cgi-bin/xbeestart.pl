#!usr/bin/perl

`ln -s /dev/ttyUSB0 ~/.wine/dosdevices/com10`;
$slash = "\\";
$wine = 'wine ~/.wine/drive_c/Program'.$slash.' Files/Digi/XCTU/X-CTU.exe';
`$wine`;
