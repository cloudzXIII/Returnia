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