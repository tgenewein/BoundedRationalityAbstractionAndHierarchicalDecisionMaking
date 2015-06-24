
function setuptaxonomy()
    #set up taxonomy example
    #observations
    o_strings = ["Persian","Siamese","British Shorthair", #CATS
                 "German Shepherd","Rottweiler","Dachshund", #DOGS
                 "Oak","Birch","Pine", #TREES
                 "Rose","Dandelion","Sunflower", #FLOWERS
                 "Hibiscus" #Tree and flower (to break symmetry)
                ]

    num_obs = size(o_strings,1)
    o_vec = [1:num_obs]

    #actions are observations + categories + supercategories
    a_strings = [o_strings, "CAT","DOG","TREE","FLOWER","Animal","Plant"]
    num_acts = size(a_strings,1)
    a_vec = [1:num_acts]
    
    #set up uniform p(o)
    p_o = ones(num_obs)/num_obs 


    #define utility function
    #(everything is hardcoded here, which is a bit hacky but will do the job)
    function U(a,o)
        u_correct_o = 3;
        u_correct_category = 2.2;
        u_correct_supercategory = 1.6;

        #correct observation
        if o==a
            return u_correct_o
        end


        #correct category
        if o < 13
            cat = ceil(o/3)
            if (a-13) == cat
                return u_correct_category
            end
        end

        if o == 13  #hibiscus case
            if (a==16 || a==17)
                return u_correct_category
            end
        end


        #correct supercategory
        supcat = ceil(o/6)
        if (a-17) == supcat
            return u_correct_supercategory
        end

        if o == 13 #hibiscus case
            if a==19
                return u_correct_supercategory
            end
        end

        #incorrect action
        return 0

    end
    
    return o_vec, o_strings, a_vec, a_strings, p_o, U
end