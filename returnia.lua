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