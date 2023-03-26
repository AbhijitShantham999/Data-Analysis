create table airbnb_nyc_2019
(
id int,
name text,
host_id int,
host_name text,
neighbourhood_group text,
neighbourhood text,
latitude double,
longitude double,
room_type text,
price int,
minimum_nights int,
number_of_reviews int,
reviews_per_month text,
calculated_host_listings_count int,
availability_365 int
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\airbnb_nyc_2019.csv' 
INTO TABLE airbnb_nyc_2019 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

show variables like "secure_file_priv";

select * from airbnb_nyc_2019;


-- ANSWERING SOME QUERY QUESTIONS FOR AIRBNB DATASET:

-- EXPLORATORY DATA ANALYSIS

/* 1.What is the average preferred price of neighbourhood group to the location?*/

select neighbourhood_group,avg(price) Average_price 
from airbnb_nyc_2019
group by neighbourhood_group;

/*2. Where the customer pays the highest and lowest rent according to location?*/

select neighbourhood,max(price) as Highest_rent,min(price) as Lowest_rent 
from airbnb_nyc_2019
group by neighbourhood;

/* 3. neighbourhood group  and listing insights in percentage*/

with my_cte as ( select neighbourhood_group,count(calculated_host_listings_count) as total_listing 
				 from airbnb_nyc_2019
				 group by neighbourhood_group )
select neighbourhood_group,round((total_listing/sum(total_listing)over())* 100,2) as percentage 
from my_cte
order by percentage desc;

/*4. what is the average cost of stay in different room types */

select room_type,avg(price) avg_price 
from airbnb_nyc_2019
group by room_type;

/*5.how much room types are in each neighbourhood group*/

select neighbourhood_group,room_type,count(room_type) 
from airbnb_nyc_2019
group by neighbourhood_group,room_type;

/*6. Total no of nights spend per room types in percentage*/

with my_cte as (	select *,sum(sum_minimum_nights)over() as total_nights 
					from (  select room_type,sum(minimum_nights) as sum_minimum_nights 
							from airbnb_nyc_2019
							group by room_type )
                            as ss
				)
select room_type,round((sum_minimum_nights/total_nights)*100,2) as min_nights_percentage 
from my_cte;

/* 7.Most preferred room types by customer.*/

with pref_room as ( select *, sum(cnt_roomtype)over() as sum_roomtype 
					from (	select room_type,count(room_type) as cnt_roomtype 
							from airbnb_nyc_2019
							group by room_type	) as s1
			      )
select *, round((cnt_roomtype/sum_roomtype)*100,2) as percentage 
from pref_room;

/* 8.Find the total count of each room type*/

select room_type,count(room_type) as cnt_roomtype 
from airbnb_nyc_2019
group by room_type;


/*9.Room types and their relationship with availability in different neighbourhood groups?*/

with my_cte as (select *,sum(sum_avail)over(partition by neighbourhood_group) as total_avail
				from (select neighbourhood_group,room_type,sum(availability_365) as sum_avail
						from airbnb_nyc_2019
						group by neighbourhood_group,room_type) as s1)
select neighbourhood_group,room_type,round((sum_avail/total_avail)*100,2) as percentage_availability 
from my_cte;


/*10.Find top 10 hosts with most listings*/

select host_name,max(calculated_host_listings_count) as max_listing 
from airbnb_nyc_2019
group by host_name
order by max_listing desc
limit 10;

/*11.Find top 10 hosts with most reviews*/

select host_name,max(reviews_per_month) as max_review 
from airbnb_nyc_2019
group by host_name
order by max_review desc
limit 10;

/*12.Which host has the highest average number of reviews per month for their listings?
   Display the host ID, host name, and average reviews per month.*/

select host_id,host_name,max(avg_review) as max_review 
from (  select host_id,host_name,avg(reviews_per_month) as avg_review 
	    from airbnb_nyc_2019
		group by host_id,host_name
	    ) as sub
group by host_id,host_name
order by max_review desc
limit 1;


/*13.What is the average number of reviews per month for listings that have a price greater than or equal to $500 per night? 
     Display the average reviews per month and the number of listings that meet this criteria.*/

select distinct host_id,host_name,avg(reviews_per_month) as avg_review,calculated_host_listings_count 
from airbnb_nyc_2019
where price >= 500
group by host_id,host_name,price,calculated_host_listings_count;


/* 14.Which neighbourhood group has the highest percentage of listings with a reviews per month greater than 1? 
-- Display the neighbourhood group and the percentage of listings.*/

with my_cte as ( select neighbourhood_group,sum(calculated_host_listings_count) as total_listing 
				 from airbnb_nyc_2019
				 where number_of_reviews > 1
				 group by neighbourhood_group )
select neighbourhood_group,round((total_listing/sum(total_listing)over())* 100,2) as percentage 
from my_cte
order by percentage desc;

/* 15.For each neighbourhood, what is the average price of the 5 most expensive listings in that neighbourhood? 
	Display the neighbourhood name,the name of the listing, and the average price.*/

select neighbourhood,max(price) as max_price,avg(price) as avg_price 
from airbnb_nyc_2019 
group by neighbourhood
order by max_price desc
limit 5;


/* 16.Which host has the highest number of listings in a single neighbourhood?
 Display the host ID, host name, neighbourhood, and the number of listings.*/

select distinct host_id,host_name,neighbourhood,listing 
from( select host_id,host_name,neighbourhood,calculated_host_listings_count as listing,
	   max(calculated_host_listings_count)over(partition by neighbourhood) as max_listing
	   from airbnb_nyc_2019
    ) as sq
where listing = max_listing;

/* 17.Which neighbourhoods have at least 50 listings with a minimum number of nights greater than or equal to 5?
 Display the neighbourhood name and the number of listings that meet this criteria.*/

 select distinct neighbourhood,minimum_nights,calculated_host_listings_count 
 from airbnb_nyc_2019
 where calculated_host_listings_count >= 50 and minimum_nights >= 5
 order by minimum_nights desc;

/* 18.What is the average availability for each neighbourhood group? Display the neighbourhood group 
	and the average availability in days.*/

select distinct neighbourhood, avg(availability_365) as average_availability_next_365days 
from airbnb_nyc_2019
group by neighbourhood;

/* 19.Which hosts have at least 10 listings, all of which have a reviews per month greater than 1? Display the host ID and host name.*/

select distinct host_id,host_name 
from airbnb_nyc_2019
where calculated_host_listings_count >= 10 and reviews_per_month > 1;


/* 20.For each host, what is the median number of reviews per month across all of their listings? 
	Display the host ID, host name, and median reviews per month.*/

with my_cte as ( select *,abs(CAST(review_rows_desc AS SIGNED) - CAST(review_rows_asc AS SIGNED)) AS diff
					from 
							( select host_id,host_name,reviews_per_month,
											  row_number( )over( partition by host_name order by reviews_per_month desc ) as review_rows_desc,
                                              row_number( )over( partition by host_name order by reviews_per_month asc) as review_rows_asc
									   from airbnb_nyc_2019
									  ) as sm 
				)
select host_id,host_name,reviews_per_month as median_review_per_month from my_cte
where diff <= 1;
