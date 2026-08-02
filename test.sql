PRAGMA foreign_keys = ON;
-- ============================================================================
-- PCD SCHEMA v1
-- ============================================================================

-- ============================================================================
-- CORE ENTITY TABLES (Independent - No Foreign Key Dependencies)
-- ============================================================================
-- These tables form the foundation and can be populated in any order

-- Tags are reusable labels that can be applied to multiple entity types
CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(50) UNIQUE NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Languages used for profile configuration and custom format conditions
CREATE TABLE languages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(30) UNIQUE NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Regular expressions used in custom format pattern conditions
CREATE TABLE regular_expressions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    pattern TEXT NOT NULL,
    regex101_id VARCHAR(50),  -- Optional link to regex101.com for testing
    description TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Individual quality definitions (e.g., "1080p Bluray", "2160p REMUX")
CREATE TABLE qualities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Maps Profilarr canonical qualities to arr-specific API names
-- Absence of a row means the quality doesn't exist for that arr
-- Uses stable key: quality_name
CREATE TABLE quality_api_mappings (
    quality_name VARCHAR(100) NOT NULL,
    arr_type VARCHAR(20) NOT NULL,  -- 'radarr', 'sonarr'
    api_name VARCHAR(100) NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (quality_name, arr_type),
    FOREIGN KEY (quality_name) REFERENCES qualities(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Custom formats define patterns and conditions for media matching
CREATE TABLE custom_formats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    include_in_rename INTEGER NOT NULL DEFAULT 0,  
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- DEPENDENT ENTITY TABLES (Depend on Core Entities)
-- ============================================================================

-- Quality profiles define complete media acquisition strategies
CREATE TABLE quality_profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    upgrades_allowed INTEGER NOT NULL DEFAULT 1,
    minimum_custom_format_score INTEGER NOT NULL DEFAULT 0,
    upgrade_until_score INTEGER NOT NULL DEFAULT 0,
    upgrade_score_increment INTEGER NOT NULL DEFAULT 1 CHECK (upgrade_score_increment > 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Quality groups combine multiple qualities treated as equivalent
-- Each group is specific to a quality profile (profiles do not share groups)
-- Uses stable key: quality_profile_name instead of quality_profile_id
CREATE TABLE quality_groups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    quality_profile_name VARCHAR(100) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(quality_profile_name, name),
    FOREIGN KEY (quality_profile_name) REFERENCES quality_profiles(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Conditions define the matching logic for custom formats
-- Each condition has a type and corresponding data in a type-specific table
-- Uses custom_format_name (stable) instead of custom_format_id (autoincrement)
CREATE TABLE custom_format_conditions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    custom_format_name VARCHAR(100) NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL,
    arr_type VARCHAR(20) NOT NULL DEFAULT 'all',  -- 'radarr', 'sonarr', 'all'
    negate INTEGER NOT NULL DEFAULT 0,
    required INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(custom_format_name, name),
    FOREIGN KEY (custom_format_name) REFERENCES custom_formats(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================================
-- JUNCTION TABLES (Many-to-Many Relationships)
-- ============================================================================

-- Link regular expressions to tags
-- Uses stable keys: regular_expression_name and tag_name
CREATE TABLE regular_expression_tags (
    regular_expression_name VARCHAR(100) NOT NULL,
    tag_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (regular_expression_name, tag_name),
    FOREIGN KEY (regular_expression_name) REFERENCES regular_expressions(name) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (tag_name) REFERENCES tags(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Link custom formats to tags
-- Uses stable keys: custom_format_name and tag_name
CREATE TABLE custom_format_tags (
    custom_format_name VARCHAR(100) NOT NULL,
    tag_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (custom_format_name, tag_name),
    FOREIGN KEY (custom_format_name) REFERENCES custom_formats(name) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (tag_name) REFERENCES tags(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Link quality profiles to tags
-- Uses stable keys: quality_profile_name and tag_name
CREATE TABLE quality_profile_tags (
    quality_profile_name VARCHAR(100) NOT NULL,
    tag_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (quality_profile_name, tag_name),
    FOREIGN KEY (quality_profile_name) REFERENCES quality_profiles(name) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (tag_name) REFERENCES tags(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Link quality profiles to languages with type modifiers
-- Type can be: 'must', 'only', 'not', or 'simple' (default language preference)
-- Uses stable keys: quality_profile_name and language_name
CREATE TABLE quality_profile_languages (
    quality_profile_name VARCHAR(100) NOT NULL,
    language_name VARCHAR(30) NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'simple',  -- 'must', 'only', 'not', 'simple'
    PRIMARY KEY (quality_profile_name, language_name),
    FOREIGN KEY (quality_profile_name) REFERENCES quality_profiles(name) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (language_name) REFERENCES languages(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Define which qualities belong to which quality groups
-- All qualities in a group are treated as equivalent
-- Uses stable keys: (quality_profile_name, quality_group_name) and quality_name
CREATE TABLE quality_group_members (
    quality_profile_name VARCHAR(100) NOT NULL,
    quality_group_name VARCHAR(100) NOT NULL,
    quality_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (quality_profile_name, quality_group_name, quality_name),
    FOREIGN KEY (quality_profile_name, quality_group_name) REFERENCES quality_groups(quality_profile_name, name) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (quality_name) REFERENCES qualities(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Define the quality list for a profile (ordered by position)
-- Each item references either a single quality OR a quality group (never both)
-- Every quality must be represented (either directly or in a group)
-- The enabled flag controls whether the quality/group is active
-- Uses stable keys: quality_profile_name, quality_name, quality_group_name
CREATE TABLE quality_profile_qualities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    quality_profile_name VARCHAR(100) NOT NULL,
    quality_name VARCHAR(100),  -- References a single quality by name
    quality_group_name VARCHAR(100),  -- OR references a quality group by name (within this profile)
    position INTEGER NOT NULL,  -- Display order in the profile
    enabled INTEGER NOT NULL DEFAULT 1,  -- Whether this quality/group is enabled
    upgrade_until INTEGER NOT NULL DEFAULT 0,  -- Stop upgrading at this quality
    CHECK ((quality_name IS NOT NULL AND quality_group_name IS NULL) OR (quality_name IS NULL AND quality_group_name IS NOT NULL)),
    FOREIGN KEY (quality_profile_name) REFERENCES quality_profiles(name) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (quality_name) REFERENCES qualities(name) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (quality_profile_name, quality_group_name) REFERENCES quality_groups(quality_profile_name, name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Assign custom formats to quality profiles with scoring
-- Scores determine upgrade priority and filtering behavior
-- Uses stable keys: quality_profile_name and custom_format_name
CREATE TABLE quality_profile_custom_formats (
    quality_profile_name VARCHAR(100) NOT NULL,
    custom_format_name VARCHAR(100) NOT NULL,
    arr_type VARCHAR(20) NOT NULL,  -- 'radarr', 'sonarr', 'all'
    score INTEGER NOT NULL,
    PRIMARY KEY (quality_profile_name, custom_format_name, arr_type),
    FOREIGN KEY (quality_profile_name) REFERENCES quality_profiles(name) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (custom_format_name) REFERENCES custom_formats(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================================
-- CUSTOM FORMAT CONDITION TYPE TABLES
-- ============================================================================
-- Each condition type has a dedicated table storing type-specific data
-- A condition_id should only appear in ONE of these tables, matching its type

-- Pattern-based conditions (release_title, release_group, edition)
-- Each pattern condition references exactly one regular expression
-- Uses stable keys: (custom_format_name, condition_name) and regular_expression_name
CREATE TABLE condition_patterns (
    custom_format_name VARCHAR(100) NOT NULL,
    condition_name VARCHAR(100) NOT NULL,
    regular_expression_name VARCHAR(100) NOT NULL,
    PRIMARY KEY (custom_format_name, condition_name),
    FOREIGN KEY (custom_format_name, condition_name) REFERENCES custom_format_conditions(custom_format_name, name) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (regular_expression_name) REFERENCES regular_expressions(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Language-based conditions
-- Uses stable keys: (custom_format_name, condition_name) and language_name
CREATE TABLE condition_languages (
    custom_format_name VARCHAR(100) NOT NULL,
    condition_name VARCHAR(100) NOT NULL,
    language_name VARCHAR(30) NOT NULL,
    except_language INTEGER NOT NULL DEFAULT 0,  -- Match everything EXCEPT this language
    PRIMARY KEY (custom_format_name, condition_name),
    FOREIGN KEY (custom_format_name, condition_name) REFERENCES custom_format_conditions(custom_format_name, name) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (language_name) REFERENCES languages(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Indexer flag conditions (e.g., "Scene", "Freeleech")
-- Uses stable key: (custom_format_name, condition_name)
CREATE TABLE condition_indexer_flags (
    custom_format_name VARCHAR(100) NOT NULL,
    condition_name VARCHAR(100) NOT NULL,
    flag VARCHAR(100) NOT NULL,
    PRIMARY KEY (custom_format_name, condition_name),
    FOREIGN KEY (custom_format_name, condition_name) REFERENCES custom_format_conditions(custom_format_name, name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Source conditions (e.g., "Bluray", "Web", "DVD")
-- Uses stable key: (custom_format_name, condition_name)
CREATE TABLE condition_sources (
    custom_format_name VARCHAR(100) NOT NULL,
    condition_name VARCHAR(100) NOT NULL,
    source VARCHAR(100) NOT NULL,
    PRIMARY KEY (custom_format_name, condition_name),
    FOREIGN KEY (custom_format_name, condition_name) REFERENCES custom_format_conditions(custom_format_name, name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Resolution conditions (e.g., "1080p", "2160p")
-- Uses stable key: (custom_format_name, condition_name)
CREATE TABLE condition_resolutions (
    custom_format_name VARCHAR(100) NOT NULL,
    condition_name VARCHAR(100) NOT NULL,
    resolution VARCHAR(100) NOT NULL,
    PRIMARY KEY (custom_format_name, condition_name),
    FOREIGN KEY (custom_format_name, condition_name) REFERENCES custom_format_conditions(custom_format_name, name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Quality modifier conditions (e.g., "REMUX", "WEBDL")
-- Uses stable key: (custom_format_name, condition_name)
CREATE TABLE condition_quality_modifiers (
    custom_format_name VARCHAR(100) NOT NULL,
    condition_name VARCHAR(100) NOT NULL,
    quality_modifier VARCHAR(100) NOT NULL,
    PRIMARY KEY (custom_format_name, condition_name),
    FOREIGN KEY (custom_format_name, condition_name) REFERENCES custom_format_conditions(custom_format_name, name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Size-based conditions with min/max bounds in bytes
-- Uses stable key: (custom_format_name, condition_name)
CREATE TABLE condition_sizes (
    custom_format_name VARCHAR(100) NOT NULL,
    condition_name VARCHAR(100) NOT NULL,
    min_bytes INTEGER,  -- Null means no minimum
    max_bytes INTEGER,  -- Null means no maximum
    PRIMARY KEY (custom_format_name, condition_name),
    FOREIGN KEY (custom_format_name, condition_name) REFERENCES custom_format_conditions(custom_format_name, name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Release type conditions (e.g., "Movie", "Episode")
-- Uses stable key: (custom_format_name, condition_name)
CREATE TABLE condition_release_types (
    custom_format_name VARCHAR(100) NOT NULL,
    condition_name VARCHAR(100) NOT NULL,
    release_type VARCHAR(100) NOT NULL,
    PRIMARY KEY (custom_format_name, condition_name),
    FOREIGN KEY (custom_format_name, condition_name) REFERENCES custom_format_conditions(custom_format_name, name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Year-based conditions with min/max bounds
-- Uses stable key: (custom_format_name, condition_name)
CREATE TABLE condition_years (
    custom_format_name VARCHAR(100) NOT NULL,
    condition_name VARCHAR(100) NOT NULL,
    min_year INTEGER,  -- Null means no minimum
    max_year INTEGER,  -- Null means no maximum
    PRIMARY KEY (custom_format_name, condition_name),
    FOREIGN KEY (custom_format_name, condition_name) REFERENCES custom_format_conditions(custom_format_name, name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================================
-- CUSTOM FORMAT TESTING
-- ============================================================================

-- Test cases for validating custom format matching logic
-- Each test belongs to a custom format and specifies whether a title should match
-- Uses stable key: custom_format_name
CREATE TABLE custom_format_tests (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    custom_format_name VARCHAR(100) NOT NULL,
    title TEXT NOT NULL,              -- Release title to test against
    type VARCHAR(20) NOT NULL,        -- 'movie' or 'series'
    should_match INTEGER NOT NULL,    -- 1 = should match, 0 = should not match
    description TEXT,                 -- Why this test exists / edge case covered
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(custom_format_name, title, type),
    FOREIGN KEY (custom_format_name) REFERENCES custom_formats(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================================
-- MEDIA MANAGEMENT TABLES
-- ============================================================================

-- Radarr quality size definitions
-- Uses stable key: (name, quality_name)
CREATE TABLE radarr_quality_definitions (
    name VARCHAR(100) NOT NULL,
    quality_name VARCHAR(100) NOT NULL,
    min_size INTEGER NOT NULL DEFAULT 0,
    max_size INTEGER NOT NULL,
    preferred_size INTEGER NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (name, quality_name),
    FOREIGN KEY (quality_name) REFERENCES qualities(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Sonarr quality size definitions
-- Uses stable key: (name, quality_name)
CREATE TABLE sonarr_quality_definitions (
    name VARCHAR(100) NOT NULL,
    quality_name VARCHAR(100) NOT NULL,
    min_size INTEGER NOT NULL DEFAULT 0,
    max_size INTEGER NOT NULL,
    preferred_size INTEGER NOT NULL,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (name, quality_name),
    FOREIGN KEY (quality_name) REFERENCES qualities(name) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Radarr naming configuration
CREATE TABLE radarr_naming (
    name VARCHAR(100) NOT NULL PRIMARY KEY,
    rename INTEGER NOT NULL DEFAULT 1,
    movie_format TEXT NOT NULL,
    movie_folder_format TEXT NOT NULL,
    replace_illegal_characters INTEGER NOT NULL DEFAULT 0,
    colon_replacement_format VARCHAR(20) NOT NULL DEFAULT 'smart'
        CHECK (colon_replacement_format IN ('delete', 'dash', 'spaceDash', 'spaceDashSpace', 'smart')),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Sonarr naming configuration
CREATE TABLE sonarr_naming (
    name VARCHAR(100) NOT NULL PRIMARY KEY,
    rename INTEGER NOT NULL DEFAULT 1,
    standard_episode_format TEXT NOT NULL,
    daily_episode_format TEXT NOT NULL,
    anime_episode_format TEXT NOT NULL,
    series_folder_format TEXT NOT NULL,
    season_folder_format TEXT NOT NULL,
    replace_illegal_characters INTEGER NOT NULL DEFAULT 0,
    colon_replacement_format INTEGER NOT NULL DEFAULT 4,
    custom_colon_replacement_format TEXT,
    multi_episode_style INTEGER NOT NULL DEFAULT 5,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Radarr general media settings
CREATE TABLE radarr_media_settings (
    name VARCHAR(100) NOT NULL PRIMARY KEY,
    propers_repacks VARCHAR(50) NOT NULL DEFAULT 'doNotPrefer'
        CHECK (propers_repacks IN ('doNotPrefer', 'preferAndUpgrade', 'doNotUpgradeAutomatically')),
    enable_media_info INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Sonarr general media settings
CREATE TABLE sonarr_media_settings (
    name VARCHAR(100) NOT NULL PRIMARY KEY,
    propers_repacks VARCHAR(50) NOT NULL DEFAULT 'doNotPrefer'
        CHECK (propers_repacks IN ('doNotPrefer', 'preferAndUpgrade', 'doNotUpgradeAutomatically')),
    enable_media_info INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- DELAY PROFILES
-- ============================================================================

-- Delay profiles control download timing preferences
-- Note: Tags removed - Radarr/Sonarr only allows updating the default profile (id=1)
-- which must have empty tags. Only one delay profile can be synced per arr instance.
CREATE TABLE delay_profiles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(100) UNIQUE NOT NULL,
    preferred_protocol VARCHAR(20) NOT NULL CHECK (
        preferred_protocol IN ('prefer_usenet', 'prefer_torrent', 'only_usenet', 'only_torrent')
    ),
    usenet_delay INTEGER,  -- minutes, NULL if only_torrent
    torrent_delay INTEGER,  -- minutes, NULL if only_usenet
    bypass_if_highest_quality INTEGER NOT NULL DEFAULT 0,
    bypass_if_above_custom_format_score INTEGER NOT NULL DEFAULT 0,
    minimum_custom_format_score INTEGER,  -- Required when bypass_if_above_custom_format_score = 1
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    -- Enforce usenet_delay is NULL only when only_torrent
    CHECK (
        (preferred_protocol = 'only_torrent' AND usenet_delay IS NULL) OR
        (preferred_protocol != 'only_torrent' AND usenet_delay IS NOT NULL)
    ),
    -- Enforce torrent_delay is NULL only when only_usenet
    CHECK (
        (preferred_protocol = 'only_usenet' AND torrent_delay IS NULL) OR
        (preferred_protocol != 'only_usenet' AND torrent_delay IS NOT NULL)
    ),
    -- Enforce minimum_custom_format_score required when bypass enabled
    CHECK (
        (bypass_if_above_custom_format_score = 0 AND minimum_custom_format_score IS NULL) OR
        (bypass_if_above_custom_format_score = 1 AND minimum_custom_format_score IS NOT NULL)
    )
);

-- ============================================================================
-- QUALITY PROFILE TESTING
-- ============================================================================

-- Test entities (movies/series for quality profile testing)
CREATE TABLE test_entities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL CHECK (type IN ('movie', 'series')),
    tmdb_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    year INTEGER,
    poster_path TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(type, tmdb_id)
);

-- Test releases attached to entities
-- Uses composite FK (entity_type, entity_tmdb_id) for stable references across recompiles
CREATE TABLE test_releases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT NOT NULL CHECK (entity_type IN ('movie', 'series')),
    entity_tmdb_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    size_bytes INTEGER,
    languages TEXT NOT NULL DEFAULT '[]',
    indexers TEXT NOT NULL DEFAULT '[]',
    flags TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (entity_type, entity_tmdb_id) REFERENCES test_entities(type, tmdb_id) ON DELETE CASCADE
);

CREATE INDEX idx_test_releases_entity ON test_releases(entity_type, entity_tmdb_id);

-- ============================================================================
-- INDEXES AND CONSTRAINTS
-- ============================================================================

-- Ensure only one quality item per profile can be marked as upgrade_until
CREATE UNIQUE INDEX idx_one_upgrade_until_per_profile
ON quality_profile_qualities(quality_profile_name)
WHERE upgrade_until = 1;
-- Regular Expressions
INSERT INTO regular_expressions (name, pattern) VALUES
('Regex_VF', '(?i)\\b(multi|multifrench|multi-fr|french|truefrench|vff?|vfi|vfq|fr)\\b'),
('Regex_VOSTFR', '(?i)\\b(vostfr?|vost|subfrench|french\\.subs?|fr\\.subs?|sub\\.fr|subbed\\.fr)\\b'),
('Regex_FR_tier_1', '(?i)[-.](AMEN|ARK01|B@tman|BDHD|BlackAngel|BONBON|BOUBA|BOUC|Choco|Darki|Delivroozzi|FCK|FLOP|FORWARD|FoX|FRATERNiTY|FrIeNdS|FtLi|FTMVHD|Fuceo|FW|GKS|Goldenyann|HDForever|HeavyWeight|KAAZA|KTM|M@x|MARBLECAKE|MAX|MOONLY|MTDK|MUSTANG|NoLo|Obi|ONLY|OZEF|PATOPESTO|PEPiTE|PiouPiou|Psaro|Punisher694|QUEBEC63|RG|ROMKENT|Sicario|SR\-71|SUPPLY|T3KASHi|TANOSHii|TenmaLand|Tezcat74|TFA|THESYNDICATE|TiNA|Tsundere\-Raws|TyHD|TyrellCorp|YODA|Zapax)$'),
('Regex_FR_tier_2', '(?i)[-.](AJP|ALLDAYiN|Anime\-Heart|Aoi\-Project|ATE|AW|CHiLL|COCAIN|COLL3CTiF|D4RK|DREAM|DUSTiN|Elecman|ENIGMA|FiND|Floppy|FUJiSAN|GHT|GORE|GundamGuy|HYPERION|IssouCorp|J4CK|Kaerizaki\-Fansub|KAF|KHFR|LiDHL|LKT|Maxadonf|mHDgz|MULTiPLY|MYSTERiON|N3ZUKO|Nagutos|Natsumi\-no\-Sekai|NEO|NEOSTARK|NoNE|OECUF|Onii\-ChanSub|ONLYMOViE|Owlolf|PATOMiEL|pERsO|Pikari\-Teshima|PiXEL|PopHD|POTO|PRESTiGE|QTZ|QUALiTY|R3MIX|RiFiFi|RiPiT|SANTACRUZ|Seimeisen|Slay3R|SUPERFLU|TARDiS|TAT|Team\.Arcedo|Themouche|TkHD|TLC|TMB|TSR|UTT|WaCkS|Winks|Xantar|XSPITFIRE911|Yangire\-Raws|Yarashii|ZTM)$'),
('Regex_FR_tier_3', '(?i)[-.](Anime\.Heart|Aoi\.Project|Arcedo|BLV|BraD|BY_ORDER|D3T3R10R1TY|dRuIdE|Erai\-raws|Galactic|Alexis|HANAMi|Kaerizaki\.Fansub|kazuizui|KHAYA|KHFR|KushEnthusiast|LAZARUS|matheousse|MAX|Monkey\-D\.Lulu|NekoYu|NeoSG|Onii\-ChanSub|Pikari\.Teshima|QC63|RONiN|Scaph|TheFantastics|ToonsHub|Tsundere\.Raws|TTN|VARYG|WQM|Yangire\.Raws)$'),
('Regex_FR_tier_4', '(?i)[-.](4FR|AiR3D|AiRDOCS|AiRFORCE|AiRLiNE|AiRTV|AKLHD|AMB3R|ANMWR|AVON|AYMO|AZR|BANKAi|BAWLS|BiPOLAR|BLACKPANTERS|BODIE|BOOLZ|BRiNK|BTT|CARAPiLS|CiELOS|CiNEMA|CMBHD|CoRa|COUAC|CRYPT0|D4KiD|DEAL|DiEBEX|DUPLI|DUSS|ENJOi|EUBDS|FHD|FiDELiO|FiDO|ForceBleue|FREAMON|FRENCHDEADPOOL2|FRiES|FUTiL|FWDHD|GHOULS|GiMBAP|GLiMMER|Goatlove|HERC|HiggsBoson|HiRoSHiMa|HYBRiS|HyDe|JMT|JoKeR|JUSTICELEAGUE|KAZETV|L0SERNiGHT|LaoZi|LeON|LOFiDEL|LOST|LOWIMDB|LUCKY|LYPSG|MAGiCAL|MANGACiTY|MAXAGAZ|MaxiBeNoul|McNULTY|MELBA|MiND|MORELAND|MUNSTER|MUxHD|N0Z00M|NERDHD|NERO|NrZ|NTK|OBSTACLE|OohLaLa|OOKAMI|PANZeR|PATHECROUTE|Penrose|PHoQUE|PiNKPANTERS|PKPTRS|PRiDEHD|PROPJOE|PURE|PUREWASTEOFBW|ROUGH|RUDE|Ryotox|S4LVE|SAFETY|SASHiMi|SEiGHT|SESKAPiLE|SharpHD|SHEEEiT|SHiNiGAMi|SiGeRiS|SILVIODANTE|SLEEPINGFOREST|SODAPOP|SPINE|SPOiLER|STRINGERBELL|Sunday26th|SUNRiSE|tFR|THENiGHTMAREiNHD|THiNK|THREESOME|TiMELiNE|TSuNaMi|UKDHD|UKDTV|ULSHD|Ulysse|UNSKiLLED|URY|USURY|VENUE|VFC|VoMiT|Wednesday29th|ZEST|ZiRCON)$'),
('Regex_FR_tier_5', '(?i)[-.](ACOOL|AlioZ|ANONA|ARKRiL|ASPHiXiAS|AT|AViTECH|AZAZE|Balibalo|Bandix|bigZT|BLABLASTREAM|Boheme|BOL|BossBaby|Champion9|CINeHD|Copycomic|Cortex91|Cpasbien|CPB|CR4ZYTiME|CZ|DDLFRENCHORG|DOLL4R|Dread\.Team|Dropse|EASPORTS|EliteT|EXTREME|EZTV\.re|FERVEX|FGT|Firetown|FReeZeR|FUN|FUNKKY|FZTeam|GAIA|GHOSTSPiRiT|GHZ|GLaDOS|GOBO2S|GZR|HD2|HDMIDIMADRIDI|HEVCBay|HMiDiMADRiDi|Hush|JetAnime|JiHeff|KILLERMIX|KR4K3N|L\-O\-L|LiBERTAD|LION|LMPS|LNA3d|LTM|MACK4|Matmatha|MeMyl|METALLIKA|MGD|MKVXTEAM|Monchat|MONiCO|Moorea81|Moviz|Muxman|Mystic|MZC|MZiSYS|N3TFL1X|NEWCINE|NewZT|NG|NLX5|NoelMaison|NOMAD|NORRIS|nutella|OMERTA|Papaya|PiCKLES|PIKACHU|PREUMS|PULSE|Q7|qctimb3rlandqc|ReBoT|RELiC|ROLLED|RPZ|SANCTUAIRE|SCREEN|SHARKS|SHiFT|ShowFR|SKRiN|SP3CTR|Spow|STR4NGE|STVFRV|SubZero|T9|TeamSuW|TicaDow|Time2Watch|TIREXO|Tokushi|Tonyk|Torrent9|TORRiD|TOXIC|TSN999|TUTUTE|TVPSLO|UNiKORN|Upmix|VATFER|VERCLAM|ViKi47|Wakanim|WaNeZt|Wawa|WebAnime|WINCHESTER|WITA|YIFY|YTS|Zombie|ZONE|ZT|ZW)$'),
('Regex_INTL_tier_1', '(?i)[-.](coffee|DON|IMNEWHERE|LM|RARBG|REBORN|SA89|SoLaR|TeamSyndicate|ZoroSenpai)$'),
('Regex_INTL_tier_2', '(?i)[-.](c0kE|CtrlHD|D\-Z0N3|EbP|Geek|HiFi|LoRD|maniac|TayTo|VietHD|ZQ)$'),
('Regex_INTL_tier_3', '(?i)[-.](BV|CRiSC|decibeL|FoRM|HiDt|HiP|iFT|MADSKY|SbR|WMING)$'),
('Regex_INTL_tier_4', '(?i)[-.](ATELiER|BLOOM|BMF|eXterminator|faBR|HDMaNiAcS|IDE|LESTiN|LolHD|NCmt|NTb|RandomBytes|Skazhutin|Softboat)$'),
('Regex_INTL_tier_5', '(?i)[-.](0BSiDiAN|AJP69|BakedFEL|BAT1|BSTD|Chotab|CJ|CRX|Dariush|E\.N\.D|E1|EA|EDPH|ELiTE|ENDSkY|ESiR|EXCiSION|FraMeSToR|GALAXY|GS88|GZ|hdalx|HQMUX|HR|iLoveHD|KASHMiR|Kitsune|LAZY|LiNG|luvBB|Natuyuki|NiBuRu|nmd|NyHD|ORiGEN|pcroland|Penumbra|playHD|Positive|PTer|RiCO|rightSIZE|RO|Rose3Thorn|rttr|SaNcTi|SiMPLE|SOP|SPHD|TBB|TDD|TnP|ViSUM|VLAD|W4NK3R|WiLF|xander|ZIMBO)$'),
('Regex_INTL_tier_6', '(?i)[-.](ASD87|BRUTE|BTN|CART|CHD|EuReKA|GALVANiZE|HaB|HANDJOB|HDC|iON|Ivandro|j3rico|KnG|LEGi0N|Lulz|MaG|MTeam|NiP|ORBiT|P0W4HD|PTP|PuTao|ROCiNANTE|Slappy|ThD|WiKi|WiLDCAT)$');

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
('1080p', NULL, 'Group-Bluray-Webdl-1080p', 1, 1),
('1080p', NULL, 'Group-HDTV-Webrip-1080p', 2, 0),
('1080p', 'Remux-1080p', NULL, 3, 0),
('1080p', NULL, 'Group-Bluray-Webdl-2160p', 4, 0),
('1080p', NULL, 'Group-HDTV-Webrip-2160p', 5, 0),
('1080p', 'Remux-2160p', NULL, 6, 0),
('4K', NULL, 'Group-Bluray-Webdl-2160p', 1, 1),
('4K', NULL, 'Group-HDTV-Webrip-2160p', 2, 0),
('4K', 'Remux-2160p', NULL, 3, 0),
('4K', NULL, 'Group-Bluray-Webdl-1080p', 4, 0),
('4K', NULL, 'Group-HDTV-Webrip-1080p', 5, 0),
('4K', 'Remux-1080p', NULL, 6, 0);

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
