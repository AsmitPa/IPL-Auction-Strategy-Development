--Aggressive basman
SELECT batsman
, SUM(batsman_runs) AS total_runs, COUNT(*) - SUM(extra_runs) AS balls_faced
,  (SUM(batsman_runs)::DECIMAL / NULLIF(COUNT(*) - SUM(extra_runs), 0)) * 100 AS strike_rate 
FROM deliveries  
WHERE batsman_runs > 0   
GROUP BY batsman 
HAVING COUNT(*) - SUM(extra_runs) >= 500  
ORDER BY strike_rate DESC 
LIMIT 10;

--Anchor batsman
SELECT batsman
, AVG(batsman_runs) AS average_runs
, COUNT(DISTINCT id)  AS seasons_played 
FROM deliveries
WHERE player_dismissed IS NOT NULL  
GROUP BY batsman 
HAVING COUNT(DISTINCT id) > 2 
ORDER BY seasons_played DESC 
LIMIT 10;

-- bighitters
SELECT batsman
, SUM(batsman_runs) AS total_runs
, SUM(CASE WHEN batsman_runs = 4 THEN 1 ELSE 0 END) AS fours
, SUM(CASE WHEN batsman_runs = 6 THEN 1 ELSE 0 END) AS sixes
, (SUM(CASE WHEN batsman_runs IN (4, 6) THEN batsman_runs ELSE 0  END)::DECIMAL / SUM(batsman_runs)) * 100 AS boundary_percentage 
FROM deliveries  
GROUP BY batsman  
HAVING COUNT(DISTINCT id) > 2
ORDER BY boundary_percentage DESC
LIMIT 10;

-- finishers
SELECT batsman
,       SUM(batsman_runs) AS total_runs
,       COUNT(*) - SUM(extra_runs) AS balls_faced
,       (SUM(batsman_runs)::DECIMAL / NULLIF(COUNT(*) - SUM(extra_runs), 0)) * 100 AS strike_rate
,       COUNT(DISTINCT id) AS matches_played
 FROM deliveries
WHERE over BETWEEN 16 AND 20 
GROUP BY batsman HAVING COUNT(*) - SUM(extra_runs) >= 100 
ORDER BY strike_rate DESC 
LIMIT 10;

--strike rotators
SELECT batsman
,       SUM(batsman_runs) AS total_runs
,       COUNT(*) - SUM(extra_runs) AS balls_faced
,       SUM(CASE WHEN batsman_runs = 1 THEN 1 ELSE 0 END) AS singles
,       SUM(CASE WHEN batsman_runs = 2 THEN 1 ELSE 0 END) AS doubles
,       (SUM(CASE WHEN batsman_runs IN (1, 2) THEN batsman_runs ELSE 0 END)::DECIMAL / SUM(batsman_runs)) * 100 AS rotation_percentage
,       (SUM(CASE WHEN batsman_runs = 1 THEN 1 ELSE 0 END) + SUM(CASE WHEN batsman_runs = 2 THEN 1 ELSE 0 END))::DECIMAL / NULLIF(COUNT(*) - SUM(extra_runs), 0) AS rotation_rate
FROM deliveries 
GROUP BY batsman 
HAVING COUNT(*) - SUM(extra_runs) >= 500 
ORDER BY rotation_rate DESC 
LIMIT 10;

--wicket taking bowlers
SELECT bowler
, COUNT(player_dismissed) AS wickets_taken 
FROM deliveries 
WHERE player_dismissed IS NOT NULL
AND dismissal_kind != 'run out’
AND dismissal_kind != 'NA’
GROUP BY bowler 
ORDER BY wickets_taken DESC 
LIMIT 10;

--economical bowlers
SELECT bowler
,        SUM(total_runs) AS total_runs_conceded, COUNT(*) / 6.0 AS overs_bowled
,        (SUM(total_runs)::DECIMAL / (COUNT(*) / 6.0)) AS economy_rate 
FROM deliveries
GROUP BY bowler  
HAVING COUNT(*) >= 500 
ORDER BY economy_rate ASC 
LIMIT 10;

--best strike rate bowlees
select bowler
,	count(ball) as balls_bowled
,	sum(is_wicket) as total_wickets
, 	(count(ball)::decimal) /(nullif(sum(is_wicket),0)) as strike_rate 	
from deliveries
GROUP BY bowler 
HAVING COUNT(ball) >=500 
ORDER BY strike_rate 
LIMIT 10;

--Allrounders
SELECT b.batsman AS player
, b.balls_faced
, b.batting_strike_rate
, w.balls_bowled
, w.total_wickets
, w.bowling_strike_rate 
FROM (SELECT batsman
	,   COUNT(*) - SUM(extra_runs) AS balls_faced
	,   (SUM(batsman_runs)::DECIMAL / NULLIF(COUNT(*) - SUM(extra_runs), 0)) * 100 AS batting_strike_rate    
FROM deliveries    
WHERE batsman_runs > 0    
GROUP BY batsman    
HAVING COUNT(*) - SUM(extra_runs) >= 500) as b 
	JOIN (    SELECT bowler
	,   COUNT(*) AS balls_bowled
	,   SUM(is_wicket) AS total_wickets
	,  (COUNT(*)::DECIMAL / NULLIF(SUM(is_wicket), 0)) AS bowling_strike_rate    
FROM deliveries    
GROUP BY bowler    
HAVING COUNT(*) >= 300) as w 	
	ON b.batsman = w.bowler 
ORDER BY (b.batting_strike_rate + w.bowling_strike_rate) / 2 DESC 
LIMIT 10;

--Wicket-keepers
SELECT fielder
,  count(case when dismissal_kind ='caught' then 1  else null end ) as catches
,  count(case when dismissal_kind='stumped' then 1      else null end ) as stumpings 
from deliveries 
group by fielder 
order by stumpings desc 
limit 10;

---auction strategy
(SELECT 'Aggressive Batsman' AS category, batsman AS player,  SUM(batsman_runs) AS total_runs,  COUNT(*) - SUM(extra_runs) AS balls_faced,       (SUM(batsman_runs)::DECIMAL / NULLIF(COUNT(*) - SUM(extra_runs), 0)) * 100 AS strike_rate
FROM deliveries
WHERE batsman_runs > 0
GROUP BY batsman
HAVING COUNT(*) - SUM(extra_runs) >= 500
ORDER BY strike_rate DESC
LIMIT 3)
UNION ALL
(SELECT 'Anchor Batsman' AS category, batsman AS player,  AVG(batsman_runs) AS average_runs,  COUNT(DISTINCT id) AS seasons_played,   NULL AS strike_rate
FROM deliveries
WHERE player_dismissed IS NOT NULL
GROUP BY batsman
HAVING COUNT(DISTINCT id) > 2
ORDER BY seasons_played DESCLIMIT 3)
UNION ALL
(SELECT 'Big Hitter' AS category, batsman AS player,  SUM(batsman_runs) AS total_runs,  SUM(CASE WHEN batsman_runs = 4 THEN 1 ELSE 0 END) AS fours,   SUM(CASE WHEN batsman_runs = 6 THEN 1 ELSE 0 END) AS sixes
FROM deliveries
GROUP BY batsman
HAVING COUNT(DISTINCT id) > 2
ORDER BY sixes DESC
LIMIT 3)
UNION ALL
(SELECT 'Finisher' AS category, batsman AS player,  SUM(batsman_runs) AS total_runs,   COUNT(*) - SUM(extra_runs) AS balls_faced,  (SUM(batsman_runs)::DECIMAL / NULLIF(COUNT(*) - SUM(extra_runs), 0)) * 100 AS strike_rate
FROM deliveries
WHERE over BETWEEN 16 AND 20
GROUP BY batsman
HAVING COUNT(*) - SUM(extra_runs) >= 100
ORDER BY strike_rate DESC
LIMIT 3)
UNION ALL
(SELECT 'Strike Rotator' AS category, batsman AS player,   SUM(batsman_runs) AS total_runs,   SUM(CASE WHEN batsman_runs = 1 THEN 1 ELSE 0 END) AS singles,  SUM(CASE WHEN batsman_runs = 2 THEN 1 ELSE 0 END) AS doubles  
 FROM deliveries
GROUP BY batsman
HAVING COUNT(*) - SUM(extra_runs) >= 500
ORDER BY singles DESC
LIMIT 3)UNION ALL
(SELECT 'Wicket-Taking Bowler' AS category, bowler AS player,  COUNT(player_dismissed) AS wickets_taken,  NULL AS balls_faced,  NULL AS strike_rate
FROM deliveries
WHERE player_dismissed IS NOT NULL
	AND dismissal_kind != 'run out'
	AND dismissal_kind != 'NA'
GROUP BY bowler
ORDER BY wickets_taken DESC
LIMIT 3)
UNION ALL
(SELECT 'Economical Bowler' AS category, bowler AS player,   SUM(total_runs) AS total_runs_conceded,   COUNT(*) / 6.0 AS overs_bowled,   (SUM(total_runs)::DECIMAL / (COUNT(*) / 6.0)) AS economy_rate
FROM deliveries
GROUP BY bowler
HAVING COUNT(*) >= 500
ORDER BY economy_rate ASC
LIMIT 3)
UNION ALL
(SELECT 'All-Rounder' AS category, b.batsman AS player,   b.batting_strike_rate AS strike_rate,    w.total_wickets,    w.bowling_strike_rateFROM     (SELECT batsman,   COUNT(*) - SUM(extra_runs) AS balls_faced,   (SUM(batsman_runs)::DECIMAL / NULLIF(COUNT(*) - SUM(extra_runs), 0)) * 100 AS batting_strike_rate   
 FROM deliveries  
WHERE batsman_runs > 0   
 GROUP BY batsman    
HAVING COUNT(*) - SUM(extra_runs) >= 500    
ORDER BY batting_strike_rate DESC    LIMIT 5) as b JOIN(SELECT bowler, COUNT(*) AS balls_bowled, SUM(is_wicket) AS total_wickets,(COUNT(*)::DECIMAL / NULLIF(SUM(is_wicket), 0)) AS bowling_strike_rate    
	FROM ipl_ball    
	GROUP BY bowler    
	HAVING COUNT(*) >= 300    
	ORDER BY bowling_strike_rate ASC    
	LIMIT 5) as w ON b.batsman = w.bowler
	ORDER BY (b.batting_strike_rate + w.bowling_strike_rate) / 2 DESCLIMIT 3)
	UNION ALL
	(SELECT 'Wicketkeeper' AS category, fielder AS player, count(case when dismissal_kind ='caught' then 1 else null end ) AS catches, count(case when dismissal_kind='stumped' then 1 else null end ) AS stumpings, NULL AS strike_rate 
	FROM deliveries 
	GROUP BY fielder 
	ORDER BY stumpings DESC 
	LIMIT 3);

--Additional questions

--1.There are 33 cities hosting IPL matches.

SELECT COUNT(DISTINCT city) AS cities_hosted_ipl FROM ipl_matches;

--2.Created table’deliveries2’ using table deliveries

CREATE TABLE deliveries AS SELECT     id,    inning,    over,    ball,    batsman,          non_striker,    bowler,    batsman_runs,    extra_runs,    total_runs,    is_wicket,    dismissal_kind,    player_dismissed,    fielder,    extras_type,    batting_team,    bowling_team,    
CASE   
WHEN total_runs >= 4 THEN 'boundary'        
WHEN total_runs = 0 THEN 'dot'   ELSE 'other'   END AS ball_result 
FROM deliveries;

--3. Total boundries hit are 31468 and total dot balls are 67841.

SELECT     
SUM(CASE WHEN ball_result = 'boundary' THEN 1 ELSE 0 END) AS total_boundaries, 
SUM(CASE WHEN ball_result = 'dot' THEN 1 ELSE 0 END) AS total_dot_balls 
FROM deliveries;

--4. Total boundaries hit by each team.

SELECT     batting_team,     
SUM(CASE WHEN ball_result = 'boundary' THEN 1 ELSE 0 END) AS total_boundaries 
FROM deliveries 
GROUP BY batting_team 
ORDER BY total_boundaries DESC;

--5. Most dot balls bowled by team Mumbai Indians.

SELECT  bowling_team,  
SUM(CASE WHEN ball_result = 'dot' THEN 1 ELSE 0 END) AS total_dot_balls 
FROM deliveries 
GROUP BY bowling_team 
ORDER BY total_dot_balls DESC;

--6. Most number of dismissal kind are caught.

SELECT     dismissal_kind,     COUNT(*) AS total_dismissals 
FROM deliveries
WHERE dismissal_kind IS NOT NULL 
AND dismissal_kind <> 'NA’ 
GROUP BY dismissal_kind 
ORDER BY total_dismissals DESC;

--7. Most extra runs are given by SL malinga.
	
SELECT bowler,     
SUM(extra_runs) AS total_extra_runs 
FROM deliveries 
GROUP BY bowler 
ORDER BY total_extra_runs DESC 
LIMIT 5;

--8. Created table deliveries3 using table deliveries and ipl_matches.
	
CREATE TABLE deliveries3 AS  SELECT  d.*,     m.venue,    m.date AS match_date 
FROM     ipl_ball as d 
JOIN     ipl_matches as m ON     d.id = m.id;

--9. Most runs scored on venue Eden Gardens followed by Wankhede Stadium.
	
SELECT venue, SUM(total_runs) AS total_runs_scored 
FROM deliveries3 
GROUP BY venue 
ORDER BY total_runs_scored DESC;

--10. Most runs(2885) scored in ipl season 2018 folloed by runs(2651) scored in ipl season 2019 at Eden Gardens.
	
SELECT EXTRACT(YEAR FROM match_date) AS year, SUM(total_runs) AS total_runs_scored 
FROM deliveries2 
WHERE venue = 'Eden Gardens’
GROUP BY year 
ORDER BY total_runs_scored DESC;








select* from deliveries;

