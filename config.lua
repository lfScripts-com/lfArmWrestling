Config = {}

-- ============================================
-- CONFIGURATION GÉNÉRALE
-- ============================================

Config.Locale = 'fr' -- Langue par défaut (fr, en)

-- ============================================
-- INTERACTIONS
-- ============================================

Config.useLfInteract = true -- true pour utiliser LfInteract, false pour utiliser le helptext classique

-- Configuration LfInteract (si useLfInteract = true)
Config.lfInteract = {
    distance = 5.0,      -- Distance de détection du point d'interaction
    interactDst = 2.5    -- Distance pour activer l'interaction
}

-- ============================================
-- TABLES DE BRAS DE FER
-- ============================================
-- Liste de tous les modèles de tables de bras de fer supportés
Config.ArmWrestleModels = {
    'prop_arm_wrestle_01',
    'bkr_prop_clubhouse_arm_wrestle_01a',
    'bkr_prop_clubhouse_arm_wrestle_02a',
}

-- Tables fixes à créer automatiquement (optionnel)
-- Laissez vide si vous voulez uniquement utiliser les tables placées manuellement via lfPropsPlacer

Config.Props = {
    {x = -186.22, y = 6220.68, z = 31.49, model = 'prop_arm_wrestle_01'},
    {x = -189.89, y = 6225.55, z = 31.49, model = 'prop_arm_wrestle_01'},
    {x = 1435.95, y = 6355.04, z = 23.99, model = 'prop_arm_wrestle_01'},
    {x = 1496.21, y = 6322.42, z = 24.08, model = 'prop_arm_wrestle_01'},
    {x = -2646.27, y = 6504.02, z = 24.58, model = 'bkr_prop_clubhouse_arm_wrestle_01a'},
    {x = -2873.20, y = 6097.69, z = 7.28, model = 'prop_arm_wrestle_01'},
    {x = -454.41, y = 7698.60, z = 6.14, model = 'prop_arm_wrestle_01'},
}
