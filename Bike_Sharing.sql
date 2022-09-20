---- TASK 1

create database bike_sharing;

use bike_sharing ;
-- drop table station;

create table station (
station_id int not null ,
station_name varchar(150) not null ,
latitude float4 not null,
longitude float4 not null,
dock_count int not null,
city varchar(32) not null,
installation_date text not null,
PRIMARY KEY(`station_id`)
);

create table status (
station_id int not null ,
bikes_available int not null ,
docks_available int not null,
time text not null,
FOREIGN KEY (station_id) REFERENCES station(station_id)
);


create table trip (
id int not null ,
duration int not null ,
start_date text not null,
start_station_name varchar(150) not null,
start_station_id int not null,
end_date text not null,
end_station_name varchar(150) not null,
end_station_id int not null,
bike_id int not null,
subscription_type varchar(50) not null,
zip_code varchar(50) not null ,
PRIMARY KEY(`id`)
);

-- drop table weather;
create table weather (
id int not null ,
date text not null,
mean_temperature_f text, -- not null,
mean_humidity text, -- not null,
mean_dew_point_f text, -- not null,
mean_wind_speed_mph text, -- not null,
zip_code varchar(50) not null ,
PRIMARY KEY(`id`)
);


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/station.csv' 
INTO TABLE station 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from station;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/status.csv' 
INTO TABLE status 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from status;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/trip.csv' 
INTO TABLE trip
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from trip;


LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/weather.csv' 
INTO TABLE weather
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from weather;
 CREATE TABLE WEATHER_FORMATTED as 

SELECT id,
STR_TO_DATE(date, '%m/%d/%Y') as date, 
cast(mean_temperature_f as float) as mean_temperature_f,
cast(mean_humidity as float) as mean_humidity, cast(mean_dew_point_f as float) as mean_dew_point_f,
cast(mean_wind_speed_mph as float ) as mean_wind_speed_mph, zip_code
fRom WEATHER;

--- 	Count of Bike Stations available
select count(distinct station_id ) as total_stations from station;
--- 70 stations are present


--- 	Count of Total Number of Bikes available
select count(distinct bike_id) as total_bikes from trip;
--- 700 Bikes are present


--- 	Count of Total Number of Trips
select count(distinct id ) as total_trips from trip;
-- 669959 Trips have  occured

--- Relationship between 
-- a.) bike_id (Trip table) and start_station_id (Trip table)  : Many to Many
-- b.) pincode (Weather table) and station location (latitude and longitude in Station table) : One to One
-- c.) 8/29/2013 (date column in Weather table) and mean wind speed (Weather table)
select * from WEATHER_FORMATTED
where date = '2013-08-29';
-- c.)  8/29/2013 (date column in Weather table) and mean wind speed (Weather table) : One to Many because single date can have multiple mean wind speed

--- Find the first and the last trip in the data
-- First Trip
select * from trip
order by STR_TO_DATE(start_date, '%m/%d/%Y %T')
limit 1;
-- 1st Trip happened at 29th August 2013


-- Last Trip
select * from trip
order by STR_TO_DATE(start_date, '%m/%d/%Y %T') desc
limit 1;
-- last trip happened at 31st August 2015


-- What is the average duration:
-- Of all the trips?

select avg(duration)/60 as avg_duration_in_mins from trip;
-- 18.46 minutes is the average duration of all trips

-- Of trips on which customers are ending their rides at the same station from where they started?
select avg(duration)/60 as avg_duration_in_mins from trip
where start_station_id = end_station_id;
-- 105.95 minutes is the average duration in cases where start and end station is same

-- Which bike has been used the most in terms of duration? (Answer with the Bike ID)
select bike_id, sum(duration) as total_usage  from trip
group by 1
order by 2 desc
limit 1;
-- Bike_ID = 535

-- task 2
-- What are the top 10 least popular stations? 

SELECT START_STATION_NAME , COUNT(START_STATION_NAME) AS FREQ_STATION FROM TRIP GROUP BY 1
ORDER BY 2
LIMIT 10 ;
-- San Jose Government Center
-- Broadway at Main
-- Redwood City Public Library
-- Franklin at Maple
-- San Mateo County Center
-- Redwood City Medical Center
-- Mezes Park
-- Stanford in Redwood City
-- Park at Olive
-- Santa Clara County Civic Center

SELECT * FROM STATUS;
--- Getting records of 29th August 2013 from Status table for station_id = 2
CREATE TABLE STATUS_2_20130829 AS
WITH BASE AS (
SELECT * FROM STATUS
WHERE TIME LIKE '2013/08/29%'
AND STATION_ID =2)
SELECT STATION_ID , BIKES_AVAILABLE , DOCKS_AVAILABLE, 
 STR_TO_DATE(TIME, '%Y/%m/%d %T') AS TIME
FROM BASE;

-- REMOVING DUPLICATES IN BASE_0
with base_0 as (select bikes_available, time
from STATUS_2_20130829 group by 1,2)
-- creating a variable base_for partition in base
 ,base as (
select bikes_available, time, case when bikes_available >=3 then 1 else 0 end as base_for_partition
 from base_0)
 
 -- ordering by time after dividing with bikes available and without that as well
 -- this will help us to identify points where change in bike number has occured
 , tbl1 as (
 select bikes_available, time, base_for_partition , row_number() over(partition by bikes_available
  order by time ) as time_rank,
  row_number()over ( order by time ) as bike_time_rank

  from base)
-- using lead function to get next rows data and find break points  
, tbl2 as (
  select bikes_available , time, base_for_partition, time_rank,bike_time_rank,
     lead(time_rank,1,0) over (order by time) as next_time_rank,
     lead(bike_time_rank,1,0) over (order by time) as next_bike_time_rank
     
      from tbl1), 
tbl_3 as (
    select bikes_available,base_for_partition, time,time_rank,next_time_rank, bike_time_rank ,next_bike_time_rank ,
    next_time_rank - time_rank as tr_diff, next_bike_time_rank - bike_time_rank as br_diff
     FROM tbl2)
-- applying lead function to get the next row time 
, tbl_4 as (     
select *, lead(time  , 1, 0) over(order by time) as time_next  from tbl_3
where time_rank=1 or tr_diff <>1  )
-- aggregating the result

select base_for_partition,sum(time_diff) as total_time from (
select *, timediff(time_next, time) time_diff  from tbl_4 where time_rank =1 ) b
group by 1;
-- Total 5500 seconds of idle Time


-- Cross Join on station table

CREATE TABLE STATION_DISTANCE AS 
select
station_1, STATION_NAME_1 , STATION_NAME_2, station_2,lat_1,lat_2, long_1, long_2,

2 * 3961 * asin(sqrt(power((sin(radians((lat_2 - lat_1) / 2))),2) + cos(radians(lat_1)) * cos(radians(lat_2)) * power((sin(radians((long_2 - long_1) / 2))),2) )) as distance

from
(
select a.station_id as station_1 , a.station_name as station_name_1, a.latitude as lat_1, a.longitude as long_1,
b.station_id as station_2 , b.station_name as station_name_2, b.latitude as lat_2, b.longitude as long_2
 from station a 
join station b)
data_1
where station_1 <> station_2
order by distance;


SELECT START_STATION_ID , COUNT(START_STATION_NAME) AS FREQ_STATION FROM TRIP
GROUP BY 1
ORDER BY 2
LIMIT 10;

-- 24, 21,23,26,83,83 , 80 , 36,33


SELECT STATION_1, STATION_NAME_1,STATION_2, STATION_NAME_2,
DISTANCE
 FROM STATION_DISTANCE  WHERE STATION_1
  IN (
  SELECT START_STATION_ID FROM (
  SELECT START_STATION_ID , COUNT(START_STATION_NAME) AS FREQ_STATION FROM TRIP
GROUP BY 1
ORDER BY 2
LIMIT 10) A
  );
  -- all these have distance < 50



SELECT STATION_1, STATION_NAME_1,STATION_2, STATION_NAME_2,
DISTANCE
 FROM STATION_DISTANCE  WHERE STATION_1
  IN (
  SELECT START_STATION_ID FROM (
  SELECT START_STATION_ID , COUNT(START_STATION_NAME) AS FREQ_STATION FROM TRIP
GROUP BY 1
ORDER BY 2
LIMIT 10) A
  )
  and distance <1
  limit 10;
  
  -- 21 and 24 are close and less frequent
  -- 23 and 24 are close and less frequent
  -- 24 and 26 are close and less frequent
  -- 23 and 26 are close and less frequent
  -- So 3 out of 21,24 , 26, 23 can be closed
  
SELECT START_STATION_ID , COUNT(START_STATION_NAME) AS FREQ_STATION FROM TRIP
GROUP BY 1
ORDER BY 2
LIMIT 10;
-- 24, 21 and 23 can be closed as these are least frequent and very close to each other as well

select station_id, avg(bikes_available) as avg_bikes,
avg(docks_available) as avg_docks
 from status 
 group by 1;
 
 -- AVERAGE NUMBER OF BIKES AVAILABLE IN STATION 2 : 13.17
 -- AVERAGE NUMBER OF DOCKS AVAILABLE IN STATION 2 : 13.76
 -- AVERAGE NUMBER OF BIKES AVAILABLE IN STATION 3 : 8.46
 -- AVERAGE NUMBER OF DOCKS AVAILABLE IN STATION 2 : 6.52
 
 -- TABLEAU PUBLIC LINK FOR VIEWS : https://public.tableau.com/app/profile/sujeet.srivastava6669/viz/BikeSharingAnalysis_16423214582300/StationPopularityPlot