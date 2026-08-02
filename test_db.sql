PRAGMA foreign_keys = OFF;
-- Regular Expressions
INSERT INTO regular_expressions (name, pattern, description) VALUES
('Regex_INTL_tier_6', '(?i)[-.](ASD87|BRUTE|BTN|CART|CHD|EuReKA|GALVANiZE|HaB|HANDJOB|HDC|iON|Ivandro|j3rico|KnG|LEGi0N|Lulz|MaG|MTeam|NiP|ORBiT|P0W4HD|PTP|PuTao|ROCiNANTE|Slappy|ThD|WiKi|WiLDCAT)$', '');

-- Custom Formats
INSERT INTO custom_formats (name, description, include_in_rename) VALUES
('VF', 'VF Language or Regex', 0),
('VOSTFR', 'VOSTFR Regex', 0),
('FR Tier 1', 'French tier_1', 0),
('FR Tier 2', 'French tier_2', 0),
('FR Tier 3', 'French tier_3', 0),
('FR Tier 4', 'French tier_4', 0),
('FR Tier 5', 'French tier_5', 0),
('INTL Tier 1', 'International tier_1', 0),
('INTL Tier 2', 'International tier_2', 0),
('INTL Tier 3', 'International tier_3', 0),
('INTL Tier 4', 'International tier_4', 0),
('INTL Tier 5', 'International tier_5', 0),
('INTL Tier 6', 'International tier_6', 0);

-- Custom Format Conditions
INSERT INTO custom_format_conditions (custom_format_name, name, type, arr_type, negate, required) VALUES
('VF', 'Lang Match', 'language', 'all', 0, 0),
('VF', 'Regex Match', 'release_title', 'all', 0, 0),
('VOSTFR', 'Regex Match', 'release_title', 'all', 0, 1),
('FR Tier 1', 'Regex Match', 'release_title', 'all', 0, 1),
('FR Tier 2', 'Regex Match', 'release_title', 'all', 0, 1),
('FR Tier 3', 'Regex Match', 'release_title', 'all', 0, 1),
('FR Tier 4', 'Regex Match', 'release_title', 'all', 0, 1),
('FR Tier 5', 'Regex Match', 'release_title', 'all', 0, 1),
('INTL Tier 1', 'Regex Match', 'release_title', 'all', 0, 1),
('INTL Tier 2', 'Regex Match', 'release_title', 'all', 0, 1),
('INTL Tier 3', 'Regex Match', 'release_title', 'all', 0, 1),
('INTL Tier 4', 'Regex Match', 'release_title', 'all', 0, 1),
('INTL Tier 5', 'Regex Match', 'release_title', 'all', 0, 1),
('INTL Tier 6', 'Regex Match', 'release_title', 'all', 0, 1);

INSERT INTO condition_languages (custom_format_name, condition_name, language_name, except_language) VALUES
('VF', 'Lang Match', 'French', 0);

INSERT INTO condition_patterns (custom_format_name, condition_name, regular_expression_name) VALUES
('VF', 'Regex Match', 'Regex_VF'),
('VOSTFR', 'Regex Match', 'Regex_VOSTFR'),
('FR Tier 1', 'Regex Match', 'Regex_FR_tier_1'),
('FR Tier 2', 'Regex Match', 'Regex_FR_tier_2'),
('FR Tier 3', 'Regex Match', 'Regex_FR_tier_3'),
('FR Tier 4', 'Regex Match', 'Regex_FR_tier_4'),
('FR Tier 5', 'Regex Match', 'Regex_FR_tier_5'),
('INTL Tier 1', 'Regex Match', 'Regex_INTL_tier_1'),
('INTL Tier 2', 'Regex Match', 'Regex_INTL_tier_2'),
('INTL Tier 3', 'Regex Match', 'Regex_INTL_tier_3'),
('INTL Tier 4', 'Regex Match', 'Regex_INTL_tier_4'),
('INTL Tier 5', 'Regex Match', 'Regex_INTL_tier_5'),
('INTL Tier 6', 'Regex Match', 'Regex_INTL_tier_6');

-- Profiles
INSERT INTO quality_profiles (name) VALUES ('1080p'), ('4K');

-- Profile Languages
INSERT INTO quality_profile_languages (quality_profile_name, language_name, type) VALUES
('1080p', 'Any', 'simple'), ('4K', 'Any', 'simple');

-- Quality Groups
INSERT INTO quality_groups (quality_profile_name, name) VALUES
('1080p', 'Group-Bluray-Webdl-1080p'),
('1080p', 'Group-HDTV-Webrip-1080p'),
('1080p', 'Group-Bluray-Webdl-2160p'),
('1080p', 'Group-HDTV-Webrip-2160p'),
('4K', 'Group-Bluray-Webdl-2160p'),
('4K', 'Group-HDTV-Webrip-2160p'),
('4K', 'Group-Bluray-Webdl-1080p'),
('4K', 'Group-HDTV-Webrip-1080p');

INSERT INTO quality_group_members (quality_profile_name, quality_group_name, quality_name) VALUES
('1080p', 'Group-Bluray-Webdl-1080p', 'Bluray-1080p'),
('1080p', 'Group-Bluray-Webdl-1080p', 'WEBDL-1080p'),
('1080p', 'Group-HDTV-Webrip-1080p', 'HDTV-1080p'),
('1080p', 'Group-HDTV-Webrip-1080p', 'WEBRip-1080p'),
('1080p', 'Group-Bluray-Webdl-2160p', 'Bluray-2160p'),
('1080p', 'Group-Bluray-Webdl-2160p', 'WEBDL-2160p'),
('1080p', 'Group-HDTV-Webrip-2160p', 'HDTV-2160p'),
('1080p', 'Group-HDTV-Webrip-2160p', 'WEBRip-2160p'),
('4K', 'Group-Bluray-Webdl-2160p', 'Bluray-2160p'),
('4K', 'Group-Bluray-Webdl-2160p', 'WEBDL-2160p'),
('4K', 'Group-HDTV-Webrip-2160p', 'HDTV-2160p'),
('4K', 'Group-HDTV-Webrip-2160p', 'WEBRip-2160p'),
('4K', 'Group-Bluray-Webdl-1080p', 'Bluray-1080p'),
('4K', 'Group-Bluray-Webdl-1080p', 'WEBDL-1080p'),
('4K', 'Group-HDTV-Webrip-1080p', 'HDTV-1080p'),
('4K', 'Group-HDTV-Webrip-1080p', 'WEBRip-1080p');

-- Profile Qualities (Priorities)
INSERT INTO quality_profile_qualities (quality_profile_name, quality_name, quality_group_name, position, upgrade_until) VALUES
('1080p', NULL, 'Group-Bluray-Webdl-1080p', 0, 1),
('1080p', NULL, 'Group-HDTV-Webrip-1080p', 1, 0),
('1080p', 'Remux-1080p', NULL, 2, 0),
('1080p', NULL, 'Group-Bluray-Webdl-2160p', 3, 0),
('1080p', NULL, 'Group-HDTV-Webrip-2160p', 4, 0),
('1080p', 'Remux-2160p', NULL, 5, 0),
('4K', NULL, 'Group-Bluray-Webdl-2160p', 0, 1),
('4K', NULL, 'Group-HDTV-Webrip-2160p', 1, 0),
('4K', 'Remux-2160p', NULL, 2, 0),
('4K', NULL, 'Group-Bluray-Webdl-1080p', 3, 0),
('4K', NULL, 'Group-HDTV-Webrip-1080p', 4, 0),
('4K', 'Remux-1080p', NULL, 5, 0);

-- Profile Custom Formats Scoring
INSERT INTO quality_profile_custom_formats (quality_profile_name, custom_format_name, arr_type, score) VALUES
('1080p', 'VF', 'all', 100000),
('1080p', 'VOSTFR', 'all', 50000),
('1080p', 'FR Tier 1', 'all', 9000),
('1080p', 'FR Tier 2', 'all', 8000),
('1080p', 'FR Tier 3', 'all', 7000),
('1080p', 'FR Tier 4', 'all', 6000),
('1080p', 'FR Tier 5', 'all', 5000),
('1080p', 'INTL Tier 1', 'all', 900),
('1080p', 'INTL Tier 2', 'all', 800),
('1080p', 'INTL Tier 3', 'all', 700),
('1080p', 'INTL Tier 4', 'all', 600),
('1080p', 'INTL Tier 5', 'all', 500),
('1080p', 'INTL Tier 6', 'all', 400),
('4K', 'VF', 'all', 100000),
('4K', 'VOSTFR', 'all', 50000),
('4K', 'FR Tier 1', 'all', 9000),
('4K', 'FR Tier 2', 'all', 8000),
('4K', 'FR Tier 3', 'all', 7000),
('4K', 'FR Tier 4', 'all', 6000),
('4K', 'FR Tier 5', 'all', 5000),
('4K', 'INTL Tier 1', 'all', 900),
('4K', 'INTL Tier 2', 'all', 800),
('4K', 'INTL Tier 3', 'all', 700),
('4K', 'INTL Tier 4', 'all', 600),
('4K', 'INTL Tier 5', 'all', 500),
('4K', 'INTL Tier 6', 'all', 400);

-- Delay Profiles
INSERT INTO delay_profiles (name, preferred_protocol, usenet_delay, torrent_delay) VALUES 
('Global Delay', 'prefer_torrent', 120, 120);

-- Radarr Naming
INSERT INTO radarr_naming (name, rename, movie_format, movie_folder_format) VALUES
('Default', 1, '{Movie CleanTitle} {(Release Year)} {tmdb-{TmdbId}} {edition-{Edition Tags}} {[Custom Formats]}{[Quality Full]}{[MediaInfo 3D]}{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[Mediainfo VideoCodec]}{-Release Group}', '{Movie CleanTitle} ({Release Year})');

-- Sonarr Naming
INSERT INTO sonarr_naming (name, rename, standard_episode_format, daily_episode_format, anime_episode_format, series_folder_format, season_folder_format) VALUES
('Default', 1, '{Series TitleYear} - S{season:00}E{episode:00} - {Episode CleanTitle:90} {[Custom Formats]}{[Quality Full]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[MediaInfo VideoDynamicRangeType]}{[Mediainfo VideoCodec]}{-Release Group}', '{Series TitleYear} - {Air-Date} - {Episode CleanTitle:90} {[Custom Formats]}{[Quality Full]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[MediaInfo VideoDynamicRangeType]}{[Mediainfo VideoCodec]}{-Release Group}', '{Series TitleYear} - S{season:00}E{episode:00} - {Episode CleanTitle:90} {[Custom Formats]}{[Quality Full]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}{[MediaInfo VideoDynamicRangeType]}{[Mediainfo VideoCodec]}{-Release Group}', '{Series TitleYear}', 'Season {season:00}');

-- Media Settings
INSERT INTO radarr_media_settings (name, propers_repacks, enable_media_info) VALUES
('Default', 'preferAndUpgrade', 1);

INSERT INTO sonarr_media_settings (name, propers_repacks, enable_media_info) VALUES
('Default', 'preferAndUpgrade', 1);

-- Quality Definitions (Dynamic for all qualities)
INSERT INTO radarr_quality_definitions (name, quality_name, min_size, max_size, preferred_size)
SELECT 'Default', name, 0, 400, 400 FROM qualities;

INSERT INTO sonarr_quality_definitions (name, quality_name, min_size, max_size, preferred_size)
SELECT 'Default', name, 0, 400, 400 FROM qualities;
