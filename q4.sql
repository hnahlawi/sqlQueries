-- Grader report

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q4;

-- You must not change this table definition.
CREATE TABLE q4 (
	assignment_id integer,
	username varchar(25), 
	num_marked integer, 
	num_not_marked integer,
	min_mark real,
	max_mark real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS AssignmentTotal CASCADE;
DROP VIEW IF EXISTS finalBeforePercent CASCADE;
-- Define views for your intermediate steps here.
CREATE OR REPLACE VIEW AssignmentTotal AS
SELECT assignment_id, 
sum(weight*out_of) AS total 
FROM RubricItem 
GROUP BY assignment_id;

CREATE OR REPLACE VIEW finalBeforePercent AS
SELECT 
AssignmentGroup.assignment_id, 
Grader.username,
count(mark) as num_marked,
count(*)-count(mark) as num_not_marked,
min(Result.mark) as min_mark,
max(Result.mark) as max_mark
FROM Grader
LEFT JOIN AssignmentGroup
ON AssignmentGroup.group_id = Grader.group_id
LEFT JOIN Result
ON Result.group_id = Grader.group_id
LEFT JOIN AssignmentTotal
ON AssignmentTotal.assignment_id = AssignmentGroup.assignment_id
GROUP BY AssignmentGroup.assignment_id, Grader.username
ORDER BY AssignmentGroup.assignment_id, Grader.username;

-- Final answer.
INSERT INTO q4 (
SELECT finalBeforePercent.assignment_id, 
finalBeforePercent.username, 
finalBeforePercent.num_marked, 
finalBeforePercent.num_not_marked, 
finalBeforePercent.min_mark/AssignmentTotal.total*100 as min_mark,
finalBeforePercent.max_mark/AssignmentTotal.total*100 as max_mark
FROM finalBeforePercent
LEFT JOIN AssignmentTotal ON AssignmentTotal.assignment_id = finalBeforePercent.assignment_id
);
	-- put a final query here so that its results will go into the table.