#!/bin/bash


# Convert picture source file path into single name

namefilepath()
{
  echo "$1" | sed -r 's/[ _.\/]+/_/g'
}


# Get picture source and output path from command line

ROOT_PATH="./"
COPY_PATH="my_pics"
if [ $# -lt 2 ]; then
  echo "Requires source path to pictures and output path for copy."
  echo "(with optional picture types and minimum picture size)"
  exit 1
else
  ROOT_PATH=$1
  if [ ! -d "$ROOT_PATH" ]; then
    echo "Picture source path, parameter #1, '$ROOT_PATH' is not a valid directory"
    exit 1
  fi
  COPY_PATH=$2
  if [ ! -d "$COPY_PATH" ]; then
    echo "Picture output path, parameter #2, '$COPY_PATH' is not a valid directory"
    exit 1
  fi
  if [ ! -z "$(ls -A $COPY_PATH)" ]; then
    echo "WARNING! Output path, '$COPY_PATH' is not empty. Files may be over written."
    read -p "Press Y/y to continue? " -n 1 -r; echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
    fi
  fi
fi
echo $ROOT_PATH
echo $COPY_PATH


# Get picture types and minimum size from command line

PIC_TYPE=("" "" "" "" "")
PIC_SIZE="-size +20k"
i=$(($#-3)) # first 2 parameters are I/O paths
while [ $i -ge 0 ]; do
  #echo ${BASH_ARGV[$i]}
  if [ "${BASH_ARGV[$i]}" = "size" ]; then PIC_SIZE="-size ${BASH_ARGV[$i-1]}"; fi
  if [ "${BASH_ARGV[$i]}" = "jpg" ]; then PIC_TYPE[0]="-iname *.jpg -or -iname *.jpeg"; fi
  if [ "${BASH_ARGV[$i]}" = "png" ]; then PIC_TYPE[1]="-iname *.png"; fi
  if [ "${BASH_ARGV[$i]}" = "tif" ]; then PIC_TYPE[2]="-iname *.tif"; fi
  if [ "${BASH_ARGV[$i]}" = "bmp" ]; then PIC_TYPE[3]="-iname *.bmp"; fi
  if [ "${BASH_ARGV[$i]}" = "gif" ]; then PIC_TYPE[4]="-iname *.gif"; fi
  i=$((i-1))
done
echo $PIC_SIZE
#echo ${PIC_TYPE[@]}


# Create file extension list for 'find' command

PIC_EXT=""
added=0
for i in "${!PIC_TYPE[@]}"; do
  if [ ! -z "${PIC_TYPE[i]}" ]; then
    if [ $added = 1 ]; then PIC_EXT+=" -or "; fi
    PIC_EXT+=${PIC_TYPE[i]}; added=1;
  fi
done
if [ -z "$PIC_EXT" ]; then
  PIC_EXT="-iname *.jpg -or -iname *.jpeg -or -iname *.png -or -iname *.tif -or -iname *.bmp -or -iname *.gif"
fi
echo $PIC_EXT


# Find pictures under ROOT_PATH

readarray my_pics <<< "$(find "$ROOT_PATH" $PIC_SIZE $PIC_EXT)"
echo "found ${#my_pics[@]} pictures"


# Seperate picture filepaths from filenames

#unset my_pics_name
#unset my_pics_path
for pic in "${my_pics[@]}"; do
  my_pics_name[${#my_pics_name[@]}]=$(basename "$pic")
  my_pics_path[${#my_pics_path[@]}]=$(dirname "$pic")
  FILENAME="${my_pics_path[${#my_pics_path[@]} -1]}/${my_pics_name[${#my_pics_name[@]} -1]}"
  if [ ! -f "$FILENAME" ]; then
    echo "File not found $FILENAME"
    exit 1
  fi
done

#echo ${#my_pics_name[@]}
#echo ${#my_pics_path[@]}
if [ ${#my_pics[@]} -ne ${#my_pics_name[@]} ]; then
  echo "number of pictures(${#my_pics[@]}) not equal to number of filenames(${#my_pics_name[@]})"
  exit 1
else
  if [ ${#my_pics_path[@]} -ne ${#my_pics_name[@]} ]; then
    echo "number of filepaths(${#my_pics_path[@]}) not equal to number of filenames(${#my_pics_name[@]})"
    exit 1
  fi
fi
printf "Pictures:\t%d\nSource path:\t%s\nCopy path:\t%s\nSize limit:\t%s\nPicture type:\t%s\n"  ${#my_pics[@]} "$ROOT_PATH" "$COPY_PATH" "$PIC_SIZE" "$PIC_EXT"  >>  "$COPY_PATH/$(namefilepath "$ROOT_PATH").log"


# Copy picture files to output path

path_id=0
yes_all=0
pic_count=0
for i in "${!my_pics_path[@]}"; do
  PIC_PATH=${my_pics_path[i]}
  if [ "$PIC_PATH" = "****" ]; then continue; fi; # already copied
  
  NEW_PATH=$(printf "$COPY_PATH/%06d" $path_id)
  let "path_id+=1"

  if [ -d $NEW_PATH ]; then  
    if [ $yes_all = 0 ]; then
      echo "WARNING! Output folder exist, '$NEW_PATH'."
      read -p "To contnue writting to it press Y/y (yes once) or A/a (yes all). " -n 1 -r; echo
      if [[ $REPLY =~  ^[Aa]$ ]]; then
        yes_all=1
      else 
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
          [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
        fi
      fi
    fi
  else
    mkdir -p $NEW_PATH
  fi

  for (( ii=$i; ii<${#my_pics_path[@]}; ii++ )); do
    if [ "$PIC_PATH" = "${my_pics_path[ii]}" ]; then
      my_pics_path[ii]="****"
      PIC_FROM="$PIC_PATH/${my_pics_name[ii]}"

      if cp -aL "$PIC_FROM" "$NEW_PATH" ; then
        printf "%03d) copy %s  to  %s\n"  $pic_count "$PIC_FROM" "$NEW_PATH/${my_pics_name[ii]}" >> "$NEW_PATH/$(namefilepath "$PIC_PATH").log"
        let "pic_count=pic_count+1"
      else
        echo "FAILED! copy file #$pic_count, $PIC_FROM to $NEW_PATH"
      fi
    fi
  done

done

if [ $pic_count -ne ${#my_pics[@]} ]; then
  echo "WARNING! Copied $pic_count of ${#my_pics_name[@]}"
else
  echo "Success. Copied $pic_count pictures to $COPY_PATH"
fi


