getStation<-function(.click,.x,.randomStation){
  
  if(!is.null(.click)){
    
    filter(.x,.click$id==station_eu_code)
    
  }else{
    
    .randomStation
    
  }
  
  
}