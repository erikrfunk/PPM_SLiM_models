path="/home/centos/USS/erik/PPM/SLiMrescue/metapopulation_decline/DP_rescue/RescueN12Freq16/"

# Use this block to compare populations within a single scenario
fins = list.files(path=path,pattern="_stats.txt",full.names = T)
bottleneck_gens=2
post_gens=100
repstats=NULL
for (i in fins) {
  slimstats = read.table(i,sep=",",header=T,stringsAsFactors = F,skip=25238)
  first_gen = slimstats$Generation[1]
  slimstats = slimstats[slimstats$Generation < post_gens+bottleneck_gens+first_gen,]
  slimstats$Rep = i
  slimstats$Extinct="No"
  for(j in c("p1","p2","p3","p4")){
    popdf = slimstats[slimstats$Population==j,]
    if(popdf$PopSize[nrow(popdf)]<2){
      slimstats$Extinct[slimstats$Population==j] = "Yes"
    }
  }
  repstats = rbind(repstats,slimstats)
}


repstats$Generation = as.numeric(repstats$Generation)
repstats$Generation = repstats$Generation - (repstats$Generation[1]+bottleneck_gens)
repstats$PopSize[repstats$PopSize==0 ] = NA
repstats$Froh[repstats$PopSize==0] = NA
ggplot(repstats,aes(x=Generation,y=PopSize,group=Rep,color=Extinct))+
  geom_line(alpha=0.2)+
  #geom_line(data=repstats, aes(x=Generation,y=K),color="gray")+
  #geom_vline(xintercept=50000,"gray",linewidth=0.5,alpha=0.5)+
  #geom_smooth(alpha=10,se=F,span=0.15,linewidth=0.5)+
  facet_wrap("Population",ncol=1,scales = "free",labeller = labeller("Population" = pop_names))+
  scale_color_manual(values = c("deepskyblue4","darkred","darkgoldenrod3","darkgreen"))+
  theme_bw()

endstats=repstats[repstats$Generation>-1,]
endstats=endstats[endstats$Generation%%2==1,]
translocations = endstats[endstats$Translocation==1,c("Generation","Population")]
ggplot(endstats,aes(x=Generation,y=PopSize,group=Rep,color=Extinct))+
  geom_line(alpha=0.2)+
  geom_vline(xintercept=c(33,35),"gray",linewidth=0.25,alpha=0.25,linetype="dashed")+
  facet_wrap("Population",ncol=1,scales = "free_y",labeller = labeller("Population" = pop_names))+
  scale_color_manual(values = c("deepskyblue4","darkred","darkgoldenrod3","darkgreen"))+
  labs(x="Seasons",y="Population Size")+
  theme_bw()


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


# Calculate the effects of translocation on Het and Froh
dp = filter(endstats,Population=="p1")
gens = c(33,35) # the start and stop points to contrast values
var = "Froh"
(mean(dp[dp$Generation==gens[1],var])-mean(dp[dp$Generation==gens[2],var]))#/mean(dp[dp$Generation==gens[1],var])


