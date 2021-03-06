## functions for using cyREST with R
## toCytoscape function and mapAttributes from https://github.com/idekerlab/cy-rest-R tutorials
## resetCytoscapeSession and saveCytoscapeSession from R package stringgaussnet: https://github.com/cran/stringgaussnet


resetCytoscapeSession <-
  function(port.number=1234)
  {
    base.url = paste("http://localhost:", toString(port.number), "/v1", sep="")
    reset.url <- paste(base.url,"session",sep="/")
    if (requireNamespace("httr",quietly=TRUE)) {res<-httr::DELETE(reset.url)}
    else {stop("httr package must be installed to use this function")}
  }

mapAttributes <- function(attr.names, all.attr, i) {
  attr = list()
  cur.attr.names = attr.names
  attr.names.length = length(attr.names)
  
  for(j in 1:attr.names.length) {
    if(is.na(all.attr[[j]][i]) == FALSE) {
      #       attr[j] = all.attr[[j]][i]
      attr <- c(attr, all.attr[[j]][i])
    } else {
      cur.attr.names <- cur.attr.names[cur.attr.names != attr.names[j]]
    }
  }
  names(attr) = cur.attr.names
  return (attr)
}


saveCytoscapeSession <-
  function (filepath="",
            overwrite=TRUE,
            absolute=FALSE,
            port.number=1234)
  {
    #check<-checkCytoscapeRunning(port.number)
    filepath<-paste(gsub("\\.cys$","",filepath),"cys",sep=".")
    if (file.exists(filepath) & !overwrite){stop(paste(filepath,"already exists."))}
    if(!absolute){filepath<-paste(getwd(),filepath,sep="/")}
    filepath<-URLencode(filepath)
    base.url = paste("http://localhost:", toString(port.number), "/v1", sep="")
    save.url<-paste(base.url,paste("session?file=",filepath,sep=""),sep="/")
    print(save.url)
    if (requireNamespace("httr",quietly=TRUE)) {res <- httr::POST(save.url)} else {stop("httr package must be installed to use this function")}
  }


toCytoscape <- function (igraphobj) {
  # Extract graph attributes
  graph_attr = graph.attributes(igraphobj)
  # Extract nodes
  node_count = length(V(igraphobj))
  if('name' %in% list.vertex.attributes(igraphobj)) {
    V(igraphobj)$id <- V(igraphobj)$name
  } else {
    V(igraphobj)$id <- as.character(c(1:node_count))
  }
  
  nodes <- V(igraphobj)
  v_attr = vertex.attributes(igraphobj)
  v_names = list.vertex.attributes(igraphobj)
  
  nds <- array(0, dim=c(node_count))
  for(i in 1:node_count) {
    if(i %% 1000 == 0) {
      print(i)
    }
    nds[[i]] = list(data = mapAttributes(v_names, v_attr, i))
  }
  
  edges <- get.edgelist(igraphobj)
  edge_count = ecount(igraphobj)
  e_attr <- edge.attributes(igraphobj)
  e_names = list.edge.attributes(igraphobj)
  
  attr_exists = FALSE
  e_names_len = 0
  if(identical(e_names, character(0)) == FALSE) {
    attr_exists = TRUE
    e_names_len = length(e_names)
  }
  e_names_len <- length(e_names)
  
  eds <- array(0, dim=c(edge_count))
  for(i in 1:edge_count) {
    st = list(source=toString(edges[i,1]), target=toString(edges[i,2]))
    
    # Extract attributes
    if(attr_exists) {
      eds[[i]] = list(data=c(st, mapAttributes(e_names, e_attr, i)))
    } else {
      eds[[i]] = list(data=st)
    }

    if(i %% 1000 == 0) {
      print(i)
    }
  }
  
  el = list(nodes=nds, edges=eds)
  
  x <- list(data = graph_attr, elements = el)
  print("Done.  To json Start...")
  return (toJSON(x))
}