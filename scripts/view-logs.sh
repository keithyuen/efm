#!/bin/bash
# Script to view PostgreSQL and EFM logs locally

echo "=== EFM Cluster Log Viewer ==="
echo ""

# Function to show menu
show_menu() {
    echo "Available logs to view:"
    echo "1. Primary PostgreSQL logs"
    echo "2. Primary EFM logs"
    echo "3. Standby PostgreSQL logs"
    echo "4. Standby EFM logs"
    echo "5. Witness EFM logs"
    echo "6. All EFM logs (combined)"
    echo "7. All PostgreSQL logs (combined)"
    echo "8. All logs (tail -f live view)"
    echo "9. Show log file sizes"
    echo "0. Exit"
    echo ""
}

# Function to view primary PostgreSQL logs
view_primary_pg_logs() {
    echo "=== Primary PostgreSQL Logs ==="
    if [ -d "./logs/pg-primary/postgresql" ] && [ "$(ls -A ./logs/pg-primary/postgresql 2>/dev/null)" ]; then
        find ./logs/pg-primary/postgresql -name "*.log" -type f -exec echo "=== {} ===" \; -exec tail -50 {} \;
    else
        echo "No PostgreSQL logs found for primary node. Make sure the containers are running."
    fi
    echo ""
}

# Function to view primary EFM logs
view_primary_efm_logs() {
    echo "=== Primary EFM Logs ==="
    if [ -d "./logs/pg-primary/efm" ] && [ "$(ls -A ./logs/pg-primary/efm 2>/dev/null)" ]; then
        find ./logs/pg-primary/efm -name "*.log" -type f -exec echo "=== {} ===" \; -exec tail -50 {} \;
    else
        echo "No EFM logs found for primary node. Make sure the containers are running."
    fi
    echo ""
}

# Function to view standby PostgreSQL logs
view_standby_pg_logs() {
    echo "=== Standby PostgreSQL Logs ==="
    if [ -d "./logs/pg-standby/postgresql" ] && [ "$(ls -A ./logs/pg-standby/postgresql 2>/dev/null)" ]; then
        find ./logs/pg-standby/postgresql -name "*.log" -type f -exec echo "=== {} ===" \; -exec tail -50 {} \;
    else
        echo "No PostgreSQL logs found for standby node. Make sure the containers are running."
    fi
    echo ""
}

# Function to view standby EFM logs
view_standby_efm_logs() {
    echo "=== Standby EFM Logs ==="
    if [ -d "./logs/pg-standby/efm" ] && [ "$(ls -A ./logs/pg-standby/efm 2>/dev/null)" ]; then
        find ./logs/pg-standby/efm -name "*.log" -type f -exec echo "=== {} ===" \; -exec tail -50 {} \;
    else
        echo "No EFM logs found for standby node. Make sure the containers are running."
    fi
    echo ""
}

# Function to view witness EFM logs
view_witness_efm_logs() {
    echo "=== Witness EFM Logs ==="
    if [ -d "./logs/efm-witness/efm" ] && [ "$(ls -A ./logs/efm-witness/efm 2>/dev/null)" ]; then
        find ./logs/efm-witness/efm -name "*.log" -type f -exec echo "=== {} ===" \; -exec tail -50 {} \;
    else
        echo "No EFM logs found for witness node. Make sure the containers are running."
    fi
    echo ""
}

# Function to view all EFM logs
view_all_efm_logs() {
    echo "=== All EFM Logs ==="
    view_primary_efm_logs
    view_standby_efm_logs
    view_witness_efm_logs
}

# Function to view all PostgreSQL logs
view_all_pg_logs() {
    echo "=== All PostgreSQL Logs ==="
    view_primary_pg_logs
    view_standby_pg_logs
}

# Function to live tail all logs
live_tail_logs() {
    echo "=== Live Log Monitoring (press Ctrl+C to stop) ==="
    echo "Monitoring all PostgreSQL and EFM logs..."
    echo ""
    
    # Find all log files and tail them
    LOG_FILES=""
    for dir in "./logs/pg-primary/postgresql" "./logs/pg-primary/efm" "./logs/pg-standby/postgresql" "./logs/pg-standby/efm" "./logs/efm-witness/efm"; do
        if [ -d "$dir" ]; then
            FILES=$(find "$dir" -name "*.log" -type f 2>/dev/null)
            if [ ! -z "$FILES" ]; then
                LOG_FILES="$LOG_FILES $FILES"
            fi
        fi
    done
    
    if [ ! -z "$LOG_FILES" ]; then
        tail -f $LOG_FILES
    else
        echo "No log files found. Make sure the containers are running and generating logs."
    fi
}

# Function to show log file sizes
show_log_sizes() {
    echo "=== Log File Sizes ==="
    echo ""
    for node_dir in "./logs"/*; do
        if [ -d "$node_dir" ]; then
            node_name=$(basename "$node_dir")
            echo "--- $node_name ---"
            find "$node_dir" -name "*.log" -type f -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $9}' | sort -hr
            echo ""
        fi
    done
}

# Main menu loop
while true; do
    show_menu
    read -p "Select an option (0-9): " choice
    echo ""
    
    case $choice in
        1) view_primary_pg_logs ;;
        2) view_primary_efm_logs ;;
        3) view_standby_pg_logs ;;
        4) view_standby_efm_logs ;;
        5) view_witness_efm_logs ;;
        6) view_all_efm_logs ;;
        7) view_all_pg_logs ;;
        8) live_tail_logs ;;
        9) show_log_sizes ;;
        0) echo "Exiting log viewer."; exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
    
    if [ "$choice" != "8" ]; then
        echo ""
        read -p "Press Enter to continue..."
        echo ""
    fi
done