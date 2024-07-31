#!/bash/sh

backupPath=/tmp/mysql_backup
mysqlCfg=./mysql.txt
mysqlPass=./mysql_pass
mysqlBin=./mysql_bin

action=$1
arg1=$2
arg2=$3


mysqlBinGet(){
  # 判断有没有mysql
  checkMysql=$(command -v mysql)
  mysqlBinCfg=$(cat ${mysqlBin})
   if [ "$checkMysql" = "" ]; then
        if [ "$mysqlBinCfg" = "" ]; then
            echo "找不到mysql可执行文件,请编辑mysql_bin手动配置mysql的bin目录路径"
            exit 1
        else
          echo "$mysqlBinCfg"
        fi
    else
      mysqlRealBin="$(echo "$checkMysql" | sed 's/\/mysql//g')"
      echo "$mysqlRealBin"
    fi
}

mysqlDumpFile(){
  mysqlBinPath=$(mysqlBinGet)
  mysqlDump="$mysqlBinPath/mysqldump"

  if [ -f "${mysqlDump}" ]; then
     echo "$mysqlDump"
  else
      echo "${mysqlDump}文件不存在,请检查后再试"
      exit 1
  fi
}

mysqlFile(){
  mysqlBinPath=$(mysqlBinGet)
  mysql="$mysqlBinPath/mysql"

  if [ -f "${mysql}" ]; then
     echo "$mysql"
  else
      echo "${mysql}文件不存在,请检查后再试"
      exit 1
  fi
}


mysqlDump(){
  dumpFile=$(mysqlDumpFile)
  mysqlRootPwd=$(cat ${mysqlPass})
  mkdir -p "$backupPath"

  if [ "$arg2" = "" ]; then
     # 备份整库
      backupFile="${backupPath}/${arg1}_$(date +'%Y%m%d_%H%M%S').sql"
      echo "backup all db, db=$arg1 file=$backupFile"
      $dumpFile -uroot -p"$mysqlRootPwd" "$arg1" > "$backupFile"
  else
      # 备份单表
      backupFile="${backupPath}/${arg1}_${arg2}_$(date +'%Y%m%d_%H%M%S').sql"
      echo "backup one table,db=$arg1 table=$arg2 file=$backupFile"
      $dumpFile -uroot -p"$mysqlRootPwd" "$arg1" "$arg2"> "$backupFile"
  fi

  echo ""

  # 检查备份是否成功
  # shellcheck disable=SC2181
  if [ $? -eq 0 ]; then
    echo "MySQL备份成功: $backupFile"
  else
    echo "MySQL备份失败"
  fi
}

mysqlDbImport(){
  searchFileRes=$(ls ${backupPath} | grep "$arg1" | grep "$arg2")
  if [ "${searchFileRes}" = "" ]; then
    echo "找不到导入源文件:${searchFileRes}相关文件"
    exit 1
  fi

  mysqlFile=$(mysqlFile)

  searchFileList=(${searchFileRes// / })
  chooseFile=${searchFileList[0]}
  fileLen=${#searchFileList[*]}
  if [ ${fileLen} -gt 1 ]; then
    echo "匹配到多个文件"
    echo "====================================="
     for ((i=0;i<${fileLen};i++));
     do
        echo "[$i]=${searchFileList[${i}]}"
     done
     echo "====================================="
     read -p "入文件下标选取对应文件进行导入: " index
     while [ ${index} -lt 0 -o ${index} -ge ${fileLen} ] ; do
       read -p "文件下标错误，请重新输入: " Index
     done
  chooseFile=${searchFileList[index]}
  fi
  echo "准备导入${chooseFile}->${arg2}"
  $mysqlFile  --defaults-extra-file="$mysqlCfg" mysql <<EOF
DROP DATABASE IF EXISTS ${arg2};
CREATE DATABASE IF NOT EXISTS ${arg2};
EOF
  $mysqlFile  --defaults-extra-file="$mysqlCfg" ${arg2} < ${backupPath}/${chooseFile}
  if [ $? -eq 0 ]; then
    echo "导入数据成功"
  else
   echo "导入数据失败"
    exit 0
  fi
}

beforeAction(){
  mysqlBinGet

  if [ -f "${mysqlCfg}" ]; then
    return
  else
      echo "${mysqlCfg}文件不存在,请检查后再试"
      exit 1
  fi

  if [ -f "${mysqlPass}" ]; then
    return
  else
      echo "${mysqlPass}文件不存在,请检查后再试"
      exit 1
  fi
}

beforeAction

case $action in
  "backup")
    mysqlDump
    exit 1
    ;;
  "importDb")
    mysqlDbImport
    exit 1
    ;;
  *)
    echo "unknown action:$action"
    echo "备份数据(表名不传备份整个库)：sh mysql.sh backup dbName tableName"
    echo "导入整库数据：sh mysql.sh importDb oldDbName newDbName"
    exit 1
    ;;
esac