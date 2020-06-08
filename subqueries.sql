/*First, we needed to group by the day and channel. Then ordering by the number of events (the third column) /
gave us a quick way to answer the first question.*/


SELECT DATE_TRUNC('day',occurred_at) AS day,
   channel, COUNT(*) as events
FROM web_events
GROUP BY 1,2
ORDER BY 3 DESC;

/* Here you can see that to get the entire table in question 1 back, we included an * in our SELECT statement. /
You will need to be sure to alias your table.*/

SELECT *
FROM (SELECT DATE_TRUNC('day',occurred_at) AS day,
           channel, COUNT(*) as events
     FROM web_events
     GROUP BY 1,2
     ORDER BY 3 DESC) sub;

/* Finally, here we are able to get a table that shows the average number of events a day for each channel.*/

SELECT channel, AVG(events) AS average_events
FROM (SELECT DATE_TRUNC('day',occurred_at) AS day,
             channel, COUNT(*) as events
      FROM web_events
      GROUP BY 1,2) sub
GROUP BY channel
ORDER BY 2 DESC;


/*Here is the necessary quiz to pull the first month/year combo from the orders table.*/

SELECT DATE_TRUNC('month', MIN(occurred_at))
FROM orders;

/*Then to pull the average for each, we could do this all in one query, but for readability, I provided two queries below to perform each separately.*/

SELECT AVG(standard_qty) as avg_std, AVG(gloss_qty) as avg_gls, AVG(poster_qty) as avg_pst
FROM orders
WHERE DATE_TRUNC('month', occurred_at) =
     (SELECT DATE_TRUNC('month', MIN(occurred_at)) FROM orders);

SELECT SUM(total_amt_usd)
FROM orders
WHERE DATE_TRUNC('month', occurred_at) =
      (SELECT DATE_TRUNC('month', MIN(occurred_at)) FROM orders);


/*Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales.*/

WITH sub_table as AS (
  SELECT s.name as rep_name, r.name as region_name, SUM(o.total_amt_usd) as total_amt
   FROM sales_reps as s
   JOIN accounts as a
   ON a.sales_rep_id = s.id
   JOIN orders as o
   ON o.account_id = a.id
   JOIN region as r
   ON r.id = s.region_id
   GROUP BY 1,2
   ORDER BY 3 DESC),
  sub_table2 AS (
   SELECT region_name, MAX(total_amt) total_amt
   FROM sub_table
   GROUP BY 1)
SELECT sub_table.rep_name, sub_table.region_name, sub_table.total_amt
FROM sub_table
JOIN sub_table2
ON sub_table2.region_name = sub_table2.region_name AND sub_table2.total_amt = sub_table2.total_amt;

/*Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales.*/


WITH sub_table AS (
   SELECT r.name region_name, SUM(o.total_amt_usd) total_amt
   FROM sales_reps as s
   JOIN accounts as a
   ON a.sales_rep_id = s.id
   JOIN orders as o
   ON o.account_id = a.id
   JOIN region as r
   ON r.id = s.region_id
   GROUP BY r.name),
sub_table2 AS (
   SELECT MAX(total_amt)
   FROM sub_table)
SELECT r.name, COUNT(o.total) total_orders
FROM sales_reps as s
JOIN accounts as a
ON a.sales_rep_id = s.id
JOIN orders as o
ON o.account_id = a.id
JOIN region as r
ON r.id = s.region_id
GROUP BY r.name
HAVING SUM(o.total_amt_usd) = (SELECT * FROM sub_table2);

/*For the account that purchased the most (in total over their lifetime as a customer) standard_qty paper, /
how many accounts still had more in total purchases?*/

WITH sub_table AS (
  SELECT a.name as account_name, SUM(o.standard_qty) as total_std, SUM(o.total) as total
  FROM accounts as a
  JOIN orders as o
  ON o.account_id = a.id
  GROUP BY 1
  ORDER BY 2 DESC
  LIMIT 1),
sub_table2 AS (
  SELECT a.name
  FROM orders as o
  JOIN accounts as a
  ON a.id = o.account_id
  GROUP BY 1
  HAVING SUM(o.total) > (SELECT total FROM t1))
SELECT COUNT(*)
FROM sub_table2;

/*For the customer that spent the most (in total over their lifetime as a customer) total_amt_usd, how many web_events did they have for each channel?*/

WITH sub_table AS (
   SELECT a.id, a.name, SUM(o.total_amt_usd) as total
   FROM orders as o
   JOIN accounts as a
   ON a.id = o.account_id
   GROUP BY a.id, a.name
   ORDER BY 3 DESC
   LIMIT 1)
SELECT a.name, w.channel, COUNT(*)
FROM accounts as a
JOIN web_events as w
ON a.id = w.account_id AND a.id =  (SELECT id FROM sub_table)
GROUP BY 1, 2
ORDER BY 3 DESC;

/*What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?*/

WITH sub_table AS (
   SELECT a.id, a.name, SUM(o.total_amt_usd) as tot_spent
   FROM orders as o
   JOIN accounts as a
   ON a.id = o.account_id
   GROUP BY a.id, a.name
   ORDER BY 3 DESC
   LIMIT 10)
SELECT AVG(tot_spent)
FROM sub_table;

/*What is the lifetime average amount spent in terms of total_amt_usd, /
including only the companies that spent more per order, on average, than the average of all orders.*/

WITH sub_table AS (
   SELECT AVG(o.total_amt_usd) as avg_all
   FROM orders as o
   JOIN accounts as a
   ON a.id = o.account_id),
sub_table2 AS (
   SELECT o.account_id, AVG(o.total_amt_usd) as avg_amt
   FROM orders as o
   GROUP BY 1
   HAVING AVG(o.total_amt_usd) > (SELECT * FROM sub_table))
SELECT AVG(avg_amt)
FROM sub_table2;
