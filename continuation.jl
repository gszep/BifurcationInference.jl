using PseudoArcLengthContinuation, Flux
using PseudoArcLengthContinuation: ContResult, DefaultLS, DefaultEig
const Cont = PseudoArcLengthContinuation

unpack(curve::ContResult) = Tracker.collect(curve.branch[1,:]),Tracker.collect(curve.branch[2,:])

function continuation( f, J, u₀, p₀::T ; kwargs...) where T

	options = Cont.NewtonPar{T,typeof(DefaultLS()), typeof(DefaultEig())}(verbose=false,maxIter=kwargs[:maxIter])
	u₀, _, stable = Cont.newton( u -> f(u,p₀), u -> J(u,p₀), convert(Array{T},u₀), options )
	branch, _, _ = Cont.continuation( f,J, u₀,p₀,

		ContinuationPar{T,typeof(DefaultLS()), typeof(DefaultEig())}(
			pMin=kwargs[:pMin],pMax=kwargs[:pMax],ds=kwargs[:ds],
			maxSteps=kwargs[:maxSteps])
	)
	return Tracker.data.(u₀), unpack(branch)...
end
