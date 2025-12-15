-- ============================================================
-- SQL Performance Optimizations for Sweetiebot
-- Run this after the main sweetiebot.sql schema is created
-- ============================================================

-- ============================================================
-- 1. MISSING INDEXES
-- ============================================================

-- members table: Add index on Guild alone for filtering
-- Current: PRIMARY KEY (ID, Guild), INDEX_NICKNAME (Nickname)
-- Missing: Index on Guild for WHERE Guild = ? queries
ALTER TABLE `members` ADD INDEX `INDEX_GUILD` (`Guild`);

-- members table: Add index on FirstSeen for raid detection queries
-- Used by: GetNewestUsers, GetNewUsersWithCount, CountNewUsers
ALTER TABLE `members` ADD INDEX `INDEX_FIRSTSEEN` (`FirstSeen`);

-- members table: Composite index for raid detection (Guild + FirstSeen)
-- Covers: WHERE M.Guild = ? AND M.FirstSeen > ? ORDER BY M.FirstSeen DESC
ALTER TABLE `members` ADD INDEX `INDEX_GUILD_FIRSTSEEN` (`Guild`, `FirstSeen` DESC);

-- members table: Add index on FirstMessage for newcomer queries
-- Used by: GetNewcomers query
ALTER TABLE `members` ADD INDEX `INDEX_FIRSTMESSAGE` (`FirstMessage`);

-- chatlog table: Composite index for GetRecentMessages
-- Query: WHERE Guild = ? AND Author = ? AND Timestamp >= ?
ALTER TABLE `chatlog` ADD INDEX `INDEX_GUILD_AUTHOR_TIMESTAMP` (`Guild`, `Author`, `Timestamp`);

-- debuglog table: Add index on Guild for audit queries
-- Used by: All GetAuditRows* queries filter by Guild
ALTER TABLE `debuglog` ADD INDEX `INDEX_GUILD` (`Guild`);

-- debuglog table: Composite index for audit queries
-- Query: WHERE D.Type = ? AND D.Guild = ? ORDER BY D.Timestamp DESC
ALTER TABLE `debuglog` ADD INDEX `INDEX_TYPE_GUILD_TIMESTAMP` (`Type`, `Guild`, `Timestamp` DESC);

-- schedule table: Composite index for GetSchedule
-- Query: WHERE Guild = ? AND Date <= UTC_TIMESTAMP() ORDER BY Date ASC
-- Already has INDEX_GUILD_DATE_TYPE but reordering may help
ALTER TABLE `schedule` ADD INDEX `INDEX_GUILD_DATE` (`Guild`, `Date`);

-- schedule table: Index for GetUnsilenceDate
-- Query: WHERE Guild = ? AND Type = 8 AND Data = ?
ALTER TABLE `schedule` ADD INDEX `INDEX_GUILD_TYPE` (`Guild`, `Type`);


-- ============================================================
-- 2. OPTIMIZE RANDOM SELECTION QUERIES
-- The current pattern uses COUNT(*) + LIMIT 1 OFFSET ? which is O(n)
-- For large tables, this is very slow
-- ============================================================

-- Alternative 1: Use ORDER BY RAND() LIMIT 1 for small tables
-- Alternative 2: Use a sampling table with IDs for large tables

-- For transcripts table, add an auto-increment ID if not present
-- This enables efficient random selection via random ID range
-- Note: transcripts already has compound PK (Season, Episode, Line)
-- Adding surrogate ID for random access:

-- Check if column exists before adding (MariaDB 10.0+)
-- ALTER TABLE `transcripts` ADD COLUMN IF NOT EXISTS `_rowid` BIGINT UNSIGNED AUTO_INCREMENT UNIQUE;

-- For markov_transcripts_speaker, add min/max tracking view
CREATE OR REPLACE VIEW `markov_speaker_stats` AS
SELECT MIN(ID) as min_id, MAX(ID) as max_id, COUNT(*) as total
FROM markov_transcripts_speaker;


-- ============================================================
-- 3. COVERING INDEXES (Include all columns needed by query)
-- ============================================================

-- For GetNewestUsers query - covering index
-- SELECT U.ID, U.Email, U.Username, U.Avatar, M.FirstSeen
-- FROM members M INNER JOIN users U ON M.ID = U.ID
-- WHERE M.Guild = ? ORDER BY M.FirstSeen DESC LIMIT ?
-- The members side is already covered by INDEX_GUILD_FIRSTSEEN
-- Users side needs: INDEX on ID (already PK)

-- For FindGuildUsers - partial covering index
-- This is a complex query with JOINs and OR conditions
-- Best optimization is to ensure individual indexes exist


-- ============================================================
-- 4. OPTIMIZE TEXT SEARCH (LIKE queries)
-- ============================================================

-- For queries using LIKE 'prefix%', indexes work
-- For queries using LIKE '%anywhere%', full-text search is better

-- Add FULLTEXT index on users.Username for better search
-- Note: Only works with MyISAM or InnoDB in MySQL 5.6+/MariaDB 10.0+
ALTER TABLE `users` ADD FULLTEXT INDEX `FT_USERNAME` (`Username`);

-- Add FULLTEXT index on members.Nickname
ALTER TABLE `members` ADD FULLTEXT INDEX `FT_NICKNAME` (`Nickname`);

-- Add FULLTEXT index on aliases.Alias
ALTER TABLE `aliases` ADD FULLTEXT INDEX `FT_ALIAS` (`Alias`);


-- ============================================================
-- 5. QUERY-SPECIFIC OPTIMIZATIONS
-- ============================================================

-- GetTableCounts uses multiple subqueries which each do full table scans
-- For approximate counts (faster), can use information_schema:
-- SELECT TABLE_NAME, TABLE_ROWS FROM information_schema.TABLES
-- WHERE TABLE_SCHEMA = 'sweetiebot';

-- The GetMarkov/GetMarkov2 functions use cursors which are slow
-- Consider rewriting with a single query using cumulative sum approach


-- ============================================================
-- 6. TABLE STATISTICS
-- ============================================================

-- Ensure table statistics are up to date for query optimizer
ANALYZE TABLE `chatlog`;
ANALYZE TABLE `members`;
ANALYZE TABLE `users`;
ANALYZE TABLE `debuglog`;
ANALYZE TABLE `schedule`;
ANALYZE TABLE `aliases`;
ANALYZE TABLE `markov_transcripts`;
ANALYZE TABLE `markov_transcripts_map`;
ANALYZE TABLE `transcripts`;


-- ============================================================
-- 7. InnoDB SETTINGS RECOMMENDATIONS (server config)
-- ============================================================
-- Add these to my.cnf/my.ini for better performance:
--
-- # Buffer pool should be 70-80% of available RAM
-- innodb_buffer_pool_size = 1G
--
-- # Log file size affects recovery time vs write performance
-- innodb_log_file_size = 256M
--
-- # Flush logs once per second (better performance, slight durability risk)
-- innodb_flush_log_at_trx_commit = 2
--
-- # Use O_DIRECT to avoid double buffering
-- innodb_flush_method = O_DIRECT
--
-- # For write-heavy workloads
-- innodb_write_io_threads = 8
-- innodb_read_io_threads = 8
