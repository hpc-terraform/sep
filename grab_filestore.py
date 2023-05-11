#/usr/bin/env python
import subprocess
import re
import sys

name,file_in,file_out=sys.argv[1],sys.argv[2],sys.argv[3]
ip=None
res=subprocess.check_output("gcloud filestore instances list".split(), text=True)
for line in res.split("\n"):
    vals=line.split()
    if len(vals)>4:
        if vals[4]==name:
            ip_out=vals[5]

fin=open(file_in,"r")
fout=open(file_out,"w")
for line in fin.readlines():
    line=line.replace("@FILL_IP@",ip_out)
    fout.write(line)
fout.close()



