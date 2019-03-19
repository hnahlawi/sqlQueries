-- Getting soft

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q2;

-- You must not change this table definition.
CREATE TABLE q2 (
	ta_name varchar(100),
	average_mark_all_assignments real,
	mark_change_first_last real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS masterList CASCADE;
DROP VIEW IF EXISTS existing CASCADE;
DROP VIEW IF EXISTS resultCounts CASCADE;
DROP VIEW IF EXISTS hasntGraded CASCADE;
DROP VIEW IF EXISTS hasGradedTen CASCADE;
DROP VIEW IF EXISTS AssignmentTotal CASCADE;
DROP VIEW IF EXISTS studentMarks CASCADE;
DROP VIEW IF EXISTS averages CASCADE;
DROP VIEW IF EXISTS decreasingTAs CASCADE;
DROP VIEW IF EXISTS qualifyingTAs CASCADE;
DROP VIEW IF EXISTS last_assignment CASCADE;
DROP VIEW IF EXISTS first_assignment CASCADE;
DROP VIEW IF EXISTS markChange CASCADE;

-- Define views for your intermediate steps here.
CREATE OR REPLACE VIEW masterList AS
SELECT * 
FROM (
	SELECT distinct username 
	FROM markususer 
	WHERE type = 'TA') ta, Assignment; 

CREATE OR REPLACE VIEW existing AS
SELECT  
username, 
assignment_id,
count(*)
FROM Result
JOIN Grader
ON Grader.group_id = Result.group_id
JOIN AssignmentGroup
ON AssignmentGroup.group_id = Grader.group_id
GROUP BY username, assignment_id;

CREATE OR REPLACE VIEW resultCounts AS
SELECT  
masterList.username,
masterList.assignment_id,
due_date,
count
FROM masterList
LEFT JOIN existing
ON existing.username = masterList.username
AND existing.assignment_id = masterList.assignment_id
ORDER BY existing.username, existing.assignment_id;

CREATE OR REPLACE VIEW hasntGraded AS
SELECT distinct username
FROM resultCounts
WHERE count < 10
OR count IS NULL;

CREATE OR REPLACE VIEW hasGradedTen AS
SELECT username
FROM markususer
WHERE type = 'TA'
AND username NOT IN (
	SELECT username 
	FROM hasntGraded
);

CREATE OR REPLACE VIEW AssignmentTotal AS
SELECT assignment_id, 
sum(weight*out_of) AS total 
FROM RubricItem 
GROUP BY assignment_id;

CREATE OR REPLACE VIEW studentMarks AS
SELECT 
Result.group_id,
Result.mark/AssignmentTotal.total as percentMark,
Membership.username as student,
Grader.username as TA,
AssignmentGroup.Assignment_id,
Assignment.due_date
FROM Result
JOIN membership
ON Membership.group_id = Result.group_id
JOIN Grader 
ON Grader.group_id = Result.group_id
JOIN AssignmentGroup
ON AssignmentGroup.group_id = Result.group_id
LEFT JOIN AssignmentTotal
ON AssignmentTotal.assignment_id = AssignmentGroup.assignment_id
LEFT JOIN Assignment
ON Assignment.assignment_id = AssignmentGroup.assignment_id
WHERE Grader.username IN (
	SELECT username
	FROM hasGradedTen
);

CREATE OR REPLACE VIEW averages AS
SELECT 
assignment_id,
ta,
due_date,
avg(percentMark) as average
FROM studentMarks
GROUP BY assignment_id, ta, due_date;


CREATE OR REPLACE VIEW decreasingTAs AS
SELECT 
distinct a1.ta
FROM averages a1, averages a2
WHERE a1.ta = a2.ta
AND a1.assignment_id <> a2.assignment_id
AND a1.due_date < a2.due_date
AND a1.average >= a2.average;


CREATE OR REPLACE VIEW qualifyingTAs AS
SELECT distinct username
FROM hasGradedTen
WHERE username NOT IN (
	SELECT ta FROM decreasingTAs
);

CREATE OR REPLACE VIEW last_assignment AS
SELECT 
ta_max_dates.ta,
ta_max_dates.max_date,
averages.average
FROM(
	SELECT 
	ta,
	MAX(due_date) as max_date
	FROM averages 
	GROUP BY ta
) AS ta_max_dates
LEFT JOIN averages
ON ta_max_dates.ta = averages.ta
AND ta_max_dates.max_date = averages.due_date;


CREATE OR REPLACE VIEW first_assignment AS
SELECT 
ta_min_dates.ta,
ta_min_dates.min_date,
averages.average
FROM(
	SELECT 
	ta,
	MIN(due_date) as min_date
	FROM averages 
	GROUP BY ta
) AS ta_min_dates
LEFT JOIN averages
ON ta_min_dates.ta = averages.ta
AND ta_min_dates.min_date = averages.due_date;

CREATE OR REPLACE VIEW markChange AS
SELECT 
last_assignment.ta,
last_assignment.average - first_assignment.average AS difference
FROM last_assignment
JOIN first_assignment
ON first_assignment.ta = last_assignment.ta;


-- Final answer.
	-- put a final query here so that its results will go into the table.

INSERT INTO q2 (SELECT 
markususer.firstname || ' ' || markususer.surname as ta_name,
avg(averages.average)*100 as average_mark_all_assignments,
difference*100 as mark_change_first_st
FROM averages
LEFT JOIN markChange
ON markChange.ta = averages.ta
LEFT JOIN markususer ON averages.ta = markususer.username
WHERE averages.ta IN (SELECT * FROM qualifyingTAs)
GROUP BY ta_name, difference
);