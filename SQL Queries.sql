----------- Total Unique users : 102
SELECT
	count(DISTINCT user_id)
FROM
	events;

----------- Q1
--------- Q1.a

SELECT
	date(event_timestamp) AS Date,
	count(DISTINCT user_id) AS DAU
FROM
	events
GROUP BY
	date(event_timestamp);

--------- Q1.b
SELECT
	strftime ('%W',
		date(event_timestamp)) AS "Week",
	count(DISTINCT user_id) AS Weekly_stikiness
FROM
	events
GROUP BY
	Week;




----------- Q2
--------- Q2.a

SELECT
	date(event_timestamp) AS Date,
	sum(transaction_value) AS Daily_revenue
FROM
	events
GROUP BY
	date(event_timestamp);

--------- Q2.b
SELECT
	U.Date,
	U.number_U * 100 / DAU.number_DAU AS Conversion_rate
FROM (
	SELECT
		count(DISTINCT user_id) AS number_U,
		date(event_timestamp) AS Date
	FROM
		events
	WHERE
		event_name == 'transaction'
	GROUP BY
		date(event_timestamp)) U
	JOIN (
		SELECT
			count(DISTINCT user_id) AS number_DAU,
			date(event_timestamp) AS Date
		FROM
			events
		GROUP BY
			date(event_timestamp)) DAU ON U.Date = DAU.Date;



----------- Q3
SELECT
	dt AS Date,
	avg(julianday (ifnull(End_time, '23:59:00')) - julianday (Start_time)) * 24 * 60 AS Average_Play_time
FROM (
	SELECT
		S.user_id,
		S.Start_time,
		E.End_time,
		S.dt,
		S.session_id
	FROM (
		SELECT
			user_id,
			time(event_timestamp) AS Start_time,
			date(event_timestamp) AS dt,
			session_id
		FROM
			events
		WHERE
			event_name = 'gameStarted'
		ORDER BY
			user_id,
			event_timestamp) S
		OUTER
	LEFT JOIN (
		SELECT
			user_id,
			time(event_timestamp) AS End_time,
			date(event_timestamp) AS dt,
			session_id
		FROM
			events
		WHERE
			event_name = 'gameEnded'
		ORDER BY
			user_id,
			event_timestamp) E ON S.user_id = E.user_id
		AND S.dt = E.dt
		AND S.session_id = E.session_id)
GROUP BY
	Date;




----------- Q4
---------Q4.a

SELECT
	E.acquisition_channel,
	sum(A.cost) AS Total_acquisition_cost,
	count(E.acquisition_channel) AS Total_number_acquisition,
	AVG(A.cost) AS CPI
FROM (
	SELECT
		event_name,
		acquisition_channel,
		date(event_timestamp) AS Date
	FROM
		events
	WHERE
		event_name == 'install') E
	JOIN acquisition A ON E.Date = A.date
		AND E.acquisition_channel = A. "source "
	GROUP BY
		E.acquisition_channel;

---------Q4.b
SELECT
	E.Date,
	A.cost,
	E.acquisition_channel
FROM (
	SELECT
		event_name,
		acquisition_channel,
		date(event_timestamp) AS Date
	FROM
		events
	WHERE
		event_name == 'install') E
	JOIN acquisition A ON E.Date = A.date
		AND E.acquisition_channel = A. "source " ;



----------- Q5
		SELECT
			DF.Install_Date, AVG(DF.Datediff) as Avgerage_time_to_purchase , AVG(L.LTV) as Average_LTV
		FROM (
			---------Q5.b  ------ Average time to first purcahse after installation.
			SELECT
				E.user_id,
				julianday (A.transaction_date) - julianday (E.install_date) AS Datediff,
				date(E.install_date) AS Install_Date
			FROM (
				SELECT
					event_timestamp AS install_date,
					user_id
				FROM
					events
			WHERE
				event_name = 'install') E
			JOIN (
				SELECT
					event_timestamp AS transaction_date, user_id
				FROM
					events
				WHERE
					event_name = 'transaction') A ON E.user_id = A.user_id
			WHERE
				Datediff > 0 --- Exclude records that the installation is later than transactions!!!
			GROUP BY
				E.user_id
			HAVING
				Datediff = min(Datediff)
			ORDER BY
				E.user_id,
				Install_Date) DF
	LEFT OUTER JOIN (
	------------------- Q5.a.
	SELECT
		user_id,
		AVG(transaction_value) AS LTV
	FROM
		events
	WHERE
		event_timestamp > (
			SELECT
				event_timestamp
			FROM
				events
			WHERE
				event_name = 'install'
			GROUP BY
				user_id)
			AND event_name == 'transaction'
		GROUP BY
			user_id) L ON DF.user_id = L.user_id
GROUP BY
	Install_Date;