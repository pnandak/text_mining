require(XML)
require(RCurl)


#ȡ55bbs��̳�еİ���б����������Ϊ��վ��ҳ��ַ������ѡ�еİ���ַ����
getChanList<-function(listUrl){
listExist= url.exists(listUrl)
if(listExist) {

# ----------------------����ҳ��
url1<-htmlTreeParse(listUrl,useInternalNodes=TRUE,encoding='gbk')

#----------------------ȡ�������ƺ�����
chanlist <- getNodeSet(url1, "//body//div[@class='subnav clearfix']/ul/li/a")
chanName<-unlist(lapply(chanlist,xmlValue,encoding='utf-8'))
t<-unlist(lapply(chanlist,xmlAttrs))
chanLink<-t[names(t)=='href']

#df<-data.frame(�������=chanName,����ַ=chanLink)
#write.csv(df,'55bbs����б�.csv',row.names = TRUE)

#------------------------ѡ����Ҫ�İ������
id<-match(c('����ױ��','��ɫ����','���˰�','����','����','����','����','�в�','�����ʳ','�б�����','����','�����ĵ�','������ϱ','��̸����','�Ļ�����','���λ���','���г���'),chanName)
selChanLink<-data.frame(�������=chanLink[id],�������=chanName[id])
selChanLink

}else{
print('55bbs��ҳ�޷����ӣ�')
NULL
}
}


#��ȡ���л�����
getTitleNode<-function(urlstr){#��ȡ���б����㣬�������Ϊ����ַ�����ر������б�
nodes.title<-list()
isex <- url.exists(urlstr)
if(isex){
url1<-NULL
#--------------��ȡ������
try(url1<-htmlTreeParse(urlstr, useInternalNodes=TRUE,encoding='gbk'),silent = T)
if (!is.null(url1)){

node.start<-getNodeSet(url1, "//body//table/thead[@class='category']")
node<-getSibling(node.start[[1]],after=T)
i<-1

while (!is.null(node)){
id<-xmlAttrs(node,'id')
if (!is.null(id)&&(regexpr('thread',id)>0)) {
nodes.title[[i]]<-xmlChildren(node)[[1]]
i<-i+1
}
node<-getSibling(node,after=T)
}#-------------nodes.titleΪ�������б�
}#end for if url1
}#end for if(isex)
nodes.title
}# end for function 'getTileNode'


#��ȡ�������ݡ����ӡ����ߡ�����ʱ�䡢����������ظ�����������ظ�ʱ�䣻�������Ϊһ�������㣻����һ���ַ�������
getTitleDetail<-function(node.title){#��ȡ����topic������ϸ�����Ϣ



chd<-xmlChildren(node.title)#��ȡ���к��ӽ��
#-----------��ȡ����
s<-xmlElementsByTagName(chd[[3]],'span')[[1]]
a<-xmlElementsByTagName(s,'a')[[1]]
title<-xmlValue(a,encoding='utf-8')

#-----------��ȡ��������
link<-xmlAttrs(a)['href']#����
link<-paste('http://bbs.55bbs.com/',link,sep='')

#-----------��ȡ����ظ�ҳ��
if (length(xmlElementsByTagName(chd[[3]],'span'))>1){
p<-xmlElementsByTagName(chd[[3]],'span')[[2]]
a<-xmlElementsByTagName(p,'a')
pn<-unlist(lapply(a,xmlValue,encoding='utf-8'))
if (is.null(pn)){
rpPageNum<-'0'
}else{
lastPn<-length(pn)
rpPageNum<-pn[lastPn]
if (as.numeric(rpPageNum)<0|is.na(as.numeric(rpPageNum))) browser()
}#end for is.null(pn)
}else{
rpPageNum<-'1'
}#end for if length()>1
names(rpPageNum)<-''

author<-xmlValue(xmlElementsByTagName(chd[[5]],'a',recursive=T)[[1]],encoding='utf-8')#����
authorLink<-xmlAttrs(xmlElementsByTagName(chd[[5]],'a',recursive=T)[[1]])['href']#AuthorLink

time<-xmlValue(xmlElementsByTagName(chd[[5]],'em',recursive=T)[[1]],encoding='utf-8')#����ʱ��

str<-xmlValue(chd[[7]])
id<-regexpr('/',str)[1]
rpnum<-substring(str,1,id-1)#�ظ�����

revnum<-substring(str,id+1,nchar(str))#�������

lastTime<-xmlValue(xmlElementsByTagName(chd[[9]],'a',recursive=T)[[1]],encoding='utf-8')#����ظ�ʱ��

c(Topic=title, Link=link, Author=author, AuthorLink=authorLink, PostTime=time, RevNum=revnum,
RepNum=rpnum, RpPageNum = rpPageNum, LastTime=lastTime)

}#end for getTitleDetail

getRpTime<-function(rpinfoStr){
id1<-regexpr('������',rpinfoStr)[1]
id2<-regexpr('ֻ��������',rpinfoStr)[1]
gsub('[[:cntrl:]]','',substr(rpinfoStr,id1+3,id2-1))
}#end for getRpTime


#getRpCont�����Ĺ���Ϊ��ȡ�������ģ�����¥��������,ID=1Ϊ¥����������Ϊ�����ַ������Ϊһ�����ݿ򣺰��� TopicID Author AuthorLink ����ʱ�� ����
getRpCont<-function(curl,id){
info.rps<-data.frame()
url1<-NULL
try(url1<-htmlTreeParse(curl,useInternalNodes=TRUE,encoding='gbk'),silent = T)
if(!is.null(url1)){

#------------------��������

nodes.rpcont<-getNodeSet(url1, "//body//form/div[@class='mainbox viewthread']/table//tr/
td[@class='postcontent']/div[@class='postmessage defaultpost']/div[@class='t_msgfont']|
//body//form/div[@class='mainbox viewthread']/table//tr/td[@class='postcontent']/
div[@class='postmessage defaultpost']/div[@class='notice']")


rpconts<-lapply(nodes.rpcont,xmlValue,encoding='utf-8')
rpconts<-unlist(lapply(rpconts,function(x) gsub('[[:space:]]','',x)))

#------------------��������
nodes.rpauthor<-getNodeSet(url1, "//body//form/div[@class='mainbox viewthread']/table//tr/td[@class='postauthor']/cite")
rpauthors<-lapply(nodes.rpauthor,xmlValue,encoding='utf-8')
rpauthors<-unlist(lapply(rpauthors,function(x) gsub('[[:space:]]','',x)))#����ID

getAuthorNode<-function(x){
node<-xmlElementsByTagName(x,'a')
if (length(node)>1){
return (node[[1]])
}else{
return(NULL)
}
}

rpauthorsA<-lapply(nodes.rpauthor,getAuthorNode)
rpauthorsLink<-unlist(lapply(rpauthorsA,function(x) ifelse(is.null(x),'', xmlAttrs(x)['href'])))#AuthorLink

#------------------����ʱ��
nodes.rpinfo<-getNodeSet(url1, "//body//form/div[@class='mainbox viewthread']/table//tr/td[@class='postcontent']/div[@class='postinfo']")
rpinfos<-lapply(nodes.rpinfo,xmlValue,encoding='utf-8')
rpinfos<-unlist(lapply(rpinfos,getRpTime))

#-------------------��װ����ֵ
num<-min(c(length(rpauthors),length(rpauthorsLink),length(rpinfos),length(rpconts)))
info.rps<-NULL
if (num>0) info.rps<-data.frame(TopicID=rep(id,num),Author=rpauthors[1:num],AuthorLink=rpauthorsLink[1:num],PostTime=rpinfos[1:num],PostTxt=rpconts[1:num])
rm(url1)
}#end for if url1
info.rps
}#end for getRpCont