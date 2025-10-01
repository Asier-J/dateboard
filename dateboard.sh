#!/usr/bin/env bash
export LC_ALL=en_US.UTF-8   #to ensure the accents are being dealt with properly
file="${2:-path/to/workload}"
info_file="${3:-path/to/workload-info}"

print(){
	awk -F" - " '
		function trim(s) { sub(/^[ \t\r\n]+/, "", s); sub(/[ \t\r\n]+$/, "", s); return s } #trimming

		{
		  c1 = trim($1)
		  c2 = (NF >= 2 ? trim($2) : "")
		  if (NF >= 3) {
		    c3 = trim($3)
		    for (i = 4; i <= NF; i++) c3 = c3 " - " trim($i)
		  } else c3 = ""

		  a1[NR] = c1; a2[NR] = c2; a3[NR] = c3 #adjusting max width
		  if (length(c1) > m1) m1 = length(c1)
		  if (length(c2) > m2) m2 = length(c2)
		  if (length(c3) > m3) m3 = length(c3)
		}
		END {
		  if (NR == 0) exit

		  fmt = "%-" m1 "s | %-" m2 "s | %-" m3 "s\n" #printing with | as separators
		  sample = sprintf(fmt, "", "", "") 
		  total = length(sample)

		  title = " UPCOMING WORK "
		  tlen = length(title)
		  left = int((total - tlen) / 2) #left padding
		  right = total - tlen - left #right padding
		  padL = ""; padR = ""
		  for (i = 0; i < left; i++) padL = padL "=" #definitive left padding
		  for (i = 0; i < right; i++) padR = padR "=" #definitive right padding
		  print padL title padR

		  for (i = 1; i <= NR; i++) printf fmt, a1[i], a2[i], a3[i]
		}
		' "$file"
	}

print_menu(){
	cat <<EOF
Dateboard displays your workload from a .txt file.
Format: Date (YYYY-MM-DD) | Assignment | Subject
Options:
	-h -> prints help menu
	-a -> adds a new line
	-e -> select and edit a line (full edit required)
	-r -> select and remove a line
	-i -> select and show information about a line

Current workload:
		
EOF
}

validate_number(){ [[ $1 =~ ^[0-9]+$ ]]; }

validate_date() { [[ $1 =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; }

read_task(){
	while true; do
		read -e -p "Date (YYYY-MM-DD): " date
		validate_date "$date" && break
		echo "Incorrect format."
	done
	read -e -p "Assignment: " assignment
	read -e -p "Subject: " subject
	echo "$date - $assignment - $subject"
}

select_line(){
	local prompt=$1
	local selected
		while true; do
		read -p "$prompt" selected
		if validate_number "$selected"; then
			total_lines=$(wc -l < "$file")
			if [[ $selected -gt $total_lines || $selected -lt 1 ]]; then
				echo "Line $selected does not exist."
				continue
			fi
			echo "$selected"
			return 0
		else
			echo "Incorrect format."
		fi
	done
}

case $1 in #handle user options
	"-h") #help
		print_menu
		print #show final result
	;;

	"-a") #add
		line=$(read_task)
		(cat "$file"; echo "$line") | sort -t'-' -k1,1 -k2,2 -k3,3 > "${file}.tmp" #create a tmp file with the new line and sort it by date
		mv "${file}.tmp" "$file" #update real file
		echo "Workload added successfully!"
		print	
	;;

	#Warning: both -r and -e accept any number input, but only valid line numbers will make changes
	"-e") #edit
		cat -n "$file"
		edit=$(select_line "Select the number of the workload you wish to edit: ")
		line=$(read_task)
		sed -i "${edit}c\\${line}" "$file" #edit correct line
		echo "Workload edited successfully!"
		print
	;;

	"-r") #remove
		cat -n "$file"
		delete=$(select_line "Select the number of the workload you wish to delete: ")
		sed -i "${delete}d" "$file" #delete the line
		echo "Workload deleted successfully!"
		print
	;;

	"-i") #info
		cat -n "$file"
		info=$(select_line "Select the number of the workload you wish to know more about: ")
		sed -n "${info}p" "$info_file" #print the line
	;;

	*) #standard, empty input
		print
	;;
esac
