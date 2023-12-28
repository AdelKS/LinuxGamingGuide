#!/usr//bin/env bash

LAUNCHER="lutris" # replace if not using lutris, ie. "steam"

create_ranges() {
  local input=$1
  local output_var=$2
  IFS=',' read -r -a core_array <<< "$input"
  sorted_corenums=($(printf "%s\n" "${core_array[@]}" | sort -n))

  local ranges=""
  local flr=""
  local ceil=""
  for n in "${sorted_corenums[@]}"; do
    if [[ -z "$flr" ]]; then
      flr="$n"
    elif (( n - 1 == ceil )); then
      ceil="$n"
    else
      if [[ -n "$ranges" ]]; then
        ranges+=","
      fi
      ranges+="$flr-$ceil"
      flr="$n"
    fi
    ceil="$n"
  done

  if [[ -n "$flr" ]]; then
    if [[ -n "$ranges" ]]; then
      ranges+=","
    fi
    ranges+="$flr-$ceil"
  fi

  eval "$output_var='$ranges'"
}

read cores0 cores1 < <(lstopo-no-graphics | perl -ne '
  if ( /L3/ ) { 
    chop $result if $result;
    $result .= " " if $result; 
  } elsif ( /\(P#(\d+)\)/ ) {
    $result .= "$1,";
  }
  END { 
    chop $result; 
    print $result;
  }'
)

create_ranges $cores0 CCX0 2>/dev/null
create_ranges $cores1 CCX1 2>/dev/null

if [[ -z $CCX0 || -z $CCX1 ]]; then
  echo "Aborted! Only 1 CCX found."
  exit 1
fi

echo "Found core P#s:"
echo -e "\tCCX0: $CCX0"
echo -e "\tCCX1: $CCX1"

echo "Mounting the cpuset filesystem"
if ! [[ -d /dev/cpuset ]]; then
  mkdir /dev/cpuset
  mount -t cpuset cpuset /dev/cpuset
fi

_prefix=""

if [[ -f /dev/cpuset/cpuset.cpus ]];then
  _prefix="cpuset."
fi

if ! [[ -d /dev/cpuset/theUgly ]]; then
  echo "Creating theUgly"
  mkdir /dev/cpuset/theUgly
fi

echo "Assigning CCX0's cores to theUgly cpu set"
/bin/echo $CCX0 > /dev/cpuset/theUgly/${_prefix}cpus

echo "Giving theUgly memory node 0"
/bin/echo 0 > /dev/cpuset/theUgly/${_prefix}mems

echo "Making theUgly cpu exclusive"
/bin/echo 1 > /dev/cpuset/theUgly/${_prefix}cpu_exclusive

echo "Redirecting all processes to theUgly"
success=0
fail=0
while read p; do
  /bin/echo $p > /dev/cpuset/theUgly/tasks && ((success++)) || ((fail++))
done < /dev/cpuset/tasks 2>/dev/null
echo -e "\t$success processes successfully redirected."
echo -e "\t$fail processes failed to redirect."

if ! [[ -d /dev/cpuset/theGood ]]; then
  echo "Creating theGood"
  mkdir /dev/cpuset/theGood
fi

echo "Assigning CCX1's cores to theGood cpu set"
/bin/echo $CCX1 > /dev/cpuset/theGood/${_prefix}cpus

echo "Giving theGood memory node 0"
/bin/echo 0 > /dev/cpuset/theGood/${_prefix}mems

echo "Making theGood cpu exclusive"
/bin/echo 1 > /dev/cpuset/theGood/${_prefix}cpu_exclusive

read -p "Redirect $LAUNCHER to theGood? y/n: "
if [[ "$REPLY" == "y" ]]; then
  success=0
  fail=0
  while read p; do
      /bin/echo $p > /dev/cpuset/theGood/tasks  && ((success++)) || ((fail++))
  done < <(pgrep $LAUNCHER)

  if (( success > 0 )); then
    echo -e "\t$success $LAUNCHER process(es) successfully redirected."
  elif (( fail > 0 )); then
    echo -e "\t$fail $LAUNCHER process(es) failed to redirect."
  else
    echo -e "\tNo $LAUNCHER processes found."
  fi
fi
