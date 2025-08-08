#!/bin/bash
# Script to analyze EFM and PostgreSQL logs for common issues and events

echo "=== EFM Log Analyzer ==="
echo ""

# Function to analyze EFM logs for failover events
analyze_efm_failover_events() {
    echo "=== EFM Failover Events ==="
    echo ""
    
    local found_events=false
    
    for log_dir in "./logs/pg-primary/efm" "./logs/pg-standby/efm" "./logs/efm-witness/efm"; do
        if [ -d "$log_dir" ]; then
            local node=$(echo "$log_dir" | cut -d'/' -f3)
            local log_files=$(find "$log_dir" -name "*.log" -type f 2>/dev/null)
            
            if [ ! -z "$log_files" ]; then
                local events=$(grep -i "failover\|promote\|switchover\|election" $log_files 2>/dev/null)
                if [ ! -z "$events" ]; then
                    echo "--- $node ---"
                    echo "$events"
                    echo ""
                    found_events=true
                fi
            fi
        fi
    done
    
    if [ "$found_events" = false ]; then
        echo "No failover events found in EFM logs."
        echo ""
    fi
}

# Function to analyze EFM cluster membership changes
analyze_efm_membership() {
    echo "=== EFM Cluster Membership Changes ==="
    echo ""
    
    local found_events=false
    
    for log_dir in "./logs/pg-primary/efm" "./logs/pg-standby/efm" "./logs/efm-witness/efm"; do
        if [ -d "$log_dir" ]; then
            local node=$(echo "$log_dir" | cut -d'/' -f3)
            local log_files=$(find "$log_dir" -name "*.log" -type f 2>/dev/null)
            
            if [ ! -z "$log_files" ]; then
                local events=$(grep -i "member\|join\|leave\|disconnect\|connect" $log_files 2>/dev/null)
                if [ ! -z "$events" ]; then
                    echo "--- $node ---"
                    echo "$events"
                    echo ""
                    found_events=true
                fi
            fi
        fi
    done
    
    if [ "$found_events" = false ]; then
        echo "No membership changes found in EFM logs."
        echo ""
    fi
}

# Function to analyze PostgreSQL replication lag
analyze_replication_lag() {
    echo "=== PostgreSQL Replication Analysis ==="
    echo ""
    
    local found_events=false
    
    for log_dir in "./logs/pg-primary/postgresql" "./logs/pg-standby/postgresql"; do
        if [ -d "$log_dir" ]; then
            local node=$(echo "$log_dir" | cut -d'/' -f3)
            local log_files=$(find "$log_dir" -name "*.log" -type f 2>/dev/null)
            
            if [ ! -z "$log_files" ]; then
                echo "--- $node Replication Events ---"
                
                # Look for replication-related messages
                local repl_events=$(grep -i "replication\|standby\|wal\|streaming" $log_files 2>/dev/null | tail -20)
                if [ ! -z "$repl_events" ]; then
                    echo "$repl_events"
                    found_events=true
                else
                    echo "No replication events found."
                fi
                echo ""
            fi
        fi
    done
    
    if [ "$found_events" = false ]; then
        echo "No replication events found in PostgreSQL logs."
        echo ""
    fi
}

# Function to analyze errors and warnings
analyze_errors() {
    echo "=== Error and Warning Analysis ==="
    echo ""
    
    local found_errors=false
    
    # Check EFM logs for errors
    echo "--- EFM Errors and Warnings ---"
    for log_dir in "./logs/pg-primary/efm" "./logs/pg-standby/efm" "./logs/efm-witness/efm"; do
        if [ -d "$log_dir" ]; then
            local node=$(echo "$log_dir" | cut -d'/' -f3)
            local log_files=$(find "$log_dir" -name "*.log" -type f 2>/dev/null)
            
            if [ ! -z "$log_files" ]; then
                local errors=$(grep -i "error\|warning\|exception\|failed" $log_files 2>/dev/null | tail -10)
                if [ ! -z "$errors" ]; then
                    echo "$node:"
                    echo "$errors"
                    echo ""
                    found_errors=true
                fi
            fi
        fi
    done
    
    # Check PostgreSQL logs for errors
    echo "--- PostgreSQL Errors and Warnings ---"
    for log_dir in "./logs/pg-primary/postgresql" "./logs/pg-standby/postgresql"; do
        if [ -d "$log_dir" ]; then
            local node=$(echo "$log_dir" | cut -d'/' -f3)
            local log_files=$(find "$log_dir" -name "*.log" -type f 2>/dev/null)
            
            if [ ! -z "$log_files" ]; then
                local errors=$(grep -i "error\|warning\|fatal\|panic" $log_files 2>/dev/null | tail -10)
                if [ ! -z "$errors" ]; then
                    echo "$node:"
                    echo "$errors"
                    echo ""
                    found_errors=true
                fi
            fi
        fi
    done
    
    if [ "$found_errors" = false ]; then
        echo "No recent errors or warnings found."
        echo ""
    fi
}

# Function to show log statistics
show_log_statistics() {
    echo "=== Log Statistics ==="
    echo ""
    
    for node_dir in "./logs"/*; do
        if [ -d "$node_dir" ]; then
            local node_name=$(basename "$node_dir")
            echo "--- $node_name ---"
            
            # PostgreSQL logs
            local pg_log_dir="$node_dir/postgresql"
            if [ -d "$pg_log_dir" ]; then
                local pg_files=$(find "$pg_log_dir" -name "*.log" -type f 2>/dev/null | wc -l)
                local pg_lines=$(find "$pg_log_dir" -name "*.log" -type f -exec wc -l {} \; 2>/dev/null | awk '{sum += $1} END {print sum}')
                echo "  PostgreSQL: $pg_files files, $pg_lines lines"
            fi
            
            # EFM logs
            local efm_log_dir="$node_dir/efm"
            if [ -d "$efm_log_dir" ]; then
                local efm_files=$(find "$efm_log_dir" -name "*.log" -type f 2>/dev/null | wc -l)
                local efm_lines=$(find "$efm_log_dir" -name "*.log" -type f -exec wc -l {} \; 2>/dev/null | awk '{sum += $1} END {print sum}')
                echo "  EFM: $efm_files files, $efm_lines lines"
            fi
            
            echo ""
        fi
    done
}

# Function to search logs for specific patterns
search_logs() {
    local pattern="$1"
    if [ -z "$pattern" ]; then
        read -p "Enter search pattern: " pattern
    fi
    
    if [ -z "$pattern" ]; then
        echo "No search pattern provided."
        return
    fi
    
    echo "=== Search Results for: '$pattern' ==="
    echo ""
    
    local found_results=false
    
    for node_dir in "./logs"/*; do
        if [ -d "$node_dir" ]; then
            local node_name=$(basename "$node_dir")
            local log_files=$(find "$node_dir" -name "*.log" -type f 2>/dev/null)
            
            if [ ! -z "$log_files" ]; then
                local results=$(grep -i "$pattern" $log_files 2>/dev/null)
                if [ ! -z "$results" ]; then
                    echo "--- $node_name ---"
                    echo "$results"
                    echo ""
                    found_results=true
                fi
            fi
        fi
    done
    
    if [ "$found_results" = false ]; then
        echo "No results found for pattern: '$pattern'"
        echo ""
    fi
}

# Function to show menu
show_menu() {
    echo "EFM Log Analysis Options:"
    echo "1. Analyze failover events"
    echo "2. Analyze cluster membership changes"
    echo "3. Analyze replication issues"
    echo "4. Show errors and warnings"
    echo "5. Show log statistics"
    echo "6. Search logs for pattern"
    echo "7. Full analysis report"
    echo "0. Exit"
    echo ""
}

# Function to run full analysis
full_analysis() {
    echo "=== EFM Cluster Full Analysis Report ==="
    echo "Generated: $(date)"
    echo ""
    
    show_log_statistics
    analyze_efm_failover_events
    analyze_efm_membership
    analyze_replication_lag
    analyze_errors
    
    echo "=== End of Analysis Report ==="
    echo ""
}

# Main menu loop
if [ "$1" = "--search" ]; then
    search_logs "$2"
    exit 0
elif [ "$1" = "--full" ]; then
    full_analysis
    exit 0
fi

while true; do
    show_menu
    read -p "Select an option (0-7): " choice
    echo ""
    
    case $choice in
        1) analyze_efm_failover_events ;;
        2) analyze_efm_membership ;;
        3) analyze_replication_lag ;;
        4) analyze_errors ;;
        5) show_log_statistics ;;
        6) search_logs ;;
        7) full_analysis ;;
        0) echo "Exiting log analyzer."; exit 0 ;;
        *) echo "Invalid option. Please try again." ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    echo ""
done