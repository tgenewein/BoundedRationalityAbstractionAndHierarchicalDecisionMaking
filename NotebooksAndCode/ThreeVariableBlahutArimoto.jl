function compute_marginals(pw::Vector, pogw::Matrix, pagow)
    
    card_o = size(pogw,1)
    card_a = size(pagow,1)
    
    #compute p(o)
    #p(o) = ∑_w p(o|w)p(w)
    po = pogw * pw

    #add some small value to prevent NaNs in the KL-terms
    po += eps()
    po /= sum(po) #TODO: does this improve convergence?



    #compute p(a)
    #p(a) = ∑_w,o p(w)p(o|w)p(a|o,w)    
    #compute p(a|w)
    pagw = marginalizeo(pogw, pagow)
    #p(a) = ∑_w p(a|w)p(w)
    pa = pagw * pw

    #add some small value to prevent NaNs in the KL-terms
    pa += eps()
    pa /= sum(pa) #TODO: does this improve convergence?


    #TODO: renormalize marginals (in principle this should not be necessary,
    #but in practice they do not sum to one in the early iteration steps!)

    #TODO: adding an epsilon should not make much of a difference, but 
    #re-normalizing afterwards might do so, on the other hand... the distribution
    #should already more or less sum to one, so getting rid of the zero-entries should 
    #be fine

    #TODO: if you really leave the function with adding an eps (and potentially renormalizing)
    #indicate this in the function name somehow, and perhaps even offer both versions!

    
    return po, pa, pagw
end



function marginalizeo(pogw::Matrix, pagow)
    card_a = size(pagow,1)
    card_w = size(pogw,2)
       
    #compute p(a|w)
    pagw = zeros(card_a,card_w)

    for j in 1:card_w
        #p(a|w) = ∑_o p(o|w)p(a|o,w)
        pagw[:,j] = pagow[:,:,j] * pogw[:,j]
    end
    
    return pagw
end





function compute_pago_iteration(pogw::Matrix, pagow, β2, β3, 
                                U_pre::Matrix, pa::Vector, po::Vector, pw::Vector)

    card_a = size(U_pre,1)
    card_w = size(U_pre,2)
    card_o = size(pogw,1)

    pago = zeros(card_a,card_o)

    for k in 1:card_o
        #compute p(w|o=k)
        #TODO:which version of p(w|o) is correct?             
        pwgo_k = vec(pogw[k,:]).*pw / po[k]                
        #pwgo_k = vec(pogw[k,:]).*pw
        #pwgo_k = pwgo_k / sum(pwgo_k)


        #compute p(a|o=k)
        if(β3==0)
            #sequential case
            #p(a|o) ∝ p(a)exp( β2 ∑_w p(w|o)U(a,w) )                    
            pago[:,k] = boltzmanndist(pa, β2, U_pre*pwgo_k)               
        else
            #general case
            #p(a|o) = ∑_w p(w|o)p(a|o,w)   with p(w|o) = p(o|w)p(w)/p(o)
            pago[:,k] = squeeze(pagow[:,k,:],2) * pwgo_k

            pago[:,k] += eps() #add some small value to prevent NaNs in the KL-terms
            pago[:,k] = pago[:,k] / sum(pago[:,k]) #TODO: does this improve convergence?
        end
    end

    return pago

end



function compute_pagow_iteration(pago::Matrix, β2, β3, U_pre::Matrix, pa::Vector) 

    card_a = size(U_pre,1)
    card_w = size(U_pre,2)
    card_o = size(pago,2)

    pagow = zeros(card_a,card_o,card_w)

    for j in 1:card_w
        if(β3==0)
            #sequential case: p(a|o,w)=p(a|o) ∀w
            #save some computation by implementing this directly rather than evaluating the
            #expression for the general case
            pagow[:,:,j] = pago                       
        else
            #general case
            #p(a|o,w) ∝ p(a|o) exp( β3 U(a,w) - β3/β2 log(p(a|o)/p(a)) )
            for k in 1:card_o              
                pagow_util_kj = U_pre[:,j] - (1/β2)*log_bits(pago[:,k]./pa)                
                pagow[:,k,j] = boltzmanndist(vec(pago[:,k]), β3, pagow_util_kj)
            end
        end
    end

    return pagow

end



function compute_pogw_iteration(pago::Matrix, pagow, β2, β3, U_pre::Matrix, pa::Vector, po::Vector)

    card_w = size(U_pre,2)
    card_o = size(po,1)

    pogw = zeros(card_o,card_w)

    #------- compute the conditional EU and the two KL terms -----------#
    EU_cond = zeros(card_o,card_w)
    DKL_a = zeros(card_o,card_w)
    DKL_ago = zeros(card_o,card_w)
    
    for j in 1:card_w
        for k in 1:card_o
            if(β3==0)
                #sequential case
                EU_cond[k,j] = (pago[:,k]' * U_pre[:,j])[1]  # E[U(a,w=j) = ∑_a p(a|o=k) U(a,w=j)
                                                                #use the (...)[1] syntax to get a scalar
                DKL_a[k,j] = kl_divergence_bits(vec(pago[:,k]),pa)
                
            else
                EU_cond[k,j] = (pagow[:,k,j]' * U_pre[:,j])[1]  # E[U(a,w=j) = ∑_a p(a|o=k,w=j) U(a,w=j)
                                                                #use the (...)[1] syntax to get a scalar
                DKL_a[k,j] = kl_divergence_bits(vec(pagow[:,k,j]),pa)
            end
            DKL_ago[k,j] = kl_divergence_bits(vec(pagow[:,k,j]),vec(pago[:,k])) 
        end
    end

    if(β3==0)
        #sequential case      
        #we have β3=0 which would lead to ∞*0=NaN in the computation for pogw_util
        #DKL_ago must be zero in the sequential case, therefore β3 does not matter

        #check that KL is really zero
        if(sum(DKL_ago) > 0)
            error("Sequential case: D_KL( p(a|o,w)||p(a|o) )=$(sum(DKL_ago)) is nonzero which violates sequential case assumption!")
        end

        #p(o|w) ∝ exp( β1 E[U] - 1/β2 DKL(p(a|o)||p(a)) )    
        pogw_util = EU_cond - 1/β2 * DKL_a                
    else
        #general case
        #p(o|w) ∝ p(o) exp( β1 (E[U] - 1/β2 DKL(p(a|o,w)||p(a))) - β1 DKL(p(a|o,w)||p(a|o)) (1/β3-1/β2) )
        pogw_util = EU_cond - 1/β2 * DKL_a - ( (1/β3)-(1/β2) ) * DKL_ago
    end


    #comptue p(o|w)    
    for j in 1:card_w
        pogw[:,j] = boltzmanndist(po, β1, vec(pogw_util[:,j]))
    end

    return pogw
end




#This function performs Blahut-Arimoto iterations for the three-variable general case
#and initializes p(o|w) and p(a|o,w) either uniformly or randomly, depending on the value
#of the optional argument 'init_uniform'
function threevarBAiterations(cardinality_obs::Integer, β1, β2, β3, U_pre::Matrix, pw::Vector,
                              ε_conv::Real, maxiter::Integer; compute_performance::Bool=false,
                              performance_per_iteration::Bool=false, performance_as_dataframe::Bool=false,
                              init_pogw_uniformly::Bool=false, init_pogw_sparse::Bool=true,
                              init_pagow_uniformly::Bool=true)
    
    num_acts = size(U_pre,1)
    num_worldstates = size(U_pre,2)
    num_obs = cardinality_obs

    if init_pogw_uniformly && init_pogw_sparse
        warn("Cannot initialize p(o|w) uniformly and sparse at the same time - choosing uniform initialization.")
        init_pogw_sparse = false
    end


    #initialize p(o|w)
    if init_pogw_uniformly
        #init uniform
        p_ogw_init = ones(cardinality_obs, num_worldstates)  
    elseif init_pogw_sparse
        #init with a sparse, diagonal pattern (maximizing H(O) - inspired by autoencoder pre-training)
        if(num_worldstates<=num_obs)
            p_ogw_init = eye(num_obs,num_worldstates)
        else
            for b in num_obs:num_obs:num_worldstates
                if b==num_obs
                    p_ogw_init = eye(num_obs, num_obs)
                else
                    p_ogw_init = [p_ogw_init eye(num_obs,b-size(p_ogw_init,2))]
                end
            end
            extra = num_worldstates - size(p_ogw_init,2)
            if extra>0
                p_ogw_init = [p_ogw_init eye(num_obs,extra)]
            end
        end
        #make sure that all elements are nonzero
        p_ogw_init += rand(size(p_ogw_init)) * 0.01  #TODO: this factor depends on the number of rows in p_ogw_init... fix this!
    else
        #init random
        p_ogw_init = rand(cardinality_obs, num_worldstates)  
    end


    #initialize p(a|o,w)
    if init_pagow_uniformly
        #uniform initialization        
        p_agow_init = ones(num_acts, cardinality_obs, num_worldstates) 
    else
        #random initialization
        p_agow_init = rand(num_acts, cardinality_obs, num_worldstates) 
    end
        

    #normalize
    for j in 1:num_worldstates
        p_ogw_init[:,j] /=  sum(p_ogw_init[:,j])        
        for k in 1:cardinality_obs
            p_agow_init[:,:,j] /= sum(p_agow_init[:,:,j])
        end
    end     

    

    #------- Blahut-Arimoto call --------#
    #Blahut-Arimoto iterations for the three-variable general case
    return threevarBAiterations(p_ogw_init, p_agow_init, β1, β2, β3, U_pre, pw, ε, maxiter, 
                                compute_performance=compute_performance,
                                performance_per_iteration=performance_per_iteration,
                                performance_as_dataframe=performance_as_dataframe)
    
end


#This function performs Blahut-Arimoto iterations for the three-variable general case
function threevarBAiterations(pogw_init::Matrix, pagow_init, β1, β2, β3, 
                              U_pre::Matrix, pw::Vector, ε_conv::Real, maxiter::Integer;
                              compute_performance::Bool=false, performance_per_iteration::Bool=false,
                              performance_as_dataframe::Bool=false)
    
    card_a = size(U_pre,1)
    card_w = size(U_pre,2)
    card_o = size(pogw_init,1)     
   


    pogw_new = pogw_init
    pagow_new = pagow_init


    #Initialize the marginals consistent with the conditionals
    po_new, pa_new, pagw = compute_marginals(pw, pogw_init, pagow_init)       

    pago_new = compute_pago_iteration(pogw_init, pagow_init, β2, β3, U_pre, pa_new, po_new, pw)
    if(β3==0)
        #sequential case - make sure that D_KL( p(a|o,w)||p(a|o) ) = 0
        pagow_new = compute_pagow_iteration(pago_new, β2, β3, U_pre, pa_new)
    end


   

    #if performance measures don't need to be returned, don't compute them per iteration
    if compute_performance==false
        performance_per_iteration = false
    end 

    #preallocate if necessary
    if performance_per_iteration 
        I_ow_i = zeros(maxiter)  #I(O;W)
        I_ao_i = zeros(maxiter)  #I(A;O)
        I_awgo_i = zeros(maxiter)  #I(A;W|O)
        I_aw_i = zeros(maxiter) #I(A;W)
        Ha_i = zeros(maxiter)  #H(A)
        Ho_i = zeros(maxiter)  #H(O)
        Hago_i = zeros(maxiter)  #H(A|O)
        Hogw_i = zeros(maxiter)  #H(O|W)
        Hagow_i = zeros(maxiter)  #H(A|O,W)
        Hagw_i = zeros(maxiter) #H(A|W)
        EU_i = zeros(maxiter)
        ThreeVarRDobj_i = zeros(maxiter)
    end
    


    #TODO: rather have an optional keyword argument to select the sequential case
    #- all of this makes the code quite hard to read and understand
    #maybe fix this by writing separate functions (pull the iterations into separate 
    #functions and handle the different cases there!)
    if(β3 == 0)
        sequential_case = true 
    else
        sequential_case = false
    end



    #main iteration
    iter = 0 #initialize counter, so it persists beyond the loop
    for iter in 1:maxiter
        pa = pa_new 
        po = po_new 
        pago = pago_new
        pagow = pagow_new
        pogw = pogw_new

        #
        #figure out best or correct order of equations
        #make sure to use old distributions in curr. iteration and update all of them after every iteration
        #check the sequential case by reproducing the MEU solution 
        #   perhaps it needs "layer-wise" initialization? If so, why?



        #compute p(o|w)
        pogw_new = compute_pogw_iteration(pago, pagow, β2, β3, U_pre, pa, po)
        
        #compute p(a|o,w) and p(a|o)
        if(β3==0)
            #sequential case - compute p(a|o) first and then p(a|o,w)
            pago_new = compute_pago_iteration(pogw, pagow, β2, β3, U_pre, pa, po, pw)
            pagow_new = compute_pagow_iteration(pago_new, β2, β3, U_pre, pa)
        else
            #general case - compute p(a|o,w) first and then p(a|o)
            pagow_new = compute_pagow_iteration(pago, β2, β3, U_pre, pa)
            pago_new = compute_pago_iteration(pogw, pagow_new, β2, β3, U_pre, pa, po, pw) #TODO: use pagow_new here?
        end      



  


        #update the marginals p(o), p(a), p(a|w)
        po_new, pa_new, pagw = compute_marginals(pw, pogw_new, pagow_new) 


        
        #TODO: is it better to immediately use the pxx_new quantities, or just update all of them
        #after each iteration (the latter is implemented right now)?
        #Does the order of the equations play any role?

        #compute entropic quantities (if requested with additional parameter)
        if performance_per_iteration
            I_ow_i[iter], I_ao_i[iter], I_awgo_i[iter], I_aw_i[iter],
            Ho_i[iter], Ha_i[iter], Hogw_i[iter], Hago_i[iter],
            Hagow_i[iter], Hagw_i[iter],
            EU_i[iter], ThreeVarRDobj_i[iter] = analyze_three_var_BAsolution(pw, po_new, pa_new, pogw_new, pago_new,
                                                                             pagow_new, pagw, U_pre, β1, β2, β3)
        end

        #check for convergence
        #TODO: store the value of the convergence criterion over iterations and return it (for plotting)
        #if (norm(pa-pa_new) + norm(po-po_new)) < ε_conv            
        if (norm(pagow[:]-pagow_new[:]) + norm(pogw[:]-pogw_new[:])) < ε_conv            
            break
        end
        
    end
    
    #check if iteration limit has been reached (before convergence)
    if iter == maxiter
        warn("[Three variable BAiterations] maximum iteration reached - returning... (results might be inaccurate)")
    end



    #return results
    if compute_performance == false
        return po_new, pa_new, pogw_new, pago_new, pagow_new, pagw
    else
        if performance_per_iteration == false
            #compute performance measures for final solution
            I_ow, I_ao, I_awgo, I_aw, Ho, Ha, Hogw, Hago, Hagow, Hagw, EU, ThreeVarRDobj = analyze_three_var_BAsolution(pw, po_new,
                                                                                           pa_new, pogw_new, pago_new, pagow_new, pagw,
                                                                                           U_pre, β1, β2, β3)
        else
            #"cut" valid results from preallocated vector
            I_ow = I_ow_i[1:iter]
            I_ao = I_ao_i[1:iter]
            I_awgo = I_awgo_i[1:iter]
            I_aw = I_aw_i[1:iter]
            Ho = Ho_i[1:iter]
            Ha = Ha_i[1:iter]
            Hogw = Hogw_i[1:iter]
            Hago = Hago_i[1:iter]
            Hagow = Hagow_i[1:iter]
            Hagw = Hagw_i[1:iter]
            EU = EU_i[1:iter]
            ThreeVarRDobj = ThreeVarRDobj_i[1:iter]
        end

        #if needed, transform to data frame
        if performance_as_dataframe == false
            return po_new, pa_new, pogw_new, pago_new, pagow_new, pagw, I_ow, I_ao, I_awgo, I_aw, Ho, Ha, Hogw, Hago, Hagow, Hagw, EU, ThreeVarRDobj
        else
            performance_df = performancemeasures2DataFrame(I_ow, I_ao, I_awgo, I_aw, Ho, Ha, Hogw, Hago, Hagow, Hagw, EU, ThreeVarRDobj)
            return po_new, pa_new, pogw_new, pago_new, pagow_new, pagw, performance_df 
        end
    end
    
end



#TODO: update module (export the new functions)

#TODO: test the special cases by setting different temperatures to certain values

#TODO: is it possible to choose in the initialization routine, whether you want Float64 or the type with
#infinite precision (BigFloat) without changing anything else in the rest of the code - if so, provide the option to
#do so!
#On the other hand, it would be sufficient to use the BigFloat only during the iterations and round
#when computing the performance measures, etc. - perhaps that's a cleaner solution

#TODO: make sure that all functions that modify the arguments that are passed on to them (in particular
#matrices and vectors) indicate this with '!' in the function-name!


