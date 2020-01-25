include("_inference.jl")
using Plots: Animation,frame,gif

######################################################## model
function rates( u,p, θ₁=0.0, θ₂=0.0, θ₃=0.0)
	return [ p + θ₁*u[1] + θ₂*u[1]^3 + θ₃ ]
end

function rates_jacobian( u,p, θ₁=0.0, θ₂=0.0, θ₃=0.0)
	return [ θ₁ .+ 3 .*θ₂.*u[1].^2 ][:,:]
end

# target state density
parameter = -2:0.1:2
data = StateDensity(parameter,[0.5,-0.5])

######################################################## run inference
parameters = ContinuationPar{Float64, typeof(DefaultLS()), typeof(DefaultEig())}(
	pMin=minimum(data.parameter),pMax=maximum(data.parameter),ds=step(data.parameter), maxSteps=1000,

		newtonOptions = NewtonPar{Float64, typeof(DefaultLS()), typeof(DefaultEig())}(
		verbose=false,maxIter=5000,tol= 1e-5),

	detect_fold = false, detect_bifurcation = true)

u₀,θ,trace = [-1.0],[2.1,2.1],[]
f,J = (u,p)->rates(u,p,θ...), (u,p)->rates_jacobian(u,p,θ...)

x,y = range(-5,5,length=50),range(-7,7,length=50)
plot(x, x-> lossAt(x,-2) )
#contourf(x,y, (x,y) -> lossAt(x,y), size=(500,500))

u₀ = [-2.0]
θ=[0.6,-1.]
progress()







θ = Params([0.5,-1.])
loss()

gs = gradient(θ) do
	loss()
end

import Base: iterate
iterate(::Nothing) = Nothing

########################################################
u₀,θ,trace = [0.0],[4.5,-1.0],[]
infer( f,J,u₀,θ, data; iter=100, progress = () -> push!(trace,copy(θ)) )
plot!( map( point -> point[1], trace), map( point -> point[2], trace),
	linewidth=1,color="white",markershape=:circle,markerstrokewidth=0,markersize=3,label="")

########################################################
u₀,θ,trace = [0.0],[-5.0,2.0],[]
infer( f,J,u₀,θ, data; iter=200, progress = () -> push!(trace,copy(θ)) )
plot!( map( point -> point[1], trace), map( point -> point[2], trace),
	linewidth=1,color="white",markershape=:circle,markerstrokewidth=0,markersize=3,label="")

########################################################
u₀,θ,trace = [0.0],[1.1,1.1],[]
infer( f,J,u₀,θ, data; iter=100, progress = () -> push!(trace,copy(θ)) )
plot!( map( point -> point[1], trace), map( point -> point[2], trace),
	linewidth=1,color="white",markershape=:circle,markerstrokewidth=0,markersize=3,label="")

########################################################
u₀,θ,trace = [0.0],[-1.0,-1.0],[]
infer( f,J,u₀,θ, data; iter=100, progress = () -> push!(trace,copy(θ)) )
plot!( map( point -> point[1], trace), map( point -> point[2], trace),
	linewidth=1,color="white",markershape=:circle,markerstrokewidth=0,markersize=3,label="")

########################################################
u₀,θ,trace = [0.0],[-3.0,-3.0],[]
infer( f,J,u₀,θ, data; iter=100, progress = () -> push!(trace,copy(θ)) )
plot!( map( point -> point[1], trace), map( point -> point[2], trace),
	linewidth=1,color="white",markershape=:circle,markerstrokewidth=0,markersize=3,label="")
