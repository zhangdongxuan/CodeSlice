

第一个问题:
107s的数据在预创建前已经下载了99%的数据，是不是有点多了？

日志: 业务层预下载过多数据(99%).txt

[I][2022-06-08 +8.0 11:22:05.871][78766, 6774989][mars::cdn][taskmanager.cc:781, OnSucceed][cdntaskend error 0:OK filetype 20302 optype DOWN all false proto QUIC cdntask 113,2b5e725a4e44dfd7259d09ac7dd9400c_xV10 needgetcdn false uin 2345479215 dataid 0 allcost 4549 netcost 4548 svraddr(QUIC_IPv4) 119.145.151.35:443 filesize 9803982 recved 9123394 netinfo newnetid_MqpLvLcffHBZLqGE traceid 15885851770305740930 q.t 240000 t.t 108000000 biz 3 apptype 251 cmdid 10005 preload ratio 99 filepath 5e725a4e44dfd7259d09ac7dd9400cxV10_temp.mp4|9803982 appid 1298



第二个问题:
Player下载完成后，业务层又对这个视频重新进行预下载？


日志: 重复下载问题.txt

Player开启Streaming下载
[I][2022-06-08 +8.0 12:48:44.590][79549, 6842279*][mars::cdn][cdn_core.cc:791, start_sns_download][start_sns_download: mode 1, filekey 4e3d2e25382a190e72e3e9fecdeddde1_xV2,

下载完成
[I][2022-06-08 +8.0 12:48:46.084][79549, 6842638][mars::cdn][taskmanager.cc:781, OnSucceed][cdntaskend error 0:OK filetype 20302 optype DOWN all true proto TCP cdntask 78,4e3d2e25382a190e72e3e9fecdeddde1_xV2 needgetcdn false uin 0 dataid 0 allcost 1477 netcost 1476 svraddr(TCP_IPv4) 42.202.218.59:80 filemd5 8d6d3d4f6b7acd1d752f11df854df9f4 filesize 1314812 recved 1319706 netinfo newnetid_0KvO7g_w7UProsgL hostaddr 42.202.218.59:80 usedaddr 14.29.100.99:443|42.202.218.59:80| svr_error_count 1 redirect_count 1 redirect_url http://42.202.218.59/finderqv.video.qq.com/251/20302/stodownload?X-snsvideoflag=xV2&adaptivelytrans=0&bizid=1023&cdnkey=Cvvj5Ix3eewK0tHtibORqcsqchXNh0Gf3sJcaYqC2rQCZ0ZSKaPTMxyNzLmYIaEl6JPo7r0ExgL19lHICAeMFwegddwH2k1sdFBYpLQcBTKaTIyxRVic38Oy24BlrpBGDj&cdntoken=6EqPuYLq3ynvE_g2gtIlbqIdVwKSt3Qn9BNxTecgx3qU0Xk_jEi4QG4Emr33O3YC&dotrans=2991&extg=1&hy=SH&m=&mf=106&taskid=10932894593206455265&tokenidx=1&end=1&mkey=2 moov status 3 moov offset 28 moov length 26664 first_request_cost 1465 first_request_completed true first_request_size 1314812 first_request_downloadize 1056935 moov_request_times 1 moov_cost 157 moov_completed true moov_failreason 0 traceid 10932894593206455265 q.t 240000 t.t 86400000 biz 3 apptype 251 cmdid 10005 filepath 3d2e25382a190e72e3e9fecdeddde1xV2_temp.mp4|1314812 appid 1298 url http://42.202.218.59/finderqv.video.qq.com/251/20302/stodownload?X-snsvideoflag=xV2&adaptivelytrans=0&bizid=1023&cdnkey=Cvvj5Ix3eewK0tHtibORqcsqchXNh0Gf3sJcaYqC2rQCZ0ZSKaPTMxyNzLmYIaEl6JPo7r0ExgL19lHICAeMFwegddwH2k1sdFBYpLQcBTKaTIyxRVic38Oy24BlrpBGDj&cdntoken=6EqPuYLq3ynvE_g2gtIlbqIdVwKSt3Qn9BNxTecgx3qU0Xk_jEi4QG4Emr33O3YC&dotrans=2991&extg=1&hy=SH&m=&mf=106&taskid=10932894593206455265&tokenidx=1&end=1&mkey=2 


业务层发起预加载
[I][2022-06-08 +8.0 12:48:46.377][79549, 6842279*][mars::cdn][cdn_core.cc:791, start_sns_download][start_sns_download: mode 2, filekey 4e3d2e25382a190e72e3e9fecdeddde1_xV2, q.t 0 t.t 108000 biz 3 app 251 filetype 20302 savepath /var/mobile/Containers/Data/Application/


预下载完成
[I][2022-06-08 +8.0 12:48:47.166][79549, 6842638][mars::cdn][taskmanager.cc:781, OnSucceed][cdntaskend error 0:OK filetype 20302 optype DOWN all false proto TCP cdntask 80,4e3d2e25382a190e72e3e9fecdeddde1_xV2 needgetcdn false uin 0 dataid 0 allcost 783 netcost 783 svraddr(TCP_IPv4) 220.170.92.117:80 filesize 1314812 recved 1306340 netinfo newnetid_0KvO7g_w7UProsgL hostaddr 220.170.92.117:80 usedaddr 14.29.100.99:443|220.170.92.117:80| svr_error_count 1 redirect_count 1 redirect_url http://220.170.92.117/finderbsy.video.qq.com/251/20302/stodownload?X-snsvideoflag=xV2&adaptivelytrans=0&bizid=1023&cdnkey=Cvvj5Ix3eewK0tHtibORqcsqchXNh0Gf3sJcaYqC2rQCZ0ZSKaPTMxyNzLmYIaEl6JPo7r0ExgL19lHICAeMFwegddwH2k1sdFBYpLQcBTKaTIyxRVic38Oy24BlrpBGDj&cdntoken=6EqPuYLq3ynvE_g2gtIlbozo7CGCUAxvfmtGMj-xWkqU0Xk_jEi4QG4Emr33O3YC&dotrans=2991&extg=1&hy=SH&m=&mf=102&taskid=1441462895547137481&tokenidx=1&end=1&mkey=2 traceid 1441462895547137481 q.t 240000 t.t 108000000 biz 3 apptype 251 cmdid 10005 preload ratio 99 filepath 3d2e25382a190e72e3e9fecdeddde1xV2_temp.mp4|1302528 appid 1298 url http://220.170.92.117/finderbsy.video.qq.com/251/20302/stodownload?X-snsvideoflag=xV2&adaptivelytrans=0&bizid=1023&cdnkey=Cvvj5Ix3eewK0tHtibORqcsqchXNh0Gf3sJcaYqC2rQCZ0ZSKaPTMxyNzLmYIaEl6JPo7r0ExgL19lHICAeMFwegddwH2k1sdFBYpLQcBTKaTIyxRVic38Oy24BlrpBGDj&cdntoken=6EqPuYLq3ynvE_g2gtIlbozo7CGCUAxvfmtGMj-xWkqU0Xk_jEi4QG4Emr33O3YC&dotrans=2991&extg=1&hy=SH&m=&mf=102&taskid=1441462895547137481&tokenidx=1&end=1&mkey=2 
