## smarthome forumץȡ

library(XML)

#��ȡ����̳
ul <- "http://www.smarthome.com/forum/default.asp"
url1 <- htmlTreeParse( ul, useInternalNodes=TRUE,encoding='utf8')
tt <- getNodeSet( url1,"//td[@valign = 'top']//span[ @class = 'spnMessageText']/a")
forum <- sapply( tt, xmlValue) [ seq(1,25, by =2)]
link <- sapply( tt, function(el) 
  paste( "http://www.smarthome.com/forum/",  xmlGetAttr(el, "href" ), sep="" )) [ seq(1,25, by =2)]
forumlist <- as.data.frame( cbind( forum, link ) )
forumlist[,2] <- as.character(forumlist[,2] )
rm( forum, link, tt, ul, url1)


#��ȡ����̳����ҳ�����ӵ�forumlist
for (i in 1: nrow(forumlist)) {
  ul <- forumlist[i, 2]
  url1 <- htmlTreeParse( ul, useInternalNodes=TRUE,encoding='utf8')
  a <- getNodeSet( url1, "//body/table[2]/tr/td[1]/table[1]/tr[2]//b[2]")
  forumlist$pg[i] <- sapply( a, xmlValue ) [1]
}
forumlist$pg <- as.numeric( gsub( "[^0-9]" , "", forumlist$pg) )
forumlist$pg[ is.na(forumlist$pg)] <- 1

#��ȡ�����б�

smthome.topic.1p <- function( ul ) {  #ץȡһҳ������
ul <- "http://www.smarthome.com/forum/forum.asp?FORUM_ID=9&sortfield=lastpost&sortorder=desc&whichpage=1"
url1 <- NULL
Sys.sleep( round( runif(1, min=1, max=3)) ) 
try( url1 <- htmlTreeParse( ul, useInternalNodes=TRUE,encoding='utf8'),silent = F)
  if ( !is.null( url1))  { 
    
    #ץҳ������
    a <- getNodeSet( url1, "//body/table[2]//td/table[2]//td/table") [[1]] #ê��table
    b <- xmlElementsByTagName( a , "tr")  #ê������ÿһ��
    df <- list()  #������xmlElementsByTagNames����ȡ���浽list
    
    for ( i in 2: length(b)-1 ) {  #��һ���Ǳ��⣬���һ����������Ϣ
      c <- xmlElementsByTagName( b[[i]] , "td") #ê�������ÿ��Ԫ�� 
      row <- sapply( c, xmlValue , encoding="utf8")
      row <- gsub(  "[[:space:]]+" , " ", row ) #��ȡ����
      d <- getNodeSet( b[[i]], "td[2]//a") #ê��ÿһ������������ڽڵ�
      link <- sapply( d, function(el)  #��ȡ����
        paste( "http://www.smarthome.com/forum/" , xmlGetAttr(el, "href") , sep="") ) [1]
      
      df[[i]] <- c( row , link)     # ÿһ�к���
      rm(row, c, link , d)
    }
    content <- data.frame() #listת�������ݿ�
    for ( i in 2 : length(df)) {
      for ( j in 1 : length( df[[2]])) {
        content[i,j] =df[[i]][j] } }
    content <- content[ -1 ,-1]
    names( content ) <- c("topic", "author", "replies", "read", "lastpost", "href") 
    content <- content
    
    } # end if url1 is NULL
}

#seesee <- smthome.topic.1p( "http://www.smarthome.com/forum/forum.asp?FORUM_ID=9" )

three <- data.frame()
for (j in 1: nrow(forumlist) ) {

  two <- data.frame()
  for (i in 1 : forumlist[j,3] ) { #����̳ץ10ҳ
    one <- data.frame()
    ul <- forumlist[j, 2] #http://www.smarthome.com/forum/forum.asp?FORUM_ID=9
    ul <- paste( ul, "&sortfield=lastpost&sortorder=desc&whichpage=" ,i , sep="")
    one <- smthome.topic.1p( ul )
    if ( class(one) == "data.frame" ) { #ץȡ���ɹ��Ĵ���
    one$pg <- i
    two <- rbind(two, one) } else { NULL }
  } #��ҳѭ������
    two$topic <- forumlist[j, 1]
    three <- rbind( two, three )
}

library(RODBC)

con <- odbcConnect( "mysql", uid="xxx", pwd="xxx")
sqlSave(con, three, tablename = "ods_smarthome_topic", append = T, rownames = F, addPK = FALSE)
close(con)
##���������ڱ��ؿ�ִ�У�����������ִ��


## smarthome forumץȡ���������桪��topic��֪��ץȡ���ݲ���

library(XML)
library(RMySQL)

con <- dbConnect( MySQL(), username="xxx" , password = "xxx", dbname="test" )
topic <- dbReadTable( con , "ods_smarthome_topic") # ֱ��ץ��
dbDisconnect( con )

names(topic)
topic$id <- 1: nrow(topic)
topic$len <- round( as.numeric( topic$replies )/30)+1  #ÿ������ȡ����ҳ

#ul <- topic[1,6]

#ץȡһҳ
smarthome.1p <- function( ul) {
  
  #Sys.sleep( round( runif(1, min=1, max=3)) ) 
  url1<-NULL
  try( url1 <- htmlTreeParse( ul, useInternalNodes=TRUE,encoding='utf8'),silent = F )
  if (!is.null(url1)){ 
    a <- getNodeSet( url1, "//span[@class = 'spnMessageText' and @id = 'msg' ]") 
    content <- sapply( a, xmlValue)     
    a <- getNodeSet( url1, "//body/table[4]//table//table/tr[1]")
    posttime <- sapply( a , function(x) 
      gsub( '[[:space:]]' , "", xmlValue(x, encoding ="utf8") ) ) [-1]
    a <- getNodeSet( url1, "//span[@class = 'spnMessageText']/a[@onmouseover]") 
    author <- sapply( a , xmlValue)
    rm( url1, a)
    
    try( txt <- as.data.frame( cbind(content, author, posttime) ) )
    
    if ( class(txt) == "data.frame") { txt <- txt} else( NULL) 
    #��֤�������Ҫô��dataframe��Ҫô��NULL
  } else { NULL}
}

#txt <-  smarthome.1p( 'http://www.smarthome.com/forum/topic.asp?TOPIC_ID=163&whichpage=2')
#a <- txt

#����ַץ����
a <- data.frame()
b <- data.frame()

for (j in 1: nrow(topic) ) {
  b <- data.frame( )
  for (i in 1: topic$len[j]) {
    try( rm(a) )
    url <- paste( topic[j,6] ,  "&whichpage=", i , sep="" )
    a <- smarthome.1p( url)  # �����Ǿ���������
    if ( nrow(a) >0 )  #�쳣����
    {
      a$channel <- as.character( topic$topic[j] )
      a$topicid <- topic$id[j]
      try( b <- rbind( b, a ) )
    } else{ try( rm(a) ) } 
  } # end page roll
  if ( class(b) == "data.frame" & nrow(b) >=3 ){
    con <- dbConnect(MySQL(),user="xxx",password="xxx",dbname="test")
    try( dbWriteTable(con,"ods_smarthome_content", b , append=TRUE , row.names=FALSE) )
    dbDisconnect(con)
    rm(con)
    rm(b)} else{ rm(b)  }
}

#rm(list=ls(all=TRUE))

warnings()

