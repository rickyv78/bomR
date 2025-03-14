library(raster)
library(stringr)
library(XML)
library(lubridate)
library(sf)
library(httr)
library(xml2)
library(RCurl)
library(gdalUtilities)
library(terra)

s2.zones <- c("JNP_all", "JNP_west", "JNP_east", "JNN_all", "JNN_west", "JNN_south", "JNQ")
server <- "https://thredds.nci.org.au/thredds/catalog/ka08"

# Set the base directory where all the subfolders are located
base_folder <- "G:/Predicting_structure_model/R_downloads_raw_tifs"

i=1
for (i in 1:length(s2.zones)) {
  png_files <- list.files(paste0("E:/S2A/New downloads for 206-2025 time series/rgb/T50", s2.zones[i], "_clean"), pattern = ".png")
  dates <- paste0(substr(png_files, start = 17, stop = 18), "/", substr(png_files, start = 14, stop = 15), "/", substr(png_files, start = 9, stop = 12))
  date1<-dates[1]
  for (date1 in dates) {
    year <- substr(date1, start = 7, stop = 10)
    month <- substr(date1, start = 4, stop = 5)
    day <- substr(date1, start = 1, stop = 2)
    
    expected_pattern <- paste0(substr(s2.zones[i], start = 1, stop = 3), "_", year, "-", month, "-", day)
    
    # Find relevant subfolders that start with the first 3 characters of s2.zone
    relevant_folders <- list.dirs(base_folder, full.names = TRUE, recursive = FALSE)
    relevant_folders <- relevant_folders[grepl(paste0("^", substr(s2.zones[i], 1, 3)), basename(relevant_folders))]
    
    # Search for the file within these relevant subfolders
    existing_files <- unlist(lapply(relevant_folders, function(folder) {
      list.files(folder, pattern = expected_pattern, full.names = TRUE, recursive = TRUE)
    }))
    
    if (length(existing_files) > 0) {
      message("Skipping ", date1, " for ", s2.zones[i], " as matching files exist in relevant subfolders: ", paste(relevant_folders, collapse = ", "))
      next  # Skip to the next date
    }
    
    url_check_s2a <- paste0(server, "/ga_s2am_ard_3/50/",substr(s2.zones[i],start = 1,stop=3),"/", substr(date1,start =7,stop=10),"/", substr(date1,start =4,stop=5),"/",substr(date1,start =1,stop=2) ,"/catalog.xml")
    url_check_s2b <- paste0(server, "/ga_s2bm_ard_3/50/",substr(s2.zones[i],start = 1,stop=3),"/", substr(date1,start =7,stop=10), "/",substr(date1,start =4,stop=5),"/",substr(date1,start =1,stop=2) ,"/catalog.xml")
    # Check if the image is in the s2am folder (Sentinel-2A) or s2bm folder (Sentinel-2B)
    
    sensor<-NULL
    # If "ga_s2am_ard_3" exists in the html response, then it's Sentinel-2A
    if(url.exists(url_check_s2a)) {
      sensor <- "s2am"
    } 
    # If "ga_s2bm_ard_3" exists in the html response, then it's Sentinel-2B
    if(url.exists(url_check_s2b)) {
      sensor <- "s2bm"
    }  
    
    # Construct the URL for the catalog based on the date and sensor (A or B)
    url <-  paste0(server, "/ga_",sensor,"_ard_3/50/",substr(s2.zones[i],start = 1,stop=3),"/",substr(date1,start =7,stop=10),"/", substr(date1,start =4,stop=5),"/",substr(date1,start =1,stop=2) ,"/catalog.xml")
    response <- httr::GET(url)
    xml_content <- content(response, "text", encoding = "UTF-8")
    # Use sub() to extract the 15 characters following 'catalogRef xlink:href=', which is the time of capture, and impossible to guess, so this line reads the name of this final folder so it can be added to the url further down
    extracted_value <- sub('.*catalogRef xlink:href="(.{15}).*', '\\1',as.character(read_xml(xml_content)))
    bands.num<-c("02","03","04","05","06","07","08","08a","11","12")
   # bands.name<-c("blue","green","red","redEdge1","redEdge2","redEdge3","nir1","nir2","swir2","swir3")
    j=1
    for (j in 1:length(bands.num)){
      
      # File URL
      url <- paste0("https://thredds.nci.org.au/thredds/fileServer/ka08", "/ga_",sensor,"_ard_3/50/",substr(s2.zones[i],start = 1,stop=3),"/", substr(date1,start =7,stop=10),"/", substr(date1,start =4,stop=5),"/",substr(date1,start =1,stop=2),"/" ,extracted_value,"/",
                    "ga_",sensor,"_nbart_3-2-1_50",substr(s2.zones[i],start = 1,stop=3), "_",substr(date1,start =7,stop=10), "-",substr(date1,start =4,stop=5),"-",substr(date1,start =1,stop=2),"_final_band",bands.num[j],".tif")
      
      # Destination file path
      destfile <- paste0("G:/Predicting_structure_model/R_downloads_raw_tifs/",s2.zones[i],"/", "ga_",sensor,"_nbart_3-2-1_50",substr(s2.zones[i],start = 1,stop=3), "_",substr(date1,start =7,stop=10), "-",substr(date1,start =4,stop=5),"-",substr(date1,start =1,stop=2),"_final_band",bands.num[j],".tif")
    
      # Use curl backend with timeout of 600 seconds (10 minutes)
      download.file(url, destfile, mode = "wb", method = "curl", extra = "--max-time 600")
      } 
  }
}

