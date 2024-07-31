#!/bash/sh

action=$1
arg1=$2


portCheck(){
  echo "check port $arg1"
  if [ "$arg1" -eq 0 ]; then
      echo "$arg1不是有效的端口"
      return
  fi
  # 判断有没有netstat
  checkNetStat=$(command -v netstat)
  if [ "$checkNetStat" != "" ]; then
      netstat -tulnp | grep "$arg1"
      return
  fi
  # 判断有没有ls
  checkLSOF=$(command -v lsof)
  if [ "$checkLSOF" != "" ]; then
      lsof -i :"$arg1"
      return
  fi
  echo "I didn't find the right command to do it."
}


findPort(){
  echo "find $arg1 port"
  if [ "$arg1" = "" ]; then
      echo "$arg1 not correct,like 'sh run.sh findPort xxx'"
      return
  fi
  checkPS=$(command -v ps)
  if [ "$checkPS" != "" ]; then
      ps aux | grep "$arg1"
      return
  fi
  echo "I didn't find the right command to do it."
}


duSort(){
  echo "sort $arg1..."
  if [ "$arg1" = "" ]; then
      echo "$arg1 not correct,like 'sh run.sh duSort youPath'"
      return
  fi
  du -sh "$arg1"/* | sort -rh | head -n 10
}


case $action in
  "portCheck")
    portCheck
    exit 1
    ;;
  "findPort")
    findPort
    exit 1
    ;;
  "duSort")
    duSort
    exit 1
    ;;
  *)
    echo "unknown action:$action"
    echo "查找端口是否占用: sh run.sh portCheck 3306"
    echo "查找关键字占用端口: sh run.sh findPort mysql"
    echo "排序某个路径下的最大占用: sh run.sh duSort youPath"
    exit 1
    ;;
esac

exit 0


