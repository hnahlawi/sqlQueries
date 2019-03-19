-- Steady work

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q6;

-- You must not change this table definition.
CREATE TABLE q6 (
	group_id integer,
	first_file varchar(25),
	first_time timestamp,
	first_submitter varchar(25),
	last_file varchar(25),
	last_time timestamp, 
	last_submitter varchar(25),
	elapsed_time interval
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS submissionTimes CASCADE;

-- Define views for your intermediate steps here.
CREATE OR REPLACE VIEW submissionTimes AS
SELECT 
AssignmentGroup.group_id,
min(submission_date) as first_time,
max(submission_date) as last_time
FROM Submissions
LEFT JOIN AssignmentGroup
ON AssignmentGroup.group_id = Submissions.group_id
LEFT JOIN Assignment
ON Assignment.assignment_id = AssignmentGroup.assignment_id
WHERE Assignment.description = 'A1'
GROUP BY AssignmentGroup.group_id;
-- Final answer.
INSERT INTO q6 (
SELECT 
submissionTimes.group_id,
s_first.file_name as first_file,
submissionTimes.first_time,
s_first.username as first_submitter,
s_last.file_name as last_file,
submissionTimes.last_time,
s_last.username as last_submitter,
 submissionTimes.last_time - submissionTimes.first_time as elapsed_time
FROM submissionTimes
LEFT JOIN Submissions s_first
ON submissionTimes.first_time = s_first.submission_date
AND submissionTimes.group_id = s_first.group_id
LEFT JOIN Submissions s_last
ON submissionTimes.last_time = s_last.submission_date
AND submissionTimes.group_id = s_last.group_id
); 
	-- put a final query here so that its results will go into the table.