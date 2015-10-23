citation for latest release  
[![DOI](http://img.shields.io/badge/DOI-10.5281%2Fzenodo.32410-blue.svg?style=flat)](http://dx.doi.org/10.5281/zenodo.32410)


# Bounded rationality, abstraction and hierarchical decision-making: an information-theoretic optimality principle
Supplementary code and Jupyter notebooks for publication:  
Genewein T., Leibfried F., Grau-Moya J., Braun D.A. (2015): [*Bounded rationality, abstraction and hierarchical decision-making: an information-theoretic optimality principle*](http://journal.frontiersin.org/article/10.3389/frobt.2015.00027/), Frontiers in Robotics and AI, 2.  
[![DOI](http://img.shields.io/badge/DOI-10.3389%2Ffrobt.2015.00027-blue.svg?style=flat)](http://dx.doi.org/10.3389/frobt.2015.00027) 




## Using the notebooks
**Note:** It is recommended that you run these notebooks with ***Chrome*** as there might be some issues with the interactive plots in Firefox and Internet Explorer.

If you are unfamiliar with Jupyter notebooks it is strongly suggested that you have a look [here]( http://jupyter-notebook-beginner-guide.readthedocs.org/en/latest/index.html)

The easiest and installation-free method of using the notebooks provided here is through JuliaBox. Alternatively Julia and IJulia must be installed (besides Jupyter) along with a few Julia packages.

Alternatively, you can view a static HTML rendering of the notebook (which means that you cannot change any parameters) through [nbviewer](http://nbviewer.ipython.org/github/tgenewein/BoundedRationalityAbstractionAndHierarchicalDecisionMaking/tree/master/NotebooksAndCode/)

## Julia version
Julia release 0.4.0: [![DOI](https://zenodo.org/badge/doi/10.5281/zenodo.31957.svg)](http://dx.doi.org/10.5281/zenodo.31957)  
The supplementary code and notebooks are published for Julia 0.4 (0.4.0 to be precise). When following the instructions below, try using Julia 0.4.0 or at least another 0.4.x release as future versions of Julia might possibly break the code. Alternatively, check the [github repository](https://github.com/tgenewein/BoundedRationalityAbstractionAndHierarchicalDecisionMaking) for updated versions of the code that are compatible with later Julia releases. Up-to-date instructions on how to run the notebooks can be found there as well. If you experience problems or have suggestions for improvements, feel free to file a new issue on the github repository ([here](https://github.com/tgenewein/BoundedRationalityAbstractionAndHierarchicalDecisionMaking/issues)).
A complete listing of the versions of all required Julia packages is at the bottom of this page. You can specify a particular version of a package in the Julia REPL with ``Pkg.pin("<Name>",v"<Version No.>")``.

### Usage through JuliaBox (installation free)

*  Go to [JuliaBox](https://www.juliabox.org/) and sign in with your Google account (currently only Google accounts are supported).
*  At the very top of the JuliaBox window, select the ``Sync`` tab.
*  Under ``Git Repositories`` you can simply clone this repository to a folder in JuliaBox
*  To do so enter the HTTPS-URL of this repository in the first field on JuliaBox
  *  The URL can be found on the [landing-page](https://github.com/tgenewein/BoundedRationalityAbstractionAndHierarchicalDecisionMaking) of this repository on GitHub in the right bar of the web-page
  *  It should give you: ``https://github.com/tgenewein/BoundedRationalityAbstractionAndHierarchicalDecisionMaking.git``
*  Select the branch ``master`` in the second edit-field of JuliaBox and specify a local folder name in the third edit-field.
*  Finally click the plus sign to clone the repository.
  *  It should look like this: ![Cloning repository to JuliaBox](AddRepoToJuliaBox.png)
  

Alternatively, you can use the ``Console`` tab in JuliaBox to get a shell and clone the repository with standard git commands.

If you completed this successfully, you should see a new folder under the ``IJulia`` tab that contains the contents of the repository, including the notebooks. Simply select a notebook by clicking on it and it opens in a new tab.

When you open the notebooks, you should see that JuliaBox is using an IJulia **kernel of version 0.4.x.** It might be that future versions of JuliaBox do not include the 0.4-version kernel. In this case please refer to the [github repository](https://github.com/tgenewein/BoundedRationalityAbstractionAndHierarchicalDecisionMaking) for updated code and updated instructions on how to run the code most easily.


### Usage with IJulia installation

Install IJulia by following the instructions [here](https://github.com/JuliaLang/IJulia.jl). Note that in the future this might give you Julia versions different from 0.4.x - it is strongly recommended that you run the notebooks with Julia 0.4.x. If you can't manage to get a hold of that Julia version go to the [github repository](https://github.com/tgenewein/BoundedRationalityAbstractionAndHierarchicalDecisionMaking) for updated code and instructions.

This will require you to
*  Install Jupyter (preferably through anaconda)
*  Install Julia
*  Install IJulia

Download the contents of this repository
*  Get a .zip file of this repository from [here](https://github.com/tgenewein/BoundedRationalityAbstractionAndHierarchicalDecisionMaking/archive/master.zip) on github.
*  Unpack the zip-file to some destination-folder

Or alternatively, clone/fork the repository using git.

Navigate to the folder that contains the repository contents and start a new notebook server (typically by opening a console and typing: ``jupyter notebook``). A new browser tab should open and you can open notebooks by clicking on them.

## I've never used a Jupyter notebook before...
The notebooks are very simple to use - you can get an overwiew by clicking on ``Help -> User Interface Tour`` in any running notebook (in the browser). It might be best to run all cells after opening a notebook (by selecting ``Cell -> Run all``). Note that the first run (of any function) in Julia can take quite a bit longer (because the function gets JIT compiled).

## Other releases of this repository
Every release of this repository is tagged using a git tag. Alternatively, see the [releases](https://github.com/tgenewein/BoundedRationalityAbstractionAndHierarchicalDecisionMaking/releases) on github.

tag | Julia version | DOI
--- | ------------- | ---
v1.1.0 | 0.4.0 | [10.5281/zenodo.32410](http://dx.doi.org/10.5281/zenodo.32410)
v1.0.0 | 0.3.11 | [10.5281/zenodo.32055](http://dx.doi.org/10.5281/zenodo.32055)


## Exact package versions
The code provided was tested with Julia 0.4.0, Jupyter 0.4.1 and the following package versions
```
julia> Pkg.status()
5 required packages:
 - DataFrames                    0.6.10
 - Gadfly                        0.3.17
 - IJulia                        1.1.7
 - Interact                      0.2.1
 - Patchwork                     0.1.8
43 additional packages:
 - ArrayViews                    0.6.4
 - Benchmark                     0.1.0
 - BinDeps                       0.3.18
 - Calculus                      0.1.13
 - Codecs                        0.1.5
 - ColorTypes                    0.1.7
 - Colors                        0.5.4
 - Compat                        0.7.6
 - Compose                       0.3.17
 - Conda                         0.1.7
 - Contour                       0.0.8
 - DataArrays                    0.2.19
 - DataStructures                0.3.13
 - Dates                         0.4.4
 - Distances                     0.2.1
 - Distributions                 0.8.7
 - Docile                        0.5.19
 - DualNumbers                   0.1.5
 - FactCheck                     0.4.1
 - FixedPointNumbers             0.0.12
 - FunctionalCollections         0.1.2
 - GZip                          0.2.18
 - Grid                          0.4.0
 - Hexagons                      0.0.4
 - ImmutableArrays               0.0.11
 - Iterators                     0.1.9
 - JSON                          0.5.0
 - KernelDensity                 0.1.2
 - Loess                         0.0.4
 - NaNMath                       0.1.1
 - Nettle                        0.2.0
 - Optim                         0.4.4
 - PDMats                        0.3.6
 - Reactive                      0.2.4
 - Reexport                      0.0.3
 - SHA                           0.1.2
 - Showoff                       0.0.6
 - SortingAlgorithms             0.0.6
 - StatsBase                     0.7.4
 - StatsFuns                     0.1.4
 - URIParser                     0.1.1
 - WoodburyMatrices              0.1.2
 - ZMQ                           0.3.0
```
