setwd("/home/centos/USS/erik/PPM/SLiMrescue/metapopulation_decline/DP_rescue/")
dirs = c("RescueN4Freq16","RescueN8Freq16","RescueN12Freq16")
all_end_stats = NULL
summary_table = NULL
for(dir in dirs){
  cat("Summarizing: ", dir, "\n")
  path=paste0(dir)
  fins = list.files(path=path,pattern="_stats.txt",full.names = T)
  bottleneck_gens=2
  post_gens=100
  repstats=NULL
  for (i in fins) {
    slimstats = read.table(i,sep=",",header=T,stringsAsFactors = F,skip=25238)
    first_gen = slimstats$Generation[1]
    slimstats = slimstats[slimstats$Generation < post_gens+bottleneck_gens+first_gen,]
    slimstats$Scenario = dir
    slimstats$Rep = str_split(i,pattern = "/")[[1]][2]
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
  all_end_stats = rbind(all_end_stats,endstats)
  translocations = endstats[endstats$Translocation==1,c("Generation","Population")]
  ggplot(endstats,aes(x=Generation,y=Froh,group=Rep,color=Extinct))+
    geom_line(alpha=0.2)+
    #geom_line(data=repstats, aes(x=Generation,y=K),color="gray")+
    #geom_vline(data=translocations,aes(xintercept=Generation),"gray",linewidth=0.25,alpha=0.25,linetype="dashed")+
    #geom_smooth(alpha=10,se=F,span=0.15,linewidth=0.5)+
    facet_wrap("Population",ncol=1,scales = "free_y",labeller = labeller("Population" = pop_names))+
    scale_color_manual(values = c("deepskyblue4","darkred","darkgoldenrod3","darkgreen"))+
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
  
  extinction_summary = merge(res,res2,by="Population",all = T)
  extinction_summary$run = dir
  summary_table = rbind(summary_table,extinction_summary)
}

dp_summary_table = summary_table[summary_table$Population=="p1",]
#write.table(dp_summary_table,"DP_extinction_summaries.txt",quote=F,row.names=F)

# Calculate the changes in het / Froh following translocation
gens = c(33,35)
df = all_end_stats %>%
      filter(Population == "p1") %>% #Extract DP stats only
      filter(Generation %in% c(gens)) %>% #Generations before and after translocation
      dplyr::select(Het,Froh,Scenario,Generation) %>%
      mutate(Scenario = factor(Scenario, levels = c("RescueN4Freq16","RescueN8Freq16","RescueN12Freq16")))
  
stat = aggregate(Het~Scenario+Generation,data=df[df$Het>=0,],FUN=mean)
stat
stat[stat$Generation==gens[2],"Het"] - stat[stat$Generation==gens[1],"Het"] 
(stat[stat$Generation==gens[2],"Het"] - stat[stat$Generation==gens[1],"Het"]) / stat[stat$Generation==gens[1],"Het"]

stat = aggregate(Froh~Scenario+Generation,data=df[df$Froh<=1,],FUN=mean)
stat
stat[stat$Generation==gens[1],"Froh"] - stat[stat$Generation==gens[2],"Froh"] 
(stat[stat$Generation==gens[1],"Froh"] - stat[stat$Generation==gens[2],"Froh"]) / stat[stat$Generation==gens[1],"Froh"]
