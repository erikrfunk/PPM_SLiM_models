# Calculating Extinction Probabilities

In this tutorial, we'll run through an example of calculating an extinction probability using a previously generated metapopulation simulation state. We'll then run a scenario that uses translocations to test for genetic rescue. Before starting, download the simulation state from  [Box](https://sandiegozoo.box.com/s/lfydt6gfh4m8xtsbv6ct4si80itkz7ff). 

Scenarios:
1. [No Rescue](#no-rescue)
2. [Genetic Rescue of Dana Point](#genetic-rescue-of-dana-point)

<br>

## No Rescue
### 1. Set model parameters
Included with this repository is an accessory script that will help us set the model parameters and format the terminal command. The accessory script used here is [run-metapopulation-decline.sh](../accessory-scripts/run-metapopulation-decline.sh). Using a text editor, open the script and check the first two variables under `General run parameters`. Make sure these point to both the correct slim script and the correct saved simulation state.

For this run, we won't include any translocations, constructing a scenario that represents no management action. We will set this up by defining the translocation frequency to an arbitrarily large number that is beyond what our simulation will reach. As an example here, we'll set this to 1000.  Find the block of parameters related to translocations and set the `trans_freq` variable:
```
# Translocations
source=4
sink=1
trans_size=10
trans_freq=1000
```

Becuase a translocation will never occur in this scenario, the other parameters in this block don't matter and can be left as it. We'll also want to consider how long we want this simulation to run for. Two additional parameters can control this: `botgens` and `postbot`. Botgens is the length of the bottleneck itself - how many generations it takes to decline from the historical population size to the modern population size. Postbot is the number of generations to run after the population has decline. In the script, these are set to `botgens=10` and `postbot=100`, indicating it will take 10 simulation ticks for the population to decline, and then will run for another 100 ticks (50 calendar years).  These can be adjusted as desired but for now we will leave these as they are. 

### 2. Run the simulation
With the script adjusted, we are ready to run the simulation. We'll need to make sure SLiM is somewhere in our path. If you're working on an instance connected to the USS, you can activate the conda environment `slim4`, then set up a new directory to hold our model outputs and place the script inside.
```bash
conda activate slim4
mkdir NoRescue
cp run-MetapopulationDecline.sh NoRescue
cd NoRescue
```

We will want to run the simulation many times as a way to capture variation in the model, likely100-200 iterations. The easiest way to do this is to set up a loop that will run the script for each iteration. Each time the script runs, we can capture the output statistics into a text file.
```bash
for i in {1..100}; do
    ./run-MetapopulationDecline.sh > Rep${i}_stats.txt
done
```

### 3. View the results
After the replicates have all finished, your directory should have a separate stats file for each replicate. We can summarize and plot these iterations using the R script [plot-slim-metapop-bots.R](../accessory-scripts/plot-slim-metapop-bots.R). First, set the path to the `NoRescue` scenario directory. Then set the remaining variables to reflect the parameters that were used in the simulation:
```r
# Use this block to compare populations within a single scenario
fins = list.files(path=path,pattern="_stats.txt",full.names = T)
bottleneck_gens=10
post_gens=100
```
Run the lines of code following the variable definitions to loop through all the stats files. This will place all the results into a single dataframe, adjust the generations to begin at 1, and plot just the winter season values, instead of both summer and winter. The first block of ggplot code will include the bottleneck generations. To better view the post-bottleneck population sizes, the next few lines cutout these bottleneck generations. The ggplot command that follows will include a separate panel for each population, and a line for each replicate. The survival/extinction can be viewed by plotting PopSize in ggplot's y value, but this can also be changed to any of the other stats listed in the header of the file.

The command as listed should produce something like this:
```r
ggplot(endstats,aes(x=Generation,y=PopSize,group=Rep,color=Extinct))+
  geom_line(alpha=0.2)+
  facet_wrap("Population",ncol=1,scales = "free_y",labeller = labeller("Population" = pop_names))+
  scale_color_manual(values = c("deepskyblue4","darkred","darkgoldenrod3","darkgreen"))+
  labs(x="Seasons",y="Population Size")+
  theme_bw()
```

[](../misc/NoRescue_allPops.pdf)

The plot shows extinct replicates in red, and indicates high extinction probabilities for Dana Point and South San Mateo. Each set of replicates will be slightly different, so your result won't mirror this exactly. It should be close though. We can quantify the extinction probability using the next code block.

```r
# Calculate some statistics for each population
status = unique(endstats[,c("Population","Rep","Extinct")])
status$Extinct[status$Extinct=="Yes"] = 1
status$Extinct[status$Extinct=="No"] = 0
status$Extinct = as.numeric(status$Extinct)
res = aggregate(Extinct~Population,data=status, function(x) sum(x)/length(unique(status$Rep)))

extinctions = na.omit(endstats[endstats$Extinct=="Yes",])
ends = aggregate(Generation~Population+Rep, data=extinctions, FUN=max)
res2 = aggregate(Generation~Population,data=ends,FUN=mean)

merge(res,res2,by="Population",all = T)
```
Producing the table:
```r
Population Extinct Generation
1         p1    0.98   40.93878
2         p2    0.00         NA
3         p3    0.87   53.73563
4         p4    0.00         NA
```

Here we are given the proportion of replicates that go extinct (extinction probability) and the average generation that extinctions occur. The result is suggesting that Dana Point has a 98% extinction probability within the next 50 years (the length of the simulation post-bottleneck) and that extinctions on average happen at approximately year 20 (two simulation ticks per calendar year). 

In the next scenario, we will see how translocations from an ex situ population affect this extinction probability.

## Genetic rescue of Dana Point
### 1. Adjust the script for translocations
Returning to the original setup script, we can adjust the translocation parameters to create a scenario that reflects a genetic rescue attempt. Return to the parent directory and make a new one to represent this rescue strategy. In this scenario, we'll simulate the release of 12 mice into Dana Point every other year. So we can give our new directory an informative title:
```bash
cd ..
mkdir DP-rescue-N12-2year
cp run-metapopulation-decline.sh DP-rescue-N12-2year
cd DP-rescue-N12-2year
```

An assumption about these models is that the translocated individuals incorporate into the population readily. In reality, our best guess is that about half of the translocated mice likely won't make it to reproduction. So this strategy likely better represents a scenario of releasing 24 mice, rather than 12. We'll continue to call this scenario N12, but it is important to keep this in mind when translating results into management recommendations. With the directory set and the script copied, we can now define the translocation variables to reflect the rescue strategy.
```
# Translocations
source=4
sink=1
trans_size=12
trans_freq=4
```

The `source=4` indicates that we want to use the ex situ population (population 4) as the source for translocation individuals. The variable `sink=1` indicates that will be relocated into Dana Point (population 1). Finally, we indicate that we will move 12 individuals every 4 seasons (2 years).

### 2. Run the simulation
Just as we did above with the "No Rescue" scenario, we will iterate across 100 replicates and capture the statistics output by each replicate. This can be done using the same loop as above.

## 3. View the results
We can use the same R script as before to combine and visualize the results from this genetic rescue scenario. We can also subset the file to focus on Dana Point and compare how the extinction probability has changed. First extract Dana Point from the `endstats` dataframe. Then adjust the ggplot command so that the data argument equals this new `dp` dataframe:
```r
dp = filter(endstats,Population=="p1")
ggplot(dp,aes(x=Generation,y=PopSize,group=Rep,color=Extinct))+
  geom_line(alpha=0.2)+
  geom_vline(xintercept=c(33,35),"gray",linewidth=0.25,alpha=0.25,linetype="dashed")+
  facet_wrap("Population",ncol=1,scales = "free_y",labeller = labeller("Population" = pop_names))+
  scale_color_manual(values = c("deepskyblue4","darkred","darkgoldenrod3","darkgreen"))+
  labs(x="Seasons",y="Population Size")+
  theme_bw()
```


[](../misc/DP_rescue_N12Freq4_PopSize.pdf)

We can see that many more of the replicates are avoiding extinction. Finally, after calculating the probabilities table, we can see that this translocation strategy has reduced the extinction probability from 98% down to just 1%:
```r
  Population Extinct Generation
1         p1    0.01   63.00000
2         p2    0.00         NA
3         p3    0.91   53.24176
4         p4    0.00         NA
```

By running simulations for many different translocation scenarios, we can begin to get an idea of how both the number of individuals used during the translocation, and the frequency of translocation events, impacts the overall extinction probability of the population.