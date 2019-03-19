-- Uneven workloads

SET SEARCH_PATH TO markus;
DROP TABLE IF EXISTS q5;

-- You must not change this table definition.
CREATE TABLE q5 (
	assignment_id integer,
	username varchar(25), 
	num_assigned integer
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS Workload CASCADE;
DROP VIEW IF EXISTS unevenAssignments CASCADE;
-- Define views for your intermediate steps here.
CREATE OR REPLACE VIEW Workload AS
SELECT 
AssignmentGroup.assignment_id, 
Grader.username,
count(AssignmentGroup.group_id) as groups
FROM Grader
JOIN AssignmentGroup
ON AssignmentGroup.group_id = Grader.group_id
GROUP BY AssignmentGroup.assignment_id, Grader.username
ORDER BY AssignmentGroup.assignment_id, Grader.username;

CREATE OR REPLACE VIEW unevenAssignments AS
SELECT 
assignment_id 
FROM Workload
GROUP BY assignment_id
HAVING max(groups)-min(groups) > 10;
-- Final answer.
INSERT INTO q5(
SELECT 
AssignmentGroup.assignment_id, 
Grader.username, 
count(*) 
FROM unevenAssignments
LEFT JOIN AssignmentGroup
ON AssignmentGroup.assignment_id = unevenAssignments.assignment_id
LEFT JOIN Grader
ON Grader.group_id = AssignmentGroup.group_id
GROUP BY AssignmentGroup.assignment_id, Grader.username
);
	-- put a final query here so that its results will go into the table.