CREATE DATABASE beehive;
use beehive;
create table network_devices(Serial_High char(10),Serial_Low char(10) PRIMARY KEY,Net_Addr char(10),Device_Type char(15),Node_ID text,Parent_Addr char(10),Profile_ID char(10),Manufacturer_ID char(10),active char(10));

grant all privileges on beehive.* to 'beehive'@'localhost' identified by 'bees';
