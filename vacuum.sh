analyze() {
echo -n "Enter the name of the database with tables you'd like to analyze: "
read databaseName
echo -n "The name of the database is $databaseName"
echo -n "Enter the name of the database with tables you'd like to analyze: "
read tableName
echo -n "The name of the database is $tableName"
exists=`psql -X -A -d "$databaseName" -c "SELECT tablename FROM pg_catalog.pg_tables where tablename = 'analyze_info';"`
exists=$(echo $exists | sed 's/[^0-9]*//g')
echo $exists
if [ "$exists"  == "0" ]; then
`psql -X -A -d "$databaseName" -t -c "create table analyze_info (relname varchar(255), actual_time int);"`
fi
start=`date +%s`
`psql -X -A -d "$databaseName" -t -c "ANALYZE "$tableName";"`
end=`date +%s`
runtime=$((end-start))
echo $runtime
count=`psql -X -A -d "$databaseName" -t -c "SELECT count(*) FROM analyze_info WHERE relname = '$tableName' LIMIT 1;"`
echo $count
if [ "$count" -ge "1" ] ; then
`psql -X -A -d "$databaseName" -t -c "update analyze_info set actual_time = '$runtime' where relname = '$tableName';"`
else
`psql -X -A -d "$databaseName" -t -c "insert into analyze_info (relname, actual_time, operation) values ('$tableName', '$runtime');"`
fi
}

analyzeDB() {
echo -n "Enter the name of the database with the analyzedbLogs: "
read databaseName
exists=`psql -X -A -d "$databaseName" -c "SELECT tablename FROM pg_catalog.pg_tables where tablename = 'analyze_info';"`
exists=$(echo $exists | sed 's/[^0-9]*//g')
echo $exists
if [ "$exists"  == "0" ]; then
`psql -X -A -d "$databaseName" -t -c "create table analyze_info (relname varchar(255), actual_time int, operation varchar(255));"`
fi
#insert lastest analyzeDb log info into analyze table
cd
latestAnalyzeDB=$(ls -td gpAdminLogs/analyzedb* | head -1)
string1="Starting analyzedb with args: -d"
combined="$string1 $databaseName"
echo $combined
echo $latestAnalyzeDB
awk -v combined="$combined" -v latestAnalyzeDB="$latestAnalyzeDB" '$0~combined ,/Done./' "$latestAnalyzeDB" >> gpAdminLogs/something.out
echo step 1
grep 'finished' gpAdminLogs/something.out | awk -F' ' '{print $5 $8 }' | sed 's/\./,/2' >> gpAdminLogs/analyze.out
echo building file analyze.out for getting analyzedb information
awk '!seen[$0]' gpAdminLogs/analyze.out >> gpAdminLogs/seenAnalyze.out
sed 's/rootpartitiontime://g' gpAdminLogs/seenAnalyze.out >> gpAdminLogs/removeJunkAnalyze.out
cat gpAdminLogs/removeJunkAnalyze.out | grep . >> gpAdminLogs/removeEOF.out
echo Inserting information into analyze_info table
`psql -X -A -d "$databaseName" -t -c "create table analyze_info_temp (id serial, relname varchar(255), actual_time int);"`
`psql -X -A -d "$databaseName" -t -c "COPY analyze_info_temp (relname, actual_time) FROM '/home/gpadmin/gpAdminLogs/removeEOF.out' WITH DELIMITER ',';"`
echo Removing duplicate rows or tables that have a 0 value
`psql -X -A -d "$databaseName" -t -c "DELETE FROM analyze_info_temp where actual_time = '0';"`
`psql -X -A -d "$databaseName" -t -c "delete from analyze_info_temp where exists (select 1 from analyze_info t2 where t2.relname = analyze_info_temp.relname and t2.actual_time = analyze_info_temp.actual_time);"`
`psql -X -A -d "$databaseName" -t -c "insert into analyze_info (relname,actual_time)  (select relname, actual_time from analyze_info_temp);"`
`psql -X -A -d "$databaseName" -t -c "Drop Table analyze_info_temp;"`
rm -r gpAdminLogs/something.out
rm -r gpAdminLogs/analyze.out
rm -r gpAdminLogs/seenAnalyze.out
rm -r gpAdminLogs/removeJunkAnalyze.out
rm -r gpAdminLogs/removeEOF.out
}

reindex() {
echo -n "Enter the name of the database with the table you'd like to reindex: "
read databaseName
#create the table
exists=`psql -X -A -d "$databaseName" -c "SELECT tablename FROM pg_catalog.pg_tables where tablename = 'reindex_info';"`
exists=$(echo $exists | sed 's/[^0-9]*//g')
if [ "$exists"  == "0" ]; then
`psql -X -A -d "$databaseName" -t -c "create table reindex_info (relname varchar(255), actual_time int);"`
fi
echo -n "Do you want to reindex a database or table (please select database or table): "
read dbOrTable
if [ "$dbOrTable" == "table" ]; then
echo -n "Enter the name of the table you'd like to reindex: "
read tableName
start=`date +%s`
`psql -X -A -d "$databaseName" -t -c "REINDEX Table "$tableName";"`
end=`date +%s`
runtime=$((end-start))
echo $runtime
count=`psql -X -A -d "$databaseName" -t -c "SELECT count(*) FROM reindex_info WHERE relname = '$tableName' LIMIT 1;"`
echo $count
if [ "$count" -ge "1" ] ; then
`psql -X -A -d "$databaseName" -t -c "update reindex_info set actual_time = '$runtime' where relname = '$tableName';"`
else
`psql -X -A -d "$databaseName" -t -c "insert into reindex_info (relname, actual_time) values ('$tableName', '$runtime');"`
fi
else
start=`date +%s`
`psql -X -A -d "$databaseName" -t -c "REINDEX DATABASE "$databaseName";"`
end=`date +%s`
runtime=$((end-start))
echo $runtime
count=`psql -X -A -d "$databaseName" -t -c "SELECT count(*) FROM reindex_info WHERE relname = '$databaseName' LIMIT 1;"`
echo $count
if [ "$count" -ge "1" ] ; then
database="$databaseName database"
`psql -X -A -d "$databaseName" -t -c "update reindex_info set actual_time = '$runtime' where relname = '$database';"`
else
database="$databaseName database"
`psql -X -A -d "$databaseName" -t -c "insert into reindex_info (relname, actual_time) values ('$database', '$runtime');"`
fi 
fi
}

vacuum() {
echo -n "Enter the name of the database with tables you'd like to vacuum: "
read databaseName
echo -n "The name of the database is $databaseName"
#create the table with the dummy number of 1000
exists=`psql -X -A -d "$databaseName" -c "SELECT tablename FROM pg_catalog.pg_tables where tablename = 'vacuum_info';"`
exists=$(echo $exists | sed 's/[^0-9]*//g')
if [ "$exists"  == "0" ]; then
`psql -X -A -d "$databaseName" -t -c "create table vacuum_info As select bdinspname, bdirelname, bdirelpages, bdiexppages, (bdirelpages - bdiexppages) bdidiff,  1000 pages_per_second,
ROUND((((bdirelpages)/1000)/60), 2) estimated_time, 0 actual_time  from gp_toolkit.gp_bloat_diag where bdirelname <> 'gp_persistent_relation_node';"`
fi
#get the most bloated catalog table
tableName=`psql -X -A -d "$databaseName" -t -c "Select bdirelname, (bdirelpages - bdiexppages) bdidiff from gp_toolkit.gp_bloat_diag where bdirelname <> 'gp_persistent_relation_node' order by bdidiff desc limit 1;"`
#trim the numbers created by the bdidiff category
tableName=${tableName//[0-9]/}
#trim the pipe of the table name
tableName=${tableName//[|]/}
#get the relpages from that table
relPages=`psql -X -A -d "$databaseName" -t -c  "Select bdirelpages from gp_toolkit.gp_bloat_diag where bdirelname = '$tableName';"`
echo "Running Vacuum on $tableName"
start=`date +%s`
`psql -X -A -d "$databaseName" -t -c "Vacuum $tableName;"`
echo "vacuum complete"
end=`date +%s`
runtime=$((end-start))
echo  "This how long in seconds it took $runtime"
if [ $runtime = 0 ]; then
echo "the run time equals 0 no point in updating"
exit
fi
#divide relpages and total run time to get a page per second
final=$((relPages / runtime))
echo  "your base line is $final bdirelpages per second"
#check for view existance by getting count
exist=`psql -X -A -d "$databaseName" -t -c "select count(*) from vacuum_info;"`
if [ "$exist" >  "0" ]
then
# database exists
count=`psql -X -A -d "$databaseName" -t -c "select * from vacuum_info where pages_per_second <> $final;"`
echo $count
oldFinal=`psql -X -A -d "$databaseName" -t -c "select pages_per_second from vacuum_info limit 1;"`
if [ "$count" > "0" ]; then
newFinal=$(((oldFinal+final)/2))
echo "this the upated average $newFinal"
`psql -X -A -d "$databaseName" -t -c "update vacuum_info set pages_per_second = '$newFinal' where pages_per_second = '$oldFinal' and bdirelname = '$tableName';"`
`psql -X -A -d "$databaseName" -t -c "update vacuum_info set actual_time = '$runtime' where bdirelname = '$tableName';"`
`psql -X -A -d "$databaseName" -t -c "update vacuum_info set estimated_time = ROUND((bdirelpages/$newFinal), 2) where pages_per_second = '$newFinal' and bdirelname = '$tableName';"`
fi
else
# create database for metric logging
`psql -X -A -d "$databaseName" -t -c "create table vacuum_info As select bdinspname, bdirelname, bdirelpages, bdiexppages, (bdirelpages - bdiexppages) bdidiff,  $final pages_per_second,
ROUND((((bdirelpages)/$final)/60), 2) estimated_time, 0 actual_time  from gp_toolkit.gp_bloat_diag where bdirelname <> 'gp_persistent_relation_node';"`
fi
}

vacuum_full() {
echo -n "Enter the name of the database with tables you'd like to vacuum: " 
read databaseName
echo -n "The name of the database is $databaseName"

#create the table with the dummy number of 1000
exists=`psql -X -A -d "$databaseName" -c "SELECT tablename FROM pg_catalog.pg_tables where tablename = 'vacuum_full_info';"`
exists=$(echo $exists | sed 's/[^0-9]*//g')
echo $exists
if [ "$exists"  == "0" ]; then
`psql -X -A -d "$databaseName" -t -c "create table vacuum_full_info As select bdinspname, bdirelname, bdirelpages, bdiexppages, (bdirelpages - bdiexppages) bdidiff,  1000 pages_per_second,
ROUND((((bdirelpages)/1000)/60), 2) estimated_time, 0 actual_time  from gp_toolkit.gp_bloat_diag where bdirelname <> 'gp_persistent_relation_node';"`
fi
#get the most bloated catalog table
tableName=`psql -X -A -d "$databaseName" -t -c "Select bdirelname, (bdirelpages - bdiexppages) bdidiff from gp_toolkit.gp_bloat_diag where bdirelname <> 'gp_persistent_relation_node' order by bdidiff desc limit 1;"`
#trim the numbers created by the bdidiff category
tableName=${tableName//[0-9]/}
#trim the pipe of the table name
tableName=${tableName//[|]/}
#get the relpages from that table
relPages=`psql -X -A -d "$databaseName" -t -c  "Select bdirelpages from gp_toolkit.gp_bloat_diag where bdirelname = '$tableName';"`
echo "Running Vacuum Full on $tableName"
start=`date +%s`
`psql -X -A -d "$databaseName" -t -c "Vacuum Full $tableName;"` 
echo "vacuumdb complete"
end=`date +%s`
runtime=$((end-start))
echo  "This how long in seconds it took $runtime"
if [ $runtime = 0 ]; then
echo "the run time equals 0 no point in updating"
exit
fi
#divide relpages and total run time to get a page per second
final=$((relPages / runtime))
echo  "your base line is $final bdirelpages per second"
#check for view existance by getting count
exist=`psql -X -A -d "$databaseName" -t -c "select count(*) from vacuum_full_info;"`
if [ "$exist" >  "0" ]
then
# database exists
count=`psql -X -A -d "$databaseName" -t -c "select * from vacuum_full_info where pages_per_second <> $final;"`
echo $count
oldFinal=`psql -X -A -d "$databaseName" -t -c "select pages_per_second from vacuum_full_info limit 1;"`
if [ "$count" > "0" ]; then
newFinal=$(((oldFinal+final)/2))
echo "this the upated average $newFinal"
`psql -X -A -d "$databaseName" -t -c "update vacuum_full_info set pages_per_second = '$newFinal' where pages_per_second = '$oldFinal' and bdirelname = '$tableName';"`
`psql -X -A -d "$databaseName" -t -c "update vacuum_full_info set actual_time = '$runtime' where bdirelname = '$tableName';"`
`psql -X -A -d "$databaseName" -t -c "update vacuum_full_info set estimated_time = ROUND((bdirelpages/$newFinal), 2) where pages_per_second = '$newFinal' and bdirelname = '$tableName';"`
fi
else
# create database for metric logging
`psql -X -A -d "$databaseName" -t -c "create table vacuum_full_info As select bdinspname, bdirelname, bdirelpages, bdiexppages, (bdirelpages - bdiexppages) bdidiff,  $final pages_per_second,
ROUND((((bdirelpages)/$final)/60), 2) estimated_time, 0 actual_time  from gp_toolkit.gp_bloat_diag where bdirelname <> 'gp_persistent_relation_node';"`
fi
}

maintenance_window() {
echo -n "How long is your maintenance window in seconds (i.e. 8 hours is 8 * 60 * 60)?: "
read maintenanceWindowTime

echo -n "Enter the name of the database you'd like perform maintenance on: " 
read databaseName


}

display_help() {
echo -n "./maintenance.sh [OPTION]...

These are 

Options:
-a, --analyze       run analyze for specific table
-A, --analyzeDB     take analyzedb log info and insert into table
-r, --reindex       reindex table or database
-v, --vacuum        vacuum table
-V, --vacuum_full   run vacuum full on table
-h, --help          Display this help and exit
"
}

main() {
if [ -z "$1" ]; then
echo -n  Please specify database name, --analyze, --reindex, --vacuum, --vacuum_full
echo
fi
while [ $# -gt 0 ]; do
case "$1" in
-a | --analyze)
analyze
;;
-A | --analyzeDB)
analyzeDB
;;
-h | --help)
display_help
exit 0
;;
-r | --reindex)
reindex
;;
-v | --vacuum)
vacuum
;;
-V | --vacuum_full)
vacuum_full
;;
*)
#last analyze
currentDate=`psql -X -A -t -c  "SELECT CURRENT_DATE;"`
lastAnalyzeDate=`psql -X -A -d "$1" -t -c "SELECT DATE(pslo.statime) as action_date FROM pg_stat_last_operation pslo right outer join pg_class pc on pc.oid = pslo.objid and pslo.staactionname in ('ANALYZE') join pg_namespace pn on pn.oid = pc.relnamespace WHERE 1=1 AND pc.relkind IN ('r','s','') AND pc.relstorage IN ('h', 'a', 'c','') AND pslo.statime IS NOT NULL ORDER BY pslo.statime desc LIMIT 1;"`
if [ -z "$lastAnalyzeDate" ]; then
echo "You haven't analyzed your database"
else
dateDiff=`psql -X -A -t -c "SELECT CURRENT_DATE - '$lastAnalyzeDate';"`
echo Your last analyze on "$1" was $dateDiff day\(s\) ago
fi

#last reindex
currentDate=`psql -X -A -t -c "SELECT CURRENT_DATE;"`
lastReindexDate=`psql -X -A -d "$1" -t -c "SELECT DATE(pslo.statime) as action_date FROM pg_stat_last_operation pslo right outer join pg_class pc on pc.oid = pslo.objid and pslo.staactionname in ('REINDEX') join pg_namespace pn on pn.oid = pc.relnamespace WHERE 1=1 AND pc.relkind IN ('r','s','') AND pc.relstorage IN ('h', 'a', 'c','') AND pslo.statime IS NOT NULL ORDER BY pslo.statime desc LIMIT 1;"`
if [ -z "$lastReindexDate"  ]; then
echo "You haven't reindexed any tables"
else
dateDiff=`psql -X -A -t -c "SELECT CURRENT_DATE - '$lastReindexDate';"`
echo Your last reindex on "$1" was $dateDiff day\(s\) ago
fi

#last vacuum
currentDate=`psql -X -A -t -c "SELECT CURRENT_DATE;"`
lastVacuumDate=`psql -X -A -d "$1" -t -c "SELECT DATE(pslo.statime) as action_date FROM pg_stat_last_operation pslo right outer join pg_class pc on pc.oid = pslo.objid and pslo.staactionname in ('VACUUM') join pg_namespace pn on pn.oid = pc.relnamespace WHERE 1=1 AND pc.relkind IN ('r','s','') AND pc.relstorage IN ('h', 'a', 'c','') AND pslo.statime IS NOT NULL AND pslo.stasubtype IS NOT NULL ORDER BY pslo.statime desc LIMIT 1;"`
if [ -z "$lastVacuumDate" ]; then
echo "You haven't vacuumed your database"
else
dateDiff=`psql -X -A -t -c "SELECT CURRENT_DATE - '$lastVacuumDate';"`
echo Your last vacuum was on "$1" $dateDiff day\(s\) ago
fi

#last vacuum full
currentDate=`psql -X -A -t -c "SELECT CURRENT_DATE;"`
lastVacuumFullDate=`psql -X -A -d "$1" -t -c "SELECT DATE(pslo.statime) as action_date FROM pg_stat_last_operation pslo right outer join pg_class pc on pc.oid = pslo.objid and pslo.staactionname in ('VACUUM') join pg_namespace pn on pn.oid = pc.relnamespace WHERE 1=1 AND pc.relkind IN ('r','s','') AND pc.relstorage IN ('h', 'a', 'c','') AND pslo.statime IS NOT NULL AND pslo.stasubtype IS NOT NULL ORDER BY pslo.statime desc LIMIT 1;"`
if [ -z "$lastVacuumFullDate" ]; then
echo "You haven't ran vacuum full on your database"
else
dateDiff=`psql -X -A -t -c "SELECT CURRENT_DATE - '$lastVacuumFullDate';"`
echo Your last vacuum on "$1" full was $dateDiff day\(s\) ago
fi
esac
shift
done
}
main "$@"; exit



# select sum(actual_time) from (
# select relname, actual_time from analyze_info
# union all
# select relname, actual_time from reindex_info
# union all 
# select bdirelname, actual_time from vacuum_full_info
# order by actual_time desc
# ) x;