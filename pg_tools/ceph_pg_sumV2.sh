#i!/bin/bash
ceph pg dump | awk '
 /^PG_STAT/ { col=1; while($col!="UP") {col++}; col++ }
 /^[0-9a-f]+\.[0-9a-f]+/ { match($0,/^[0-9a-f]+/); pool=substr($0, RSTART, RLENGTH); poollist[pool]=0;
 up=$col; i=0; RSTART=0; RLENGTH=0; delete osds; while(match(up,/[0-9]+/)>0) { osds[++i]=substr(up,RSTART,RLENGTH); up = substr(up, RSTART+RLENGTH) }
 for(i in osds) {array[osds[i],pool]++; osdlist[osds[i]];}
}
END {
 printf("\n");
 slen=asorti(poollist,newpoollist);
 printf("pool :\t");for (i=1;i<=slen;i++) {printf("%s\t", newpoollist[i])}; printf("| SUM \n");
 for (i in poollist) printf("--------"); printf("----------------\n");
 slen1=asorti(osdlist,newosdlist)
 delete poollist;
 for (j=1;j<=slen;j++) {maxpoolosd[j]=0};
 for (j=1;j<=slen;j++) {for (i=1;i<=slen1;i++){if (array[newosdlist[i],newpoollist[j]] >0  ){minpoolosd[j]=array[newosdlist[i],newpoollist[j]] ;break } }}; 
 for (i=1;i<=slen1;i++) { printf("osd.%i\t", newosdlist[i]); sum=0; 
 for (j=1;j<=slen;j++)  { printf("%i\t", array[newosdlist[i],newpoollist[j]]); 
      sum+=array[newosdlist[i],newpoollist[j]]; 
      poollist[j]+=array[newosdlist[i],newpoollist[j]];if(array[newosdlist[i],newpoollist[j]] != 0){poolhasid[j]+=1 };
      if(array[newosdlist[i],newpoollist[j]]>maxpoolosd[j]){maxpoolosd[j]=array[newosdlist[i],newpoollist[j]];
      maxosdid[j]=newosdlist[i]};
      if(array[newosdlist[i],newpoollist[j]] != 0){if(array[newosdlist[i],newpoollist[j]]<=minpoolosd[j]){minpoolosd[j]=array[newosdlist[i],newpoollist[j]];
      minosdid[j]=newosdlist[i]}}}; 
      printf("| %i\n",sum)} for (i in poollist) printf("--------"); printf("----------------\n");
 
 slen2=asorti(poollist,newpoollist);
 printf("SUM :\t"); for (i=1;i<=slen;i++) printf("%s\t",poollist[i]); printf("|\n");
 printf("Osd :\t"); for (i=1;i<=slen;i++) printf("%s\t",poolhasid[i]); printf("|\n");
 printf("AVE :\t"); for (i=1;i<=slen;i++) printf("%.2f\t",poollist[i]/poolhasid[i]); printf("|\n");
 printf("Max :\t"); for (i=1;i<=slen;i++) printf("%s\t",maxpoolosd[i]); printf("|\n");
 printf("Osdid :\t"); for (i=1;i<=slen;i++) printf("osd.%s\t",maxosdid[i]); printf("|\n");
 printf("per:\t"); for (i=1;i<=slen;i++) printf("%.1f%\t",100*(maxpoolosd[i]-poollist[i]/poolhasid[i])/(poollist[i]/poolhasid[i])); printf("|\n");
 for (i=1;i<=slen2;i++) printf("--------");printf("----------------\n");
 printf("min :\t"); for (i=1;i<=slen;i++) printf("%s\t",minpoolosd[i]); printf("|\n");
 printf("osdid :\t"); for (i=1;i<=slen;i++) printf("osd.%s\t",minosdid[i]); printf("|\n");
 printf("per:\t"); for (i=1;i<=slen;i++) printf("%.1f%\t",100*(minpoolosd[i]-poollist[i]/poolhasid[i])/(poollist[i]/poolhasid[i])); printf("|\n");
}'
echo "-----------------------------------------------"
total_osd=`ceph osd df |awk '{total+=$12}END{print total}'`
echo 'TOTAL osd is:' $total_osd
total_pg=`ceph osd df |awk '{total+=$13}END{print total}'`
echo 'TOTAL pg is:' $total_pg
pg_per_osd=`expr $total_pg / $total_osd`
echo 'AVERAGE pg per osd is:'$pg_per_osd
max_osd_with_pg=`ceph osd df |awk 'BEGIN{max = 0}{if($13 > max) max = $13}END{print max}'`
min_osd_with_pg=`ceph osd df |grep -v PGS | grep -v STDDEV | grep -v TOTAL | awk '{print $13}' | sort -n | awk '{if((NR==1)) {print $1}}'`
#echo $max_osd_with_pg
echo 'OSD with MAX pg is: ' $max_osd_with_pg '; OSD with MIN is: ' $min_osd_with_pg
