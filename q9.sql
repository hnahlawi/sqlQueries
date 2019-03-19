-- Inseparable

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q9;

-- You must not change this table definition.
CREATE TABLE q9 (
	student1 varchar(25),
	student2 varchar(25)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS groupAssignments CASCADE;
DROP VIEW IF EXISTS singleMemberGroup CASCADE;
DROP VIEW IF EXISTS singleMemberStudent CASCADE;
DROP VIEW IF EXISTS groupStudents CASCADE;
DROP VIEW IF EXISTS masterList CASCADE;
DROP VIEW IF EXISTS actual CASCADE;
DROP VIEW IF EXISTS disqualifiedPairs CASCADE;
DROP VIEW IF EXISTS masterListPairs CASCADE;

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

CREATE OR REPLACE VIEW masterList AS
SELECT 
assignment_id,
s1.username as student1,
s2.username as student2
FROM groupAssignments, groupStudents s1, groupStudents s2
WHERE s1.username <> s2.username;


CREATE OR REPLACE VIEW actual AS
SELECT 
m1.group_id,
AssignmentGroup.assignment_id,
m1.username as student1,
m2.username as student2
FROM Membership m1, Membership m2, AssignmentGroup
WHERE m1.group_id = m2.group_id
AND m1.username <> m2.username
AND AssignmentGroup.group_id = m1.group_id;

CREATE OR REPLACE VIEW disqualifiedPairs AS
SELECT 
distinct masterlist.student1, masterlist.student2 
FROM masterList
LEFT JOIN actual
ON masterList.assignment_id = actual.assignment_id
AND masterlist.student1 = actual.student1
AND masterlist.student2 = actual.student2
WHERE group_id IS NULL 
ORDER BY masterlist.student1, masterlist.student2;


CREATE OR REPLACE VIEW masterListPairs AS
SELECT 
distinct student1, student2
FROM masterList;



-- Final answer.
INSERT INTO q9(
SELECT * 
FROM masterListPairs
WHERE (masterListPairs.student1, masterListPairs.student2) NOT IN (
	SELECT Student1, Student2 FROM disqualifiedPairs
)
AND student1 < student2);
	-- put a final query here so that its results will go into the table.
