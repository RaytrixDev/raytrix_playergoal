-- PlayerGoals Database Tabel
-- Deze tabel slaat completed goals op per server sessie
-- Bij elke server restart wordt de tabel automatisch geleegd door het script

CREATE TABLE IF NOT EXISTS `playergoals_completed` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_count` int(11) NOT NULL,
  `server_start_time` bigint(20) NOT NULL,
  `completed_at` bigint(20) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_goal` (`player_count`, `server_start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
