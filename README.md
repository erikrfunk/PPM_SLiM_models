# Extinction probabilities and genetic rescue in Pacific pocket mouse

This repository contains scripts for SLiM models used to simulate various parts of the PPM system. See below for a more in-depth description of each script and their parameters. Finally, a set of accessory scripts used to run, analyze, and visualize results are included in the `accessory-scripts` folder and are briefly described below.

Also see the `tutorials` folder for examples of how to run some of these models.  

**Contents**:  
1. [Model Descriptions](#Model-descriptions-and-important-user-defined-parameters)  
	1.  [Full Metapopulation and genetic rescue](#Full-Metapopulation)  
	2. [Ex situ population and supplementation](#Ex-situ-population)  
	3. [Single Population Decline](#Single-Population-Decline)  
2. [Accessory scripts](#Accessory-scripts-used-for-analysis-and-visualization)  
	1. [Shell scripts and configuration files](#Shell-scripts-and-configuration-files)  
	2. [R scripts](#R-scripts)  

<br>

## Model descriptions and important user-defined parameters
All models for PPM treat SLiM's built in tick as a season, rather than a calendar year. We model two seasons per year: a breeding season and a winter season. The key interpretation for all these models is that **2 ticks = 1 calendar year**. 


#### Full Metapopulation 
A set of three scripts to simulate the combined wild and captive PPM system, starting from an ancestral population using a burnin, followed by the formation of the metapopulation, ending with population declines and the formation of the captive population. These scripts make up the core of the project, allowing the comparison of different translocation strategies for genetic rescue.  
Many of the parameters described for *`burnin.slim`* are general and used in all scripts. Additional parameters are listed for each of the subsequent scripts.


##### *burnin.slim*  
Used to burned-in the ancestral population prior to forming the metapopulation. This script is unlikely to be needed unless a new ancestral model state is needed. This could be the case if a new demographic models suggests a different ancestral population size. Otherwise, see the simulation state produced by this script in [Box](https://sandiegozoo.box.com/s/80sag63uzm1zaq8k4w19of3avqeome02).

Relevant parameters:  
- `K1`: Population size  
- `b`: Length of simulation in ticks (simulation steps/generations)  
- `samp_size`: Number of individuals to use when calculating summary statistics  
- `Q`: A scaling factor that reduces the population size while increasing mutation rate, selection, and recombination.  
- `outfreq`: How frequently statistics are output. Expressed in number of simulation ticks.  
- `rescaleOut`: If a scaling factor was used, this True/False can be set to indicate whether the simulated mutations should have their selection coefficients returned to unscaled values.  
- `resume`: When true, the simulation will expect an input file (see `fin` below), and will resume the burnin from the last saved state. The parameter `b` now becomes the number of additional ticks to run.  
- `fin`: A file name that defines a previous simulation state from which to continue. Must be used in combination with `resume=T`
- `winterMortality`: a fraction that defines the probability of an individual not surviving through the winter.  
- `L`:  A life table setting the probability of survival at each age class. Remember to consider two seasons per year.  

##### *form-metapopulation.slim* 
Using a burned-in ancestral population, this script forms the metapopulation by performing a series of population splits with user defined migration rates. This script is unlikely to be needed unless a different historical demography is needed. This could be the case if a new demographic models suggests a different ancestral population sizes, divergence dates, or migration rates. A simulation state produced by this script can be found on [Box](https://sandiegozoo.box.com/s/lfydt6gfh4m8xtsbv6ct4si80itkz7ff). 

Relevant parameters:  
*See the accessory script `run-form-metapopulation.sh` for easy parameter setting and an automated formatting of the command line.*  
- `fin`: Path to the saved simulation state from an ancestral burn-in.  
- `K1hist`: Historical population size of Dana Point  
- `K2hist`: Historical population size of South San Mateo  
- `K3hist`: Historical Population size of Santa Margarita  
- `K12anc`: Ancestral population size of populations 1 and 2  
- `divdate`: Number of simulation ticks *from the ancestor* before `K12Anc` should split in to `K1` and `K2`  
- `postdiv`: Number of simulation ticks the simulation should run following all population splits  
- `P1P3iso`: Number of simulation ticks before the present that migration should stop between populations 1 and 3  
- `P2P3iso`: Number of simulation ticks before the present that migration should stop between populations 2 and 3  

Also see a block of parameters that can alter the rates of migration between each pair of populations. Following FastSimCoal2 documentation, these are set as the probability of an individual in a sink population having ancestry from the source population. This means the number of migrants are estimated as the migration rate (m) times the sink population size (N)

##### *metapopulation-decline.slim* 
Run the metapopulation through a defined population bottleneck, including the formation of the captive population and optional translocations for genetic rescue. See the [tutorial](tutorials/ExtinctionProbability_tutorial.md) on how this script can be used to assess extinction probabilities and genetic rescue.

Parameters:  
*See the accessory script `run-metapopulation-decline.sh` for easy parameter setting and an automated formatting of the command line.*  

- `fin`: Path to the saved metapopulation simulation state.  
- `K1`: Current Dana Point population size  
- `K2`: Current South San Mateo population size  
- `K3`: Current Santa Margarita population size  
- `Kcb`: Carrying capacity of the ex situ conservation breeding population  
- `botgens`: Length of the bottleneck in simulation ticks. `botgens=1` is equal to an instantaneous bottleneck. Using more incrementally decreases population size throughout the bottleneck period.  
- `postbot`: Number of simulation ticks to simulate after populations reach their final bottleneck size.  

The following parameters apply to translocation scenarios.  
- `source`:  The population number (4 = ex situ population) to use as the source for translocation individuals.  
- `sink`: The population number(s) to use as the receiver of translocated individuals (this is the genetic rescue target population)  
- `trans_size`: Number of individuals to translocate.  
- `trans_freq`: Frequency that translocations will occur. This value is in ticks, not calendar years (`trans_freq=4` is equal to a translocation every other year).  

<br>

#### Ex situ population
##### *exsitu.slim*
This script utilizes sequence data from the individuals used to found the ex situ population. Simulating a single, medium sized chromosome (10), the script reads in a VCF file and a sample list of individuals. Model options include:
1. **Add new founders to the population**: This is modeled by recycling the founder individuals. Four individuals are randomly selected from one of the wild population, iterating through a different wild population each supplementation.
	- This option is controlled by the parameters `trans_size` and `trans_freq`.
2. **Release individuals back into the wild**: This option will randomly select individuals (who themselves were not founders and are younger than three years old), and remove them from the population. This step is intended to mimic the reintroduction of individuals back into the wild as either a reintroduction effort or a translocation for genetic rescue. 
	- This option is controlled by the parameters `trans_size` and `trans_freq`.

See the [tutorial](../tutorials/ExSituSupplementation_tutorial.md) on how this script can be used to assess supplementation and release strategies for the *ex situ* population.

Parameters
*See the accessory file `ex-situ-parameters.json` for easy parameter setting*

- `kcap`: Carrying capacity of the *ex situ* population
- `kwild`: Carrying capacity of the reintroduced population (if tracked)
- `gen`: Number of ticks to run the simulation (2 ticks per calendar year)
- `release_delay`: If releasing individuals, specify how long to wait after the formation of the population before releases occur.
- `track_reintro`: If releasing individuals, this option specifies whether or not statistics in the reintroduced population will be tracked.
- `trans_size`: Number of individuals to be released as reintroductions
- `trans_freq`: The frequency, in simulation ticks, that reintroductions occur
- `founderVariants`: Path to the VCF file containing sequence data for all founders
- `sampleMap`: Path to the sample list with cohort and population IDs for all founders
- `Supplemental_founders`: A list of all the supplemental founder cohorts. This should include all the names present in the second column of the `sampleMap` sample list. If new founder cohorts are added to the VCF file, the cohort name should be added to this parameter and to the sample list. Additionally, the `founderSize` parameter should be updated to reflect the total number of individuals in the VCF file.
- `Supplemental_times`: The simulation ticks that each supplementation will occur. If supplementation is to occur at a regular interval, each of the ticks should be written out in this list (for now, sorry!).
- `recycle_supplements`: If the number of supplemental times exceeds the number of supplemental founder cohorts, this should be set to T to allow the simulation to resample from each of the different "wild" source cohorts.
<br>

#### Single Population Decline
##### *single-population-decline.slim*
This script is primarily used during testing.  It takes a burned-in ancestral simulation state and imposes a user-defined bottleneck on only the single population, instead of first forming a metapopulation. 

<br>

## Accessory scripts used for analysis and visualization

#### Shell scripts and configuration files
##### *run-form-metapopulation.sh* 
A shell script with the most important user defined variables placed at the top. This script will automatically format the shell command and run the slim model to form the metapopulation. See the parameter descriptions listed above for the script [*form-metapopulation.slim*](#form-metapopulationslim). A valid ancestral simulation state must be provided, along with the path to the `FormMetapopulation.slim` script. Once formatted, an example run would be: 
```bash
chmod u+x Run-FormMetapopulation.sh
./Run-FormMetapopulation.sh > stats.txt  
```

##### *run-metapopulation-decline.sh* 
A shell script to run the bottleneck segment of the model. This script is set up and run similarly to `Run-FormMetapopulation.sh` described above.

##### *ex-situ-parameters.json* 
While the `ExSitu.slim` script does not have an associated shell script to format and run the simulation, the important user-defined variables can be set using this .json file as a template, then provided to the script as a command line parameter. See the parameter descriptions listed above for the script [*exsitu.slim*](#exsituslim). Once the parameters are set, an example command line would be:
```bash
slim -d "jsonParams='ex-situ-parameters.json'" ${path/to/exsitu.slim} > stats.txt
```

<br>

#### R scripts
##### *plot-slim-metapop-bots.R*
Plots a statistic such as population size or heterozygosity for all replicates of a bottleneck simulation. The plot is a multi-panel figure with one panel for each population, and a single line plotted for each simulation replicate.

##### *summarize-slim-metapop-bots.R*
Summarize the extinction probabilities from replicated simulations across multiple scenarios (i.e. different translocation sizes or frequencies)

##### *plot-ex-situ.R*
Plot ex situ statistics from replicates across multiple supplementation strategies.

##### *plot-slim-1pop-bots.R*
Mostly used during testing, but will plot statistics from replicates of a single population decline. This can combine runs across different scaling factors.
