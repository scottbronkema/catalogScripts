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

echo -n "Are you ok with copying transaction logs, they take up a lot of space. Yes or No? "
read transLogsYn

echo -n "Which version of Greenplum are you? Enter 4, 5, 6, etc "
read gpdbVersion

echo -n "Which index we need to test? "
read indexScanTest

mkdir -p /tmp/pivotal
mkdir -p /tmp/pivotal/master
mkdir -p /tmp/pivotal/segment

if [ $transLogsYn == 'Yes' ] || [ $transLogsYn == 'Y' ] || [ $transLogsYn == 'yes' ] ||  [ $transLogsYn == 'y' ]; then
	`psql -X -A -d "$databaseName" -c "select * from gp_transaction_log;" -o '/tmp/pivotal/'$databaseName'_transaction_log'`
fi

`psql -X -A -d "$databaseName"  -c "select oid, relname, reltype from pg_class limit 2;" -o '/tmp/pivotal/pg_class.out'`

echo "creating indexscan"
`psql -f $GPHOME/share/postgresql/contrib/indexscan.sql $databaseName`
if [ $gpdbVersion == '4' ] || [ $gpdbVersion == '5' ]; then
	`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "select * from readindex('$indexScanTest'::regclass::oid) as (ictid tid, hctid tid, aotid text, istatus text, hstatus text, oid int);"`
else
	`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "select * from readindex('$indexScanTest'::regclass::oid) as (ictid tid, hctid tid, aotid text, istatus text, hstatus text, oid oid);"`
fi


##do the utility mode connections commands
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster"  -X -A -d "$databaseName" -c "set gp_select_invisible=on; select * from pg_aoseg.pg_aocsseg_$oid;" -o '/tmp/pivotal/master/'$databaseName_'gp_aocsseg.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster" -h "$hostNameMaster"  -X -A -d "$databaseName" -c "set gp_select_invisible=on; select xmin,xmax,cmin,cmax,ctid,* from pg_stat_last_operation;" -o  '/tmp/pivotal/master/'$databaseName'_pg_stat_last_operation.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "set gp_select_invisible=on; select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aoseg_$oid;"  -o  '/tmp/pivotal/master/'$databaseName'_pg_aoseg.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "set gp_select_invisible=on; select xmin,xmax,cmin,cmax,ctid,* from pg_appendonly;" -o  '/tmp/pivotal/master/'$databaseName'_pg_appendonly.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "set gp_select_invisible=on; select * from gp_distributed_log;" -o '/tmp/pivotal/master/'$databaseName'_gp_distributed_log.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "set gp_select_invisible=on; select ctid, * from gp_persistent_relation_node;" -o  '/tmp/pivotal/master/'$databaseName'_gp_persistent_relation_node.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "set gp_select_invisible=on; select xmin,xmax,cmin,cmax,ctid,oid,* from pg_class;" -o  '/tmp/pivotal/master/'$databaseName'_pg_class.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "set gp_select_invisible=on; select xmin,xmax,cmin,cmax,ctid,* from pg_stat_last_operation;" -o  '/tmp/pivotal/master/'$databaseName'_pg_stat_last_operation.out'  `

##do utility segment
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -c "set gp_select_invisible=on; select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aocsseg_$oid;" -o  '/tmp/pivotal/segment/'$databaseName'_pg_aocsseg.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -c "set gp_select_invisible=on; select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aoseg_$oid;"  -o  '/tmp/pivotal/segment/'$databaseName'_pg_aoseg.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -c "set gp_select_invisible=on; select xmin,xmax,cmin,cmax,ctid,* from pg_appendonly;" -o  '/tmp/pivotal/segment/'$databaseName'_pg_appendonly.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -c " select * from gp_distributed_log;" -o '/tmp/pivotal/segment/'$databaseName'_gp_distributed_log.out'`
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -c "set gp_select_invisible=on; select xmin,xmax,cmin,cmax,ctid,oid,* from pg_class;" -o '/tmp/pivotal/segment/'$databaseName'_pg_class.out'  `

#set invisible
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "set gp_select_invisible=off; select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aocsseg_$oid;" -o  '/tmp/pivotal/master/'$databaseName'_pg_aocsseg_inv.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster" -h "$hostNameMaster"  -X -A -d "$databaseName" -c "set gp_select_invisible=off; select xmin,xmax,cmin,cmax,ctid,* from pg_stat_last_operation;" -o  '/tmp/pivotal/master/'$databaseName'_pg_stat_last_operation_inv.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "set gp_select_invisible=off; select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aoseg_$oid;"  -o  '/tmp/pivotal/master/'$databaseName'_pg_aoseg_inv.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "set gp_select_invisible=off; select xmin,xmax,cmin,cmax,ctid,* from pg_appendonly;" -o  '/tmp/pivotal/master/'$databaseName'_pg_appendonly_inv.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "set gp_select_invisible=off; select * from gp_distributed_log;" -o '/tmp/pivotal/master/'$databaseName'_gp_distributed_log_inv.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "set gp_select_invisible=off; select xmin,xmax,cmin,cmax,ctid,oid,* from pg_class;" -o  '/tmp/pivotal/master/'$databaseName'_pg_class_inv.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberMaster"  -h "$hostNameMaster" -X -A -d "$databaseName" -c "set gp_select_invisible=off; select xmin,xmax,cmin,cmax,ctid,* from pg_stat_last_operation;" -o  '/tmp/pivotal/master/'$databaseName'_pg_stat_last_operation_inv.out'  `

##do utility segment
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -c "set gp_select_invisible=off; select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aocsseg_$oid;" -o  '/tmp/pivotal/segment/'$databaseName'_pg_aocsseg_inv.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -c "set gp_select_invisible=off; select xmin, xmax,cmin,cmax,ctid,*  from pg_aoseg.pg_aoseg_$oid;"  -o  '/tmp/pivotal/segment/'$databaseName'_pg_aoseg_inv.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -c "set gp_select_invisible=off; select xmin,xmax,cmin,cmax,ctid,* from pg_appendonly;" -o  '/tmp/pivotal/segment/'$databaseName'_pg_appendonly_inv.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -c "set gp_select_invisible=off; select * from gp_distributed_log;" -o '/tmp/pivotal/segment/'$databaseName'_gp_distributed_log_inv.out'  `
`PGOPTIONS='-c gp_session_role=utility' psql -p "$portNumberSegment"  -h "$hostNameSegment" -X -A -d "$databaseName" -c "set gp_select_invisible=off; select xmin,xmax,cmin,cmax,ctid,oid,* from pg_class;" -o '/tmp/pivotal/segment/'$databaseName'_pg_class_inv.out'  `


tar -zcvf catalog-rca.tar.gz /tmp/pivotal
