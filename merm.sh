#!/bin/bash

input_file="${1}"
echo "input_file -> ${input_file}"

output_file="${2}"
echo "output_file -> ${output_file}"

merm_head='```mermaid'
echo "merm_head -> ${merm_head}"

script_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo "script_directory -> ${script_directory}"
base_name=${script_directory%%+(/)}
base_name=${base_name##*/} 
echo "base_name -> ${base_name}"

IFS="~" # need to reset?
mnd_fenced_array=($(awk -v MERMHEAD="$merm_head" -v RS="${merm_head}" -v ORS='~' '{print MERMHEAD $0}' $input_file))

# generate mnd files from array, skip first record
for i in "${mnd_fenced_array[@]:1}"
do
    echo "===="
    clean_fence=$(awk -v MERMHEAD="$merm_head" '$1~MERMHEAD{flag=1}flag; /```$/{flag=0}' <<< ${i})
    # echo "clean_fence -> ${clean_fence}"

    clean_mnd=$(sed '1d;/```/ d' <<< ${clean_fence})
    echo "clean_mnd -> ${clean_mnd}"

    # fence name from the mermaid fence
    diag_name=$(echo ${clean_fence} | awk 'NR==1{print $2;}')
    echo "diag_name -> ${diag_name}"

    filename_ex=$(echo ${diag_name}).mnd
    echo "filename_ex -> $filename_ex"

    if [ -e $(echo ${filename_ex}) ]
    then
        echo "${filename_ex} already exists"
    else
        echo $clean_mnd >> $(echo ${filename_ex})
    fi
done

# generate images from mmd file
for mnd_file_name in ./*mnd; do
    echo "generating mnd_file_name -> ${mnd_file_name}"
    filename="${mnd_file_name##*/}"
    filename_noex="${filename%%.*}"
    # echo "filename_noex -> ${filename_noex}"
    filename_png="${filename_noex}".png
    echo "generating filename_png -> ${filename_png}"
    mmdc -i $mnd_file_name -o ${filename_png}
done

# inject images
gawk '{ $0 = gensub(/```mermaid (\w+)/, "![\\1](./'"$base_name"'/\\1.png \"\\1\")\n```mermaid \\1", "g"); print }'  $input_file > $output_file
