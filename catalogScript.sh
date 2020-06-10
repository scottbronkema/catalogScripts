#what database args
echo -n "Enter the name of the database: "
read databaseName

echo -n "Enter the oid number: "
read oid

echo -n "Enter the master port number: "
read portNumberMaster

echo -n "Enter the master host Name: "
read hostNameMaster

echo -n "Enter the segment port number: "
read portNumberSegment

echo -n "Enter the segment host Name: "
read hostNameSegment

mkdir /tmp/pivotal
mkdir /tmp/pivotal/master
mkdir /tmp/pivotal/segment

`psql -X -A -d "$databaseName" -t -c "select * from  gp_configuration_history;" -o '/tmp/pivotal/gp_config.out'`

`psql -X -A -d "$databaseName" -t -c "select oid, relname, reltype from pg_class limit 2;" -o '/tmp/pivotal/pg_class.out'`


##do the utility mode connections commands
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aocsseg_$oid;" -o  '/tmp/pivotal/master/pg_aocsseg.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster"  -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;select * from gp_toolkit.__gp_aocsseg($oid);" -o '/tmp/pivotal/master/gp_aocsseg.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster" -h "$hostNameMaster"  -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;select xmin,xmax,cmin,cmax,ctid,* from pg_stat_last_operation;" -o  '/tmp/pivotal/master/pg_stat_last_operation.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aoseg_$oid;"  -o  '/tmp/pivotal/master/pg_aoseg.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;Select xmin,xmax,cmin,cmax,ctid,* from pg_appendonly;" -o  '/tmp/pivotal/master/pg_appendonly.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;select * from gp_distributed_log;" -o '/tmp/pivotal/master/gp_distributed_log.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;select ctid, * from gp_persistent_relation_node;" -o  '/tmp/pivotal/master/gp_persistent_relation_node.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;select xmin,xmax,cmin,cmax,ctid,oid,* from pg_class;" -o  '/tmp/pivotal/master/pg_class.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;select xmin,xmax,cmin,cmax,ctid,* from pg_stat_last_operation;" -o  '/tmp/pivotal/master/pg_stat_last_operation.out'`

##do utility segment
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;select * from gp_toolkit.__gp_aocsseg($oid);" -o '/tmp/pivotal/segment/gp_aocsseg_seg.out'` 
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aocsseg_$oid;" -o  '/tmp/pivotal/segment/pg_aocsseg.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aoseg_$oid;"  -o  '/tmp/pivotal/segment/pg_aoseg.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$portNumberSegment" -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;Select xmin,xmax,cmin,cmax,ctid,* from pg_appendonly;" -o  '/tmp/pivotal/segment/pg_appendonly.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$portNumberSegment" -X -A -d "$databaseName" -t -c "select * from gp_distributed_log;" -o '/tmp/pivotal/segment/gp_distributed_log.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$portNumberSegment" -X -A -d "$databaseName" -t -c "set gp_select_invisible=on;select xmin,xmax,cmin,cmax,ctid,oid,* from pg_class;" -o '/tmp/pivotal/segment/pg_class.out'`

#set invisible
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aocsseg_$oid;" -o  '/tmp/pivotal/master/pg_aocsseg_inv.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster"  -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;select * from gp_toolkit.__gp_aocsseg($oid);" -o '/tmp/pivotal/master/gp_aocsseg_inv.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster" -h "$hostNameMaster"  -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;select xmin,xmax,cmin,cmax,ctid,* from pg_stat_last_operation;" -o  '/tmp/pivotal/master/pg_stat_last_operation_inv.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aoseg_$oid;"  -o  '/tmp/pivotal/master/pg_aoseg_inv.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;Select xmin,xmax,cmin,cmax,ctid,* from pg_appendonly;" -o  '/tmp/pivotal/master/pg_appendonly_inv.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;select * from gp_distributed_log;" -o '/tmp/pivotal/master/gp_distributed_log_inv.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;select xmin,xmax,cmin,cmax,ctid,oid,* from pg_class;" -o  '/tmp/pivotal/master/pg_class_inv.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;select xmin,xmax,cmin,cmax,ctid,* from pg_stat_last_operation;" -o  '/tmp/pivotal/master/pg_stat_last_operation_inv.out'`

##do utility segment
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;select * from gp_toolkit.__gp_aocsseg($oid);" -o '/tmp/pivotal/segment/gp_aocsseg_seg_inv.out'` 
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aocsseg_$oid;" -o  '/tmp/pivotal/segment/pg_aocsseg_inv.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aoseg_$oid;"  -o  '/tmp/pivotal/segment/pg_aoseg_inv.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;Select xmin,xmax,cmin,cmax,ctid,* from pg_appendonly;" -o  '/tmp/pivotal/segment/pg_appendonly_inv.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;select * from gp_distributed_log;" -o '/tmp/pivotal/segment/gp_distributed_log_inv.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -t -c "set gp_select_invisible=off;set gp_select_invisible=on;select xmin,xmax,cmin,cmax,ctid,oid,* from pg_class;" -o '/tmp/pivotal/segment/pg_class_inv.out'`


tar -zcvf catalog-rca.tar.gz /tmp/pivotal