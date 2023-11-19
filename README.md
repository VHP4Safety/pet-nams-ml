# pet-nams-ml
This is the repo for the Machine Learning lesson in the Post-graduate Education Track 'Toxicology' - New Approach Methodologies Course

## Installation
The contents of this repo are an R package that can be installed by running in a Terminal
```
git clone https://github.com/VHP4Safety/pet-nams-ml
cd pet-nams-ml
```

And then from that folder in R:
```
install.packages("pak")
pak::local_install(".") 
```

This will install the package locally, and also will install any dependencies necessary for the contents of the repo to run.

## Bookdown
This Github repo is also an R `{bookdown}` project. To build the bookdown site locally, run the above commands, followed by:
```
bookdown::render_book(".")
```
After rendering is finished, the wite can be viewed by opening "./_book/index.html" 

## Citing this work
The citation information can be found in the `./CITATION.cff` file. When using this work, please pay proper attribution, by including the citation.

## Licence
This work is published under a permissive licence. CC BY-NC 4.0. The details can be viewed in the file `./LICENSE.md` 
