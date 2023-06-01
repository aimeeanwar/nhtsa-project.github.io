Create table newcrash as(

with Date_cleansing as ( 
select * ,
case
	  when state_name in ('Alabama','Arkansas','Illinois','Iowa','Kansas','Kentucky','Louisiana','Minnesota','Mississippi', 'Nebraska','Florida','Missouri','North Dakota', 'Oklahoma','South Dakota','Tennessee','Texas','Wisconsin')
        then timestamp_of_crash at time zone 'cst'
	  when state_name in ('Alaska')
		then timestamp_of_crash at time zone 'kst'
      when state_name in ('Arizona','Colorado','Idaho','Kansas','Montana','New Mexico','Oregon','Utah','Wyoming')
		then timestamp_of_crash at time zone 'mst'
	  when state_name in ('California','Nevada','Washington','Oregon')
		then timestamp_of_crash at time zone 'pst'
	  when state_name in ('Connecticut','Delaware','District of Columbia','Florida','Georgia','Indiana','Maine','Maryland','Massachusetts','Michigan','New Hampshire','New Jersey', 'New York','North Carolina','Ohio','Pennsylvania','Rhode Island','South Carolina','Vermont','Virginia','West Virginia')
		then timestamp_of_crash at time zone 'est'
	  when state_name in ('Hawaii')
		then timestamp_of_crash at time zone 'hst'
       end waktu_kecelakaan
 from crash
)

	select 
	consecutive_number,
	State_name,
	number_of_persons_in_motor_vehicles_in_transport_mvit Total_persons_in_vehicle,
	type_of_intersection_name,
	manner_of_collision_name,
	land_use_name,
	functional_system_name,
	atmospheric_conditions_1_name,
	milepoint,
	waktu_kecelakaan,
    to_char(waktu_kecelakaan,'DD-MM-YYYY') Date_of_crash,
	extract(hour from waktu_kecelakaan) Hour_only,
	to_char (waktu_kecelakaan, 'hh24:mm:ss') accident_hour, 
	to_char (waktu_kecelakaan, 'Day') Day_of_crash,
	To_char (waktu_kecelakaan, 'Month') Month_of_crash,
	extract(Year from waktu_kecelakaan) Year_of_crash,
	case
      when number_of_drunk_drivers >= 1
	  then 'Drunk Driver'
	  else 'Not Drunk Driver'
	  end Driver_condition,
	 case 
	   when light_condition_name like ('%Not Lighted%') Then 'Night Not Lighted'
	   When light_condition_name like ('%Lighted%') Then 'Night Lighted'
	   else 'Day'
	   end day_condition,
	 case 
	  when to_char (waktu_kecelakaan, 'HH24:MM:SS')   between '05:00:00' and '10:59:00' then 'Morning'
	  when to_char (waktu_kecelakaan, 'HH24:MM:SS')   between '11:00:00' and '15:00:00' then 'Afternoon'
	  When to_char (waktu_kecelakaan, 'HH24:MM:SS')  between '15:01:00' and '18:00:00' then 'Evening'
	  When to_char (waktu_kecelakaan, 'HH24:MM:SS')   between '18:01:00' and '23:59:59' then 'Night'
	  When to_char (waktu_kecelakaan, 'HH24:MM:SS')   between '00:00:00' and '04:59:00' then 'Ealy Morning'
      end Time_of_Accident,
	 case
      when number_of_motor_vehicles_in_transport_mvit =1 then 'Single Accident'
	  when number_of_motor_vehicles_in_transport_mvit >= 1 and number_of_parked_working_vehicles >=1 then 'Single Accident'
	 else 'Multi Accident'
	 end type_of_accident,
	 case
	  when number_of_persons_in_motor_vehicles_in_transport_mvit =1 then 'Single Driver'
	  when number_of_persons_in_motor_vehicles_in_transport_mvit =2 and number_of_motor_vehicles_in_transport_mvit =2 then 'Single Driver'
	  when number_of_persons_in_motor_vehicles_in_transport_mvit =3 and number_of_motor_vehicles_in_transport_mvit =2 then 'Single Driver'
	 else 'Not Single Driver'
	end type_of_Driver,
	 Count(to_char(waktu_kecelakaan,'DD-MM-YYYY')) Total_accident,
	sum(number_of_fatalities) Total_Fatalities
from Date_cleansing
group by 
	consecutive_number,
	State_name,
	number_of_fatalities,
	number_of_vehicle_forms_submitted_all,
	number_of_persons_in_motor_vehicles_in_transport_mvit,
	type_of_intersection_name,
	manner_of_collision_name,
	manner_of_collision_name,
	land_use_name,
	number_of_drunk_drivers,
	light_condition_name,
	atmospheric_conditions_1_name,
	number_of_drunk_drivers,
	waktu_kecelakaan,
	milepoint,
	number_of_motor_vehicles_in_transport_mvit,
	number_of_parked_working_vehicles,
	functional_system_name
)

/* 
1. kondisi yang memperbesar risiko kecekalaan?
2. 10 negara bagian teratas dengan angka kecelakaan tertinggi ?
3. jumlah rerata kecelakaan yang terjadi setiap jam?
4. persentase kecelakaan akibat pengemudi mabuk? 
5. persentasi kecelakaan di area pedesaan?
6. angka kecelakaan berdasarkan hari kecelakaan ? 
*/







--2. 10 negara bagian teratas dengan angka kecelakaan tertinggi ?

select 
    state_name,
	count(*) Total_accident
from newcrash
WHERE Year_of_crash = '2021'
group by 1
order by 2 desc limit 10


--3. jumlah rerata kecelakaan yang terjadi setiap jam?

select y.group_hour, round(sum(avg_accident)/4, 2) avg_group_hour
from
(
select x.hour_only, round(avg(x.total_num_accident), 2) as avg_accident,
       case
	       when x.hour_only in (0,1,2,3) then '0-3'
		   when x.hour_only in (4,5,6,7) then '4-7'
		   when x.hour_only in (8,9,10,11) then '8-11'
		   when x.hour_only in (12,13,14,15) then '12-15'
		   when x.hour_only in (16,17,18,19) then '16-19'
	   else '20-23'
	   end group_hour
from
(
select date_of_crash, year_of_crash, hour_only, count(consecutive_number) total_num_accident
from newcrash
where year_of_crash = 2021
group by 1, 2, 3
order by 1
) x
group by 1
) y
group by 1	
	
--4. persentase kecelakaan akibat pengemudi mabuk? 

select 
 driver_condition,
 count(total_accident)
from newcrash
where year_of_crash = '2021'
group by 1	
	
--5. persentasi kecelakaan di area pedesaan?
	
select 
 land_use_name,
 sum(total_accident)
from newcrash
where land_use_name = 'Urban' or land_use_name ='Rural' and year_of_crash = '2021'
group by 1
order by 2 desc


--6. angka kecelakaan berdasarkan hari kecelakaan ? 

select
 day_of_crash,
 sum(total_accident) Total_accident
from newcrash
where year_of_crash = '2021'
group by 1
order by 2 desc


--Total accident and Total Death

select
 month_of_crash,
 sum(total_accident),
 sum(total_fatalities)
from newcrash
where year_of_crash = '2021'
group by 1
order by 2 desc


---Total Accident and Vehicle Loss
select
 month_of_crash,
 sum(total_accident)total_accident,
 sum(Vehicle_loss)Vehicle_loss
from newcrash
where year_of_crash = '2021'
group by 1
order by 2 desc

--1. kondisi yang memperbesar risiko kecekalaan?

select x.accident_cause, count(x.consecutive_number) total_num_accident
from (
select consecutive_number, manner_of_collision_name, type_of_intersection_name, driver_condition,
       atmospheric_conditions_1_name,
	   case
	       when manner_of_collision_name = 'Sideswipe - Same Direction' 
		       then 'Distract Driving'					
           when manner_of_collision_name = 'Sideswipe - Opposite Direction' 
		       then 'Distract Driving'					
           when manner_of_collision_name = 'Front-to-Front' 
		       then 'Distract Driving'					
           when manner_of_collision_name = 'Front-to-Rear' 
		       then 'Distract Driving'				
           when type_of_intersection_name = 'Four-Way Intersection'
		       then 'Failure to Yield'
		   when driver_condition = 'Drunk Driver'
		       then 'Drunk Driving'
           when atmospheric_conditions_1_name = 'Blowing Sand, Soil, Dirt'			
               then 'Disturbing Weather'			
           when atmospheric_conditions_1_name = 'Sleet or Hail'			
               then 'Disturbing Weather'			
           when atmospheric_conditions_1_name = 'Freezing Rain or Drizzle'			
               then 'Disturbing Weather'			
           when atmospheric_conditions_1_name = 'Blowing Snow'			
               then 'Disturbing Weather'			
		   when atmospheric_conditions_1_name = 'Fog, Smog, Smoke'			
			   then 'Disturbing Weather'			
           when atmospheric_conditions_1_name = 'Rain'			
               then 'Disturbing Weather'
	   else 'Other Cause'
	   end accident_cause
from newcrash
group by 1,2,3,4,5
) x
group by 1

-------
-- lokasi dengan kecelakaan paling banyak berdasarkan milepoint

select 
 x.state_name,
 x.Milepoint, 
 max(x.total_accident) max_num_accident
from
(
select 
 state_name,
 milepoint,
 count(*)Total_Accident
from newcrash
where milepoint not in (0,99998,99999) and
	  state_name in ('Texas', 'California','Florida','Georgia',
					 'North Carolina','Ohio','Illinois','Tennesse',
					 'Pennsylvania','Michigan')
group by 1,2
)X
group by 1,2
order by 3 desc
limit 10



--- Rural and Urban
  select land_use_name,
       type_of_intersection_name,
	   count(total_accident) total_num_accident
from newcrash
where land_use_name in ('Rural','Urban') and
      type_of_intersection_name not in ('Not an Intersection','Other Intersection Type',
									    'Reported as Unknown')
group by 1,2
order by 1

---Analisa kecelakaan yang terjadi pada rural dan urban di jalan yang berbeda-beda

select land_use_name,
       functional_system_name,
	   count(total_accident) total_num_accident
from newcrash
where land_use_name in ('Rural','Urban') and
      functional_system_name not in ('Unknown','Not Reported','Interstate',
									 'Trafficway Not in State Inventory')								    
group by 1,2
order by 1
	
	
	
	
select 
 driver_condition,
 count(total_accident)
from newcrash
group by 1

--Analisa perbandingan kecelakaan dengan adanya pengemudi mabuk dengan adanya penumpang lain dan
--tidak ada penumpang lain

select x.driver_condition, x.driving_status, sum(x.total_num_accident) total_accident
from
(
select driver_condition, total_persons_in_vehicle, count(consecutive_number) total_num_accident,
       case
	       when total_persons_in_vehicle = 1 then 'Lone Driving'
	   else 'Not Lone Driving'
	   end driving_status
from newcrash
group by 1,2
) x  
group by 1,2	



---single driver,single accident lost focus


select
 type_of_accident,
 sum(total_accident)
from newcrash
where type_of_driver = 'Single Driver' and year_of_crash = '2021'
group by 1


-- single driver and drunk


select
 type_of_accident,
 sum(total_accident)
from newcrash
where type_of_driver = 'Single Driver' and driver_condition = 'Drunk Driver' and year_of_crash = '2021'
group by 1



