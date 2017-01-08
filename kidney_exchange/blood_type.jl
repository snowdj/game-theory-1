"""
```
BloodType
```

Enum type with values `A`, `B`, `AB`, and `O`.
"""
@enum BloodType A=1 B=2 AB=3 O=4

"""
```
BloodTypeDist(μ_A::Float64, μ_B::Float64, μ_AB::Float64, μ_O::Float64)
```
"""
type BloodTypeDist <: DiscreteUnivariateDistribution
    μ_A::Float64
    μ_B::Float64
    μ_AB::Float64
    μ_O::Float64

    function BloodTypeDist(μ_A::Float64, μ_B::Float64, μ_AB::Float64, μ_O::Float64)
        @assert 0 <= μ_A <= 1
        @assert 0 <= μ_B <= 1
        @assert 0 <= μ_AB <= 1
        @assert 0 <= μ_O <= 1
        @assert μ_A + μ_B + μ_AB + μ_O == 1
        return new(μ_A, μ_B, μ_AB, μ_O)
    end
end

"""
```
pdf(dist::BloodTypeDist, val::BloodType)
```
"""
function Distributions.pdf(dist::BloodTypeDist, val::BloodType)
    if val == A
        return dist.μ_A
    elseif val == B
        return dist.μ_B
    elseif val == AB
        return dist.μ_AB
    elseif val == O
        return dist.μ_O
    end
end

"""
```
rand(dist::BloodTypeDist)
```
"""
function Distributions.rand(dist::BloodTypeDist)
    x = rand()
    if 0 <= x < dist.μ_A
        return A
    elseif dist.μ_A <= x <= (dist.μ_A + dist.μ_B)
        return B
    elseif (dist.μ_A + dist.μ_B) <= x <= (dist.μ_A + dist.μ_B + dist.μ_AB)
        return AB
    else
        return O
    end
end

"""
```
PRADist(γ_high::Float64, γ_low::Float64, p_low::Float64)
```
"""
type PRADist <: DiscreteUnivariateDistribution
    γ_high::Float64
    γ_low::Float64
    p_low::Float64

    function PRADist(γ_high::Float64, γ_low::Float64, p_low::Float64)
        @assert 0 <= γ_high <= 1
        @assert 0 <= γ_low <= 1
        @assert 0 <= p_low <= 1
        return new(γ_high, γ_low, p_low)
    end
end

"""
```
rand(dist::PRADist)
```
"""
function Distributions.rand(dist::PRADist)
    x = rand()
    if x < dist.p_low
        return dist.γ_low
    else
        return dist.γ_high
    end
end
