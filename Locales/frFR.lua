local addonName, UVL = ...

if GetLocale() ~= "frFR" then return end

local L = UVL.L

-- Core / UI
L["UI_OPEN_EDIT_MODE"]  = "Ouvrir le mode édition"
L["UI_RESET"]           = "Réinitialiser"
L["UI_PREVIEW"]         = "Aperçu"
L["UI_VERSION"]         = "Version %s"
L["UI_EDITMODE_HINT"]   = "Déplace cet élément dans le mode édition."
L["UI_COMBAT"]          = "Indisponible en combat."
L["UI_LAYOUT_PENDING"]  = "Disposition du mode édition pas encore chargée, réessaie dans un instant."
L["UI_ACTIVE_MODULES"]  = "Modules actifs : %d / %d"
L["UI_TIP_LEFT"]        = "Clic gauche : ouvrir les paramètres"
L["UI_TIP_RIGHT"]       = "Clic droit : ouvrir le mode édition"

-- Réglages communs
L["SET_ENABLE"]         = "Activer le module"
L["SET_FONT_SIZE"]      = "Taille du texte"
L["SET_COLOR"]          = "Couleur"
L["SET_OUTLINE"]        = "Contour"
L["SET_OUTLINE_NONE"]   = "Aucun"
L["SET_OUTLINE_THIN"]   = "Fin"
L["SET_OUTLINE_THICK"]  = "Épais"
L["SET_OPACITY"]        = "Opacité"
L["SET_SHOW_LABEL"]     = "Afficher le libellé"

-- Module : groupe de raid
L["GROUP_NAME"]         = "Groupe de raid"
L["GROUP_DESC"]         = "Affiche le groupe de raid (1-8) dans lequel tu es."
L["GROUP_LABEL"]        = "Groupe : %d"

-- Module : durabilité
L["DUR_NAME"]           = "Durabilité"
L["DUR_DESC"]           = "Affiche la durabilité moyenne de ton équipement."
L["DUR_LABEL"]          = "Durabilité %d%%"
L["DUR_SET_AUTOCOLOR"]  = "Couleur selon le niveau"
L["DUR_SET_HIDEFULL"]   = "Masquer à 100%"

-- Module : mana des soigneurs
L["HEAL_NAME"]          = "Mana des soigneurs"
L["HEAL_DESC"]          = "Affiche une barre de mana pour chaque soigneur du groupe."
L["HEAL_SET_WIDTH"]     = "Largeur des barres"
L["HEAL_SET_HEIGHT"]    = "Hauteur des barres"
L["HEAL_SET_SPACING"]   = "Espacement des barres"
L["HEAL_SET_CLASSCOLOR"] = "Couleurs de classe"
L["HEAL_SET_SHOWNAME"]  = "Afficher le nom"
L["HEAL_SET_SHOWPCT"]   = "Afficher le pourcentage"
L["HEAL_SET_RAIDONLY"]  = "Uniquement en raid"
L["HEAL_SAMPLE_NAME"]   = "Soigneur %d"

-- Module : quêtes
L["QUEST_NAME"]          = "Quêtes"
L["QUEST_DESC"]          = "Accepte et rend les quêtes, et sélectionne les dialogues automatiquement."
L["QUEST_SET_ACCEPT"]    = "Accepter les quêtes"
L["QUEST_SET_TURNIN"]    = "Rendre les quêtes"
L["QUEST_SET_GOSSIP"]    = "Sélection auto des dialogues"
L["QUEST_SET_REWARD"]    = "Choix de la récompense"
L["QUEST_REWARD_MANUAL"] = "Manuel"
L["QUEST_REWARD_PRICE"]  = "Prix de vente le plus élevé"
L["QUEST_HINT"]          = "Maintiens Maj, Ctrl ou Alt pour suspendre l'automatisation."

-- Paramètres (général)
L["GENERAL_NAME"]       = "Paramètres"
L["GENERAL_DESC"]       = "Options générales de l'addon."
L["GENERAL_SET_HIDE_MINIMAP"] = "Masquer l'icône de la minimap"
