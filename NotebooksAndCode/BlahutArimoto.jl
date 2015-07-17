
#Setup pre-evalutated utility matrix and the utility-maximum vector
function setuputilityarrays(a::Vector, w::Vector, utility::Function)
    cardinality_a = length(a) 
    cardinality_w = length(w)

    #pre-compute utilities, find maxima
    U_pre = zeros(cardinality_a, cardinality_w)
    Umax = zeros(cardinality_w)
    for i in 1:cardinality_w
        for j in 1:cardinality_a
            U_pre[j,i]=utility(a[j], w[i])
        end
        Umax[i] = maximum(U_pre[:,i])
    end
    
    return U_pre, Umax
end


#This function computes p_boltz = 1/Z * p0 * exp(β*ΔU),
#where Z is the normalization constant (partition function)
### arguments:
#p0 ... prior distribution (vector of length N)
#β ... inverse temperature (scalar)
#ΔU ... utility or potential-difference (vector of length N)
### returns:
#p_boltz ... 1/Z * p0 * exp(β*ΔU)
function boltzmanndist(p0::Vector, β, ΔU::Vector)
    p_boltz = p0.*exp(β.*ΔU)
    p_boltz /= sum(p_boltz)
    return p_boltz

    #=
    #do the computation with more precision (but slower)
    deltaU = convert(Array{BigFloat}, ΔU)
    p_boltz = p0.*exp(β.*ΔU)
    p_boltz = p_boltz/sum(p_boltz)
    return float64(p_boltz)
    =#

    #TODO: the exponential operation might be problematic when you run out of machine precision
    #i.e. for very large β values or very large utility values - can you make this numerically
    #more stable (because afterwards there is a normalization step, where for instance a single
    #large value in the exponential would simply be normalized to one)
end





#This function performs Blahut-Arimoto iterations
function BAiterations(pa_init::Vector, β, U_pre::Matrix, pw::Vector, ε_conv::Real, maxiter::Integer; 
                       compute_performance::Bool=false, performance_per_iteration::Bool=false,
                       performance_as_dataframe::Bool=false)
    pa_new = pa_init    
    card_a = size(U_pre,1)
    card_w = size(U_pre,2)    
    pagw_new = zeros(card_a,card_w)

    #if performance measures don't need to be returned, don't compute them per iteration
    if compute_performance==false
        performance_per_iteration = false
    end 

    #preallocate if necessary
    if performance_per_iteration 
        I_i = zeros(maxiter)
        Ha_i = zeros(maxiter)
        Hagw_i = zeros(maxiter)
        EU_i = zeros(maxiter)
        RDobj_i = zeros(maxiter)
    end
    
    #main iteration
    iter = 0 #initialize counter, so it persists beyond the loop
    for iter in 1:maxiter
        pa = deepcopy(pa_new)  #make sure not to just copy the reference
        #pa_new = zeros(card_a)       
        pagw = deepcopy(pagw_new)
        pagw_new = zeros(card_a,card_w)

        for k in 1:card_w
            #update p(a|o)
            pagw_new[:,k] = boltzmanndist(pa,β,vec(U_pre[:,k]))            
            #update p(a)            
            pa_new = pa_new + vec((pagw_new[:,k]')*pw[k])
        end

        #TODO: is this really necessary
        #add small value to pa_new to make sure there are no zero-entries
        #due to limited numerical precision, then re-normalize
        pa_new += eps()
        pa_new /= sum(pa_new)


        #compute entropic quantities (if requested with additional parameter)
        if performance_per_iteration
            I_i[iter], Ha_i[iter], Hagw_i[iter], EU_i[iter], RDobj_i[iter] = analyzeBAsolution(pw, pa_new, pagw_new, U_pre, β)
        end

        #check for convergence
        if norm(pagw-pagw_new) < ε_conv            
            break
        end
    end
    
    #check if iteration limit has been reached (before convergence)
    if iter == maxiter
        warn("[BAiterations] maximum iteration reached - returning... (results might be inaccurate)")
    end



    #return results
    if compute_performance == false
        return pagw_new, vec(pa_new)  #the squeeze will turn pa into a vector again
    else
        if performance_per_iteration == false
            #compute performance measures for final solution
            I, Ha, Hagw, EU, RDobj = analyzeBAsolution(pw, pa_new, pagw_new, U_pre, β)
        else
            #"cut" valid results from preallocated vector
            I = I_i[1:iter]
            Ha = Ha_i[1:iter]
            Hagw = Hagw_i[1:iter]
            EU = EU_i[1:iter]
            RDobj = RDobj_i[1:iter]
        end

        #if needed, transform to data frame
        if performance_as_dataframe == false
            return pagw_new, vec(pa_new), I, Ha, Hagw, EU, RDobj
        else
            performance_df = performancemeasures2DataFrame(I, Ha, Hagw, EU, RDobj)
            return pagw_new, vec(pa_new), performance_df 
        end
    end
    
end



