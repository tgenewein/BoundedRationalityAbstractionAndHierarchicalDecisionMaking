# Medical system utility
# There are three kinds of diseases, each comes in two types
#
#  *  Heart disease
#    *  h1
#    *  h2
#  *  Lung disease 1
#    *  l1
#    *  l2
#  *  Lung disease 2
#    *  l3
#    *  l4
#
#
# For each specific type, there is a specific treatment that works best (=highest utility)
# Applying the specific treatment to the wrong type of the same disease is less effective
# Applying the specific treatment to the wrong disease is bad (low utility)
#
# There are also general treatments for each disease: ``treat h``, ``treat l12``, ``treat l34``
# The general treatement works for both types of the corresponding disease equally well, 
# but has no effect when applied to the wrong disease.
# The general treatement for the heart is less effective (lower utility) than the general treatments
# for lung disease 1 or lung disease 2.
#
# There is one general lung treatement ``treat l`` that has an effect when applied to ``l1, l2, l3`` or ``l4``
# However, it is less efficient than the general treatments for the corresponding lung disease ``treat l12`` or ``treat l34``
# The general lung treatment has no effect when applied to a heart disease
#
#
#
# The function ``setup_medical_example`` has an optional argument that allows to choose between
#   -) a uniform environment where all diseases appear with equal probability and
#   -) a nonuniform environment where both heart disease types ``h1, h2`` appear with inceased chance.
#
#
function setup_medical_example(;uniform_w=true)

    w_strings = ["h1","h2", "l1","l2", "l3", "l4"]
    w_values = collect(1:length(w_strings))

    numw = length(w_values)

    if uniform_w
        #uniform distribution over w's
        pw = ones(numw)/numw
    else
        #non-uniform p(w)
        pw = medical_nonuniform_pw(numw)
    end


    a_strings = [ map((x)->("treat "*w_strings[x]), w_values),
                  "treat l12", "treat l34", "treat h", "treat l" ]
    a_values = collect(1:length(a_strings))


    function U(a,w)
        #correct treatment
        correct_utility = 3

        #wrong treatment for cause: heard-disease
        wrong_utility_heart = correct_utility * 0.3

        #general heart-treatment
        utility_heart_general = 1.5

        #wrong treatment for cause: lung-disease
        wrong_utility_lung = correct_utility * 0.5

        #wrong treatment for cause: lung-disease
        wrong_utility_lung_2 = correct_utility * 0

        #general lung treatment
        utility_lung_general = 1.5

        #general lung treatment l12
        utiliy_lung_general_12 = 2.5

        #general lung treatment l12
        utiliy_lung_general_34 = 2.5


        #correct treatment
        if a==w
            return correct_utility
        end


        #heart-disease, heart treatment (but not correct one)
        if w<3 && a<3
            return wrong_utility_heart
        end

        #lung-disease, lung treatment (but not correct one)
        if w>2 && w<5 && a>2 && a<5
            return wrong_utility_lung
        end

        #lung-disease, lung treatment (but not correct one)
        if w>2 && w<5 && a>4 && a<7
            return wrong_utility_lung_2
        end

        #lung-disease, lung treatment (but not correct one)
        if w>4 && w<7 && a>4 && a<7
            return wrong_utility_lung
        end

        #lung-disease, lung treatment (but not correct one)
        if w>4 && w<7 && a>2 && a<5
            return wrong_utility_lung_2
        end

        #general heart treatment
        if w<3 && a==9
            return utility_heart_general
        end

        #general lung treatments
        if w>2 && w<7
            if a==7 && w<5
                return utiliy_lung_general_12
            end

            if a==8 && w>4
                return utiliy_lung_general_34
            end

            if a==10
                return utility_lung_general
            end
        end




        #wrong treatment for wrong cause
        return 0

    end

    return w_values, w_strings, a_values, a_strings, pw, U

end




function medical_nonuniform_pw(num_w_values)
        #increased probability of one heart-disease and pancreatic disease
        pw = ones(num_w_values)
        pw[1:2] = 3
        #pw[3:6] = 3
        #pw[6:7] = 3
        #pw[8:9] = 1
        pw /= sum(pw)  #re-normalize
    return pw
end

