#!/bin/bash

VOTER_FILE="voters.txt"
VOTE_COUNT_FILE="votes.txt"
CANDIDATE_FILE="candidates.txt"
EMAIL_FILE="emails.txt"
ADMIN_PASS="admin123"  # Change this for security

# Initialize files if not exist
touch "$VOTER_FILE" "$VOTE_COUNT_FILE" "$CANDIDATE_FILE" "$EMAIL_FILE"

# Function for voter menu
vote() {
    read -p "Enter your ID card number: " id
    if grep -q "^$id,voted$" "$VOTER_FILE"; then
        echo "You have already voted! ❌"
    elif grep -q "^$id,unvoted$" "$VOTER_FILE"; then
        echo "Candidates: "
        cat -n "$CANDIDATE_FILE" | awk '{print $1 ") "$2}'

        read -p "Enter candidate number: " choice
        candidate=$(sed -n "${choice}p" "$CANDIDATE_FILE" | cut -d',' -f1)

        if [ -z "$candidate" ]; then
            echo "Invalid choice! ❌"
        else
            echo "$candidate" >> "$VOTE_COUNT_FILE"
            sed -i "s/^$id,unvoted\$/$id,voted/" "$VOTER_FILE"
            echo "Vote registered successfully ✅"

            check_all_voted
        fi
    else
        echo "ID not found. ❌ Please contact the admin."
    fi
}

# Function to authenticate admin
admin_authenticate() {
    read -sp "Enter Admin Password: " pass
    echo
    if [ "$pass" != "$ADMIN_PASS" ]; then
        echo "❌ Incorrect Password!"
        return 1
    fi
    return 0
}

# Function to check vote count
admin_check_votes() {
    admin_authenticate || return
    echo "🔍 Vote Count:"
    awk '{count[$0]++} END {for (c in count) print c, ":", count[c]}' "$VOTE_COUNT_FILE"
}

# Function to reset voting system
reset_votes() {
    admin_authenticate || return
    sed -i 's/,voted/,unvoted/g' "$VOTER_FILE"
    > "$VOTE_COUNT_FILE"
    echo "All votes and participation records have been reset 🔄"
}

# Function for admin to add candidates with email
add_candidate() {
    admin_authenticate || return
    read -p "Enter candidate name: " candidate
    read -p "Enter candidate email: " email
    #echo "$candidate,$email" >> "$CANDIDATE_FILE"
    echo "$candidate" >> "$CANDIDATE_FILE"
    echo "Candidate '$candidate' added successfully ✅"
}

# Function for admin to add voters
add_voter() {
    admin_authenticate || return
    read -p "Enter Voter ID: " voter_id
    read -p "Enter Voter Name: " voter_name
    echo "$voter_id,unvoted" >> "$VOTER_FILE"
    echo "Voter '$voter_name' (ID: $voter_id) added successfully ✅"
}

# Function to check if all voters have voted
check_all_voted() {
    if ! grep -q ",unvoted" "$VOTER_FILE"; then
        echo "✅ All voters have voted!"
        notify_candidates
        display_results
    fi
}

# Function to send email notifications to candidates
notify_candidates() {
    echo "📧 Notifying candidates..."
    while IFS=',' read -r candidate email; do
        echo "Dear $candidate, voting is complete. Check the results soon!" | mail -s "Voting Completed" "$email"
        echo "📨 Notification sent to $candidate ($email)"
    done < "$CANDIDATE_FILE"
}

# Function to display final results
display_results() {
    echo "📊 Final Voting Results:"
    awk '{count[$0]++} END {for (c in count) print c, ":", count[c]}' "$VOTE_COUNT_FILE"
}

# Main menu
while true; do
    echo "📌 Online Voting System"
    echo "1) Voter"
    echo "2) Admin"
    echo "3) Exit"
    read -p "Select an option: " user_type

    case $user_type in
        1)
            vote
            ;;
        2)
            admin_authenticate || continue
            echo "1) Check Votes"
            echo "2) Reset Votes"
            echo "3) Add Candidate"
            echo "4) Add Voter"
            echo "5) Back"
            read -p "Select an option: " admin_option
            case $admin_option in
                1) admin_check_votes ;;
                2) reset_votes ;;
                3) add_candidate ;;
                4) add_voter ;;
                5) continue ;;
                *) echo "Invalid option! ❌" ;;
            esac
            ;;
        3)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option! ❌"
            ;;
    esac
done
