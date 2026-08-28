# Evaluating Ex Situ Supplementation Strategies

This tutorial will cover how to run the `exsitu.slim` model as a means for evaluating the *ex situ* conservation breeding population, including the effects of adding new founders under a variety of supplementation strategies. This script uses sequence data from a VCF file to initialize the starting population. This step requires both the VCF file and a sample list to be accessible to the script. These files can be found on [box](https://sandiegozoo.box.com/s/q2zevmka3mr4amou73edg7bkv2s9yuap). This tutorial will also make use of the accessory file `ex-situ-parameters.json` which can be found in the [accessory-scripts](../acccessory-scripts/) folder. Make sure the SLiM program is accessible in your current environment.

##### Tutorial Sections
1. [Model Overview](#1-model-overview)
2. [Running the default simulation](#2-running-the-default-simulation)
3. [Adding founders and releases](#3-adding-founders-and-releases)
4. [Comparing supplementation scenarios](#4-comparing-supplementation-scenarios)

<br>

## 1. Model Overview
The model starts by reading in the VCF file, containing sequence information for all the founders. Using the sample list, it will break up the individuals into different founder cohorts. During the first 18 simulation ticks, it will add in each of these founder cohorts according to the year they were actually added to the *ex situ* population. At that point, the population should be a fairly close representation of what the actual *ex situ* population looks like today. 

Following these steps, two options are available to add to the model:  
1. **Add new founders to the population**: This is modeled by recycling the founder individuals. Four individuals are randomly selected from one of the wild population, iterating through a different wild population each supplementation.
2. **Release individuals back into the wild**: This step will randomly select individuals (who themselves were not founders and are younger than three years old), and remove them from the population. This step is intended to mimic the reintroduction of individuals back into the wild as either a reintroduction effort or a translocation for genetic rescue. 

Statistics are tracked throughout the simulation to evaluate population size, heterozygosity, and runs of homozygosity depending on the supplementation and release parameters. We can use these statistics to determine how to optimally supplement the *ex situ* population, and determine a sustainable number of individuals to be released each year, while maintaining heterozygosity and avoiding inbreeding.

<br>

## 2. Running the default simulation
A default model, where no additional founders are added, and no individuals are released, provides us with a baseline measure of how quickly diversity is lost from the *ex situ* population. 

All of our adjustments to the model parameters will take place inside the accessory script `generate-exsitu-configs.sh`. First, in a text editor, ensure that the `founderVariants` and `sampleMap` parameters point to the correct files on your system, the VCF file and sample list, respectively. Then, lets double check that the translocation and reintroduction parameters are set so that neither occur. Open the shell script and check the following parameters: 

```json
"track_reintro": "F",
"trans_size": 0,
"trans_freq": 2,
```
Most importantly, make sure `trans_size` is 0. Next, check that the `Supplemental_times` parameter includes only the four supplements used to form the current *ex situ* population (5, 9, 15, 17). 
```json

"Supplemental_times": [5, 9, 15, 17],
```

The file we've been editing can now be used to pass all of our parameters to SLiM at once. Because we will want to account for variation in the model, it's important that we run lots of replicates of the simulation, likely 100-200. We'll make a new subdirectory, lets call it "NoSupplements", to house all of the results from our default model, and place this `.json` file inside to record what our parameter settings were for these runs. We can then navigate into this new directory and run our replicates using a for loop:
```bash
mkdir NoSupplements
cp ex-situ-parameters.json NoSupplements/
cd NoSupplements

for i in {1..100}; do
	slim -d "jsonParams='ex-situ-parameters.json" ${path/to/exsitu.slim} > Rep${i}_stats.txt
done
```

This could take awhile, so it might be better to break this up in to a handful of small loops and run them in parallel. Once complete, we can use the R script `plot-ex-situ.R` to visualize how heterozygosity declines over the next 50 years. First, set the correct path to your general working directory, and set the `scenarios` list to include just our `NoSupplementation`folder. For now, `dirs` will be empty. Set these variables, then run the code through the first ggplot command.
```r
scenarios = c("NoSupplements")
dirs=c("")
```
<p align="center"> 
	<img src="../misc/Pasted image 20260828093914.png" width="500"> 
</p>

We can see that heterozygosity declines quite a bit. For reference, the sloping dashed line represents a loss of 10% of starting heterozygosity over 100 years, a common benchmark rate for *ex situ* populations. 

It will likely be desirable to set up different combinations of supplementation and releases to assess potential interactions. This can be achieved by creating additional subdirectories within "NoSupplements", and further modifying the `.json`  with various `trans_size` arguments. The next section will walk through the adjustments to the configuration file and directory structure to run simulations that include both supplementation to the ex situ population and yearly releases of mice into the wild.

<br>

## 3. Adding founders and releases
We'll start by structuring our working directory to keep our results organized. For this example, we'll test three different supplementation frequencies (every year, every other year, and every four years), and within each strategy, we'll test releases of 30, 50, and 80 individuals. We can nest the release subdirectories within each supplementation directory: 
```bash
for i in FourYearSupplements  NoSupplements  TwoYearSupplements  YearlySupplements; do
	mkdir ${i}
	cd ${i}
	mkdir ReleaseN30 ReleaseN50 ReleaseN80
	cd ../
done
```
to get a folder structure that looks something like this:
```bash
├── FourYearSupplements
│   ├── ReleaseN30
│   ├── ReleaseN50
│   └── ReleaseN80
├── NoSupplements
│   ├── ReleaseN30
│   ├── ReleaseN50
│   └── ReleaseN80
├── TwoYearSupplements
│   ├── ReleaseN30
│   ├── ReleaseN50
│   └── ReleaseN80
└── YearlySupplements
    ├── ReleaseN30
    ├── ReleaseN50
    └── ReleaseN80
```

This structure is one that is compatible with some of the downstream R scripts for visualizing the results from these simulations. We can now adjust the parameters file to create each one of the above scenarios. As an example, we'll set the two year supplement and 50 individual release scenario. Starting with the release size, we can set `trans_size` and `trans_freq` to 50 and 2, respectively (frequency is set in seasons, not years, and will happen once each year):
```json
"track_reintro": "F",
"trans_size": 50,
"trans_freq": 2,
```

We can now set the supplementation times. This is defined using the `Supplementation_times` parameter and simply lists the simulation tick that a supplementation should occur. We'll also set `recycle=T` to continuously cycle through the wild populations one at a time for supplementation.
```json
"Supplemental_times": [5, 9, 15, 17,21, 25, 29, 33, 37, 41, 45, 49, 53, 57, 61, 65, 69, 73, 77, 81, 85, 89, 93, 97],
  "recycle_supplements": "T"
```

In the future, this will be adjusted so it isn't such a pain to set a reoccurring introduction frequency, but for now each one needs to be set manually. Here we leave the four original introductions setting up the current *ex situ* population (5, 9, 15, 17), then add a reintroduction every four ticks (two years) following. This parameter file can now be copied into the `TwoYearSupplements/ReleaseN50` directory, and parameter files for all the other scenarios can be set up accordingly. Run replicates for each scenario, then move on to the next section to compare results across all supplementation and release combinations.

<br>

## 4. Comparing supplementation scenarios
With replicates completed for all scenarios, we can pull up our R script to summarize the results across all of them. We'll start by adjusting the `Scenarios` and `dirs` variables. Here, We'll plot just the supplementation scenarios with 50 replicates each:
```r
scenarios = c("FourYearSupplements","TwoYearSupplements","YearlySupplements")
dirs=c("ReleaseN30","ReleaseN50","ReleaseN80")

```
Run the code block to iterate through each scenario and each subdirectory, adding them all to common dataframe. The ggplot code is setup to plot heterozygosity and should look something like this:
<p align="center"> 
	<img src="../misc/Pasted image 20260828135132.png" width="500"> 
</p>
Again, we have a reference line showing the 10% per 100 generations line. In each panel we have a different supplementation strategy, and each colored line showing a different release size. We can also do this for inbreeding (measured as Froh) by adjusting the y axis variable in the ggplot command:
```r
ggplot(repstats,aes(x=Generation,y=Froh,color=Group,group=Group))+
  geom_smooth(span=1,alpha=0.25)+
  geom_abline(slope=-7.6e-7,intercept=0.001525,linetype="dashed",color="gray")+
  scale_color_manual(values = c("deepskyblue4","darkred","darkgoldenrod3","darkgreen","black"))+
  facet_wrap("Scenario")+
  labs(x="Seasons",y="Inbreeding (Froh)")+
  theme_bw()
```
Included in the script are a few lines that are commented out, but have been removed in the above code chunk. Those are additional plotting options that include things like showing all the points. The above block should return something like the following:

<p align="center"> 
	<img src="../misc/Pasted image 20260828135855.png" width="500"> 
</p>

Considering both the heterozygosity plot and the inbreeding plot, we see that there is little difference in the *ex situ* diversity between releasing 30 individuals each year and releasing 50, but there is a noticeable difference when releasing 80, suggesting this is likely too many individuals to release every year given the capacity of the breeding program. Supplementing every year or every other year also result in populations that stay relatively near or above the reference diversity line. 