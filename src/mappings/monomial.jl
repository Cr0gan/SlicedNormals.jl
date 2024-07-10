# Monomial mapping
mutable struct MonomialMapping <: AbstractMapping
    d::Integer
end

function (Z::MonomialMapping)(δ::AbstractVector)
    x = @polyvar x[1:length(δ)]
    z = mapreduce(p -> monomials(x..., p), vcat, 1:Z.d)

    return map(p -> p(δ), z)
end