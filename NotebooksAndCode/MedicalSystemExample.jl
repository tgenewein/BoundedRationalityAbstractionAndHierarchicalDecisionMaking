#TODO: document utility


function setup_medical_example(;uniform_w=true)

    w_strings = ["h1","h2","h3", "l1","l2", "l4", "l5", "p1", "p2"]
    w_values = [1:length(w_strings)]

    numw = length(w_values)

    if uniform_w
        #uniform distribution over w's
        pw = ones(numw)/numw
    else
        #non-uniform p(w)
        pw = medical_nonuniform_pw(numw)
    end


    a_strings = [ map((x)->("treat "*w_strings[x]), w_values) ]
    a_values = w_values


    function U(a,w)
        #correct treatment
        correct_utility = 3

        #wrong treatment for cause: heard-disease
        wrong_utility_heart = correct_utility * 0.3

        #wrong treatment for cause: lung-disease
        wrong_utility_lung = correct_utility * 0.8

        #wrong treatment for cause: lung-disease
        wrong_utility_lung_2 = correct_utility * 0.3

        #wrong treatment for cause: pancreatic-desease
        wrong_utility_pancreas = correct_utility * 0.8


        #correct treatment
        if a==w
            return correct_utility
        end


        #heart-disease, heart treatment (but not correct one)
        if w<4 && a<4
            return wrong_utility_heart
        end

        #lung-disease, lung treatment (but not correct one)
        if w>3 && w<6 && a>3 && a<6
            return wrong_utility_lung
        end

        #lung-disease, lung treatment (but not correct one)
        if w>3 && w<6 && a>5 && a<8
            return wrong_utility_lung_2
        end

        #lung-disease, lung treatment (but not correct one)
        if w>5 && w<8 && a>5 && a<8
            return wrong_utility_lung
        end

        #lung-disease, lung treatment (but not correct one)
        if w>5 && w<8 && a>3 && a<6
            return wrong_utility_lung_2
        end


        #pancreatic-disease, pancreas treatment (but not correct one)
        if w>7 && a>7
            return wrong_utility_pancreas
        end



        #wrong treatment for wrong cause
        return 0

    end

    return w_values, w_strings, a_values, a_strings, pw, U

end




function medical_nonuniform_pw(num_w_values)
        #increased probability of one heart-disease and pancreatic disease
        pw = ones(num_w_values)
        #pw[1] = 5
        pw[4:7] = 3
        #pw[6:7] = 3
        #pw[8:9] = 1
        pw /= sum(pw)  #re-normalize
    return pw
end

