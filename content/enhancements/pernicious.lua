SMODS.Atlas({
  key = "ReturniaEnhancements",
  path = "enhancements.png",
  px = 71,
  py = 95,
})

SMODS.Enhancements {
	atlas = 'tieredEnhancements',
    key = 'gambler',
    pos = { x = 2, y = 3 },
    config = { extra = { mult = -10, xdollars = 0.5, retrigger = 1, mult_odds = 3, dollars_odds = 5, retrigger_odds = 15 } },
    loc_vars = function(self, info_queue, card)
        local mult_numerator, mult_denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.mult_odds,
            'returnia_gambler_mult')
		local dollarss_numerator, dollarss_denominator = SMODS.get_probability_vars(card, 1, card.ability.extra.dollars_odds,
            'returnia_gambler_dollars')
        local retrigger_numerator, retrigger_denominator = SMODS.get_probability_vars(card, 1,
            card.ability.extra.retrigger_odds, 'returnia_gambler_retrigger')
        return { vars = { mult_numerator, mult_denominator, card.ability.extra.mult,  dollars_numerator, dollars_denominator, card.ability.extra.xdollars, retrigger_numerator, retrigger_denominator, card.ability.extra.retrigger} }
    end,
    calculate = function(self, card, context)
        if context.main_scoring and context.cardarea == G.play then
            local ret = {}
            if SMODS.pseudorandom_probability(card, 'returnia_gambler_mult', 1, card.ability.extra.mult_odds) then
                card.gambler_trigger = true
                ret.mult = card.ability.extra.mult
            end
            if SMODS.pseudorandom_probability(card, 'returnia_gambler_dollars', 1, card.ability.extra.dollars_odds) then
                card.gambler_trigger = true
                ret.dollars = card.ability.extra.dollars
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.2,
                    func = function()
                        dollar = G.GAME.dollars * ( card.ability.extras.xdollars)
                        ease_dollars(dollar)
                        return true
                    end
                }))
            end
            return ret
        end
        if context.repetition and context.cardarea == G.play then
            if SMODS.pseudorandom_probability(card, 'returnia_gambler_retrigger', 1, card.ability.extra.retrigger_odds) then
                card.gambler_trigger = true
                return {
                    message = localize('k_again_ex'),
                    repetitions = card.ability.extra.retrigger,
                    card = card
                }
            end
        end
    end,
    m_original = "m_lucky",
}