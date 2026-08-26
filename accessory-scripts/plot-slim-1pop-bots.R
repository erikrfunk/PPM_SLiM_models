# View multiple PostBot replicates
setwd("/home/centos/USS/erik/PPM/SLiMrescue/tests/final_scaling_tests/adjusted_ageMorts/adjusted_repro/standard_intervals/")
repstats = NULL
reps=100
botgens=1
postgens=98
prefix="N40kGens160k"
suffix="N100Bot1Post100"
Qs=c(1) # Define the set of Q values to visualize

for (j in 1:reps) {
  for (i in Qs){
    slimstats1 = read.table(paste0(prefix,"Q",i,"_",suffix,"/Rep_",j,"_stats.txt"),sep=",",skip=25218,header=T)
    slimstats1$ScaleType = paste0("Q",i)
    slimstats1$Rep = paste(i,j,sep="-")
    slimstats1$Generation = slimstats1$Generation - (slimstats1$Generation[1] + botgens)
    slimstats1$Q=i
    slimstats1$Extinct="No"
    slimstats1$Extinct[max(slimstats1$Generation)<postgens] = "Yes"
    repstats = rbind(repstats,slimstats1)
  }
}

repstats = filter(repstats,Generation>0)
repstats$ScaleType = factor(repstats$ScaleType,levels=c(paste0("Q",Qs)))
repstats = repstats[repstats$Generation %% 2 == 1,] # Only winter popsizes
ggplot(repstats,aes(x=Generation,y=PopSize,group=Rep,color=Extinct,alpha=0.35))+
  geom_line(alpha=0.35)+
  #geom_vline(xintercept=50000,"gray",linewidth=0.5,alpha=0.5)+
  #geom_smooth(alpha=10,se=F,span=0.15,linewidth=0.15)+
  facet_wrap("ScaleType",ncol=1)+
  scale_color_manual(values = c("deepskyblue4","darkred","darkgoldenrod3","darkgreen"))+
  theme_bw()

# Calculate some statistics for each population
status = unique(repstats[,c("ScaleType","Rep","Extinct")])
status$Extinct[status$Extinct=="Yes"] = 1
status$Extinct[status$Extinct=="No"] = 0
status$Extinct = as.numeric(status$Extinct)
res = aggregate(Extinct~ScaleType,data=status, function(x) sum(x)/length(x))
extinctions = na.omit(repstats[repstats$Extinct=="Yes",])
ends = aggregate(Generation~ScaleType+Rep, data=extinctions, FUN=max)
res2 = aggregate(Generation~ScaleType,data=ends,FUN=mean)
prob_table = merge(res,res2,by="ScaleType",all = T)
prob_table
# Bootstrap a probability 
Qboot=paste0("Q",c(1,2,4,8))
prob_table$ScaleType = as.character(prob_table$ScaleType)
prob_table$Boot95Min=NA
prob_table$Boot95Max=NA
for(q in Qboot){
  boot_vec = rep(NA,100)
  for(i in 1:100){
    bootreps = sample(status[status$ScaleType==q,"Extinct"],100,replace=T)
    boot_vec[i] = sum(bootreps)
  }
  prob_table[prob_table$ScaleType==q,"Boot95Min"] = sort(boot_vec)[6]
  prob_table[prob_table$ScaleType==q,"Boot95Max"] = sort(boot_vec)[94]
}
prob_table

# Calculate Fisher's exact
ext_counts = aggregate(Extinct~ScaleType,status,sum)
count_table = matrix(NA,nrow(ext_counts),2)
count_table[,1] = ext_counts$Extinct
count_table[,2] = 100-ext_counts$Extinct
fisher.test(count_table)

# ggplot(ends,aes(x=Generation))+
#   geom_histogram(aes(y = ..density..),
#                  colour = 1, fill = "white")+
#   geom_density(lwd = 1, colour = 4,
#                fill = 4, alpha = 0.25)+
#   facet_wrap("ScaleType",ncol=1)+
#   theme_bw()

