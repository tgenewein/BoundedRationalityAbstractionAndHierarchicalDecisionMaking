# This example contains two different utility functions which can be switched
# with the optional input argutment to ``setup_preator_prey_example``

# =============== 1 - predator-prey utility =====================
#w is size of opponent and there are three generic actions:
#a1 - ambush (wait and attack)
#a2 - sneak up (stalk and attack)
#a3 - flee

#w of group 1 (can't hear well)
#a1 ++ (might not come towards you)
#a2 +++ (will not hear you)
#a3 - (no food)

#w of group 2 (can hear well)
#a1 ++ (might not come towards you)
#a2 + (might hear you and flee)
#a3 - (no food)

#w of group 3 (can kill you)
#a1 -- 
#a2 --
#a3 ++++ (you survive)

#additionally there is a w-specific action for attack-w1 to attack-w8 (could be
#different sneak-up patterns, distance to strike, etc.)
#
#For g1, each of the specific actions increases the success (=utility) compared to the generic group action.
#For g2, the specific actions do not have an advantage over the generic action and give the same utility
#When applying a specific action to the wrong animal (within the same group), it is only 80% effective,
#thus the utility is 20% lower

# =============== 2 - mating utility =====================
#same animal sizes as before (they come in three groups, small, medium, large)
#Potential mate is in the medium group: w=8
#Rival of the same size is: w=6
#Rival that is bigger is: w=7
#
#All animals of the large group must be avoided in order not to fall prey to them
#Animals of the small size are irrelevant for the mating scenario
#
#
#Two possible actions
# 1) Display: gets the attention of the other animal
#             this is good for attracting a potential mate (w=8, high utility)
#             this is bad when facing a rival that is bigger (w=7) as it probably leads to aggression against you
#             this is ok when facing a rival of the same size as it might either drive the rival away or lead to a confrontation
#             this is bad when facing a large animal as it draws attention to you
#             this is a waste of time when facing a small animal (but it also won't harm you)
#
# 2) Flee:    move away from the other animal as quickly as possible
#             this is good when facing a large animal (increses chances of survival)
#             this is bad when facing a potential mate (w=8)
#             this is pretty good when facing a larger rival (w=7, avoids injury)
#             this is not so good when facing a rival of the same size (w=6)
#             this is a waste of time when facing a small animal
#
function setup_predator_prey_example(;mating_utility=false)

    w_values = [2,3,4, 6,7,8, 10,11,12]
    w_vec = [1:length(w_values)]
    w_strings = map((x)->string(x), w_values)

    numw = length(w_vec)
    #uniform distribution over w's
    pw = ones(numw)/numw


    if(mating_utility)
        a_strings = ["display", "flee"]
        a_values = [400, 500]
    else
        a_strings = [ map((x)->("sneak up w="*w_strings[x]), w_vec[1:3]),
                      map((x)->("ambush w="*w_strings[x]), w_vec[4:6]),
                      "ambush", "sneak up", "flee"]
        a_values = [w_values[1:6], 100, 200, 300]
    end

    if(mating_utility)
        function U(a,w)
            #w = animal from the large animal group (can kill you)
            if w>9
                if a==a_values[end]
                    #flee
                    return 5 #survive
                else
                    #display
                    return 0 #become prey for larger animal
                end
            end

            #w = animals from the same group as you - potential mates or rivals
            if w==w_values[4]
                #rival, same size as you
                 if a==a_values[end]
                    #flee
                    return 1 #decreases chances to find a mate
                else
                    #display
                    return 2.5 #might drive rival away, but risk of confrontation
                end
            end

            if w==w_values[5]
                #rival, bigger than you
                if a==a_values[end]
                    #flee
                    return 4 #avoid injury
                else
                    #display
                    return 0.5 #get potentially injured
                end
            end

            if w==w_values[6]
                #potential mate
                if a==a_values[end]
                    #flee
                    return 0.5 #missed chance to mate
                else
                    #display
                    return 4
                end
            end

            #w = animal from the small animal group - displaying to them or fleeing from them makes no difference
            #return a utility that is larger than when displaying to large animal (and become their prey)
            return 1
        end
    else
        function U(a,w)
            #survive (=generic flee g3) +++++
            survive_utility = 5
            #specific hunting pattern for each w of g1 ++++
            best_hunt_utility = 3.5   
            #generic sneak up g1 +++
            sneakup_g1_utility = 3
            #generic ambush g1, g2 ++
            ambush_utility = 2.3
            #generic sneak up g2 +
            sneakup_g2_utility = 1.5
            #generic flee g1, g2 -
            flee_g1g2_utility = 0.5
            #generic ambush, sneak up g3 --
            become_prey_utility = 0

            #for w1,w2,w3 there is a specific sneak-up pattern that has higher success ++++
            if w<5 && a==w
                return best_hunt_utility
            end

            #for w5,w6,w7 there is a specific ambush pattern, but it has no higher success than the generic
            #ambush  ++
            if w<9  && a==w
                return ambush_utility
            end

            #------- action = generic sneak up ---------
            #group 1 - sneak up +++ (will not hear you)
            #group 2 - sneak up + (might hear you and flee)
            if a==a_values[end-1]         
                if w<5
                    return sneakup_g1_utility
                end        
                if w<9
                    return sneakup_g2_utility
                end
            end

            #--------- w of group 1 or group 2 ----------
            #generic ambush ++ (might not come towards you)
            #generic flee - (no food)
            if w<9
                if a==a_values[end-2]
                    return ambush_utility
                end        
                if a==a_values[end]
                    return flee_g1g2_utility
                end        
            end

            #--------- w of group 3 (can kill you) ---------
            #generic ambush -- 
            #generic sneak up --
            #generic flee +++++ (you survive)
            if w>9
                if a == a_values[end]
                    return survive_utility
                else
                    return become_prey_utility
                end        
            end 

            
            #the only cases that are left are applying a specific hunting pattern to the wrong animal
            #for g1 and g2 - if the wrong specific approach is used on an animal from the same group,
            #it will only be 80% effective
            #If the wrong specific approach is used on an animal from the other group, it will be as 
            #effective as the generic action (either sneak-up or ambush)
            #(meaning that the utility is 20% lower)
            if w<5
                if a<5
                    return sneakup_g1_utility*0.8
                else
                    return ambush_utility
                end
            end

            if w<9
                if a<5
                    return sneakup_g2_utility
                else
                    return ambush_utility*0.8
                end
            end
        end
    end


    return w_values, w_strings, a_values, a_strings, pw, U

end



#wvec = [2,3,4, 6,7,8, 10,11,12]
#ovec = [1,2,3, ... , 11,12,13]  #expected to start at 1 (for boundary check)
                                 #must be a consecutive interval (no missing values allowed)
#λ ... noise-level
function pogw_handcrafted(ovec, wvec , λ)
    #determine p(o=k|w=j,λ)  ∀j,k
    #using a sampling-based approach
    #
    #o is a noisy version of w - the precision is governed by λ
    #o can only take on discrete values (as specified by ovec),
    #these values can not lie outside the interval - therefore
    #if a value lies outside the interval, reject and resample
    
    #check that λ is nonzero
    if λ==0
        error("Precision λ must have a nonzero value!")
    end
    
    numw = length(wvec)
    numo = length(ovec)
    pogw = zeros(numo, numw)
    
    Nsamp = 5000  #number of samples to draw in order to estimate p(o|w=j,λ)
   
    
    for j=1:numw
        #draw many samples of p(o|w=j,λ) and determine frequencies over o    
        acc = 0 #acceptance counter
        ogw_samples = zeros(Nsamp)
        while acc<Nsamp
            ogw_samples[acc+1] = round(wvec[j] + randn(1)/λ)[1]  #[1] syntax to treat 1-element vector as scalar
            #check boundaries - everything outside boundaries gets rejected and re-sampled
            if (ogw_samples[acc+1]>0) && (ogw_samples[acc+1]<(numo+1))
                #accept
                acc +=1
            end
        end
            
        #count frequencies over o (using a histogram with specified bin-borders)
        e,freqs = hist(ogw_samples, 0.5:(numo+0.5))

        #normalize frequencies to get a probability vector
        pogw[:,j] = freqs / sum(freqs)
    end
    
    return pogw
end

