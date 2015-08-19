# Bounded rational inference and decision-making hierarchies: aninformation-theoretic optimality principle
Supplementary code and Jupyter notebooks for publication: Bounded rational inference and decision-making hierarchies: an information-theoretic optimality principle

## Using the notebooks
If you are unfamiliar with Jupyter notebooks it is strongly suggested that you have a look here: http://jupyter-notebook-beginner-guide.readthedocs.org/en/latest/index.html

The easiest and installation-free method of using the notebooks provided here is through JuliaBox. Alternatively Julia and IJulia must be installed (on top of IPython) along with a few Julia packages.

### Usage through JuliaBox

*  Go to https://www.juliabox.org/ and sign in with your Google account (currently only Google accounts are supported).
*  At the very top of the JuliaBox window, select the ``Sync`` tab.
*  Under ``Git Repositories`` you can simply clone this repository to a folder in JuliaBox
*  To do so enter the HTTPS-URL of this repository in the first field on JuliaBox
  *  The URL can be found on the landing-page of this repository on GitHub (https://github.com/tgenewein/LossyCompressionAndDecisionMaking) in the right bar of the web-page
  *  It should give you: ``https://github.com/tgenewein/LossyCompressionAndDecisionMaking.git``
*  Select the branch ``master`` in the second edit-field of JuliaBox and specify a local folder name in the third edit-field.
*  Finally click the plus sign to clone the repository.
  *  It should look like this: ![Cloning repository to JuliaBox](AddRepoToJuliaBox.png)
  

Alternatively, you can use the ``Console`` tab in JuliaBox to get a shell and clone the repository with standard git commands.

If you completed this successfully, you should see a new folder under the ``IJulia`` tab that contains the contents of the repository, including the notebooks. Simply select a notebook by clicking on it and it opens in a new tab.

### Usage with IJulia installation

Install IJulia by following the instructions here: https://github.com/JuliaLang/IJulia.jl

This will require you to
*  Install IPython (preferably through anaconda)
*  Install Julia
*  Install IJulia

Download the contents of this repository
*  https://github.com/tgenewein/LossyCompressionAndDecisionMaking/archive/master.zip
*  Unpack the zip-file to some destination-folder

Or alternatively, clone/fork the repository using git.

Navigate to the folder that contains the repository contents and start a new notebook server (typically by opening a console and typing: ``ipython notebook``). A new browser tab should open and you open notebooks by clicking on them.

## I've never used a Jupyter/IPython notebook before...
The notebooks are very simple to use - you can get an overwiew by clicking on ``Help -> User Interface Tour`` in any running notebook (in the browser). It might be best to run all cells after opening a notebook (by selecting ``Cell -> Run all``). Note that the first run (of any function) in Julia can take quite a bit longer (because the function gets JIT compiled).
