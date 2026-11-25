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