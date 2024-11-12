using DelimitedFiles
using DelimitedFiles
using Plots
using SlicedDistributions

δ = readdlm("demo/data/circle.csv", ',')
using SlicedDistributions

δ = readdlm("demo/data/circle.csv", ',')

# Fit Sliced Normal Distribution
d = 3
d = 3
b = 10000

Z = MonomialMapping(d)
@time sn, lh = SlicedNormal(δ, Z, b)

println("Likelihood: $lh")

samples = rand(sn, 1000)

p = scatter(
    δ[:, 1], δ[:, 2]; aspect_ratio=:equal, lims=[-4, 4], xlab="δ1", ylab="δ2", label="data"
)
scatter!(p, samples[:, 1], samples[:, 2]; label="samples")

display(p)

# Plot density
xs = range(-4, 4; length=200)
ys = range(-4, 4; length=200)

contour!(xs, ys, (x, y) -> pdf(sn, [x, y]))
contour!(xs, ys, (x, y) -> pdf(sn, [x, y]))
