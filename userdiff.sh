#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Temporary files will be cleaned up on exit
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "TEST BEGINNING, STAND BY"

# Extract usernames with UID >= 1000 and save to a file
# (Change >= to > if you prefer to exclude UID 1000)
awk -F: '$3 >= 1000 {print $1}' /etc/passwd | sort -u > "current_users.txt"
echo "Current usernames saved to current_users.txt"

# Define the two files to compare (create if missing)
file1="authd_adm.txt"
file2="authd_usr.txt"
file3="current_users.txt"

# Ensure files exist but do NOT truncate them; preserve existing contents
: > "$file3"            # we will overwrite current_users.txt with the generated list
chmod 777 "$file3"
touch "$file1" "$file2"
chmod 777 "$file1" "$file2"

echo "Please edit the authorised users files:"
echo " - admins: $file1"
echo " - users : $file2"
# Open the files in the user's editor if available (interactive)
${EDITOR:-vi} "$file1" "$file2"

read -p "Press Enter when done..."
echo "Confirmation received. Continuing with the script"

# Clean and normalize authorised lists:
# - remove blank lines and comments (# at line start or after leading whitespace)
# - trim leading/trailing whitespace
# - output one username per line
clean_file() {
  local src=$1
  local dst=$2
  # remove comments and blank lines, trim whitespace
  sed -E 's/^[[:space:]]*#.*$//; s/[[:space:]]+$//; s/^[[:space:]]+//; /^$/d' "$src" | sort -u > "$dst"
}

clean_file "$file1" "authd_adm.clean"
clean_file "$file2" "authd_usr.clean"

echo "The first user in $file1 (if any): $(head -n1 "authd_adm.clean" || echo '<none>')"
echo "All admins: $(paste -sd', ' "authd_adm.clean" || echo '<none>')"
echo "All users: $(paste -sd', ' "authd_usr.clean" || echo '<none>')"

# Combine the two authorised files (sorted, unique)
combined="combined.clean"
cat "authd_adm.clean" "authd_usr.clean" | sort -u > "$combined"
chmod 777 "$combined"
echo "Combined authorised lists into $combined"

# Prepare current users file (sorted, unique) and also save a copy to file3
sort -u "current_users.txt" > "current_sorted.txt"
cp "current_sorted.txt" "$file3"
chmod 777 "$file3"

# Compare the combined list with actual users using comm (works on sorted files)
# Lines only in current_sorted (present on system but NOT authorised) => unauthorized
# Lines only in combined (authorised but NOT present) => missing_authorized
unauthorized="unauthorized.txt"
missing_authorized="missing_authorized.txt"

comm -23 "current_sorted.txt" "$combined" > "$unauthorized" || true
comm -13 "current_sorted.txt" "$combined" > "$missing_authorized" || true

# Produce a unified diff of the sorted lists for record
diff_out="diff.txt"
diff -u "$combined" "current_sorted.txt" > "$diff_out" || true

echo "Differences written to $diff_out"
echo "Unauthorized users (present on system but not authorised):"
if [[ -s "$unauthorized" ]]; then
  cat "$unauthorized"
else
  echo "<none>"
fi

echo ""
echo "Authorised users missing from system (authorised but not present):"
if [[ -s "$missing_authorized" ]]; then
  cat "$missing_authorized"
else
  echo "<none>"
fi

echo ""
echo "TEST OVER — BEGINNING REGULARLY SCHEDULED PROGRAMMING"
echo "test complete"
