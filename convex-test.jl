# Make the Convex.jl module available
using Convex, SCS

using Distributions
using Plots
using SlicedNormals
using MinimumVolumeEllipsoids
using LinearAlgebra
using IntervalArithmetic

using QuasiMonteCarlo

n = 500

# Step 1
θ = rand(Normal(π / 2, 1.3), n)
r = 3 .+ rand(Uniform(0, 0.2), n) .* (θ .- π / 2)

δ1 = r .* cos.(θ)
δ2 = r .* sin.(θ)

idx = δ1 .< 0
δ2[idx] = δ2[idx] * -1

δ = [δ1 δ2]

# Step 2
θ = rand(Normal(π / 2, 1.3), n)
r = 3 .+ rand(Uniform(0, 0.2), n) .* (θ .- π / 2)

δ1 = r .* cos.(θ)
δ2 = r .* sin.(θ)

idx = δ1 .< 0
δ2[idx] = δ2[idx] * -1

δ = vcat(δ, [δ1 δ2] .* -1)

# Fit Sliced Normal Distribution
d = 3 # degree
b = 10000 # number of points to use  for estimation of the normalisation constant

lb = vec(minimum(δ; dims=1))
ub = vec(maximum(δ; dims=1))

s = QuasiMonteCarlo.sample(b, lb, ub, SobolSample())

zδ = mapreduce(r -> transpose(SlicedNormals.Z(r, 2d)), vcat, eachrow(δ))
zΔ = mapreduce(r -> transpose(SlicedNormals.Z(r, 2d)), vcat, eachcol(s))

μ, P = SlicedNormals.mean_and_covariance(zδ)

M = cholesky(P).U

zsosδ = Matrix(transpose(mapreduce(z -> SlicedNormals.Zsos(z, μ, M), hcat, eachrow(zδ))))
zsosΔ = Matrix(transpose(mapreduce(z -> SlicedNormals.Zsos(z, μ, M), hcat, eachrow(zΔ))))

n = size(δ, 1)

vol_m = log(prod(ub - lb) / b)

nz = size(zδ, 2)

@show nz

l = Variable(nz)

con = l >= 0
problem = minimize(
    n * (vol_m + logsumexp((zsosΔ * l) / -2)) +
    sum([sum(x .* l) for x in eachrow(zsosδ)]) / 2,
    con,
)

solve!(problem, SCS.Optimizer)

@show problem.status

@show problem.optval

@show Convex.evaluate(l)

Δ = IntervalBox(interval.(lb, ub)...)

cΔ = prod(ub - lb) / b + sum(exp.(zsosΔ * Convex.evaluate(l) / -2))

sn = SlicedNormal(d, Convex.evaluate(l), μ, M, Δ, cΔ)

samples = rand(sn, 1000)

p = scatter(
    δ[:, 1], δ[:, 2]; aspect_ratio=:equal, lims=[-4, 4], xlab="δ1", ylab="δ2", label="data"
)
scatter!(p, samples[:, 1], samples[:, 2]; label="samples")

display(p)

# Plot density
xs = range(-4, 4; length=200)
ys = range(-4, 4; length=200)

contour!(xs, ys, (x, y) -> SlicedNormals.pdf(sn, [x, y]))

# sn_jump, _ = SlicedNormal(δ, d, b)

# samples_jump = rand(sn_jump, 1000)

# p = scatter(
#     δ[:, 1], δ[:, 2]; aspect_ratio=:equal, lims=[-4, 4], xlab="δ1", ylab="δ2", label="data"
# )
# scatter!(p, samples_jump[:, 1], samples_jump[:, 2]; label="samples")

# display(p)

# # Plot density
# xs = range(-4, 4; length=200)
# ys = range(-4, 4; length=200)

# contour!(xs, ys, (x, y) -> SlicedNormals.pdf(sn_jump, [x, y]))
