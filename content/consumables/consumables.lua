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