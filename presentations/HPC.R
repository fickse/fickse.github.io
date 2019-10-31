
#' ---
#' title: HPC clusters and SLURM with R
#' author: Stephen Fick
#' output:
#'    rmdformats::readthedown
#' ---

#' ![A dam with many spouts is a parallel operation](dam.jpg)

#+ label=preamble 
#+ warning=FALSE
#+ echo=FALSE


############################################################################################
############################################################################################
############################################################################################


knitr::opts_knit$set(root.dir = '.' )
knitr::opts_chunk$set(fig.width=8, fig.height=6)
knitr::opts_chunk$set( warning=FALSE, message=FALSE)


############################################################################################
############################################################################################
############################################################################################
# to run:

#  setwd( "C:\\PROJECTS\\fickse.github.io\\presentations" ) # local directory
#  rmarkdown::render(file.path(getwd(), 'HPC.R'))

run_it <- function() rmarkdown::render(file.path(getwd(), 'HPC.R'))

#reference : http://brooksandrew.github.io/simpleblog/articles/render-reports-directly-from-R-scripts/


# review missing data


#' # Why Use an HPC Cluster

#' * You have an 'embarassingly parallel\*' computing task that takes **too long** to run on a single desktop computer
#' * You have a computing task which is too large (too much memory / data) for running on a desktop
#' * You want to collaborate with colleagues on a shared system
#' * You don't have/want to pay for a more powerful computer.

#'  
#' # How do HPC/Clusters work ?
#'  
#'  
#' HPCs (High Performance Computers), Clusters, or 'SuperComputers' are really just a bunch of smaller computers networked together.  
#'  Some Definitions:  
#'  
#'* **Processor**: Does things with data. Processor may contain 1-many **CPU**S. A CPU is usually a chip which may have several microprossesors or **cores**.
#'* **Memory**: Fast storage for data **RAM**. R is a reknowned RAM-hog because it tends to load all data into memory (vs. keeping some on the disk)
#'* **Node**: a "computer" which combines processors and memory. Clusters consist of many nodes networked together. When you request resources from a cluster, you usually specify the number of nodes needed
#'  
#' ![from https://hpcportal.cr.usgs.gov/hpc-user-docs/](memory.png)  
#'  
#' There are two major types of architectures: **Distributed memory** and **Shared Memory**. Most Clusters contain both distributed and shared partitions.  The type of architecture determines what type of software is typically used to parallelize a program.  

#+ echo=FALSE

df <- data.frame(" " = c( "description", "example", "software for communication", "R packages"), 'Distributed' = c( "Separate 'nodes' with processors and private memory networked together", "SUMMIT cluster", "'MPI': Message Passing Interface'", "Rmpi, pdbMPI, snow, rredis"), "Shared" = c( "All processors have access to same memory", "Desktop computer, 'BigMem' partitions", "OpenMP", "Rdsm, pnmath"))
names(df)[1] <- ' '
knitr::kable(df)


#'  
#' Desktop computers are shared-memory systems. The CPU and all of its processors have access to the same memory bank. As the number of processors grows in a cluster, it is sometimes more efficient to have memory specific to one set of processors. The combination of processor + memory is a **node**.  
#'  
#'  On a cluster, jobs are executed by submitting a script and requesting resources (processors, memory, and time) from a workload manager, which determines who gets access to what resources when. A common workload manager is **SLURM**, or Simple Linux Utility for Resource Management.  

#'  
#'  
#' ## Parallelization

#' \*A task can run in **parallel** if the inputs of one operation are **independent** of the outputs of the other operations
#'  An example of a **parallel** task:

# Picking 100 random numbers

  out = c()

  for(i in 1:100){
    out[i] <- rnorm(n = 1)
  } 

#' An example of a **serial** task:

  out = c()
  j = 0

  for(i in 1:100){

    # Pick a random number
     n = rnorm(n = 1)
     
    # If previous number was <= 0, multiply by 2
     if(j <= 0) {
        n = n*2
    
    # else multiply by .5
    } else {
        n = n*.5
     }

    out[i] <- n
    j <- n

  }
#' Each loop from the first example could be assigned to 100 different computers. The computers could all run their code at the same time and then later combine the result. This is essentially the principle of cluster computing.  
#'  
#' In the second example, each loop depends on the output from the previous loop (e.g. whether the number was positive or negative). This operation cannot be sped up by breaking the problem up into separate parts and running them at the same time  

#'  
#' In these examples, the operation is trivial and runs very fast on one computer (or 1 core). It would not be efficient to split the first example among different computers because it would take more time to send the results back and forth than to just compute it on one machine. But for bigger tasks the time saved running in parallel can be huge  
#'  



#' # Requesting an account

#' Many (most?) Universities and Government Agencies either maintain or have access to HPC resources. 
#' The USGS has its own HPC cluster [Yeti](https://www.usgs.gov/core-science-systems/sas/arc/machine-access). You can request an account by emailing them
#' [XSEDE]( also has a platform available to university and non-profit researchers to request allocations on various supercomputers around the country.  
#' Each system should have some documentation about how to securely access resources.   
#'  

#' # Logging in

#' Windows: use [Putty](https://www.putty.org/).  Enter your `username@host.ip.address` in the hostname, select the correct port (usually 22) and click open  
#'  
#' ![](putty.png)  
#'  
#' Mac and linux can start an ssh session directly from the terminal by entering `ssh username@host.ip.address`
#'  
#'  Once you are logged in, everything will be UNIX. Time to embrace it. [This](http://www.physics.louisville.edu/williger/Astronomybootcamp/Unix_tutorials/Tenminuteunix/tenminuteunix.pdf) is a pretty good introduction/cheat sheet  
#'  
#' Also check out [tips](https://medium.com/@tzhenghao/a-guide-to-building-a-great-bashrc-23c52e466b1c) on setting up your **~/.bashrc** script file, which is executed every time you log in. You can put nifty shortcuts in there  
#' Here is an example of what mine looks like:  

#' ```
#'# load modules  
#'module load python/2.7.8-gcc  
#'module load R/3.6.1-gcc7.1.0  
#'module load gdal/2.2.2-gcc proj/5.0.1-gcc-7.1.0 gcc/7.1.0  
#'module load gis/geos-3.5.0  
#'  
#'# check on jobs  
#'alias sq="squeue -u sfick" # check on jobs  
#'alias histALL='sacct --starttime 2014-07-01  --format=JobID,Jobname,partition,state,start,end,elapsed,MaxRss,MaxVMSize,nnodes,ncpus,nodelist'  
#'alias hist='sacct --starttime $(date --date="$1 day ago" +%Y-%m-%d)  --format=JobID,Jobname,partition,state,start,end,elapsed,MaxRss,MaxVMSize,nnodes,ncpus,nodelist'  
#'alias ljob='cat $(ls *.out | tail -1)'  
#'  
#'# shortcuts to change working directory  
#'alias gis='cd /path/to/GIS/storage'  
#'alias out='cd /path/to/outputs/'  
#'alias dart='cd ~/path/to/dartcode'  
#'  
#'# generate a template batch file
#'alias batch='cp ~/templates/batch.sh .'  
#'# request an interactive allocation
#'alias alloc='salloc -p normal -A swbsc -N 1 --mem 16GB -t 00:30:00'  
#' ```



#' # Transferring code & files
#'  
#'* If your HPC allows it, using SFTP is the fastest way to transfer data to and from your local machine. [Filezilla](https://filezilla-project.org/) is a useful tool for this.
#' For more secure servers, you may need to use a client such as [globus](https://www.globus.org/data-transfer)
#'  
#'* It would also be good to set up version control for all code with **git**. Hosting code on a service like [github](https://github.com) is another way to transfer code between your local and remote terminal  
#'
#'* Finally, for downloading files from the internet checkout the (built-in) linux utilities `wget` or `curl`  
#'  



#' # Configuring R  
#'* Most systems should have R. You may have to make R available with the `module` function. In the `~/.bashrc` script above, modules for python, R and GDAL are loaded automatically at login  
#'* you can check for available modules with the `module avail` syntax, as in `module avail R`  
#'* To start R in linux you simply type `R`<enter>. If it is your first time you'll want to install your preferred packages. These should be downloaded to a local folder you own, and the packages should become available to all the nodes in the system.  
#'  
#'  
#' ## Setting up R scripts to run from the command line
#'  It is often possible to run R scripts 'interactively' (like in R-Studio) on the cluster, but it is more common to set them up to run from the command line. In this case you simply invoke `Rscript name-of-your-script.R` in the terminal and all of the code inside is executed automatically.  In most cases existing R scripts will run just fine from the command line. For instance this script...   
#'```r
#'  # example.R
#'  # Simple R Script
#'  getwd()
#'  x <- TRUE
#'  cat( 'x is', x, '\n')
#'```
#'  
#'  Invoking `Rscript example.R` will produce the following output:
#' ```
#'  [1] "/home/sfick"
#'  x is TRUE
#'```
#'  
#'  Notice how the working directory will always be where the script was invoked from. This is different from Windows, where R's default working directory is always the same (often `C:/Users/Username/Documents/`)
#'  
#'  We may often be interested in changing one or several variables in this script, from the outside. This is useful for batch jobs where we want to invoke the script many times in parallel, each time working with a slightly different set of starting values. This can easily be done with the `commandArgs` function:  
#'  
#'```r
#'  # exampleCLA.R
#'  # Simple R Script using command line arguments
#'  
#'  args <- commandArgs(trailingOnly = TRUE)
#'  getwd()
#'  x <- args[1]
#'  cat( 'x is', x, '\n')
#'```
#'  
#'Invoking `Rscript exampleCLA.R kanye` produces:
#' ```
#'  [1] "/home/sfick"
#'  x is kanye
#'```  
#'  
#' You can pass as many command line arguments as you want
#'```r
#'  #manyArgs.R
#'  args <- commandArgs(TRUE)
#'  for(arg in args){ cat(arg,' <clap>') }
#'```
#'  
#'  `Rscript manyArgs.R when you try hard you die hard`
#'  
#'  ```
#'  when <clap> you <clap> try <clap> hard <clap> you <clap> die <clap> hard <clap>
#' ```
#'  
#'  




#' # Requesting resources from SLURM
#'  
#'  Computing time and resources are requested from the Simple Linux Utility for Resource Management (SLURM). There are three major ways of requesting resources for a job:  
#'  
#'* `salloc`: Request an **interactive** job. This will 'log you in' to the selected resource, then you can either invoke your Rscripts or start an R session and execute your commands one-by-one  
#'* `srun`: Requests to run its command on the next available resource. Typically only used for quick tests or to initiate individual processes within a `sbatch` batch job
#'* `sbatch`: request resources and execute commands in a batch file. When resources are available, the batch file is loaded on all the nodes requested
#'  
#' ## Important SLURM parameters
#'* `-N` or `--nodes`: Minimum number of **nodes** (computers) to run a job
#'* `-n` or `--ntasks`: Specifies the number of **processes** to be run in parallel at any given time. Usually equivalent to the number of 'cores' needed 
#'* `-t` or `--time`: Total amount of time needed. Your job will be cancelled if it exceeds this limit. Asking for too much time may delay the start of your job. 
#'* `-p` or `--partition`: Which part of the cluster you want to run on (large memory, normal, long-walltime, etc)
#'* `-J` or `--job-name`: Name for your job (visible to all)
#'* `-A` or `--account`: Mandatory for Yeti. This tracks usage by research group
#'* `-o` or `--output`: Name for the log file. Use `%` wildcards to substitute the job or array id, e.g. `jobNumber_%j` or `arrayJob_%A_%a`
#'* `-a` or `--array`: Submit multiple jobs by index number. Ex: `--array:1-10` will submit 10 jobs, each with a global variable named $SLURM_ARRAY_TASK_ID ranging from 1-10. This variable can be passed to scripts to change the initial parameters. 
#'* `-m` or `--mem`: How much memory is requested. E.g. `16G` means 16 gigabytes  
#'  
#' ## Interactive jobs
#'  
#'  It is usually **not** a good idea to try any heavy computations directly from the terminal when you login. Thats because these 'login' nodes have little memory and cpu power. Accidentally crashing a login node is no bueno for everyone else.
#'  
#'  The best way to experiment with code is to request an interactive session with salloc and test your code there. The following requests access to a node for 30 minutes, with 16 gb of ram:  
#'`salloc -p normal -A swbsc -N 1 --mem 16GB -t 00:30:00`  
#'  
#'  To avoid typing this frequently I've added an alias in my ~/.bashrc file
#' ```
#' alias interactive='salloc -p normal -A swbsc -N 1 --mem 16GB -t 00:30:00'`  
#' ```
#'  So that I can just type `interactive` and get the same result
#'  
#'  
#' ## Batch jobs
#'  
#'  Batch jobs are the most common way to request resources from SLURM. They require a little bit of overhead to set-up, and can be a bit of a shell game.  
#'![](shell.png)  
#'  
#'  Slurm batch scripts look like the following  
#' ![](batch.png)
#'  
#'  I created a template batch file as above in my `~` directory and created a shortcut to copy this file to wherever I'm working, using `~/.bashrc`:  
#'  `alias batch='cp ~/templates/batch.sh .'`  
#'  
#' Batch jobs are submitted simply as follows:  
#' `sbatch path/to/mybatchfile.sh`  
#' If this fails because of a permissions error may have to make the batch file executable by running: `chmod +x mybatchfile.sh`  
#'  
#'  
#' # Monitoring
#'  There are several ways to check on the status of our jobs.  
#'  
#' #### sbatch
#'  typing `squeue` in the console shows all active and pending jobs  
#' ![](squeue.PNG)  
#'  
#'  We can focus on just our jobs with `squeue -u my-username`. I use this command so often I've added it to my `~/.bashrc` file as: `alias sq="squeue -u sfick"`  
#'  
#'  ![There it is](sq.png)  
#'  
#'  Note: If you're not sure your username you can type `whoami` in the unix console.
#'   
#'  
#' #### Log files 
#'  We specified above that console output from our batch scripts would be saved as `serialJob%j.out`, where `%j` represents the slurm job id.  
#'* We can read this with the `cat` command as in `cat serialJob12345.out`.  
#' ![](cat.png)  
#'  
#'* We can also 'follow' the output as its being written with `tail -f serialJob12345.out`. `<Ctr>-c` will exit from this view. 
#' 
#' 
#' #### History
#' `sacct` provides job history. The following looks at jobs from the last day (also in ~/.bashrc):  
#' `sacct --starttime $(date --date="$1 day ago" +%Y-%m-%d) --format=JobID,Jobname,partition,state,start,end,elapsed,MaxRss,MaxVMSize,nnodes,ncpus,nodelist`
#'  
#'  ![](hist.png)  
#'  
#' # Visualization
#'  
#'* You can view R plots (often very slowly) if [x11 forwarding](http://www.cs.umd.edu/~nelson/classes/utilities/xforwarding.shtml) is enabled in your ssh client, and (in windows) a utility such as [xming](https://sourceforge.net/projects/xming/?source=typ_redirect) is enabled.
#'* On Yeti, there are special [visualization](https://hpcportal.cr.usgs.gov/enginframe/sgi/sgi.xml) nodes. You can create a remote-desktop link to these nodes. Details [here](https://hpcportal.cr.usgs.gov/docs/wiki/vizualizationServer/index.html)  
#'  


#' # Examples: Geoprocessing

#' One type of application where parallelization can be particularly helpful is in **geoprocessing**. Often these problems can be split into many 'smaller' tasks which can be run in parallel.  
#'  
#' For example, say we have built a randomForest model predicting Temperature Seasonality from other bioclimatic variables

  library(raster)
  
  # download bioclim
  bio <- getData('worldclim', var = 'bio', res = 10)
  
  # generate pretend dataset
  set.seed(1984)
  dat <- sampleRandom(bio, 1000)
  
  # build a randomForest model to predict Temperature Seasonality (bio4) from other variables
  library(randomForest)
  rfm <- randomForest( bio4 ~ ., data = dat)
  rfm

#' preeety good  
#'  
#' ## Example 1: Serial

#' Now we may want to generate predictions of temperature seasonality for the whole world.  
#'  
#' #### On the Desktop
#' On a desktop this process could be run (serially) with the following:
#+ cache=TRUE
  system.time( out <- predict(bio, rfm))

#' Here is (sort of) how predictions would occur in **serial**
#+ echo=FALSE
  vir <- colorRampPalette(c("#440154FF", "#481567FF", "#482677FF", "#453781FF", "#404788FF",
 "#39568CFF", "#33638DFF", "#2D708EFF", "#287D8EFF", "#238A8DFF", "#1F968BFF", "#20A387FF",
 "#29AF7FFF", "#3CBB75FF", "#55C667FF", "#73D055FF", "#95D840FF", "#B8DE29FF", "#DCE319FF",
 "#FDE725FF"),bias = 2)
  
  plot( bio[['bio1']] , col = vir(20))
  x1 <-c(-150, 150, -150, 150, -150, 150, -150)
  x2 <-c(150, -150, 150, -150, 150, -150, 150)
  yy <- seq(-50, 100,length.out = 7)
  arrows(x1,yy, x2, yy, lwd = 2, lty = 1, length = .15)
  arrows(x2[-7],yy[1:6] ,x2[-7] , yy[2:7], lwd = 2, length = .15)

#'  Raster pretty much makes predictions line by line, loading in as much data as memory will allow. This is inefficient if the dataset is much larger than what can be fit into memory  
#'  
#' #### On the Cluster
#'  
#'  Serial tasks can easily be run on a **cluster**. 
#' Perhaps it is not possible to parallelize your task, but it requires a decent amount of memory and time to run.
#'  
#'  `serial.R`:
#+ eval=FALSE
  start.time <- Sys.time()
  
  library(raster)
  
  # download/load bioclim
  bio <- getData('worldclim', var = 'bio', res = 10)
  
  # generate pretend dataset
  set.seed(1984)
  dat <- sampleRandom(bio, 1000)
  
  # build a randomForest model to predict Temperature Seasonality (bio4) from other variables
  library(randomForest)
  rfm <- randomForest( bio4 ~ ., data = dat)
  rfm
  
  out <- predict(bio, rfm, file = 'pred1.tif')
  
  print( start.time - Sys.time() )

#'  
#'  We can create a batch file `batchSerial.sh` as follows:  
#+ eval=FALSE
#!/bin/bash

#SBATCH --job-name=serial
#SBATCH --partition=normal
#SBATCH --account=swbsc
#SBATCH --time=01:00:00
#SBATCH --output=serialJob%j.out
#SBATCH --mem=16G

echo "SLURM_JOBID: " $SLURM_JOBID
echo "Scratch: " $GLOBAL_SCRATCH

module load R/3.6.1-gcc7.1.0
module load gdal/2.2.2-gcc proj/5.0.1-gcc-7.1.0 gcc/7.1.0
module load gis/geos-3.5.0

Rscript serial.R

#'  
#' We can submit as follows  
#'```
#'sbatch batchSerial.sh
#'```
#'  
#' ## Example 2: Built-in Parallel
#' 
#' #### On the Desktop (multi-core)
#' Alternatively we could use raster's **built-in** parallelization framework to take advantage of our multi-core desktop machine  
#' Here I execute the same task in parallel, taking advantage of 4 cores
#+ cache=TRUE

  # predict in parallel
  beginCluster(n = 4)
  system.time( out <- clusterR(bio, raster::predict, args= list(model = rfm)))
  endCluster()

#' We can see that there's a bit of a speed up. The speed-up will be related to how many cores are available on the machine. There may be some 'overhead' time costs of setting up communication among the cluster, demonstrated by the fact that the process was not 4 times faster than serial.  
#'  
#+ echo=FALSE  
  plot( bio[['bio1']] , col = vir(20))
  yy <- seq(-50, 100,length.out = 4)
  arrows(rep(-150, 4),yy, rep(150, 4), yy, lwd = 2, lty = 1, length = .15)
  
#'  
#' This same process can be performed on a **distributed** cluster, requesting multiple nodes (and multiple 'cores' or processes per node). However there are at least two downsides to this approach:  
#'  
#'1.  Distributing the work across an MPI (distributed) cluster requires **extra coding** in MPI and can be a bit tricky  
#'2.  Requesting a **large amount of resources** at the same time (i.e. multiple nodes) may be difficult if many other users are on the cluster. Often there are some beastly genomics jobs hogging many nodes and running for days. Don't be like them if you can help it! Below I outline a way that takes advantage of resources as they become available.  
#'  
#' On the desktop, neither of these methods took long. However if the dataset were much larger, or the process much more complex (e.g. cropping, transforming, then predicting with a complex model with many more predictors), this could become really slow.  
#'  
#' #### On the Cluster
#'  `par.R`
#+ echo=FALSE, eval=FALSE
"https://hpcc.usc.edu/support/documentation/r/parallel/"
"https://www.osc.edu/~kmanalo/r_parallel"
#'
#+ eval=FALSE 
 library(raster)
  
  # download bioclim
  bio <- getData('worldclim', var = 'bio', res = 10)
  
  # generate pretend dataset
  set.seed(1984)
  dat <- sampleRandom(bio, 1000)
  
  # build a randomForest model to predict Temperature Seasonality (bio4) from other variables
  library(randomForest)
  rfm <- randomForest( bio4 ~ ., data = dat)
  rfm

  # predict in parallel
  library(parallel)
  cores <- detectCores()
  cores
  myCluster <- makeCluster(n = cores)
  system.time( out <- clusterR(bio, raster::predict, args= list(model = rfm), cl = myCluster))
  stopCluster(myCluster)

#' Our batch script `batchPar.sh` looks like this:  
#+ eval=FALSE
#!/bin/bash

#SBATCH --job-name=par
#SBATCH --partition=normal
#SBATCH --account=swbsc
#SBATCH --time=00:10:00
#SBATCH --output=parJob%J.out
#SBATCH --ntasks=36
#SBATCH --mem=32G

echo "SLURM_JOBID: " $SLURM_JOBID
echo "Scratch: " $GLOBAL_SCRATCH

module load R/3.6.1-gcc7.1.0
module load gdal/2.2.2-gcc proj/5.0.1-gcc-7.1.0 gcc/7.1.0
module load gis/geos-3.5.0
module load openmpi/1.8.8-gcc

mpirun -n 1 Rscript par.R 

#'  
#' submit: `sbatch batchPar.sh`
#'  
#' ## Example 3: DIY Parallel ('swarm')
#'  
#' In the previous method, we let R handle much of the parallelization 'overhead' : splitting the task into separate jobs, assigning jobs to processors, then combining these outputs at the end. An alternative method I have used for larger geospatial problems on the cluster is to basically manage the parallelization ourselves -- e.g. splitting the target area into 'chunks', submitting independent jobs for each chunk, and combining the results at the end.  

#'![](grid.png)
#'  
#' Breaking the job into multiple, smaller chunks makes each process run faster. An advantage of this technique on an HPC cluster is that it will not request a large amount of resources at any given time, and the job will run as fast as free workers become available.  
#'  

#'  Next lets see how to implement this on a cluster
#'  
#'  Here we will re-format our job request as a job array, submitting many independent jobs to slurm. 
#'  

#' First we need a function that will take a single number and return the bounding box for the tile of interest. We will use this to let each worker in our cluster know what to focus on by passing only a single argument (the tile number, derived from the job array id).  
#'We can save it in a file called `splitter.R`  
#+ eval=FALSE

  getBounds <- function(r, tile_number, nx = 6, ny = 6){
      # r = raster
      # tile_number = tile of interest
      # nx = number of columns
      # ny = number of rows
      
      
      # sanity
        if(tile_number > nx*ny) stop(' tile number must be less than nx * ny')
        if(!all(c(tile_number, nx, ny) > 0)) stop('params must be > 0')
        
      # get column and row number
         y = ceiling( tile_number / nx)
         x =  tile_number %% nx
         if(x==0) x = nx
         
      # split into tiles
         
         # function to split vector x into equal groups of size n
         cfun <- function(x, n) as.numeric(cut( 1:x, n ))
         
         # get boundary of each column
         cols <- which(x == cfun( ncol(r),nx))
         cz <- xFromCol(r, cols)
         
         # add 1 pixel width buffer
         c0 <- min(cz) - 1 * res(r)[1]
         c1 <- max(cz) + 1 * res(r)[1]

         # get boundaries of each row
         rows <- which(y == cfun( nrow(r),ny))
         rz <- yFromRow(r, rows)
         
         # add 1 pixel buffer
         r0 <- min(rz) - 1* res(r)[2]
         r1 <- max(rz) + 1* res(r)[2]
         
         return( extent( c( c0, c1, r0, r1) ))
         
  }

#' To be more efficient we will also fit our model in a separate step. This script must be run before the batch request is sent off  
#'  `model.R`
#'  
#+ eval=FALSE
  
  # download/load bioclim
  bio <- getData('worldclim', var = 'bio', res = 10)
  
  # generate pretend dataset
  set.seed(1984)
  dat <- sampleRandom(bio, 1000)
  
  # build a randomForest model to predict Temperature Seasonality (bio4) from other variables
  library(randomForest)
  rfm <- randomForest( bio4 ~ ., data = dat)
  rfm
  save(rfm, file= 'model.RData')

#'  
#'  Our processing script looks like this: 
#'  `swarm.R`  
#+ eval=FALSE

  start.time <- Sys.time()

  library(raster)
  library(randomForest)

  # load our splitter function
  source('splitter.R')

  # load our fit model
  load('model.RData')
  
  # find out which tile we need to process  
  args <- commandArgs(TRUE)
  tile_no <- as.numeric(args[1]) # tile number is first argument
  nx <- as.numeric(args[2]) # number of columns is second argument
  ny <- as.numeric( args[3] ) # number of rows is third argument
  
  #specify our output directory for tiles
  outdir <- 'tiles'
  if( !dir.exists(outdir )) dir.create(outdir)
  
  # specify out output file name
  outfile <- file.path(outdir, paste0( tile_no, '.tif') )
  
  # don't waste time if file already exists
  if(file.exists(outfile)) stop( 'file already exists' )
    
  # load bioclim
  bio <- getData('worldclim', var = 'bio', res = 10)
  
  # crop to desired extent
  ext <- getBounds(bio, tile_no, nx, ny)
  b <- crop(bio, ext, progress= 'text')
  
  # predict
  predict(bio, rfm, file = outfile, progress = 'text')
  
  print( Sys.time() - start.time )

#'  
#' Our batch script `batchSwarm.sh` looks like this:  
#+ eval=FALSE
#!/bin/bash

#SBATCH --job-name=swrm
#SBATCH --partition=normal
#SBATCH --account=swbsc
#SBATCH --time=00:10:00
#SBATCH --output=logs/swarmJob%A_%a.out
#SBATCH --array=1-36
#SBATCH --mem=16G

echo "SLURM_JOBID: " $SLURM_JOBID
echo "SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID
echo "SLURM_ARRAY_JOB_ID: " $SLURM_ARRAY_JOB_ID
echo "Scratch: " $GLOBAL_SCRATCH

module load R/3.6.1-gcc7.1.0
module load gdal/2.2.2-gcc proj/5.0.1-gcc-7.1.0 gcc/7.1.0
module load gis/geos-3.5.0

mkdir logs
Rscript swarm.R $SLURM_ARRAY_TASK_ID 6 6

#'  
#' which we invoke with  
#'```sh
#'sbatch batchSwarm.R
#'```
#'  
#'  Once our jobs are done, we need to combine our results. In the console:  
#'```sh
#'# check that we have all of our output files (should be 36):
#'ls -l tiles | wc -l
#'
#'# Merge tiles with gdal (R would also work)
#'gdalbuildvrt out3.vrt tiles/*
#'gdal_translate out3.vrt pred3.tif
#'rm out3.vrt
#'```


#' # Other resources 

#' https://cran.r-project.org/web/views/HighPerformanceComputing.html


