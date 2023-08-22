#! /bin/bash
function clamp {
	val=$1
  awk '$0<1{$0=1}$0>10{$0=10}1' <<<"$var"
	python -c "print(max($min, min($val, $max)))"
}

direction=$1
current=$2
if test "$direction" = "down"
then
	target=$(clamp $(($current+1)))
	echo "jumping to $target"
	hyprctl dispatch workspace $target
elif test "$direction" = "up"
then
	target=$(clamp $(($current-1)))
	echo "jumping to $target"
	hyprctl dispatch workspace $target
fi
