#!/bin/bash
set -euo pipefail
IFS=$'\n'

echo "TEST BEGINNING, STAND BY"

# Extract usernames with UID > 1000 and save to a file
awk -F: '$3 > 1000 {print $1}' /etc/passwd > current_users.txt
echo "Current usernames saved to current_users.txt"

# Define the two files to compare (create if missing)
file1="authd_adm.txt"
file2="authd_usr.txt"
file3="current_users.txt"

: > "$file1"
chmod 664 "$file1"
: > "$file2"
chmod 664 "$file2"

echo "Please input the authorised users into $file1 (admins) and $file2 (users)."
read -p "Press Enter when done..."

echo "Confirmation received. Continuing with the script"

# Read the admin list into an array (example)
mapfile -t usernames < "$file1"
echo "The first user is: ${usernames[0]:-<none>}"
echo "All users are: ${usernames[*]:-<none>}"

for user in "${usernames[@]}"; do
    echo "Processing user: $user"
done

# Combine the two authorised files
combined="combined.txt"
cat "$file1" "$file2" > "$combined"
chmod 664 "$combined"
echo "Combined authorised lists into $combined"

# Compare the combined list with actual users
diff "$combined" "$file3" > diff.txt || true
echo "Differences (if any) written to diff.txt"

echo "TEST OVER — BEGINNING REGULARLY SCHEDULED PROGRAMMING"
echo "test complete"
