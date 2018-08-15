module TestArrayOfComponents

println("\nTestArrayOfComponents: Demonstrating the handling of arrays of components")

using Modia
using Modia.Electric
using ModiaMath: plot
using Test

@model LPfilter begin
    R = Resistor(R=100.0)
    C = Capacitor(C=2.5E-3, v=Float(start=0.0))
    V = ConstantVoltage(V=10.0)
    ground = Ground()
    @equations begin
        connect(V.n, ground.p)
        connect(V.p, R.p)
        connect(R.n, C.p)
        connect(C.n, V.n)
    end
end 

# Array of components
@model TwoFilters begin
    F = [LPfilter(); LPfilter(C=Capacitor(C=10 * 2.5E-3))]
end
checkSimulation(TwoFilters, 1, "F[2].C.v", 3.2967995487381305)


nFilters = 10
# Array comprehensions of components
@model ManyFilters begin
    F = [LPfilter() for i in 1:nFilters]
end
checkSimulation(ManyFilters, 1, "F[1].C.v", 9.816405569531037)

nFilters = 10
# Array comprehensions of components
@model ManyDifferentFilters begin
    F = [LPfilter(C=Capacitor(C=i * 2.5E-3)) for i in 1:nFilters]
end
result = simulate(ManyDifferentFilters, 1)
plot(result, Tuple(["F[$i].C.v" for i in 1:nFilters]), heading="ManyDifferentFilters", figure=5)
@test result["F[1].C.v"][end] == 9.816405569531037
@test result["F[$nFilters].C.v"][end] == 3.2967995487381305

# -----------------------------------

# Connecting arrays of components
@model AdvancedLPfilter begin
    M = [Resistor(R=1); Capacitor(C=1E-3)]
    V = ConstantVoltage(V=1)
    ground = Ground()
    @equations begin
        connect(V.n, ground.p)
        # connect(V.p, M[1].p)
        # connect(M[1].n, M[2].p)
        # connect(M[2].n, V.n)
    end
end 

#=
# Alternative connect constructs:
for i in 1:size(M)
  connect(M[i].p, M[i+1].n)
end
connect(M[1:end-1].p, M[2:end].n)]
[connect(M[i].p, M[i+1].n) for i in 1:size(M)]
connect(M[i].p, M[i+1].n) for i in 1:size(M)
=#

# -----------------------------------

# Experimental:
using Modia: @equation
addEquation!(M, e) = begin @show e; push!(M.initializers, Modia.Instantiation.Equations([e])) end

@model LPfilterComponent begin
    R = Resistor(R=100.0)
    C = Capacitor(C=2.5E-3, v=Float(start=0.0))
    ground = Ground()
    in = Pin()
    out = Pin()
    @equations begin
        connect(in, R.p)
        connect(R.n, C.p)
        connect(C.n, ground.p)
        connect(C.p, out)
    end
end 

@model ManyConnectedDifferentFilters begin
    V = ConstantVoltage(V=10.0)
    ground = Ground()
    F = [LPfilterComponent(C=Capacitor(C=i * 2.5E-3)) for i in 1:nFilters]
    @equations begin
        connect(V.n, ground.p)
#  connect(V.p, F[1].in)
    end
end

#=
Not working yet
for i in 1:nFilters-1
  addEquation!(ManyConnectedDifferentFilters, @equation(connect(this.F[$i].out, this.F[$(i+1)].in)))
end

simulate(ManyConnectedDifferentFilters, 1)
=#

end
