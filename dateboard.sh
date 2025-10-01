#!/usr/bin/env bash
export LC_ALL=en_US.UTF-8   #to ensure the accents are being dealt with properly
file="${2:-path/to/your/file}"
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
case $1 in #handle user options
	"-a") #add
		while true; do
			read -e -p "Date (YYYY-MM-DD): " date
			if [[ $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
				break #ensure date has the correct format
			else
				echo "Incorrect format."
			fi
		done
		read -e -p "Assignment: " assignment
		read -e -p "Subject: " subject
		line="$date - $assignment - $subject"
		(cat "$file"; echo "$line") | sort -t'-' -k1,1 -k2,2 -k3,3 > "${file}.tmp" #create a tmp file with the new line and sort it by date
		mv "${file}.tmp" "$file" #update real file
		echo "Workload added successfully!"
	;;
	#Warning: both -r and -e accept any number input, but only valid line numbers will make changes
	"-r") #remove
		cat -n "$file" #show enumerated files
		while true; do
			read -p "Select the number of the workload you wish to delete: " delete 
			if [[ $delete =~ ^[0-9]+$ ]]; then
				sed -i "${delete}d" "$file" #delete the line
				echo "Workload deleted successfully!"
				break
			else
				echo "Incorrect format"
			fi
		done

	;;
	"-e") #edit
		cat -n "$file"
		while true; do
			read -p "Select the number of the workload you wish to edit: " edit
			if [[ $edit =~ ^[0-9]+$ ]]; then
				while true; do
					read -e -p "Date (YYYY-MM-DD): " date
					if [[ $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then #ensure proper format
						break
					else
						echo "Incorrect format."
					fi
				done
				read -e -p "Assignment: " assignment
				read -e -p "Subject: " subject
				line="$date - $assignment - $subject"
				sed -i "${edit}c\\${line}" "$file" #edit correct line
				echo "Workload edited successfully!"
				break
			else
				echo "Incorrect format"
			fi
		done
	;;
	"-h") #help
		cat <<EOF
Dateboard displays your workload from a .txt file.
Format: Date (YYYY-MM-DD) | Assignment | Subject
Options:
	-a -> adds a new line
	-e -> select and edit a line (full edit required)
	-r -> select and remove a line

Current workload:
		
EOF
	;;
esac
print #show final result
