############################################################################ hyperparameter updates
function getParameters(data::StateSpace{N,T}; max_iterations::Int=800, tol=1e-12, kwargs...) where {N,T<:Number}
    newton_options = NewtonPar(verbose=false, max_iterations=max_iterations, tol=T(tol))

    # support for StaticArrays github.com/JuliaArrays/StaticArrays.jl/issues/73
    newton_options = @set newton_options.linsolver.useFactorization = false
    return ContinuationPar(p_min=minimum(data.parameter), p_max=maximum(data.parameter), max_steps=10 * length(data.parameter),
        ds=step(data.parameter), dsmax=step(data.parameter), dsmin=step(data.parameter), newton_options=newton_options, detect_fold=false, detect_bifurcation=true,
        save_eigenvectors=false, nev=N)
end

function updateParameters!(parameters::ContinuationPar{T,S,E}, steady_states::Vector{Branch{V,T}};
    resolution=400) where {T<:Number,V<:AbstractVector{T},S<:AbstractLinearSolver,E<:AbstractEigenSolver}

    # estimate scale from steady state curves
    branch_points = map(length, steady_states)
    ds = maximum(branch_points) * parameters.ds / resolution
    parameters = setproperties(parameters; ds=ds, dsmin=ds, dsmax=ds)
end

function mean(f::Function, x::AbstractArray{T}; type::Symbol=:geometric, kwargs...) where {T}
    return type == :geometric ? mapreduce(y -> f(y)^(1 / length(x)), *, x; init=1, kwargs...) : mapreduce(y -> f(y) / length(x), +, x; init=zero(f(zero(T))), kwargs...)
end

############################################################################# training loop
function train!(F::Function, parameters::NamedTuple, data::StateSpace;
    iter::Int=200, optimiser=Momentum(0.001), plot_solution=false,
    convergence=0.02, kwargs...)

    hyperparameters = getParameters(data; kwargs...)
    Loss = steady_states = nothing

    ∇Loss = similar(parameters.θ)
    trajectory = typeof(parameters.θ)[]

    for i = 1:iter
        try
            steady_states = deflationContinuation(F, data.roots, parameters, hyperparameters; kwargs...)
            Loss, ∇Loss = ∇loss(F, steady_states, parameters.θ, data; kwargs...)

        catch error
            printstyled(color=:red, "Iteration $i\tError = $error\n")
        end
        printstyled(color=:yellow, "Iteration $i\tLoss = $Loss\n")

        printstyled(color=:blue, "$steady_states\n")
        println("Parameters\t$(parameters.θ)")
        println("Gradients\t$(∇Loss)")

        if isinf(Loss)
            throw("infinite loss")
        end
        push!(trajectory, copy(parameters.θ))

        predictions = unique([s.z for branch ∈ steady_states for s ∈ branch if s.bif]; atol=2 * step(data.parameter))
        if (Loss < convergence) & (length(predictions) == length(data.targets))
            break
        end

        if plot_solution > 0
            if i % plot_solution == 0
                plot(steady_states, data)
            end
        end
        update!(optimiser, parameters.θ, ∇Loss)
    end

    return trajectory
end

############################################################################## loss evaluation helper
function loss(F::Function, θ::AbstractVector, data::StateSpace, hyperparameters::ContinuationPar; kwargs...)

    try
        parameters = (θ=θ, p=minimum(data.parameter))
        steady_states = deflationContinuation(F, data.roots, parameters, hyperparameters; kwargs...)
        return loss(F, steady_states, θ, data; kwargs...)

    catch error
        printstyled(color=:red, "$error\n")
        return NaN
    end
end

function loss(F::Function, θ::AbstractVector, data::StateSpace; kwargs...)
    return loss(F, θ, data, getParameters(data); kwargs...)
end

function ∇loss(F::Function, θ::AbstractVector, data::StateSpace, hyperparameters::ContinuationPar; kwargs...)
    try
        parameters = (θ=θ, p=minimum(data.parameter))
        steady_states = deflationContinuation(F, data.roots, parameters, hyperparameters; kwargs...)
        return ∇loss(F, steady_states, θ, data; kwargs...)

    catch error
        printstyled(color=:red, "$error\n")
        return NaN, fill(NaN, length(θ))
    end
end

function ∇loss(F::Function, θ::AbstractVector, data::StateSpace; kwargs...)
    return ∇loss(F, θ, data, getParameters(data); kwargs...)
end