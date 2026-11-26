RETURNIA = RETURNIA or {}

RETURNIA.bypass_pernicious_lock = false

function RETURNIA.is_pernicious(card_or_center)
  local center = card_or_center
  if type(center) == 'table' and center.config and center.config.center then
    center = center.config.center
  end
  if type(center) == 'string' then
    center = G.P_CENTERS[center]
  end
  return (center and center.returnia_pernicious) and true or false
end

function RETURNIA.Pernicious(args)
  args.returnia_pernicious = true
  args.weight = args.weight or 0

  local original_set_badges = args.set_badges
  args.set_badges = function(self, card, badges)
    if original_set_badges then
      original_set_badges(self, card, badges)
    end
    badges[#badges + 1] = create_badge("Pernicious", G.C.RED, G.C.WHITE, 1.0)
  end

  return SMODS.Enhancement(args)
end

--------------------------------------------------------------
-- Collection tab
--------------------------------------------------------------

local previous_collection_tabs = SMODS.current_mod.custom_collection_tabs
SMODS.current_mod.custom_collection_tabs = function()
  local tabs = previous_collection_tabs and previous_collection_tabs() or {}
  tabs[#tabs + 1] = UIBox_button({
    button = 'your_collection_returnia_pernicious',
    id = 'your_collection_returnia_pernicious',
    label = { "Pernicious" },
    minw = 5,
    minh = 1
  })
  return tabs
end

local function pernicious_collection_ui()
  local pernicious_pool = {}
  for _, enhancement_center in ipairs(G.P_CENTER_POOLS.Enhanced) do
    if enhancement_center.returnia_pernicious then
      pernicious_pool[#pernicious_pool + 1] = enhancement_center
    end
  end

  return SMODS.card_collection_UIBox(pernicious_pool, { 5, 5 }, {
    snap_back = true,
    hide_single_page = true,
    collapse_single_page = true,
    center = 'c_base',
    h_mod = 1.03,
    back_func = 'your_collection_other_gameobjects',
    modify_card = function(card, center)
      card:set_ability(center)
    end,
  })
end

G.FUNCS.your_collection_returnia_pernicious = function()
  G.SETTINGS.paused = true
  G.FUNCS.overlay_menu {
    definition = pernicious_collection_ui()
  }
end

local create_UIBox_your_collection_enhancements_ref = create_UIBox_your_collection_enhancements
create_UIBox_your_collection_enhancements = function()
  local full_enhancement_pool = G.P_CENTER_POOLS.Enhanced
  local normal_enhancement_pool = {}
  for _, enhancement_center in ipairs(full_enhancement_pool) do
    if not enhancement_center.returnia_pernicious then
      normal_enhancement_pool[#normal_enhancement_pool + 1] = enhancement_center
    end
  end

  G.P_CENTER_POOLS.Enhanced = normal_enhancement_pool
  local ui_definition = create_UIBox_your_collection_enhancements_ref()
  G.P_CENTER_POOLS.Enhanced = full_enhancement_pool

  return ui_definition
end

--------------------------------------------------------------
-- No changing pernicious
--------------------------------------------------------------

local card_set_ability_ref = Card.set_ability
function Card:set_ability(center, initial, delay_sprites)
  if not RETURNIA.bypass_pernicious_lock
      and self.playing_card
      and self.config and self.config.center
      and self.config.center.returnia_pernicious then
    local new_center = center
    if type(new_center) == 'string' then
      new_center = G.P_CENTERS[new_center]
    end

    if new_center and new_center ~= self.config.center
        and (new_center.set == 'Enhanced' or new_center.key == 'c_base') then
      if self.area and not G.SETTINGS.paused then
        card_eval_status_text(self, 'extra', nil, nil, nil, {
          message = localize('k_not_allowed_ex'),
          colour = G.C.RED,
        })
      end
      return
    end
  end

  return card_set_ability_ref(self, center, initial, delay_sprites)
end

SMODS.Atlas({
  key = "ReturniaEnhancements",
  path = "enhancements.png",
  px = 71,
  py = 95,
})


-- Evil Gold
RETURNIA.Pernicious {
  key = 'fugitive',
  original = 'm_gold',
  atlas = 'ReturniaEnhancements',
  pos = { x = 0, y = 5 },
  config = { extra = { dollars = 3, increase = 1 } },
  loc_txt = {
    name = 'Fugitive',
    text = {
      "{C:red}-$#1#{} when played",
      "If {C:attention}discarded{}, this cost increases by {C:red}$#2#{}",
      "and card is {C:attention}shuffled{} back into the deck",
    },
  },
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.dollars, card.ability.extra.increase } }
  end,
  calculate = function(self, card, context)
    if context.main_scoring and context.cardarea == G.play then
      return { dollars = -card.ability.extra.dollars }
    end

    if context.discard and context.other_card == card then
      card.ability.extra.dollars = card.ability.extra.dollars + card.ability.extra.increase

      local discard_ticks = 0
      G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        blocking = false,
        blockable = false,
        func = function()
          discard_ticks = discard_ticks + 1
          if card.area == G.discard then
            draw_card(G.discard, G.deck, nil, 'down', nil, card)
            local deck_ticks = 0
            G.E_MANAGER:add_event(Event({
              trigger = 'immediate',
              blocking = false,
              blockable = false,
              func = function()
                deck_ticks = deck_ticks + 1
                if card.area == G.deck then
                  G.deck:shuffle('returnia_fugitive')
                  return true
                end
                return deck_ticks > 600
              end
            }))
            return true
          end
          return discard_ticks > 600
        end
      }))

      return { message = "-$" .. card.ability.extra.dollars }
    end
  end,
}

-- Evil Lucky
RETURNIA.Pernicious {
  key = 'gambler',
  original = 'm_lucky',
  atlas = 'ReturniaEnhancements',
  pos = { x = 2, y = 3 },
  config = { extra = { mult_loss = 10, mult_odds = 3, dollars_odds = 5, retrigger_odds = 15 } },
  loc_txt = {
    name = 'Gambler',
    text = {
      "{C:green}#1# in #2#{} chance for {C:red}-#3#{} Mult",
      "{C:green}#4# in #5#{} chance to lose {C:attention}half{} your {C:money}${}",
      "{C:green}#6# in #7#{} chance to retrigger",
    },
  },
  loc_vars = function(self, info_queue, card)
    local mult_numerator, mult_denominator = SMODS.get_probability_vars(
      card, 1, card.ability.extra.mult_odds, 'returnia_gambler_mult')
    local dollars_numerator, dollars_denominator = SMODS.get_probability_vars(
      card, 1, card.ability.extra.dollars_odds, 'returnia_gambler_dollars')
    local retrigger_numerator, retrigger_denominator = SMODS.get_probability_vars(
      card, 1, card.ability.extra.retrigger_odds, 'returnia_gambler_retrigger')
    return {
      vars = {
        mult_numerator, mult_denominator, card.ability.extra.mult_loss,
        dollars_numerator, dollars_denominator,
        retrigger_numerator, retrigger_denominator,
      }
    }
  end,
  calculate = function(self, card, context)
    if context.main_scoring and context.cardarea == G.play then
      local effects = {}
      if SMODS.pseudorandom_probability(card, 'returnia_gambler_mult', 1,
          card.ability.extra.mult_odds, 'returnia_gambler_mult') then
        effects.mult = -card.ability.extra.mult_loss
      end
      if SMODS.pseudorandom_probability(card, 'returnia_gambler_dollars', 1,
          card.ability.extra.dollars_odds, 'returnia_gambler_dollars') and G.GAME.dollars > 0 then
        local dollars_lost = G.GAME.dollars / 2
        if type(dollars_lost) == 'number' then
          dollars_lost = math.floor(dollars_lost)
        end
        effects.dollars = -dollars_lost
      end
      if next(effects) then
        return effects
      end
    end

    if context.repetition and context.cardarea == G.play and context.other_card == card then
      if SMODS.pseudorandom_probability(card, 'returnia_gambler_retrigger', 1,
          card.ability.extra.retrigger_odds, 'returnia_gambler_retrigger') then
        return { repetitions = 1 }
      end
    end
  end,
}

-- Riveted: can't be selected (so it can't be played or discarded either)
local card_area_add_to_highlighted_ref = CardArea.add_to_highlighted
function CardArea:add_to_highlighted(card, silent)
  if self == G.hand and card and card.config and card.config.center
      and card.config.center.returnia_unselectable
      and not (card.ability and card.ability.forced_selection) then
    if not silent then
      card_eval_status_text(card, 'extra', nil, nil, nil, {
        message = "Not Allowed!",
        colour = G.C.RED,
      })
    end
    return
  end
  return card_area_add_to_highlighted_ref(self, card, silent)
end

-- Evil Steel
RETURNIA.Pernicious {
  key = 'riveted',
  original = 'm_steel',
  returnia_unselectable = true,
  atlas = 'ReturniaEnhancements',
  pos = { x = 3, y = 2 },
  config = {},
  loc_txt = {
    name = 'Riveted',
    text = {
      "Cannot be {C:attention}discarded{}",
      "or {C:attention}selected{}",
    },
  },
}


-- Evil Stone
RETURNIA.Pernicious {
  key = 'sediment',
  original = 'm_stone',
  returnia_to_deck_top = true,
  no_rank = true,
  no_suit = true,
  replace_base_card = true,
  atlas = 'ReturniaEnhancements',
  pos = { x = 0, y = 3 },
  config = {},
  loc_txt = {
    name = 'Sediment',
    text = {
      "{C:attention}Never scores{}",
      "After being played",
      "return to the {C:attention}top of the deck{}",
    },
  },
  calculate = function(self, card, context)
    if context.modify_scoring_hand and context.other_card == card then
      -- only for a real play (the card is in the played area), and only once per play
      if card.area == G.play and not card.ability.returnia_sediment_pending then
        card.ability.returnia_sediment_pending = true

        -- wait for the vanilla code to put it in the discard pile, then move it to the deck
        local discard_ticks = 0
        G.E_MANAGER:add_event(Event({
          trigger = 'immediate',
          blocking = false,
          blockable = false,
          func = function()
            discard_ticks = discard_ticks + 1
            if card.area == G.discard then
              card.ability.returnia_sediment_pending = nil
              draw_card(G.discard, G.deck, nil, 'down', false, card)

              -- emplacing into the deck puts a card at the bottom, so move it to the top
              local deck_ticks = 0
              G.E_MANAGER:add_event(Event({
                trigger = 'immediate',
                blocking = false,
                blockable = false,
                func = function()
                  deck_ticks = deck_ticks + 1
                  if card.area == G.deck then
                    for index, deck_card in ipairs(G.deck.cards) do
                      if deck_card == card then
                        table.remove(G.deck.cards, index)
                        break
                      end
                    end
                    table.insert(G.deck.cards, card)
                    G.deck:set_ranks()
                    return true
                  end
                  return deck_ticks > 600
                end
              }))
              return true
            end
            if discard_ticks > 600 then
              card.ability.returnia_sediment_pending = nil
              return true
            end
            return false
          end
        }))
      end

      return { remove_from_hand = true }
    end
  end,
}

-- Evil Wild
RETURNIA.Pernicious {
  key = 'ivy',
  original = 'm_wild',
  atlas = 'ReturniaEnhancements',
  pos = { x = 5, y = 2 },
  config = {},
  loc_txt = {
    name = 'Ivy',
    text = {
      "Forced to be {C:attention}selected{} when drawn",
      "When scored {C:attention}randomize{} the {C:attention}rank{} and {C:attention}suit",
      "of all {C:attention}held{} cards",
    },
  },
  calculate = function(self, card, context)
    if card.area == G.hand and not card.ability.returnia_ivy_watching then
      card.ability.returnia_ivy_watching = true
      G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        blocking = false,
        blockable = false,
        func = function()
          if card.area ~= G.hand then
            card.ability.returnia_ivy_watching = nil
            card.ability.returnia_ivy_discarding = nil
            return true
          end
          if not card.highlighted
              and not card.ability.returnia_ivy_discarding
              and G.STATE == G.STATES.SELECTING_HAND
              and #G.hand.highlighted < G.hand.config.highlighted_limit then
            G.hand:add_to_highlighted(card, true)
          end
          return false
        end
      }))
    end

    if context.discard and context.other_card == card then
      card.ability.returnia_ivy_discarding = true
    end

    if context.main_scoring and context.cardarea == G.play then
      return {
        func = function()
          local suit_keys = {}
          for suit_key, _ in pairs(SMODS.Suits) do
            suit_keys[#suit_keys + 1] = suit_key
          end
          table.sort(suit_keys)
          local rank_keys = {}
          for rank_key, _ in pairs(SMODS.Ranks) do
            rank_keys[#rank_keys + 1] = rank_key
          end
          table.sort(rank_keys)

          local targets = {}
          for _, held_card in ipairs(G.hand.cards) do
            if not (SMODS.has_no_rank(held_card) or SMODS.has_no_suit(held_card)) then
              targets[#targets + 1] = held_card
            end
          end

          for _, held_card in ipairs(targets) do
            G.E_MANAGER:add_event(Event({
              trigger = 'after',
              delay = 0.1,
              func = function()
                held_card:flip()
                play_sound('card1', 0.9 + math.random() * 0.2, 0.6)
                held_card:juice_up(0.3, 0.3)
                return true
              end
            }))
          end
          delay(0.2)
          for _, held_card in ipairs(targets) do
            G.E_MANAGER:add_event(Event({
              trigger = 'after',
              delay = 0.1,
              func = function()
                local new_suit = pseudorandom_element(suit_keys, pseudoseed('returnia_ivy_suit'))
                local new_rank = pseudorandom_element(rank_keys, pseudoseed('returnia_ivy_rank'))
                SMODS.change_base(held_card, new_suit, new_rank)
                return true
              end
            }))
          end
          for _, held_card in ipairs(targets) do
            G.E_MANAGER:add_event(Event({
              trigger = 'after',
              delay = 0.1,
              func = function()
                held_card:flip()
                play_sound('tarot2', 0.9 + math.random() * 0.2, 0.6)
                held_card:juice_up(0.3, 0.3)
                return true
              end
            }))
          end
        end
      }
    end
  end,
}

-- Evil Glass
RETURNIA.Pernicious {
  key = 'fluid',
  original = 'm_glass',
  atlas = 'ReturniaEnhancements',
  pos = { x = 1, y = 3 },
  config = { extra = { copy_odds = 2, blind_increase = 25 } },
  loc_txt = {
    name = 'Fluid',
    text = {
      "{C:green}#1# in #2#{} chance to",
      "create a {C:attention}copy{} in hand when scored",
      "raise {C:attention}blind requirement{} by {C:red}+#3#%{} when scored",
    },
  },
  loc_vars = function(self, info_queue, card)
    local numerator, denominator = SMODS.get_probability_vars(
      card, 1, card.ability.extra.copy_odds, 'returnia_fluid_copy')
    return { vars = { numerator, denominator, card.ability.extra.blind_increase } }
  end,
  calculate = function(self, card, context)
    if context.main_scoring and context.cardarea == G.play then
      local create_copy = SMODS.pseudorandom_probability(card, 'returnia_fluid_copy', 1,
        card.ability.extra.copy_odds, 'returnia_fluid_copy')
      return {
        func = function()
          if create_copy then
            G.E_MANAGER:add_event(Event({
              func = function()
                local copied_card = copy_card(card, nil, nil, G.playing_card)
                copied_card:add_to_deck()
                G.deck.config.card_limit = G.deck.config.card_limit + 1
                table.insert(G.playing_cards, copied_card)
                G.hand:emplace(copied_card)
                copied_card.states.visible = nil
                G.E_MANAGER:add_event(Event({
                  func = function()
                    copied_card:start_materialize()
                    return true
                  end
                }))
                SMODS.calculate_context({ playing_card_added = true, cards = { copied_card } })
                return true
              end
            }))
            SMODS.calculate_effect({
              message = localize('k_copied_ex'),
              colour = G.C.ATTENTION,
            }, card)
          end

          if G.GAME and G.GAME.blind and G.GAME.blind.chips then
            local new_requirement = G.GAME.blind.chips * (1 + card.ability.extra.blind_increase / 100)
            if type(new_requirement) == 'number' then
              new_requirement = math.floor(new_requirement)
            end
            G.GAME.blind.chips = new_requirement
            G.GAME.blind.chip_text = number_format(new_requirement)
            SMODS.calculate_effect({
              message = "+" .. card.ability.extra.blind_increase .. "%",
              colour = G.C.RED,
            }, card)
          end
        end
      }
    end
  end,
}

-- Evil Bonus
RETURNIA.Pernicious {
  key = 'inflation',
  original = 'm_bonus',
  atlas = 'ReturniaEnhancements',
  pos = { x = 2, y = 2 },
  config = { extra = { percent = 2 } },
  loc_txt = {
    name = 'Inflation',
    text = {
      "Lowers scoring {C:chips}Chips{} by {C:red}#1#%{}",
      "for each {C:attention}played{} card",
    },
  },
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.percent } }
  end,
  calculate = function(self, card, context)
    if context.main_scoring and context.cardarea == G.play then
      local chips_lost = hand_chips + card.base.nominal * (card.ability.extra.percent / 100) * #context.full_hand
      if type(chips_lost) == 'number' then
        chips_lost = math.floor(chips_lost)
      end
      return { chips = -chips_lost }
    end
  end,
}

-- Evil Mult
RETURNIA.Pernicious {
  key = 'division',
  original = 'm_mult',
  atlas = 'ReturniaEnhancements',
  pos = { x = 3, y = 3 },
  config = { extra = { mult_floor = 0.1 } },
  loc_txt = {
    name = 'Division',
    text = {
      "when scored sets the current",
	  "{C:mult}Mult{} to {C:red}#1#{}",
    },
  },
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.mult_floor } }
  end,
  calculate = function(self, card, context)
    if context.main_scoring and context.cardarea == G.play then
      if mult > card.ability.extra.mult_floor then
        return { mult = -(mult - card.ability.extra.mult_floor) }
      end
    end
  end,
}