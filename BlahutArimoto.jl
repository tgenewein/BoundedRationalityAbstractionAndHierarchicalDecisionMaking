
#Setup pre-evalutated utility matrix and the utility-maximum vector
function setuputilityarrays(a::Vector, o::Vector, utility::Function)
    cardinality_a = length(a) 
    cardinality_o = length(o)

    #pre-compute utilities, find maxima
    U_pre = zeros(cardinality_a, cardinality_o)
    Umax = zeros(cardinality_o)
    for i in 1:cardinality_o
        U_pre[:,i]=utility(a,o[i])
        Umax[i],ind = findmax(U_pre[:,i])
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
    p_boltz = p_boltz/sum(p_boltz)
    return p_boltz
end





#This function performs Blahut-Arimoto iterations
function BAiterations(pa_init::Vector, β, U_pre::Matrix, Umax::Vector, po::Array, ε_conv::Real, maxiter::Integer; 
                       compute_performance::Bool=false, performance_per_iteration::Bool=false,
                       performance_as_dataframe::Bool=false)
    pa_new = pa_init    
    card_a = size(U_pre,1)
    card_o = size(U_pre,2)    
    pago = zeros(card_a,card_o)

    #if performance measures don't need to be returned, don't compute them per iteration
    if compute_performance==false
        performance_per_iteration = false
    end 

    #preallocate if necessary
    if performance_per_iteration 
        I_i = zeros(maxiter)
        Ha_i = zeros(maxiter)
        Hago_i = zeros(maxiter)
        EU_i = zeros(maxiter)
        RDobj_i = zeros(maxiter)
    end
    
    #main iteration
    iter = 0 #initialize counter, so it persists beyond the loop
    for iter in 1:maxiter
        pa = deepcopy(pa_new)  #make sure not to just copy the reference
        pa_new = zeros(card_a)       
        for k in 1:card_o
            #update p(a|o)
            pago[:,k] = boltzmanndist(pa,β,vec(U_pre[:,k]))            
            #update p(a)            
            pa_new = pa_new + vec((pago[:,k]')*po[k])
        end


        #compute entropic quantities (if requested with additional parameter)
        if performance_per_iteration
            I_i[iter], Ha_i[iter], Hago_i[iter], EU_i[iter], RDobj_i[iter] = analyzeBAsolution(po, pa_new, pago, U_pre, β)
        end

        #check for convergence
        if norm(pa-pa_new) < ε_conv            
            break
        end
    end
    
    #check if iteration limit has been reached (before convergence)
    if iter == maxiter
        warn("[BAiterations] maximum iteration reached - returning... (results might be inaccurate)")
    end



    #return results
    if compute_performance == false
        return pago, vec(pa_new)  #the squeeze will turn pa into a vector again
    else
        if performance_per_iteration == false
            #compute performance measures for final solution
            I, Ha, Hago, EU, RDobj = analyzeBAsolution(po, pa_new, pago, U_pre, β)
        else
            #"cut" valid results from preallocated vector
            I = I_i[1:iter]
            Ha = Ha_i[1:iter]
            Hago = Hago_i[1:iter]
            EU = EU_i[1:iter]
            RDobj = RDobj_i[1:iter]
        end

        #if needed, transform to data frame
        if performance_as_dataframe == false
            return pago, vec(pa_new), I, Ha, Hago, EU, RDobj
        else
            performance_df = performancemeasures2DataFrame(I, Ha, Hago, EU, RDobj)
            return pago, vec(pa_new), performance_df 
        end
    end
    
end

#convert performance measures to DataFrame representation
function performancemeasures2DataFrame(I, Ha, Hago, EU, RDobj)
    return DataFrame(I_ao=I, H_a=Ha, H_ago = Hago, E_U = EU, RD_obj = RDobj)
end

#TODO: include 2-level BA algorithm(s) here(?)

