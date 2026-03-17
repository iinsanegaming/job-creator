Config = {}

-- Command to open the Job & Gang Creator (admin only)
Config.OpenCommand = 'jobcreator'


-- Lock to character(s): only these citizenids can open the Job & Gang Creator and place boss/gang locations.
-- Add your character's CitizenID (from Admin Player Info or database). Use {} to allow everyone.
Config.AllowedCitizenIds = { 'NUS27608' } -- Your character; add more IDs to allow others

-- Path to store custom jobs/gangs (relative to resource)
Config.DataFile = 'data/jobs_gangs.json'

-- Path to store boss/gang menu locations (placed from NUI)
Config.LocationsFile = 'data/boss_gang_locations.json'

-- Default job type for new jobs (used by RSG)
Config.DefaultJobType = 'none'

-- Default duty for new jobs
Config.DefaultDuty = true

-- Off duty pay for new jobs
Config.OffDutyPay = false

-- Show "Boss Menu" / "Gang Menu" buttons in the creator (built-in)
Config.ShowBossMenuButton = true
Config.ShowGangMenuButton = true

-- ========== Boss Menu (built-in) ==========
-- Keybind for in-world prompts; storage limits for boss stash. Locations are placed from the NUI Locations tab.
Config.BossMenu = {
    Keybind = 'J',
    StorageMaxWeight = 4000000,
    StorageMaxSlots = 50,
    BossLocations = {}, -- Fallback when locations file is missing; normally use NUI to add.
}

-- ========== Gang Menu (built-in) ==========
Config.GangMenu = {
    Keybind = 'J',
    StorageMaxWeight = 4000000,
    StorageMaxSlots = 50,
    GangLocations = {}, -- Fallback when locations file is missing; normally use NUI to add.
}
