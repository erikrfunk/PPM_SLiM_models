# Summarize a lot of reps
path="/home/centos/USS/erik/PPM/SLiMrescue/vcf_based_simulations/ExSitu/"
scenarios = c("FourYearSupplements","TwoYearSupplements","YearlySupplements")
dirs=c("ReleaseN30","ReleaseN50","ReleaseN80")
scenarios = c("NoSupplements","FourYearSupplements","TwoYearSupplements","YearlySupplements")
dirs=c("NoRelease","ReleaseN30","ReleaseN50","ReleaseN80")
scenarios = c("TwoYearSupplements")
dirs=c("MaxReleases")

repstats=NULL
for (s in 1:length(scenarios)){
for (d in 1:length(dirs)) {
  fins = list.files(path=paste0(path,scenarios[s],"/",dirs[d]),pattern="stats.txt",full.names = T)
  if(length(fins)!=0){
  for (i in 1:length(fins)) {
    slimstats = na.omit(read.csv(fins[i],sep=",",skip=40,header=T,stringsAsFactors = F,comment.char = "#"))
    slimstats$Scenario = scenarios[s]
    slimstats$Rep = paste0(d,"_",i)
    slimstats$Group = dirs[d]
    repstats = rbind(repstats,slimstats)
  }
  }
}
}
repstats$Generation = as.numeric(repstats$Generation)
repstats=repstats[repstats$Generation %% 2 == 0,]
repstats$Het_adj = repstats$Heterozygosity*(72600000/(66000000-(66000000*0.04)))
repstats$Scenario = factor(repstats$Scenario,levels=c("NoSupplements","FourYearSupplements","TwoYearSupplements","YearlySupplements"))

smooth_ribbon = function(df,col) {
  dat = df[,c("Generation","Rep","Scenario","Group",col)]
  res_names = c("Generation","Rep","Scenario","Group",col)
  simMin = setNames(aggregate(get(col)~Generation+Scenario+Group,data=dat,FUN = function(z) quantile(z,0.025)),res_names)
  simMinSmoothed = NULL
  for(i in 1:length(unique(dat$Set))){
    setMins = simMin[simMin$Set == unique(simMin$Set)[i],]
    loess_fit <- loess(setMins[,3] ~ setMins$Generation, span = 0.5)
    smoothed_min <- predict(loess_fit)
    smoothed_res = data.frame("Generation"=seq(1:max(dat$Generation)),
                              "Set" = unique(simMin$Set)[i],
                              "SmoothedMin" = smoothed_min)
    simMinSmoothed = rbind(simMinSmoothed,smoothed_res)
  }
  simMax = setNames(aggregate(get(col)~Generation+Scenario+Group,data=dat,FUN = function(z) quantile(z,0.975)),res_names)
  simMaxSmoothed = NULL
  for(i in 1:length(unique(dat$Set))){
    setMaxes = simMax[simMax$Set == unique(simMax$Set)[i],]
    loess_fit <- loess(setMaxes[,3] ~ setMaxes$Generation,span = 0.5)
    smoothed_max <- predict(loess_fit)
    smoothed_res = data.frame("Generation"=seq(1:max(dat$Generation)),
                              "Set" = unique(simMax$Set)[i],
                              "SmoothedMax" = smoothed_max)
    simMaxSmoothed = rbind(simMaxSmoothed,smoothed_res)
  }
  ribbon = merge(simMinSmoothed,simMaxSmoothed,by=c("Generation","Set"))
  #names(ribbon) = c("Generation","Set","SmoothedMin","SmoothedMax")
  ribbon$Set = as.factor(ribbon$Set)
  return(ribbon)
}

ggplot(repstats,aes(x=Generation,y=Het_adj,color=Group,group=Group))+
  #geom_point(alpha=0.15)+
  #geom_point(data=hets,inherit.aes = F, aes(x=Generation,y=Het_obs,size=3),shape=4)+
  #geom_line(stat="smooth",method="loess",aes(group=Rep),alpha=0.35)+
  geom_smooth(span=1,alpha=0.25)+
  geom_vline(xintercept=28,linetype="dashed",color="gray")+
  geom_abline(slope=-7.6e-7,intercept=0.001525,linetype="dashed",color="gray")+
  scale_color_manual(values = c("deepskyblue4","darkred","darkgoldenrod3","darkgreen","black"))+
  facet_wrap("Scenario")+
  #ylim(c(0.0009,0.00145))+
  labs(x="Seasons",y="Inbreeding (Froh)")+
  theme_bw()

# Check the extinction proportions
final_gens = aggregate(Generation~Scenario+Group+Rep,data=repstats,FUN=max)
final_pops = aggregate(PopSize~Scenario+Group+Rep,data=repstats[repstats$Generation>20,],FUN=min)
res = merge(final_gens,final_pops,by=c("Scenario","Group","Rep"))
res$Extinct = 0
res$Extinct[res$Generation < 100 | res$PopSize < 100] = 1
aggregate(Extinct~Scenario+Group,data=res,function(x) sum(x)/length(x))

# Explore ancestry
ggplot(repstats,aes(x=Generation,y=DPanc,group=Rep,color=Group))+
  geom_smooth(span=1,alpha=0.25)+
  scale_color_manual(values = c("deepskyblue4","darkred","darkgoldenrod3","darkgreen","black"))+
  facet_wrap("Scenario")+
  theme_bw()

# Investigate the breeders and offspring
breeders = read.csv("breeders.txt",header=T)
hist(breeders$Breeders)
hist(breeders$Offspring)

join_gens_by_year = as.data.frame(matrix(NA,nrow = nrow(breeders)/2,ncol=3))
names(join_gens_by_year) = c("Year","Pairs","Offspring")
for(i in 1:nrow(join_gens_by_year)){
  join_gens_by_year[i,1] = i
  young = sum(breeders$Offspring[c(((i*2)-1),i*2)])
  bpairs = sum(breeders$Breeders[c(((i*2)-1),i*2)])
  join_gens_by_year[i,2] = bpairs
  join_gens_by_year[i,3] = young
}
hist(join_gens_by_year$Pairs)

#Then investigate the stats
res1 = read.csv("ExSituNoRelease_rep1_stats.txt",header=T,comment.char = "#",skip = 18)
res1$rep = "NoRelease1"
res1$Group = "NoRelease"
res2 = read.csv("ExSituNoRelease_rep2_stats.txt",header=T,comment.char = "#",skip = 18)
res2$rep = "NoRelease2"
res2$Group = "NoRelease"
res3 = read.csv("ExSituReleaseN50_stats.txt",header=T,comment.char = "#",skip = 18)
res3$rep = "Release1"
res3$Group = "Release"
res4 = read.csv("ExSituReleaseN50_rep2_stats.txt",header=T,comment.char = "#",skip = 18)
res4$rep = "Release2"
res4$Group = "Release"

res = rbind(res1,res2,res3,res4)

ggplot(res,aes(x=Generation,y=Heterozygosity,group=rep,color=Group))+
  geom_line(alpha=0.5,stat = "smooth",method="loess",span=0.2)+
  geom_vline(xintercept=20,linetype="dashed",color="gray")+
  scale_color_manual(values = c("deepskyblue4","darkred","darkgoldenrod3","darkgreen","black"))+
  facet_wrap("Population")+
  theme_bw()

# An Froh table based on the empirical
frohs = data.frame("Generation" = c(2,3,4,5,6,7,8,9,10,11,12,13,14),
                   "Froh_obs"=c(0.152,0.092,0.076,0.078,0.055,0.051,0.064,0.056,0.056,0.067,0.064,0.069,0.06))
hets = data.frame("Generation"= c(2,3,4,5,6,7,8,9,10,11,12,13,14),
                  "Het_obs"=c(0.00154,0.00159,0.00159,0.00155,0.00154,0.00155,0.00155,0.00158,0.00157,0.00158,0.00155,0.00153,0.00150))
