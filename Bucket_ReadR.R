#!/usr/bin/env Rscript

#Bucket_ReadR


##################
#
# USAGE
#
##################

#This takes a list of bucket args and outputs a file with summary stats of the bucket.

#Run the following command in a terminal where R is installed for help.

#Rscript --vanilla Bucket_ReadR.R --help

##################
#
# Env. Setup
#
##################

#List of needed packages
list_of_packages=c("tidyr","dplyr","stringi","xfun","optparse","tools")

#Based on the packages that are present, install ones that are required.
new.packages <- list_of_packages[!(list_of_packages %in% installed.packages()[,"Package"])]
suppressMessages(if(length(new.packages)) install.packages(new.packages, repos = "http://cran.us.r-project.org"))

#Load libraries.
suppressMessages(library(dplyr,verbose = F))
suppressMessages(library(tidyr,verbose = F))
suppressMessages(library(stringi,verbose = F))
suppressMessages(library(xfun,verbose = F))
suppressMessages(library(optparse,verbose = F))
suppressMessages(library(tools,verbose = F))


#remove objects that are no longer used.
rm(list_of_packages)
rm(new.packages)


##################
#
# Arg parse
#
##################

#Option list for arg parse
option_list = list(
  make_option(c("-b", "--buckets"), type="character", default=NULL, 
              help="A list of buckets, each separated by a comma (no spaces). Please provide the bucket names in a format that does not include the 's3://' prefix or the '/' suffix.", metavar="character")
)

#create list of options and values for file input
opt_parser = OptionParser(option_list=option_list, description = "\nBucket_ReadR v1.0.0")
opt = parse_args(opt_parser)


#obtain buckets
buckets=unlist(strsplit(opt$buckets, ","))

###############
#
# Start write out
#
###############

#Rework the file path to obtain a file name, this will be used for the output file.
path=paste(getwd(),"/",sep = "")

file_name=paste(numbers_to_words(length(buckets)),"_buckets",sep = "")

#Output file name based on input file name and date/time stamped.
output_file=paste(file_name,
                  "_ReadR",
                  stri_replace_all_fixed(
                    str = Sys.Date(),
                    pattern = "-",
                    replacement = ""),
                  sep="")

#Start writing in the outfile.
sink(paste(path,output_file,".txt",sep = ""))

sink()

#Do a list of the bucket and then check the file size and name against the metadata submission.
for (bucket in (buckets)){
  #pull bucket metadata
  if (!is.na(bucket)){
    metadata_files=suppressMessages(suppressWarnings(system(command = paste("aws s3 ls --recursive s3://", bucket,"/",sep = ""),intern = TRUE)))
    
    #fix bucket metadata to have fixed delimiters of one space
    while (any(grepl(pattern = "  ",x = metadata_files))==TRUE){
      metadata_files=stri_replace_all_fixed(str = metadata_files,pattern = "  ",replacement = " ")
    }
    
    #Break bucket string into a data frame and clean up
    bucket_metadata=data.frame(all_metadata=metadata_files)
    bucket_metadata=separate(bucket_metadata, all_metadata, into = c("date","time","file_size","file_path"),sep = " ", extra = "merge")%>%
      select(-date, -time)%>%
      mutate(file_path=paste("s3://",bucket,"/",file_path,sep = ""),extension=file_ext(file_path))
    
    #Fix some of the file extensions. Add more information to gzipped files and get rid of blanks and insert NA for those missing an extension.
    for (row_ext in 1:dim(bucket_metadata)[1]){
      if (bucket_metadata$extension[row_ext]=="gz"){
        new_ext=stri_reverse(paste(unlist(stri_split_fixed(str = stri_reverse(basename(bucket_metadata$file_path[row_ext])), pattern = ".", n = 3))[1:2],collapse = "."))
        bucket_metadata$extension[row_ext]=new_ext
      }
      if (bucket_metadata$extension[row_ext]==""){
        bucket_metadata$extension[row_ext]=NA
      }
    }
    
    #calculate stats
    bucket_size=round(sum(as.numeric(bucket_metadata$file_size))/1e12, 2)
    bucket_count=dim(bucket_metadata)[1]
    ext_df=count(group_by(bucket_metadata, extension))
    
  
    #Write out bucket stats for each bucket
    sink(paste(path,output_file,".txt",sep = ""),append = TRUE)
    cat(paste("\n",bucket,"\n",sep = ""))
    cat(paste("\nThe bucket size in Tb is: ", bucket_size,sep = ""))
    cat(paste("\nThe bucket file count is: ", bucket_count,sep = ""))
    cat(paste("\nThe breakdown of file extension: ",sep = ""))
    for (ext_count in 1:dim(ext_df)[1]){
      cat(paste('\n\t',ext_df$extension[ext_count],": ",ext_df$n[ext_count],sep = ""))
    }
    cat("\n\n")
    sink()
  }
}

cat(paste("\n\nProcess Complete.\n\nThe output file can be found here: ",path,"\n\n",sep = ""))
