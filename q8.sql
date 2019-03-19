-- Never solo by choice

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q8;

-- You must not change this table definition.
CREATE TABLE q8 (
	username varchar(25),
	group_average real,
	solo_average real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS groupAssignments CASCADE;
DROP VIEW IF EXISTS singleMemberGroup CASCADE;
DROP VIEW IF EXISTS singleMemberStudent CASCADE;
DROP VIEW IF EXISTS groupStudents CASCADE;
DROP VIEW IF EXISTS studentAssignmentMaster CASCADE;
DROP VIEW IF EXISTS nonContributingStudents CASCADE;
DROP VIEW IF EXISTS neverSolo CASCADE;
DROP VIEW IF EXISTS AssignmentUserSubmissions CASCADE;
DROP VIEW IF EXISTS AssignmentTotal CASCADE;
DROP VIEW IF EXISTS group_averages CASCADE;
DROP VIEW IF EXISTS nonGroupAssignments CASCADE;
DROP VIEW IF EXISTS solo_averages CASCADE;


-- Define views for your intermediate steps here.

CREATE OR REPLACE VIEW groupAssignments AS
SELECT assignment_id 
FROM Assignment 
WHERE group_max > 1;


CREATE OR REPLACE VIEW singleMemberGroup AS
SELECT  
AssignmentGroup.group_id
FROM groupAssignments
LEFT JOIN AssignmentGroup
ON AssignmentGroup.assignment_id = groupAssignments.assignment_id
LEFT JOIN Membership
ON AssignmentGroup.group_id = Membership.group_id
GROUP BY AssignmentGroup.group_id
HAVING count(*) = 1;


CREATE OR REPLACE VIEW singleMemberStudent AS
SELECT Membership.username 
FROM singleMemberGroup
LEFT JOIN Membership
ON Membership.group_id = singleMemberGroup.group_id;


CREATE OR REPLACE VIEW groupStudents AS
SELECT * 
FROM markususer
WHERE type = 'student'
AND username NOT IN (
	SELECT * FROM singleMemberStudent
	WHERE username IS NOT NULL
);


CREATE OR REPLACE VIEW studentAssignmentMaster AS
SELECT assignment_id, username
FROM Assignment, (SELECT username FROM markususer WHERE type = 'student') AS Students;

CREATE OR REPLACE VIEW AssignmentUserSubmissions AS
SELECT distinct username, assignment_id 
FROM Submissions
LEFT JOIN AssignmentGroup
ON AssignmentGroup.group_id = Submissions.group_id;


CREATE OR REPLACE VIEW nonContributingStudents AS
SELECT distinct studentAssignmentMaster.username 
FROM studentAssignmentMaster
LEFT JOIN AssignmentUserSubmissions
ON AssignmentUserSubmissions.username = studentAssignmentMaster.username
AND AssignmentUserSubmissions.assignment_id = studentAssignmentMaster.assignment_id
WHERE AssignmentUserSubmissions.username IS NULL;


CREATE OR REPLACE VIEW neverSolo AS
SELECT *
FROM groupStudents
WHERE username NOT IN (
	SELECT username FROM nonContributingStudents
);


CREATE OR REPLACE VIEW AssignmentTotal AS
SELECT assignment_id, 
sum(weight*out_of) AS total 
FROM RubricItem 
GROUP BY assignment_id;


CREATE OR REPLACE VIEW group_averages AS
SELECT 
neverSolo.username,
avg(Result.mark/AssignmentTotal.total) as group_average
FROM neverSolo, groupAssignments
LEFT JOIN AssignmentGroup
ON groupAssignments.assignment_id = AssignmentGroup.assignment_id
LEFT JOIN Membership
ON Membership.group_id = AssignmentGroup.group_id
LEFT JOIN AssignmentTotal
ON AssignmentTotal.assignment_id = groupAssignments.assignment_id
LEFT JOIN Result
ON Result.group_id = AssignmentGroup.group_id
WHERE Membership.username = neverSolo.username
GROUP BY neverSolo.username;


CREATE OR REPLACE VIEW nonGroupAssignments AS
SELECT * FROM Assignment
WHERE assignment_id NOT IN (
	SELECT * FROM groupAssignments
);

CREATE OR REPLACE VIEW solo_averages AS
SELECT 
neverSolo.username,
avg(Result.mark/AssignmentTotal.total) as solo_average
FROM neverSolo, nonGroupAssignments
LEFT JOIN AssignmentGroup
ON nonGroupAssignments.assignment_id = AssignmentGroup.assignment_id
LEFT JOIN Membership
ON Membership.group_id = AssignmentGroup.group_id
LEFT JOIN AssignmentTotal
ON AssignmentTotal.assignment_id = nonGroupAssignments.assignment_id
LEFT JOIN Result
ON Result.group_id = AssignmentGroup.group_id
WHERE Membership.username = neverSolo.username
GROUP BY neverSolo.username;


-- Final answer.
INSERT INTO q8(
SELECT 
neverSolo.username,
group_averages.group_average,
solo_averages.solo_average 
FROM neverSolo
LEFT JOIN group_averages
ON group_averages.username = neverSolo.username
LEFT JOIN solo_averages
ON solo_averages.username = neverSolo.username
);
	-- put a final query here so that its results will go into the table.