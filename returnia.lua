RETURNIA = SMODS.current_mod
RETURNIA.description_loc_vars = function()
  return { background_colour = G.C.CLEAR, text_colour = G.C.WHITE, scale = 1.2, shadow = true }
end

function RETURNIA.recursive_load(path)
  local files = NFS.getDirectoryItems(ASAS.path .. path)
  table.sort(files)
  for _, item in ipairs(files) do
    if string.sub(item, -4) == ".lua" then
      local f, err = SMODS.load_file(path .. "/" .. item)
      if err then
        error(err)
      elseif f then
        f()
      end
    elseif path:find("%.") == nil then
      RETURNIA.recursive_load(path .. "/" .. item)
    end
  end
end

--[[
Usage for the above function would be:
RETURNIA.recursive_load("content")
(loads everything including subfolders for any given directory)
]]


-- Imaginary levels
RETURNIA.imaginary = {
  chips_per_level = 0.35,
  mult_per_level = 0.25,
}

function RETURNIA.get_imaginary_level(hand)
  local hand_data = G.GAME.hands[hand]
  return hand_data and hand_data.returnia_imag_level or 0
end


function RETURNIA.level_up_imaginary(card, hand, amount, instant)
  amount = amount or 1
  local hand_data = G.GAME.hands[hand]
  if not hand_data then return end

  local old_level = hand_data.returnia_imag_level or 0
  local new_level = math.max(0, old_level + amount)
  if new_level == old_level then return end

  if not instant then
    update_hand_text(
      { sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 },
      { handname = localize(hand, "poker_hands"), chips = hand_data.chips, mult = hand_data.mult, level = hand_data.level .. "+" .. old_level .. "i" }
    )
  end

  local chips_ratio = (1 + RETURNIA.imaginary.chips_per_level * new_level) / (1 + RETURNIA.imaginary.chips_per_level * old_level)
  local mult_ratio = (1 + RETURNIA.imaginary.mult_per_level * new_level) / (1 + RETURNIA.imaginary.mult_per_level * old_level)

  hand_data.returnia_imag_level = new_level
  hand_data.s_chips = hand_data.s_chips * chips_ratio
  hand_data.l_chips = hand_data.l_chips * chips_ratio
  hand_data.s_mult = hand_data.s_mult * mult_ratio
  hand_data.l_mult = hand_data.l_mult * mult_ratio
  hand_data.chips = math.max(hand_data.s_chips + hand_data.l_chips * (hand_data.level - 1), 0)
  hand_data.mult = math.max(hand_data.s_mult + hand_data.l_mult * (hand_data.level - 1), 1)

  if instant then return end

  G.E_MANAGER:add_event(Event({
    trigger = "after",
    delay = 0.2,
    func = function()
      play_sound("tarot1")
      if card then card:juice_up(0.8, 0.5) end
      G.TAROT_INTERRUPT_PULSE = true
      return true
    end
  }))
  update_hand_text({ delay = 0 }, { mult = hand_data.mult, StatusText = true })
  G.E_MANAGER:add_event(Event({
    trigger = "after",
    delay = 0.9,
    func = function()
      play_sound("tarot1")
      if card then card:juice_up(0.8, 0.5) end
      return true
    end
  }))
  update_hand_text({ delay = 0 }, { chips = hand_data.chips, StatusText = true })
  G.E_MANAGER:add_event(Event({
    trigger = "after",
    delay = 0.9,
    func = function()
      play_sound("tarot1")
      if card then card:juice_up(0.8, 0.5) end
      G.TAROT_INTERRUPT_PULSE = nil
      return true
    end
  }))
  update_hand_text(
    { sound = "button", volume = 0.7, pitch = 0.9, delay = 0 },
    { level = hand_data.level .. "+" .. new_level .. "i" }
  )
  delay(1.3)
  update_hand_text(
    { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
    { mult = 0, chips = 0, handname = "", level = "" }
  )
end

-- Level every hand at once (for an "all hands" card)
function RETURNIA.level_up_all_imaginary(card, amount)
  update_hand_text(
    { sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 },
    { handname = localize("k_all_hands"), chips = "...", mult = "...", level = "" }
  )
  G.E_MANAGER:add_event(Event({
    trigger = "after",
    delay = 0.2,
    func = function()
      play_sound("tarot1")
      if card then card:juice_up(0.8, 0.5) end
      G.TAROT_INTERRUPT_PULSE = true
      return true
    end
  }))
  update_hand_text({ delay = 0 }, { mult = "+", StatusText = true })
  G.E_MANAGER:add_event(Event({
    trigger = "after",
    delay = 0.9,
    func = function()
      play_sound("tarot1")
      if card then card:juice_up(0.8, 0.5) end
      return true
    end
  }))
  update_hand_text({ delay = 0 }, { chips = "+", StatusText = true })
  G.E_MANAGER:add_event(Event({
    trigger = "after",
    delay = 0.9,
    func = function()
      play_sound("tarot1")
      if card then card:juice_up(0.8, 0.5) end
      G.TAROT_INTERRUPT_PULSE = nil
      return true
    end
  }))
  update_hand_text(
    { sound = "button", volume = 0.7, pitch = 0.9, delay = 0 },
    { level = "+" .. amount .. "i" }
  )
  delay(1.3)
  for hand_key, _ in pairs(G.GAME.hands) do
    RETURNIA.level_up_imaginary(card, hand_key, amount, true)
  end
  update_hand_text(
    { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
    { mult = 0, chips = 0, handname = "", level = "" }
  )
end


-- Spectrals 

SMODS.Atlas({
  key = "ReturniaSpectrals",
  path = "consumables/spectrals.png",
  px = 71,
  py = 95,
})

SMODS.Consumable {
  key = "astrolabe",
  set = "Spectral",
  config = { extra = { levels = 2 } },
  cost = 4,
  atlas = "ReturniaSpectrals",
  pos = { x = 2, y = 0 },
  
  loc_txt = {
    name = "Astrolabe",
    text = {
      "Gives {C:attention}#1#{} imaginary levels",
      "to your {C:attention}highest level{}",
      "poker hand",
    }
  },
  
  abn_artist_credits = {
	artist = "Boko"
  },
  
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.levels } }
  end,
  
  can_use = function(self, card)
    return true
  end,
  
  use = function(self, card, area, copier)
    local highest_level = -math.huge
    local highest_hands = {}
    for hand_key, hand_data in pairs(G.GAME.hands) do
      if hand_data.visible then
        if hand_data.level > highest_level then
          highest_level = hand_data.level
          highest_hands = { hand_key }
        elseif hand_data.level == highest_level then
          highest_hands[#highest_hands + 1] = hand_key
        end
      end
    end
    if #highest_hands == 0 then return end
    local target_hand = pseudorandom_element(highest_hands, pseudoseed("returnia_astrolabe"))
    RETURNIA.level_up_imaginary(card, target_hand, card.ability.extra.levels)
  end,
}

SMODS.Consumable {
  key = "catastrophe",
  set = "Spectral",
  config = { extra = { max_highlighted = 1, target_level = -1, edition = "e_returnia_distorted" } },
  cost = 4,
  atlas = "ReturniaSpectrals",
  pos = { x = 0, y = 1 },

  loc_txt = {
    name = "Catastrophe",
    text = {
      "Add {C:dark_edition}Distorted{} Edition to {C:attention}#1#{} selected Joker,",
      "{C:red}level down{} a random poker hand to level {C:attention}#2#{}",
    }
  },

  abn_artist_credits = {
    artist = "Boko"
  },

  loc_vars = function(self, info_queue, card)
    info_queue[#info_queue + 1] = G.P_CENTERS.e_returnia_distorted
    return { vars = { card.ability.extra.max_highlighted, card.ability.extra.target_level } }
  end,

  can_use = function(self, card)
    if not G.jokers or #G.jokers.highlighted ~= card.ability.extra.max_highlighted then return false end
    for _, joker in ipairs(G.jokers.highlighted) do
      if joker.edition then return false end
    end
    return true
  end,

  use = function(self, card, area, copier)
    local target_jokers = {}
    for _, joker in ipairs(G.jokers.highlighted) do
      target_jokers[#target_jokers + 1] = joker
    end

    G.E_MANAGER:add_event(Event({
      trigger = 'after',
      delay = 0.4,
      func = function()
        play_sound('tarot1')
        card:juice_up(0.3, 0.5)
        for _, joker in ipairs(target_jokers) do
          joker:set_edition(card.ability.extra.edition, true)
        end
        return true
      end
    }))

    local big = to_big or function(value) return value end

    local visible_hands = {}
    for hand_key, hand_data in pairs(G.GAME.hands) do
      if hand_data.visible and big(hand_data.level) > big(card.ability.extra.target_level) then
        visible_hands[#visible_hands + 1] = hand_key
      end
    end
    table.sort(visible_hands)

    if #visible_hands > 0 then
      local target_hand = pseudorandom_element(visible_hands, pseudoseed("returnia_catastrophe"))
      local to_plain = to_number or function(value) return value end
      local level_change = to_plain(big(card.ability.extra.target_level) - big(G.GAME.hands[target_hand].level))

      level_up_hand(card, target_hand, false, level_change)
    end

    G.E_MANAGER:add_event(Event({
      trigger = 'after',
      delay = 0.2,
      func = function()
        G.jokers:unhighlight_all()
        return true
      end
    }))
    delay(0.6)
  end,
}

SMODS.Consumable {
  key = 'infinity',
  set = 'Spectral',
  atlas = "ReturniaSpectrals",
  pos = { x = 1, y = 0 },
  cost = 4,
  discovered = false,
  config = { extra = { max_highlighted = 1, blind_mult = 1.5, edition = "e_returnia_static" } },

  loc_txt = {
    name = "Infinity",
    text = {
      "Add {C:dark_edition}Static{} Edition to {C:attention}#1#{} selected Joker",
      "increase {C:attention}blind requirements{} by {X:mult,C:white}X#2#{} for each owned {C:attention}Joker",
    }
  },

  loc_vars = function(self, info_queue, card)
    info_queue[#info_queue + 1] = G.P_CENTERS[card.ability.extra.edition]
    return { vars = { card.ability.extra.max_highlighted, card.ability.extra.blind_mult } }
  end,

  can_use = function(self, card)
    if not G.jokers or #G.jokers.highlighted ~= card.ability.extra.max_highlighted then return false end
    for _, joker in ipairs(G.jokers.highlighted) do
      if joker.edition then return false end
    end
    return true
  end,

  use = function(self, card, area, copier)
    local target_jokers = {}
    for _, joker in ipairs(G.jokers.highlighted) do
      target_jokers[#target_jokers + 1] = joker
    end
    local total_mult = card.ability.extra.blind_mult * #G.jokers.cards

    G.E_MANAGER:add_event(Event({
      trigger = 'after',
      delay = 0.4,
      func = function()
        play_sound('tarot1')
        card:juice_up(0.3, 0.5)
        for _, joker in ipairs(target_jokers) do
          joker:set_edition(card.ability.extra.edition, true)
        end

        G.GAME.starting_params.ante_scaling = G.GAME.starting_params.ante_scaling * total_mult

        if G.GAME.blind and G.GAME.blind.in_blind then
          G.GAME.blind.chips = G.GAME.blind.chips * total_mult
          G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
          if G.HUD_blind then G.HUD_blind:recalculate() end
        end
        return true
      end
    }))

    G.E_MANAGER:add_event(Event({
      trigger = 'after',
      delay = 0.2,
      func = function()
        G.jokers:unhighlight_all()
        return true
      end
    }))
    delay(0.6)
  end,

  abn_artist_credits = {
    artist = "Boko"
  },
}

-- Tarots

SMODS.Atlas({
  key = "ReturniaTarots",
  path = "consumables/tarots.png",
  px = 71,
  py = 95,
})


SMODS.Consumable {
  key = "polarity",
  set = "Tarot",
  atlas = "ReturniaTarots",
  pos = { x = 0, y = 0 },
  cost = 4,

  abn_artist_credits = {
    artist = "Da Gorbage Rat"
  },

  loc_txt = {
    name = "Polarity",
    text = {
      "Select an {C:attention}original{} Joker and {C:attention}transform{} it",
	  "Next {C:attention}Boss Blind{} create an {C:attention}Inverse{} {C:crepuscular}Crepuscular Tarot{} card",
	  "{C:inactive}(Must have room)",
	 
    }
  },
  
  loc_vars = function(self, info_queue, card)
	info_queue[#info_queue + 1] = G.P_CENTERS.c_returnia_inverse
  end,

  can_use = function(self, card)
    if #G.jokers.highlighted ~= 1 then return false end
    local selected_joker = G.jokers.highlighted[1]
    local sides = selected_joker.config.center.polarity_sides
    return sides ~= nil and selected_joker.ability.extra.side == sides[1]
  end,

  use = function(self, card, area, copier)
    local selected_joker = G.jokers.highlighted[1]
    G.E_MANAGER:add_event(Event({
      trigger = "after",
      delay = 0.4,
      func = function()
        play_sound("tarot1")
        card:juice_up(0.3, 0.5)
        selected_joker.config.center:set_side(selected_joker, selected_joker.config.center.polarity_sides[2])
        selected_joker:juice_up(0.8, 0.5)
        G.jokers:unhighlight_all()
        return true
      end
    }))
	
	local _card = create_card('Tarot', G.consumeables, nil, nil, nil, nil, 'c_returnia_polarity')
    _card:add_to_deck()
    G.vouchers:emplace(_card)
  end,
  
  calculate = function(self, card, context)
	if card.area ~= G.vouchers then return end
	
	if context.setting_blind and G.GAME.blind.boss and #G.consumeables.cards < G.consumeables.config.card_limit then
		local _card = create_card('Tarot', G.consumeables, nil, nil, nil, nil, 'c_returnia_inverse')
		_card:add_to_deck()
		G.consumeables:emplace(_card)
		card:start_dissolve()
	end
	
  end,
}

SMODS.Consumable {
  key = "inverse",
  set = "crepuscular",
  atlas = "ReturniaTarots",
  pos = { x = 0, y = 0 },
  cost = 4,

  abn_artist_credits = {
    artist = "Da Gorbage Rat"
  },

  loc_txt = {
    name = "Inverse",
    text = {
      "Select a {C:attention}transformed{} Joker",
      "and turn it back into its {C:attention}original{}",
    }
  },

  can_use = function(self, card)
    if #G.jokers.highlighted ~= 1 then return false end
    local selected_joker = G.jokers.highlighted[1]
    local sides = selected_joker.config.center.polarity_sides
    return sides ~= nil and selected_joker.ability.extra.side == sides[2]
  end,

  use = function(self, card, area, copier)
    local selected_joker = G.jokers.highlighted[1]
    G.E_MANAGER:add_event(Event({
      trigger = "after",
      delay = 0.4,
      func = function()
        play_sound("tarot1")
        card:juice_up(0.3, 0.5)
        selected_joker.config.center:set_side(selected_joker, selected_joker.config.center.polarity_sides[1])
        selected_joker:juice_up(0.8, 0.5)
        G.jokers:unhighlight_all()
        return true
      end
    }))
  end,
}

-- Jokers

SMODS.Atlas({
  key = "ReturniaJokerSheet1",
  path = "jokers/joker1.png",
  px = 71,
  py = 95,
})

SMODS.Joker {
  key = "linoprint_joker",
  atlas = "ReturniaJokerSheet1",
  pos = { x = 2, y = 2 },
  rarity = 2,
  cost = 8,
  blueprint_compat = false,
  eternal_compat = true,
  perishable_compat = true,
  config = {
    extra = {
      levels = 1,
      hands = { ["Pair"] = true, ["Two Pair"] = true, ["abn_triple_pair"] = true },
    }
  },
  
  abn_artist_credits = {
	artist = "ImaginaryNeon"
  },
  
  loc_txt = {
    name = "Linoprint Joker",
    text = {
      "{C:attention}Level up{} the {C:attention}Imaginary Level{} of first",
      "played {C:attention}Pair{}, {C:attention}Two Pair{} or {C:attention}Triple Pair{}",
	  "each round",
    }
  },
  
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.levels } }
  end,

  calculate = function(self, card, context)
    if context.before and not context.blueprint
      and G.GAME.current_round.hands_played == 0
      and card.ability.extra.hands[context.scoring_name] then
      local hand = context.scoring_name
      local hand_data = G.GAME.hands[hand]
      if not hand_data then return end

      local old_level = hand_data.returnia_imag_level or 0
      local new_level = math.max(0, old_level + card.ability.extra.levels)
      if new_level == old_level then return end

      local chips_ratio = (1 + RETURNIA.imaginary.chips_per_level * new_level) / (1 + RETURNIA.imaginary.chips_per_level * old_level)
      local mult_ratio = (1 + RETURNIA.imaginary.mult_per_level * new_level) / (1 + RETURNIA.imaginary.mult_per_level * old_level)

      hand_data.returnia_imag_level = new_level
      hand_data.s_chips = hand_data.s_chips * chips_ratio
      hand_data.l_chips = hand_data.l_chips * chips_ratio
      hand_data.s_mult = hand_data.s_mult * mult_ratio
      hand_data.l_mult = hand_data.l_mult * mult_ratio
      hand_data.chips = math.max(hand_data.s_chips + hand_data.l_chips * (hand_data.level - 1), 0)
      hand_data.mult = math.max(hand_data.s_mult + hand_data.l_mult * (hand_data.level - 1), 1)

      update_hand_text(
        { sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 },
        { handname = localize(hand, "poker_hands"), chips = hand_data.chips, mult = hand_data.mult, level = hand_data.level .. "+" .. new_level .. "i" }
      )
      G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.2,
        func = function()
          play_sound("tarot1")
          card:juice_up(0.8, 0.5)
          return true
        end
      }))
      return {
        message = localize("k_level_up_ex"),
        colour = G.C.ATTENTION,
      }
    end
  end,
}

SMODS.Joker {
  key = "seriousness_joker",
  atlas = "ReturniaJokerSheet1",
  pos = { x = 0, y = 2 },
  rarity = 1,
  cost = 4,
  blueprint_compat = true,
  eternal_compat = true,
  perishable_compat = true,
  config = {
    extra = {
      side = "seriousness",
      seriousness_mult = 6,
      level_threshold = 1,
      chips = 6,
      mult = 2,
      seriousness_cost = 4,
      jester_cost = 6,
    }
  },

  polarity_sides = { "seriousness", "jester" },

  abn_artist_credits = {
    artist = "Wikypedia"
  },

  loc_txt = {
    name = "Seriousness Joker",
    text = {
      "Gives {C:mult}+#1#{} Mult if {C:attention}scoring{} cards have",
      "more than {C:attention}#2#{} level of {C:planet}Planet{} {C:attention}Ranks{}",
      "Use {C:tarot}Polarity{} to transform into {C:attention}Jester of Seriousness{}",
    }
  },

  loc_txt_jester = {
    name = "Jester of Seriousness",
    text = {
      "Gives {C:chips}+#1#{} Chips and {C:mult}+#2#{} Mult",
      "per {C:planet}Planet{} {C:attention}Rank{} of each played card",
      "Use {C:crepuscular}Inverse{} to transform into {C:attention}Seriousness Joker{}",
    }
  },

  process_loc_text = function(self)
    SMODS.Joker.process_loc_text(self)
    SMODS.process_loc_text(G.localization.descriptions.Joker, self.key .. "_jester", self.loc_txt_jester)
  end,

  loc_vars = function(self, info_queue, card)
    if card.ability.extra.side == "jester" then
      return { vars = { card.ability.extra.chips, card.ability.extra.mult }, key = self.key .. "_jester" }
    end
    return { vars = { card.ability.extra.seriousness_mult, card.ability.extra.level_threshold } }
  end,

  set_side = function(self, card, side)
    card.ability.extra.side = side
    card.base_cost = side == "jester" and card.ability.extra.jester_cost or card.ability.extra.seriousness_cost
    card:set_cost()
  end,

  calculate = function(self, card, context)
    if context.joker_main and card.ability.extra.side == "seriousness" and G.GAME.abn_rank_upgrades then
      local total_levels = 0
      for _, scoring_card in ipairs(context.scoring_hand) do
        if not SMODS.has_no_rank(scoring_card) then
          local rank_data = G.GAME.abn_rank_upgrades[scoring_card.base.value]
          if rank_data then
            total_levels = total_levels + rank_data.level
          end
        end
      end
      if total_levels > card.ability.extra.level_threshold then
        return { mult = card.ability.extra.seriousness_mult }
      end
    end

    if context.individual and context.cardarea == G.play and card.ability.extra.side == "jester"
      and G.GAME.abn_rank_upgrades
      and not SMODS.has_no_rank(context.other_card) then
      local rank_data = G.GAME.abn_rank_upgrades[context.other_card.base.value]
      if rank_data then
        return {
          chips = card.ability.extra.chips * rank_data.level,
          mult = card.ability.extra.mult * rank_data.level,
        }
      end
    end
  end,
}

SMODS.Joker {
  key = "sadness_joker",
  atlas = "ReturniaJokerSheet1",
  pos = { x = 1, y = 2 },
  rarity = 1,
  cost = 4,
  blueprint_compat = true,
  eternal_compat = true,
  perishable_compat = true,
  config = {
    extra = {
      side = "sadness",
      sadness_mult = 6,
      mult = 10,
      chips = 30,
      sadness_cost = 4,
      jester_cost = 6,
    }
  },

  polarity_sides = { "sadness", "jester" },

  abn_artist_credits = {
    artist = "Wikypedia"
  },

  loc_txt = {
    name = "Sadness Joker",
    text = {
		"{C:mult}+#1#{} Mult if the played hand has an {C:attention}unscored{} card",
        "Use {C:tarot}Polarity{} to transform into {C:attention}Jester of Sadness{}",
    }
  },

  loc_txt_jester = {
    name = "Jester of Sadness",
    text = {
      {
        "{C:mult}+#1#{} Mult if all {C:attention}scoring{} cards are {C:attention}Even{}",
        "and all {C:attention}unscored{} cards are {C:attention}Odd{}",
      },
      {
        "{C:chips}+#2#{} Chips if all {C:attention}scoring{} cards are {C:attention}Odd{}",
        "and all {C:attention}unscored{} cards are {C:attention}Even{}",
      },
      {
        "Use {C:crepuscular}Inverse{} to transform into {C:attention}Sadness Joker{}",
      },
    }
  },

  process_loc_text = function(self)
    SMODS.Joker.process_loc_text(self)
    SMODS.process_loc_text(G.localization.descriptions.Joker, self.key .. "_jester", self.loc_txt_jester)
  end,

  loc_vars = function(self, info_queue, card)
    if card.ability.extra.side == "jester" then
      return { vars = { card.ability.extra.mult, card.ability.extra.chips }, key = self.key .. "_jester" }
    end
    return { vars = { card.ability.extra.sadness_mult } }
  end,

  set_side = function(self, card, side)
    card.ability.extra.side = side
    card.base_cost = side == "jester" and card.ability.extra.jester_cost or card.ability.extra.sadness_cost
    card:set_cost()
  end,

  calculate = function(self, card, context)
    if context.joker_main and card.ability.extra.side == "sadness" then
      if #context.full_hand > #context.scoring_hand then
        return { mult = card.ability.extra.sadness_mult }
      end
    end

    if context.joker_main and card.ability.extra.side == "jester" then
      local scoring_all_even = true
      local scoring_all_odd = true
      local unscored_count = 0
      local unscored_all_even = true
      local unscored_all_odd = true

      for _, played_card in ipairs(context.full_hand) do
        local is_scoring = false
        for _, scoring_card in ipairs(context.scoring_hand) do
          if scoring_card == played_card then
            is_scoring = true
            break
          end
        end

        if is_scoring then
          if not ABN.is_even(played_card) then scoring_all_even = false end
          if not ABN.is_odd(played_card) then scoring_all_odd = false end
        else
          unscored_count = unscored_count + 1
          if not ABN.is_even(played_card) then unscored_all_even = false end
          if not ABN.is_odd(played_card) then unscored_all_odd = false end
        end
      end

      if unscored_count == 0 then return end

      if scoring_all_even and unscored_all_odd then
        return { mult = card.ability.extra.mult }
      elseif scoring_all_odd and unscored_all_even then
        return { chips = card.ability.extra.chips }
      end
    end
  end,
}

SMODS.Joker {
  key = "beneficient_joker",
  atlas = "ReturniaJokerSheet1",
  pos = { x = 5, y = 2 },
  rarity = 1,
  cost = 4,
  blueprint_compat = true,
  eternal_compat = true,
  perishable_compat = true,
  config = {
    extra = {
      side = "beneficient",
      dollars = 1,
      mult = 0.5,
      beneficient_cost = 4,
      jester_cost = 6,
    }
  },

  polarity_sides = { "beneficient", "jester" },

  abn_artist_credits = {
    artist = "Heart of Crow"
  },

  loc_txt = {
    name = "Beneficient Joker",
    text = {
      "{C:attention}Played{} and {C:attention}Unscoring{} cards give {C:money}$#1#{}",
      "Use {C:tarot}Polarity{} to transform into {C:attention}Jester of Benefits{}",
    }
  },

  loc_txt_jester = {
    name = "Jester of Benefits",
    text = {
      "{C:attention}Played{} and {C:attention}Unscoring{} cards give {C:mult}+#1#{} Mult",
      "Use {C:crepuscular}Inverse{} to transform into {C:attention}Beneficient Joker{}",
    }
  },

  process_loc_text = function(self)
    SMODS.Joker.process_loc_text(self)
    SMODS.process_loc_text(G.localization.descriptions.Joker, self.key .. "_jester", self.loc_txt_jester)
  end,

  loc_vars = function(self, info_queue, card)
    if card.ability.extra.side == "jester" then
      return { vars = { card.ability.extra.mult }, key = self.key .. "_jester" }
    end
    return { vars = { card.ability.extra.dollars } }
  end,

  set_side = function(self, card, side)
    card.ability.extra.side = side
    card.base_cost = side == "jester" and card.ability.extra.jester_cost or card.ability.extra.beneficient_cost
    card:set_cost()
  end,

  calculate = function(self, card, context)
    if context.individual and (context.cardarea == "unscored" or context.cardarea == G.play) then
      if card.ability.extra.side == "beneficient" then
        return { dollars = card.ability.extra.dollars }
      else
        return { mult = card.ability.extra.mult }
      end
    end
  end,
}

-- Editions 
SMODS.Shader({key = 'distorted', path = 'distorted.fs'})

SMODS.Edition {
    key = 'distorted',
    shader = 'distorted',
    in_shop = true,
    weight = 1,
    extra_cost = 2,
    config = {
        extra = {
            odds = 6,
        }
    },

    loc_txt = {
        name = "Distorted",
		label = 'Distorted',
        text = {
            "Scoring cards give the base {C:mult}Mult{} of played hand",
            "{C:green}#1# in #2#{} chance to {C:attention}level up{} their {C:planet}Planet{} {C:attention}ranks{}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                G.GAME.probabilities.normal,
                card.edition.extra.odds
            }
        }
    end,

    calculate = function(self, card, context)
    if context.individual and context.cardarea == G.play then
        local scoring_card = context.other_card

        local ret = {
            mult = G.GAME.hands[context.scoring_name].mult,
        }

        if scoring_card and not SMODS.has_no_rank(scoring_card) then
            local rank = scoring_card.base.value

            if rank and G.GAME.abn_rank_upgrades[rank] then
                local roll = pseudorandom('distorted')
                local odds = G.GAME.probabilities.normal / card.edition.extra.odds

                if roll < odds then
                    ret.extra = {
                        func = function()
                            ABN.level_up_rank(scoring_card, rank, 1, false)

                            SMODS.calculate_effect({
                                message = localize('k_level_up_ex'),
                                colour = G.C.ATTENTION,
                            }, scoring_card)
                        end
                    }
                end
            end
        end

        return ret
    end
end,
}

--apparently you can't name a shader static or balatro yells at you statics is fine tho
SMODS.Shader({key = 'statics', path = 'statics.fs'})

SMODS.Sound({
	key = "static",
	path = "static.ogg",
})

SMODS.Edition {
  key = 'static',
  shader = 'statics',
  in_shop = true,
  weight = 1,
  extra_cost = 2,
  config = {
    extra = {
      odds = 5,
      amp_per_hand = 1,
      xchips_per_discard = 2,
    }
  },

  loc_txt = {
    name = "Static",
    label = "Static",
    text = {
      "{C:green}#1# in #2#{} chance to {C:attention}level up{} a random played {C:attention}hand{}",
      "{C:abn_amperage}+#3#{} Amperage per remaining {C:blue}hand",
      "{X:chips,C:white}X#4#{} Chips per remaining {C:red}discard",
    }
  },

  loc_vars = function(self, info_queue, card)
    local numerator, denominator = SMODS.get_probability_vars(card, 1, card.edition.extra.odds, 'abn_static')
    return {
      vars = {
        numerator,
        denominator,
        card.edition.extra.amp_per_hand,
        card.edition.extra.xchips_per_discard,
      }
    }
  end,

  calculate = function(self, card, context)
    if context.post_joker or (context.main_scoring and context.cardarea == G.play) then
      local ret = {
		sound = 'returnia_static',
        amp = card.edition.extra.amp_per_hand * G.GAME.current_round.hands_left,
      }

      if G.GAME.current_round.discards_left > 0 then
        ret.xchips = card.edition.extra.xchips_per_discard * G.GAME.current_round.discards_left
      end

      if SMODS.pseudorandom_probability(card, 'abn_static', 1, card.edition.extra.odds, 'abn_static') then
        local played_hands = {}
        for hand_key, hand_data in pairs(G.GAME.hands) do
          if hand_data.visible and hand_data.played > 0 then
            played_hands[#played_hands + 1] = hand_key
          end
        end
        table.sort(played_hands)

        if #played_hands > 0 then
          ret.level_up_hand = pseudorandom_element(played_hands, pseudoseed('abn_static_hand'))
          ret.level_up = 1
        end
      end

      return ret
    end
  end,
}

SMODS.Shader({key = 'glitch', path = 'glitch.fs'})

SMODS.Edition {
    key = 'glitch',
    shader = 'glitch',
    in_shop = true,
    weight = 1,
    extra_cost = 2,
    config = {
        extra = {
            mayhem = 1,
        }
    },

    loc_txt = {
        name = "Glitch",
        label = "Glitch",
        text = {
            "Scoring cards give {C:green}+#1#{} Mayhem",
            "and {C:attention}half{} their base {C:chips}Chips{} as",
            "{C:abn_modulate}Modulate{} or {C:abn_amperage}Amperage{}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card.edition.extra.mayhem,
            }
        }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and not context.other_card.debuff then
            local scoring_card = context.other_card or card
            local nominal = (scoring_card and scoring_card.base and scoring_card.base.nominal) or 0
            local bonus_val = math.floor(nominal / 2)

            local ret = {}

            if bonus_val > 0 then
                if pseudorandom('abn_glitch_type') < 0.5 then
                    ret.modulate = bonus_val
                else
                    ret.amp = bonus_val
                end
            end

            ret.func = function()
                ABN.mayhem(card.edition.extra.mayhem, true)
            end

            return ret
        end
    end,
}