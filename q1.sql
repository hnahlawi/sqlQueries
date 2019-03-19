-- Distributions

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q1;

-- You must not change this table definition.
CREATE TABLE q1 (
	assignment_id integer,
	average_mark_percent real, 
	num_80_100 integer, 
	num_60_79 integer, 
	num_50_59 integer, 
	num_0_49 integer
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS AssignmentTotal CASCADE;
DROP VIEW IF EXISTS inRange CASCADE;

-- Define views for your intermediate steps here.
CREATE OR REPLACE VIEW AssignmentTotal AS
SELECT assignment_id, 
sum(weight*out_of) AS total 
FROM RubricItem 
GROUP BY assignment_id;

CREATE OR REPLACE VIEW inRange AS
SELECT 
Result.group_id,
AssignmentGroup.assignment_id,
Result.mark,
AssignmentTotal.total,
Result.mark/AssignmentTotal.total*100 AS percentMark,
(CASE WHEN Result.mark/AssignmentTotal.Total >= 0.8 
THEN 1 ELSE 0 END),
(CASE WHEN Result.mark/AssignmentTotal.Total >= 0.6 
AND Result.mark/AssignmentTotal.Total < 0.8
THEN 1 ELSE 0 END) as b,
(CASE WHEN Result.mark/AssignmentTotal.Total >= 0.5 
AND Result.mark/AssignmentTotal.Total < 0.6
THEN 1 ELSE 0 END) as c,
(CASE WHEN Result.mark/AssignmentTotal.Total < 0.5 
THEN 1 ELSE 0 END) as d
FROM Result
JOIN AssignmentGroup 
ON AssignmentGroup.group_id = Result.group_id
JOIN AssignmentTotal 
ON AssignmentTotal.assignment_id = AssignmentGroup.assignment_id;

ALTER TABLE inRange
RENAME COLUMN "case" TO "a";


-- Final answer.
INSERT INTO q1 (SELECT 
AssignmentGroup.assignment_id,
avg(inRange.percentMark) as average_mark_percent,
sum(a) as num_80_100,
sum(b) as num_60_79,
sum(c) as num_50_59,
sum(d) as num_0_49
FROM Assignment
LEFT JOIN AssignmentGroup
ON AssignmentGroup.assignment_id = Assignment.assignment_id
LEFT JOIN Result
ON Result.group_id = AssignmentGroup.group_id
LEFT JOIN inRange
ON inRange.group_id = Result.group_id
GROUP BY AssignmentGroup.Assignment_id);
	-- put a final query here so that its results will go into the table.