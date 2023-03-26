drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1, '2017-04-19', 2),
       (3, '2019-12-18', 1),
       (2, '2020-07-20', 3),
       (1, '2019-10-23', 2),
       (1, '2018-03-19', 3),
       (3, '2016-12-20', 2),
       (1, '2016-11-09', 1),
       (1, '2016-05-20', 3),
       (2, '2017-09-24', 1),
       (1, '2017-03-11', 2),
       (1, '2016-03-11', 1),
       (3, '2016-11-10', 1),
       (3, '2017-12-07', 2),
       (3, '2016-12-15', 2),
       (2, '2017-11-08', 2),
       (2, '2018-09-10', 3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

select * from goldusers_signup;
select * from sales;
select * from product;
select * from users;

-- EXPLORATORY DATA ANALYSIS 

1.what is total amount each customer spent on zomato ?

select userid,sum(price) from sales s join product p on s.product_id = p.product_id 
group by userid
order by userid;


2.How many days has each customer visited zomato?

select userid,count(created_date) from sales
group by userid
order by userid;


3.what was the first product purchased by each customer?

select userid, min(created_date) as mdate,product_id from sales
where product_id = 1
group by userid,product_id
order by userid;


4.what is most purchased item on menu & how many times was it purchased by all customers ?


SELECT created_date, product_id, maxp,COUNT(maxp)
FROM (	select  created_date, product_id, MAX(product_id) AS maxp  from sales
		GROUP BY created_date, product_id
	  ) am
group by created_date, product_id,maxp;

select userid, count(product_id) cnt 
from sales 
where product_id = (
						select  product_id 
						from sales 
						group by product_id 
						order by count(product_id) desc
                        limit 1
					  ) 
group by userid


5.which item was most popular for each customer?


with cte as (select *,dense_rank() over(partition by userid order by cnt desc ) as rnk
				from (select userid, product_id , count(product_id) over(partition by userid,product_id ) as cnt 
						from sales) as c)
select distinct * from cte     
where rnk = 1;
  
  
6.which item was purchased first by customer after they become a member ?


with cte as (  select s.userid,product_id,created_date from sales s join users u on s.userid = u.userid 
			   order by userid asc, created_date asc
			 )
select * from (select *,row_number()over(partition by userid order by created_date) rnk from cte) rm
where rnk = 1


7. which item was purchased just before the customer became a member?


with tb as (select distinct s.userid,product_id,gold_signup_date,created_date
			from goldusers_signup gs 
			join sales s 
			on s.userid = gs.userid
			where created_date < gold_signup_date
			order by s.userid asc ,created_date desc ,gold_signup_date asc)
select * from (select *,dense_rank()over(partition by userid order by created_date desc) as rnk 
			   from tb) as fi
where rnk = 1
order by userid;



8. what is total orders and amount spent for each member before they become a member?


with tb as (
				select s.userid,s.product_id,product_name,price,gold_signup_date,created_date
				from sales s 
				join product p 
				on s.product_id = p.product_id 
				join goldusers_signup gs
				on gs.userid = s.userid
				where created_date < gold_signup_date
				order by userid,created_date desc,gold_signup_date
			) 
select userid,count(product_id) as total_orders,sum(price) as amount_spent from tb
group by userid
order by userid


9. If buying each product generates points for eg 5rs=2 zomato point 
  and each product has different purchasing points for eg for p1 5rs=1 zomato point,for p2 10rs=zomato point and p3 5rs=1 zomato point  
  2rs =1zomato point, calculate points collected by each customer and for which product most points have been given till now.

with tb as (select userid,product_name,
			round(sum(case when product_name = 'p1' then price/5 
			         when product_name = 'p2' then price/10 
                     when product_name = 'p3' then price/5 else 0
			    end*2),0) as zomato_point
                from sales s join product p on s.product_id = p.product_id
                group by userid,product_name
                )
select userid,product_name,zompnt from(select userid,product_name,zompnt,
		rank()over(partition by userid order by zompnt desc) as rnk
 from(select userid,product_name,
	  max(zomato_point)over(partition by userid,product_name order by zomato_point ) as zompnt
	  from tb) as a) as b
where rnk = 1


10. In the first year after a customer joins the gold program (including the join date) irrespective of what customer 
has purchased earn 5 zomato points for every 10rs spent who earned more more 1 or 3 what int earning in first yr ? 1zp = 2rs

with my_cte as (    select distinct s.userid,u.signup_date,gold_signup_date,
								s.created_date,s.product_id,product_name,price,
								round(((price/10)*5)*2,0) as zomato_points_rupees,year(created_date) as yr,
								row_number()over(partition by userid order by s.created_date) as row_num
                from sales s
				join goldusers_signup gs on s.userid = gs.userid 
				join product p on p.product_id = s.product_id
				join users u on u.userid = s.userid
				where created_date > gold_signup_date
			)
select * from my_cte
where row_num = 1


11. rnk all transaction of the customers

select *,rank()over(partition by userid order by created_date) as transaction from sales
order by userid


12. rank all transaction for each member whenever they are zomato gold member for every non gold member transaction mark as na


select s.userid,s.product_id,price,gold_signup_date,created_date,
		 case when created_date > gold_signup_date then rank()over(partition by userid order by userid asc,created_date desc) else 'NA' end as rnk 
from sales s 
join goldusers_signup gs 
on s.userid = gs.userid
join product p
on p.product_id = s.product_id;



