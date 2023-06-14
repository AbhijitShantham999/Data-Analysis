create table athlete_events
(
	ID	int, 
	Name text,
    Sex text,
    Age text,
	Height	text,
    Weight text,
	Team text,
    NOC text,
	Games text,
    Year int,
	Season text,
    City text,	
	Sport text,
    Event text,
	Medal text
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\athlete_events.csv' 
INTO TABLE athlete_events 
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;

select * from athlete_events;
select * from noc_regions;

-- SQL Query Questions:

-- Exploratory Data Analysis

-- 1.How many olympics games have been held?

select count(distinct games) from athlete_events;

-- 2.List down all Olympics games held so far.

select distinct games,city from athlete_events
order by games;

-- 3.Mention the total no of nations who participated in each olympics game?

select * from athlete_events;
select * from noc_regions;

select games,count(distinct a.noc) count_of_noc from athlete_events a join noc_regions n on a.noc = n.noc
group by games
order by games;
-------------------------------------------------------------------------------------------------
-- 4.Which year saw the highest and lowest no of countries participating in olympics?

(select games,min(count_of_team) mi  from
(select distinct games,count(distinct team) count_of_team from athlete_events
group by games
order by count_of_team) sq
group by games
limit 1)
union all
(select games,max(count_of_team) ma  from
(select distinct games,count(distinct team) count_of_team from athlete_events
group by games
order by count_of_team) sq
group by games
order by ma desc
limit 1);


  with all_countries as
              (select games, nr.region
              from athlete_events oh
              join noc_regions nr ON nr.noc=oh.noc
              group by games, nr.region),
          tot_countries as
              (select games, count(1) as total_countries
              from all_countries
              group by games)
      select distinct
      concat(first_value(games) over(order by total_countries)
      , ' - '
      , first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      concat(first_value(games) over(order by total_countries desc)
      , ' - '
      , first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
      from tot_countries
      order by 1;

---------------------------------------------------------------------------------------------------

-- 5.Which nation has participated in all of the olympic games?

select distinct games from athlete_events;

with cte as (
				select region,count(region) participated_in_all_games 0
				from
					(	select distinct region,games,count(region) 
						from athlete_events a 
						join noc_regions n 
						on a.noc = n.noc
                        group by games,region
                        order by region,games
					) sq
				group by region
			)
select * from cte 
where participated_in_all_games = (select count(distinct games)from athlete_events);


-- 6.Identify the sport which was played in all summer olympics.

with cte1 as
(select distinct sport,games from athlete_events
where season = 'summer'
group by sport,games),
cte2 as
( select sport,count(sport) as cnt_sport from cte1
  group by sport
)
select * from cte2
where cnt_sport = (select count(distinct games) from athlete_events
					where season = 'summer');

-- 7.Which Sports were just played only once in the olympics?

with cte1 as
(select distinct sport,games from athlete_events
where season = 'summer'
group by sport,games),
cte2 as
( select sport,count(sport) as cnt_sport from cte1
  group by sport
)
select * from cte2
where cnt_sport = 1;


-- 8.Fetch the total no of sports played in each olympic games.

select games,count(distinct sport) from athlete_events
group by games
order by 2 desc;

-- 9.Fetch details of the oldest athletes to win a gold medal.

with cte as(
			select Name,sex,case when age = 'NA' then 0 else age end as age,team,games,city,sport,event,medal from athlete_events
			where medal like 'Gold%'
			order by age desc
		   ),
cte2 as (
			select *, rank()over(order by age desc) rnk from cte
		)
select name,sex,age,team,games,city,sport,event,medal from cte2
where rnk = 1;

-- 10.Find the Ratio of male and female athletes participated in all olympic games.
			   
select concat(round(F/F) , ' : ', round(M/F ,2)) Ratio	 -- (Female to Male)
from(        select count(case when sex = 'M' then 1 end) as M,
			 count(case when sex = 'F' then 1 end) as F
			 from athlete_events 
	) sq;

-- 11.Fetch the top 5 athletes who have won the most gold medals.

with cte as(
select name,team,count(medal)as Total_Gold_Medals from athlete_events
where medal like 'gold%'
group by name,team
),
cte2 as(select *,dense_rank()over(order by Total_Gold_Medals desc) rnk from cte)
select name,team,Total_Gold_Medals from cte2
where rnk <= 5;

-- 12.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

with cte as
(select name,team,count(medal) as Total_medals from athlete_events
where medal like 'Gold%' or medal like 'Silver%' or medal like 'Bronze%'
group by name,team),
cte2 as(
select *,dense_rank()over(order by Total_medals desc) rnk from cte
)
select * from cte2
where rnk <= 5;

-- 13.Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

with cte as
		(	select region,count(medal) Total_Medals
			from athlete_events a 
			join noc_regions n 
			on a.noc = n.noc
			where medal like 'Gold%' or medal like 'Silver%' or medal like 'Bronze%'
			group by region
			order by 2 desc
		),
cte2 as (	select *,rank()over(order by Total_Medals desc) rnk 
			from cte
		) 
select * from cte2
where rnk <=5;

-- 14.List down total gold, silver and broze medals won by each country.

select region,sum(case when medal like 'Gold%' then 1 else 0 end ) Total_Gold_Medals,
			  sum(case when medal like 'Silver%' then 1 else 0 end ) Total_Silver_Medals,
			  sum(case when medal like 'Bronze%' then 1 else 0 end ) Total_Bronze_Medals
from athlete_events a 
join noc_regions n 
on a.noc = n.noc
where medal not like 'NA%'
group by region
order by 2 desc,3 desc,4 desc;


-- 15.List down total gold, silver and broze medals won by each country corresponding to each olympic games.

select games,region, sum(case when medal like 'Gold%' then 1 else 0 end ) Gold,
					 sum(case when medal like 'Silver%' then 1 else 0 end ) Silver,
                     sum(case when medal like 'Bronze%' then 1 else 0 end ) Bronze
from athlete_events a 
join noc_regions n 
on a.noc = n.noc
where medal not like 'NA%'
group by games,region
order by 1,2;
                     
-- 16.Identify which country won the most gold, most silver and most bronze medals in each olympic games.

with cte1 as (
				select games,max_gold from (
												select games,concat(region,'-',cnt_medal) as max_gold,
                                                row_number()over(partition by games) as rownum 
                                                from(
														select games,region,count(medal) as cnt_medal
														from athlete_events a 
														join noc_regions n 
														on a.noc = n.noc
														where medal like 'Gold%'
														group by games,region 
														order by 1,3 desc
													 ) as sq1
											)sq2
				where rownum = 1
			),
cte2 as (
			select games,max_silver from (
												select games,concat(region,'-',cnt_medal) as max_silver,
                                                row_number()over(partition by games) as rownum 
                                                from(
														select games,region,count(medal) as cnt_medal
														from athlete_events a 
														join noc_regions n 
														on a.noc = n.noc
														where medal like 'Silver%'
														group by games,region 
														order by 1,3 desc
													 ) as sq1
											)sq2
				where rownum = 1
),
cte3 as (
			select games,max_bronze from (
												select games,concat(region,'-',cnt_medal) as max_bronze,
                                                row_number()over(partition by games) as rownum 
                                                from(
														select games,region,count(medal) as cnt_medal
														from athlete_events a 
														join noc_regions n 
														on a.noc = n.noc
														where medal like 'Bronze%'
														group by games,region 
														order by 1,3 desc
													 ) as sq1
											)sq2
				where rownum = 1
)

select c1.games,max_gold,max_silver,max_bronze 
from cte1 c1 
join cte2 c2 on c1.games = c2.games 
join cte3 c3 on c1.games = c3.games;


-- 17.Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.

with cte1 as (
				select games,max_gold from (
												select games,concat(region,'-',cnt_medal) as max_gold,
                                                row_number()over(partition by games) as rownum 
                                                from(
														select games,region,count(medal) as cnt_medal
														from athlete_events a 
														join noc_regions n 
														on a.noc = n.noc
														where medal like 'Gold%'
														group by games,region 
														order by 1,3 desc
													 ) as sq1
											)sq2
				where rownum = 1
			),
cte2 as (
			select games,max_silver from (
												select games,concat(region,'-',cnt_medal) as max_silver,
                                                row_number()over(partition by games) as rownum 
                                                from(
														select games,region,count(medal) as cnt_medal
														from athlete_events a 
														join noc_regions n 
														on a.noc = n.noc
														where medal like 'Silver%'
														group by games,region 
														order by 1,3 desc
													 ) as sq1
											)sq2
				where rownum = 1
),
cte3 as (
			select games,max_bronze from (
												select games,concat(region,'-',cnt_medal) as max_bronze,
                                                row_number()over(partition by games) as rownum 
                                                from	(
															select games,region,count(medal) as cnt_medal
															from athlete_events a 
															join noc_regions n 
															on a.noc = n.noc
															where medal like 'Bronze%'
															group by games,region 
															order by 1,3 desc
														) as sq1
										)sq2
				where rownum = 1
),
cte4 as (
			select games,max_medals from (
												select games,concat(region,'-',max_cnt_medal) as max_medals,
                                                row_number()over(partition by games) as rownum 
                                                from(
														select games,region,max(cnt_medal) as max_cnt_medal from
															(	select distinct games,region,count(medal) as cnt_medal
																from athlete_events a 
																join noc_regions n 
																on a.noc = n.noc
																group by games,region 
																order by 1,3 desc	) sq2
														group by games,region	
													) as sq1
											)sq2
				where rownum = 1
)

select distinct c1.games,max_gold,max_silver,max_bronze,max_medals
from cte1 c1 
join cte2 c2 on c1.games = c2.games 
join cte3 c3 on c2.games = c3.games
join cte4 c4 on c3.games = c4.games;

-- 18.Which countries have never won gold medal but have won silver/bronze medals?


-- 19.In which Sport/event, India has won highest medals.

select Sport,count(medal) Highest_medal
from athlete_events a 
join noc_regions n 
on a.noc = n.noc
where region = 'India' and medal not like 'NA%'
group by sport
order by 2 desc
limit 1;


-- 20.Break down all olympic games where india won medal for Hockey and how many medals in each olympic games.

select region,sport,games,count(medal) Highest_medal
from athlete_events a 
join noc_regions n 
on a.noc = n.noc
where region = 'India' and sport = 'Hockey' and medal not like 'NA%'
group by games,sport
order by 4 desc;
