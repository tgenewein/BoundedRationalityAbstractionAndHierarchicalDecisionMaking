#test call for the library

#change path to actual folder containing the files
#this seems to be an issue with Sublime IJulia
#cd("GSOSpecialIssue/Code/") 

using BlahutArimoto

card_x = 3 #cardinality x
card_ω = 2 #cardinality ω
β = 1 #inverse temperature
ε = 0.000001 #convergence critetion for BAiterations
maxiter = 5000 #maximum number of BA iterations

#set up uniform p(ω)
pω = ones(card_ω)/card_ω 

#initialize p(x) uniformly
px_init = ones(card_x)/card_x 



#cosine utility function (returns pre-computed utilities and maximum for each y)
function CosineUtility(cardinality_x, cardinality_y)
    #set up x ∈ (0,π/2)
    xvec = linspace(0,pi/2,cardinality_x)
    #set up y ∈ (0,π/4)
    yvec = linspace(0,pi/4,cardinality_y)

    #set up the utility function
    #utility is cosine, ω acts as a phase shift
    function U(x,ω)
        cos(x-ω)
    end

    #pre-compute utilities, find maxima
    U_pre, Umax = setuputilityarrays(xvec,yvec,U)
    
    return U_pre, Umax
end


#exemplary usage
U_pre, Umax = CosineUtility(card_x, card_ω)
pxgω,px = BAiterations(px_init,β,U_pre,Umax,pω,ε,maxiter)

U_pre,pxgω,px
