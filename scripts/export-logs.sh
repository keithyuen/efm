#!/bin/bash
# Script to export and archive logs for analysis

echo "=== EFM Log Export Utility ==="
echo ""

# Set default export directory
EXPORT_DIR="./exported-logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="efm_logs_${TIMESTAMP}"

# Function to show usage
show_usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d, --dir DIR     Export directory (default: ./exported-logs)"
    echo "  -a, --archive     Create tar.gz archive"
    echo "  -c, --clean       Clean old exports (older than 7 days)"
    echo "  -h, --help        Show this help message"
    echo ""
}

# Function to export logs
export_logs() {
    local export_path="$EXPORT_DIR/$ARCHIVE_NAME"
    
    echo "Creating export directory: $export_path"
    mkdir -p "$export_path"
    
    # Copy all log files with directory structure
    if [ -d "./logs" ]; then
        echo "Copying logs..."
        cp -r ./logs/* "$export_path/" 2>/dev/null || true
        
        # Create metadata file
        echo "Export created: $(date)" > "$export_path/export_metadata.txt"
        echo "EFM Cluster: efm_cluster" >> "$export_path/export_metadata.txt"
        echo "Export source: $(pwd)" >> "$export_path/export_metadata.txt"
        echo "" >> "$export_path/export_metadata.txt"
        
        # Add file inventory
        echo "=== File Inventory ===" >> "$export_path/export_metadata.txt"
        find "$export_path" -name "*.log" -type f -exec ls -lh {} \; >> "$export_path/export_metadata.txt"
        
        # Count log entries
        echo "" >> "$export_path/export_metadata.txt"
        echo "=== Log Entry Counts ===" >> "$export_path/export_metadata.txt"
        find "$export_path" -name "*.log" -type f -exec sh -c 'echo "{}: $(wc -l < "{}")" lines' _ {} \; >> "$export_path/export_metadata.txt"
        
        echo "Logs exported to: $export_path"
        
        # Show summary
        echo ""
        echo "=== Export Summary ==="
        echo "Export directory: $export_path"
        echo "Total files: $(find "$export_path" -name "*.log" -type f | wc -l)"
        echo "Total size: $(du -sh "$export_path" | cut -f1)"
        echo ""
        
        return 0
    else
        echo "No logs directory found. Make sure containers have been running."
        return 1
    fi
}

# Function to create archive
create_archive() {
    local export_path="$EXPORT_DIR/$ARCHIVE_NAME"
    local archive_file="$EXPORT_DIR/${ARCHIVE_NAME}.tar.gz"
    
    if [ -d "$export_path" ]; then
        echo "Creating archive: $archive_file"
        tar -czf "$archive_file" -C "$EXPORT_DIR" "$ARCHIVE_NAME"
        
        if [ $? -eq 0 ]; then
            echo "Archive created successfully: $archive_file"
            echo "Archive size: $(ls -lh "$archive_file" | awk '{print $5}')"
            
            # Ask if user wants to remove the uncompressed directory
            read -p "Remove uncompressed directory? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$export_path"
                echo "Uncompressed directory removed."
            fi
        else
            echo "Failed to create archive."
            return 1
        fi
    else
        echo "Export directory not found: $export_path"
        return 1
    fi
}

# Function to clean old exports
clean_old_exports() {
    if [ -d "$EXPORT_DIR" ]; then
        echo "Cleaning exports older than 7 days from: $EXPORT_DIR"
        
        # Find and list old files
        OLD_FILES=$(find "$EXPORT_DIR" -type f -name "efm_logs_*" -mtime +7 2>/dev/null)
        OLD_DIRS=$(find "$EXPORT_DIR" -type d -name "efm_logs_*" -mtime +7 2>/dev/null)
        
        if [ ! -z "$OLD_FILES" ] || [ ! -z "$OLD_DIRS" ]; then
            echo "Found old exports:"
            [ ! -z "$OLD_FILES" ] && echo "$OLD_FILES"
            [ ! -z "$OLD_DIRS" ] && echo "$OLD_DIRS"
            echo ""
            
            read -p "Delete these old exports? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                [ ! -z "$OLD_FILES" ] && echo "$OLD_FILES" | xargs rm -f
                [ ! -z "$OLD_DIRS" ] && echo "$OLD_DIRS" | xargs rm -rf
                echo "Old exports cleaned."
            else
                echo "Clean operation cancelled."
            fi
        else
            echo "No old exports found."
        fi
    else
        echo "Export directory does not exist: $EXPORT_DIR"
    fi
}

# Parse command line arguments
CREATE_ARCHIVE=false
CLEAN_OLD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            EXPORT_DIR="$2"
            shift 2
            ;;
        -a|--archive)
            CREATE_ARCHIVE=true
            shift
            ;;
        -c|--clean)
            CLEAN_OLD=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
if [ "$CLEAN_OLD" = true ]; then
    clean_old_exports
    exit 0
fi

# Export logs
if export_logs; then
    # Create archive if requested
    if [ "$CREATE_ARCHIVE" = true ]; then
        create_archive
    fi
    
    echo ""
    echo "=== Export Complete ==="
    echo "Use './scripts/view-logs.sh' to view logs interactively"
    echo "Use '$0 --clean' to clean old exports"
    echo ""
else
    echo "Export failed."
    exit 1
fi