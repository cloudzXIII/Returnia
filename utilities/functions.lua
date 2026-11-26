if not ABN then
    ABN = {}
end

if not ABN.is_even then
    ABN.is_even = function(card)
        local even_ranks = { "abn_12", "abn_14" }
        if card:get_id() <= 10 and card:get_id() >= 0 and card:get_id() % 2 == 0 then
            return true
        end
        for _, rank in ipairs(even_ranks) do
            if card:get_id() == SMODS.Ranks[rank].id then
                return true
            end
        end
        return false
    end
end
if not ABN.is_odd then
    ABN.is_odd = function(card)
        local odd_ranks = { "abn_11", "abn_13" }
        if (card:get_id() <= 10 and card:get_id() >= 0 and card:get_id() % 2 == 1) or (card:get_id() == 14) then
            return true
        end
        for _, rank in ipairs(odd_ranks) do
            if card:get_id() == SMODS.Ranks[rank].id then
                return true
            end
        end
        return false
    end
end

function RETURNIA.build_pernicious_table()
    RETURNIA.PerniciousEnh= {}
    for i, v in pairs(G.P_CENTERS) do
        if v.m_original then
            RETURNIA.PerniciousEnh[v.m_original] = v.key
        end
    end
end
function RETURNIA.pernicious_switch(card)
    if (RETURNIA.PerniciousEnh[card.config.center.key]) then
        card:set_ability(RETURNIA.PerniciousEnh[card.config.center.key])
    end
end

local loadmodsref = SMODS.injectItems
function SMODS.injectItems(...)
    local ret = loadmodsref(...)
    RETURNIA.build_pernicious_table()
    return ret
end