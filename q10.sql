-- A1 report

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q10;

-- You must not change this table definition.
CREATE TABLE q10 (
	group_id integer,
	mark real,
	compared_to_average real,
	status varchar(5)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS AssignmentTotal CASCADE;
DROP VIEW IF EXISTS a1grades CASCADE;
DROP VIEW IF EXISTS averageA1 CASCADE;
-- Define views for your intermediate steps here.

CREATE OR REPLACE VIEW AssignmentTotal AS
SELECT assignment_id, 
sum(weight*out_of) AS total 
FROM RubricItem 
GROUP BY assignment_id;


CREATE OR REPLACE VIEW a1grades AS
SELECT AssignmentGroup.group_id, 
(Result.mark*100)/AssignmentTotal.total as percentmark,
Assignment.assignment_id as assignment_id
FROM AssignmentGroup
JOIN AssignmentTotal ON AssignmentTotal.assignment_id = AssignmentGroup.assignment_id
LEFT JOIN Result ON Result.group_id = AssignmentGroup.group_id
LEFT JOIN Assignment ON Assignment.assignment_id = AssignmentGroup.assignment_id 
WHERE Assignment.description = 'A1';


CREATE OR REPLACE VIEW averageA1 AS
SELECT assignment_id, avg(percentmark) as average 
FROM a1grades
GROUP BY assignment_id;


-- Final answer.
INSERT INTO q10(
SELECT a1grades.group_id, 
a1grades.percentmark as mark,
(a1grades.percentmark - averageA1.average) as compared_to_average,
CASE WHEN  (a1grades.percentmark - averageA1.average) > 0 THEN 'above'
WHEN (a1grades.percentmark - averageA1.average) < 0 THEN 'below'
WHEN (a1grades.percentmark - averageA1.average) = 0 THEN 'at'
ELSE NULL
END as status
FROM a1grades
JOIN averageA1 ON a1grades.assignment_id = averageA1.assignment_id);
	-- put a final query here so that its results will go into the table.
