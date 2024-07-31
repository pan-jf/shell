#!/bash/sh

backupPath=/tmp/mysql_backup
mysqlCfg=./mysql.txt
mysqlPass=./mysql_pass
mysqlBin=""

action=$1
arg1=$2
arg2=$3


mysqlBinGet(){
  # 判断有没有mysql
  checkMysql=$(command -v mysql)
   if [ "$checkMysql" = "" ]; then
        if [ "$mysqlBin" = "" ]; then
            echo "找不到mysql可执行文件,请编辑本文件手动配置mysql的bin目录路径"
            exit 1
        else
          echo "$mysqlBin"
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
  *)
    echo "unknown action:$action"
    echo "备份数据：sh mysql.sh backup dbName tableName"
    exit 1
    ;;
esac