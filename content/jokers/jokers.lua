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