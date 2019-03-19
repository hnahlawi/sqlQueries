-- High coverage

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q7;

-- You must not change this table definition.
CREATE TABLE q7 (
	ta varchar(100)
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS masterList CASCADE;
DROP VIEW IF EXISTS existing CASCADE;
DROP VIEW IF EXISTS resultCounts CASCADE;
DROP VIEW IF EXISTS hasntGraded CASCADE;
DROP VIEW IF EXISTS masterList2 CASCADE;
DROP VIEW IF EXISTS existingStudentTA CASCADE;
DROP VIEW IF EXISTS resultCountsStudent CASCADE;
DROP VIEW IF EXISTS hasntGradedEveryStudent CASCADE;
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
WHERE count < 1
OR count IS NULL;



CREATE OR REPLACE VIEW masterList2 AS
SELECT m1.username as ta, m2.username as student 
FROM markususer m1, markususer m2
WHERE m1.type = 'TA'
AND m2.type = 'student';


CREATE OR REPLACE VIEW existingStudentTA AS
SELECT  
Grader.username as ta,
Membership.username as student, 
count(*)
FROM Result
JOIN Grader
ON Grader.group_id = Result.group_id
JOIN Membership
ON Membership.group_id = Grader.group_id
GROUP BY Grader.username, Membership.username; 


CREATE OR REPLACE VIEW resultCountsStudent AS
SELECT  
masterList2.ta,
masterList2.student,
count
FROM masterList2
LEFT JOIN existingStudentTA
ON existingStudentTA.ta = masterList2.ta
AND existingStudentTA.student = masterList2.student
ORDER BY existingStudentTA.ta, existingStudentTA.student;


CREATE OR REPLACE VIEW hasntGradedEveryStudent AS
SELECT distinct ta
FROM resultCountsStudent
WHERE count IS NULL;


-- Final answer.
INSERT INTO q7(
SELECT username
FROM markususer
WHERE type = 'TA' AND username NOT IN (SELECT ta FROM hasntGradedEveryStudent) AND username NOT IN (SELECT username FROM hasntGraded)
); 
	-- put a final query here so that its results will go into the table.