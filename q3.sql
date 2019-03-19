-- Solo superior

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q3;

-- You must not change this table definition.
CREATE TABLE q3 (
	assignment_id integer,
	description varchar(100), 
	num_solo integer, 
	average_solo real,
	num_collaborators integer, 
	average_collaborators real, 
	average_students_per_submission real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS solo CASCADE;
DROP VIEW IF EXISTS grp CASCADE;
DROP VIEW IF EXISTS assignGrpCounts CASCADE;
DROP VIEW IF EXISTS totalGrpId CASCADE;
DROP VIEW IF EXISTS AssignmentTotal CASCADE;
DROP VIEW IF EXISTS averageSolo CASCADE;
DROP VIEW IF EXISTS averageGroup CASCADE;
-- Define views for your intermediate steps here.
CREATE OR REPLACE VIEW solo AS
SELECT group_id
FROM Membership
GROUP BY group_id
HAVING count(*) = 1;


CREATE OR REPLACE VIEW grp AS
SELECT group_id
FROM Membership
GROUP BY group_id
HAVING count(*) > 1;



CREATE OR REPLACE VIEW assignGrpCounts AS
SELECT AssignmentGroup.assignment_id, count(*) as collaborators
FROM Membership
JOIN AssignmentGroup ON membership.group_id = AssignmentGroup.group_id 
WHERE membership.group_id IN (SELECT group_id FROM grp)
GROUP BY AssignmentGroup.assignment_id;


CREATE OR REPLACE VIEW totalGrpId AS
SELECT AssignmentGroup.assignment_id, count(*) as total
FROM AssignmentGroup
GROUP BY AssignmentGroup.assignment_id;

CREATE OR REPLACE VIEW AssignmentTotal AS
SELECT assignment_id, 
sum(weight*out_of) AS total 
FROM RubricItem 
GROUP BY assignment_id;

CREATE OR REPLACE VIEW averageSolo AS
SELECT 
AssignmentGroup.assignment_id, 
avg(Result.mark/AssignmentTotal.total) as soloAvg,
count(*) as countSoloAvg
FROM AssignmentGroup
JOIN solo ON AssignmentGroup.group_id = solo.group_id
JOIN Result ON AssignmentGroup.group_id = Result.group_id
LEFT JOIN AssignmentTotal
ON AssignmentTotal.assignment_id = AssignmentGroup.assignment_id
GROUP BY AssignmentGroup.assignment_id;

CREATE OR REPLACE VIEW averageGroup AS
SELECT AssignmentGroup.assignment_id, 
avg(Result.mark/AssignmentTotal.total) as grpAvg,
assignGrpCounts.collaborators
FROM AssignmentGroup
JOIN grp ON AssignmentGroup.group_id = grp.group_id
JOIN Result ON AssignmentGroup.group_id = Result.group_id
LEFT JOIN AssignmentTotal
ON AssignmentTotal.assignment_id = AssignmentGroup.assignment_id
LEFT JOIN assignGrpCounts
ON assignGrpCounts.assignment_id = AssignmentGroup.assignment_id
GROUP BY AssignmentGroup.assignment_id, assignGrpCounts.collaborators;


-- Final answer.
INSERT INTO q3(
SELECT 
averageSolo.assignment_id,
Assignment.description,
averageSolo.countSoloAvg as num_solo, 
averageSolo.soloAvg*100 as average_solo,
averageGroup.collaborators as num_collaborators, 
averageGroup.grpAvg*100 as average_collaborators,
(averageGroup.collaborators + averageSolo.countSoloAvg)/totalGrpId.total::float as average_students_per_group
FROM averageSolo
JOIN Assignment ON averageSolo.assignment_id = Assignment.assignment_id
JOIN averageGroup ON averageSolo.assignment_id = averageGroup.assignment_id
JOIN totalGrpId ON totalGrpId.assignment_id = averageSolo.assignment_id
WHERE averageSolo.soloAvg > averageGroup.grpAvg
);
	-- put a final query here so that its results will go into the table.
