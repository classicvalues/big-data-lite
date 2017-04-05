#!/bin/bash
#
# jupyter  Start/Stop the Jupyter notebooks
#
# chkconfig: 5 90 60

# If anything goes wrong, fail
exit_err () {
  echo "There was an error, please review the output above and, if appropriate, report a bug on https://github.com/oracle/big-data-lite with the full output of the script."
  exit 1
}
trap 'exit_err' ERR

dir=$(dirname "$(readlink -f $0)")
thirdparty_root=$dir/inst/
anaconda_inst_url=https://repo.continuum.io/archive/Anaconda2-4.3.1-Linux-x86_64.sh
jupyter_root=$thirdparty_root/jupyter

check_running () {
  if [ ! -f $jupyter_root/server_pid.txt ]; then
    return 1
  fi

  if ps $(cat $jupyter_root/server_pid.txt) &> /dev/null; then
    return 0
  fi

  rm -rf $jupyter_root/server_pid.txt
  return 1
}

cd $dir

if [ "$1" == "install" ]; then
  echo "Setting up Anaconda..."
  mkdir -p $jupyter_root
  anaconda_inst=$jupyter_root/$(basename $anaconda_inst_url)
  [ -f $anaconda_inst ] ||
    curl $anaconda_inst_url -o $anaconda_inst

  rm -rf $jupYter_root/anaconda2
  bash $anaconda_inst -b -p$jupyter_root/anaconda2 

  (
  echo "Add to system services? (works on Oracle Linux, requires sudo) [Y/n]"
  read a
  a=""
  [ "$a" == "n" ] && exit 0
  sudo rm -f /etc/init.d/jupyter
  sudo ln -s "$(readlink -f $0)" /etc/init.d/jupyter
  sudo chkconfig --add jupyter
  )

  exit 0
elif [ "$1" == "start" ]; then
  if check_running; then
    echo "Error: Jupyter notebook already running (PID: $(cat $jupyter_root/server_pid.txt), stop it first."
    exit 0
  fi
  $jupyter_root/anaconda2/bin/jupyter-notebook --no-browser &

  sleep 3

  pid=$!
  echo $pid > $jupyter_root/server_pid.txt

  exit 0
elif [ "$1" == "uninstall" ]; then
  rm -rf $thirdparty_root/anaconda
  rm -rf $thirdparty_root/jupyter

  exit 0
elif [ "$1" == "stop" ]; then
  if ! check_running; then
    echo "Error: Jupyter notebook not running."
    exit 0
  fi
  kill -SIGTERM $(cat $jupyter_root/server_pid.txt)
  rm $jupyter_root/server_pid.txt

  exit 0
elif [ "$1" == "status" ]; then
  trap '' ERR

  if check_running; then
    echo "Jupyter notebook running (pid: $(cat $jupyter_root/server_pid.txt))."
    exit 0
  else
    echo "Jupyter notebook not running."
    exit 1
  fi
fi

echo "Usage: $0 {install | uninstall | start | stop | status}"
exit -1

