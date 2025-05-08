-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: May 08, 2025 at 07:16 AM
-- Server version: 10.11.9-MariaDB
-- PHP Version: 8.3.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `dyplux`
--

-- --------------------------------------------------------

--
-- Table structure for table `alerts`
--

CREATE TABLE `alerts` (
  `alert_id` int(11) NOT NULL,
  `alert_type_id` int(11) NOT NULL,
  `device_id` int(11) NOT NULL,
  `port_id` int(11) NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `disabled_at` datetime NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `alerts_tmp`
--

CREATE TABLE `alerts_tmp` (
  `alert_id` int(11) NOT NULL,
  `alert_type_id` int(11) NOT NULL,
  `device_id` int(11) NOT NULL,
  `port_id` int(11) NOT NULL,
  `dt` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `alert_types`
--

CREATE TABLE `alert_types` (
  `alert_type_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `alert_types`
--

INSERT INTO `alert_types` (`alert_type_id`, `name`) VALUES
(1, 'port oper changed'),
(2, 'port admin changed'),
(3, 'min threshold reached'),
(4, 'max threshold reached'),
(5, 'device is offline');

-- --------------------------------------------------------

--
-- Table structure for table `collectors`
--

CREATE TABLE `collectors` (
  `collector_id` int(11) NOT NULL,
  `collector_name` varchar(255) NOT NULL,
  `enabled` tinyint(1) NOT NULL DEFAULT 1,
  `disable_alerts` tinyint(1) NOT NULL DEFAULT 0,
  `active_host` varchar(255) NOT NULL DEFAULT '0.0.0.0',
  `last_run` datetime NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE current_timestamp(),
  `interval_seconds` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `collectors`
--

INSERT INTO `collectors` (`collector_id`, `collector_name`, `enabled`, `disable_alerts`, `active_host`, `last_run`, `interval_seconds`) VALUES
(1, 'default', 1, 0, '0.0.0.0', '0000-00-00 00:00:00', 0);

-- --------------------------------------------------------

--
-- Table structure for table `dashboards`
--

CREATE TABLE `dashboards` (
  `dashboard_id` int(11) NOT NULL,
  `dashboard_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `dashboard_ports`
--

CREATE TABLE `dashboard_ports` (
  `dashboard_id` int(11) NOT NULL,
  `port_id` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `devices`
--

CREATE TABLE `devices` (
  `device_id` int(11) NOT NULL,
  `ip` varchar(15) NOT NULL,
  `name` varchar(255) NOT NULL,
  `community` varchar(255) NOT NULL DEFAULT 'getstats',
  `collector_id` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ports`
--

CREATE TABLE `ports` (
  `port_id` int(11) NOT NULL,
  `device_id` int(11) NOT NULL,
  `port_name` varchar(255) NOT NULL,
  `ifindex` int(11) NOT NULL,
  `ifname` varchar(255) NOT NULL,
  `ifalias` varchar(255) NOT NULL DEFAULT '',
  `ifdescr` varchar(255) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `thresholds`
--

CREATE TABLE `thresholds` (
  `threshold_id` int(11) NOT NULL,
  `port_id` int(11) NOT NULL,
  `min_in` varchar(255) NOT NULL DEFAULT '-1',
  `min_out` varchar(255) NOT NULL DEFAULT '-1',
  `max_in` varchar(255) NOT NULL DEFAULT '-1',
  `max_out` varchar(255) NOT NULL DEFAULT '-1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `alerts`
--
ALTER TABLE `alerts`
  ADD PRIMARY KEY (`alert_id`);

--
-- Indexes for table `alerts_tmp`
--
ALTER TABLE `alerts_tmp`
  ADD PRIMARY KEY (`alert_id`);

--
-- Indexes for table `alert_types`
--
ALTER TABLE `alert_types`
  ADD PRIMARY KEY (`alert_type_id`);

--
-- Indexes for table `collectors`
--
ALTER TABLE `collectors`
  ADD PRIMARY KEY (`collector_id`);

--
-- Indexes for table `dashboards`
--
ALTER TABLE `dashboards`
  ADD PRIMARY KEY (`dashboard_id`);

--
-- Indexes for table `dashboard_ports`
--
ALTER TABLE `dashboard_ports`
  ADD UNIQUE KEY `dashboard_id` (`dashboard_id`,`port_id`),
  ADD KEY `port_id` (`port_id`);

--
-- Indexes for table `devices`
--
ALTER TABLE `devices`
  ADD PRIMARY KEY (`device_id`),
  ADD UNIQUE KEY `ip` (`ip`);

--
-- Indexes for table `ports`
--
ALTER TABLE `ports`
  ADD PRIMARY KEY (`port_id`),
  ADD UNIQUE KEY `device_id_2` (`device_id`,`ifindex`),
  ADD KEY `device_id` (`device_id`) USING BTREE;

--
-- Indexes for table `thresholds`
--
ALTER TABLE `thresholds`
  ADD PRIMARY KEY (`threshold_id`),
  ADD UNIQUE KEY `port_id` (`port_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `alerts`
--
ALTER TABLE `alerts`
  MODIFY `alert_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `alerts_tmp`
--
ALTER TABLE `alerts_tmp`
  MODIFY `alert_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `alert_types`
--
ALTER TABLE `alert_types`
  MODIFY `alert_type_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `collectors`
--
ALTER TABLE `collectors`
  MODIFY `collector_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `dashboards`
--
ALTER TABLE `dashboards`
  MODIFY `dashboard_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `devices`
--
ALTER TABLE `devices`
  MODIFY `device_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ports`
--
ALTER TABLE `ports`
  MODIFY `port_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `thresholds`
--
ALTER TABLE `thresholds`
  MODIFY `threshold_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `dashboard_ports`
--
ALTER TABLE `dashboard_ports`
  ADD CONSTRAINT `dashboard_ports_ibfk_1` FOREIGN KEY (`dashboard_id`) REFERENCES `dashboards` (`dashboard_id`) ON DELETE CASCADE ON UPDATE NO ACTION,
  ADD CONSTRAINT `dashboard_ports_ibfk_2` FOREIGN KEY (`port_id`) REFERENCES `ports` (`port_id`) ON DELETE CASCADE ON UPDATE NO ACTION;

--
-- Constraints for table `ports`
--
ALTER TABLE `ports`
  ADD CONSTRAINT `ports_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`device_id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
