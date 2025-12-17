#!/bin/bash

################################################################################
# FTP Backup Script with Resume Support
# Backs up recovered drive data to remote FTP server
################################################################################

# Configuration
FTP_HOST=""
FTP_USER=""
FTP_PASSWORD=""  # Leave empty to prompt, or set password here
LOCAL_PATH="/mnt/baracuda-main/epi-2025/RRBS_delivery_relaxed/FINAL_DELIVERY/covgs_stats/"
REMOTE_PATH="/faraz_upload/covgs_stats/"  # Change to your desired remote directory
LOG_FILE="/home/$(whoami)/ftp_backup.log"
PARALLEL_TRANSFERS=2  # Number of simultaneous uploads

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

################################################################################
# Functions
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

check_requirements() {
    log "Checking requirements..."
    
    # Check if lftp is installed
    if ! command -v lftp &> /dev/null; then
        error "lftp is not installed. Install it with: sudo apt install lftp"
        exit 1
    fi
    
    # Check if local path exists
    if [ ! -d "$LOCAL_PATH" ]; then
        error "Local path does not exist: $LOCAL_PATH"
        exit 1
    fi
    
    # Check if local path is mounted
    if ! mountpoint -q "$LOCAL_PATH"; then
        warning "Local path is not a mount point: $LOCAL_PATH"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    success "All requirements met"
}

prompt_password() {
    if [ -z "$FTP_PASSWORD" ]; then
        read -sp "Enter FTP password: " FTP_PASSWORD
        echo
    fi
}

estimate_size() {
    log "Calculating local directory size..."
    local size=$(du -sh "$LOCAL_PATH" 2>/dev/null | cut -f1)
    log "Local directory size: $size"
}

create_lftp_script() {
    local script_file="/tmp/lftp_backup_$$.lftp"
    
    cat > "$script_file" << EOF
# Open connection
open -u $FTP_USER,$FTP_PASSWORD $FTP_HOST

# SSL settings (disable certificate verification)
set ssl:verify-certificate no

# Connection settings
set net:max-retries 10
set net:timeout 120
set net:reconnect-interval-base 10
set net:reconnect-interval-multiplier 1.5

# Transfer settings
set net:limit-rate 0:0  # No rate limit
set ftp:sync-mode off   # Don't wait for ACK

# Mirror settings
set mirror:use-pget-n $PARALLEL_TRANSFERS

# Verbose output
set cmd:trace true

# Navigate to remote directory
mkdir -p -f $REMOTE_PATH
cd $REMOTE_PATH

# Perform backup with resume and skip existing files
mirror \\
    --reverse \\
    --continue \\
    --only-missing \\
    --verbose \\
    --parallel=$PARALLEL_TRANSFERS \\
    --log="$LOG_FILE.mirror" \\
    $LOCAL_PATH .

# Exit
bye
EOF
    
    echo "$script_file"
}

run_backup() {
    log "Starting backup from $LOCAL_PATH to $FTP_HOST:$REMOTE_PATH"
    log "Parallel transfers: $PARALLEL_TRANSFERS"
    log "Mode: Skip existing files (--only-missing)"
    
    local lftp_script=$(create_lftp_script)
    
    # Run lftp with the script
    if lftp -f "$lftp_script" 2>&1 | tee -a "$LOG_FILE"; then
        success "Backup completed successfully!"
        local exit_code=0
    else
        error "Backup encountered errors. Check log: $LOG_FILE"
        local exit_code=1
    fi
    
    # Cleanup
    rm -f "$lftp_script"
    
    return $exit_code
}

show_summary() {
    log "=== Backup Summary ==="
    log "Local path: $LOCAL_PATH"
    log "Remote host: $FTP_HOST"
    log "Remote path: $REMOTE_PATH"
    log "Log file: $LOG_FILE"
    
    if [ -f "$LOG_FILE.mirror" ]; then
        log "Mirror log: $LOG_FILE.mirror"
        
        # Count transferred files
        local transferred=$(grep -c "^get\|^put" "$LOG_FILE.mirror" 2>/dev/null || echo "0")
        log "Files processed: $transferred"
    fi
}

dry_run() {
    log "=== DRY RUN MODE ==="
    log "This will show what would be transferred without actually doing it"
    
    local script_file="/tmp/lftp_dryrun_$$.lftp"
    
    cat > "$script_file" << EOF
open -u $FTP_USER,$FTP_PASSWORD $FTP_HOST
set ssl:verify-certificate no
cd $REMOTE_PATH || mkdir -p $REMOTE_PATH
mirror --reverse --only-missing --dry-run --verbose $LOCAL_PATH .
bye
EOF
    
    lftp -f "$script_file"
    rm -f "$script_file"
}

################################################################################
# Main Script
################################################################################

main() {
    echo "======================================================================"
    echo "  FTP Backup Script"
    echo "======================================================================"
    echo
    
    # Parse command line arguments
    DRY_RUN=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --parallel)
                PARALLEL_TRANSFERS="$2"
                shift 2
                ;;
            --password)
                FTP_PASSWORD="$2"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo
                echo "Options:"
                echo "  --dry-run              Show what would be transferred without doing it"
                echo "  --parallel N           Number of parallel transfers (default: 2)"
                echo "  --password PASS        FTP password (will prompt if not provided)"
                echo "  --help                 Show this help message"
                echo
                echo "Configuration:"
                echo "  Edit the script to change FTP_HOST, LOCAL_PATH, REMOTE_PATH"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Initialize log
    log "=== Backup Script Started ==="
    
    # Run checks
    check_requirements
    
    # Prompt for password if needed
    prompt_password
    
    # Show size estimate
    estimate_size
    
    # Dry run or actual backup
    if [ "$DRY_RUN" = true ]; then
        dry_run
    else
        echo
        warning "This will backup $LOCAL_PATH to $FTP_HOST:$REMOTE_PATH"
        warning "Existing files will be skipped (--only-missing mode)"
        read -p "Continue? (y/n): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            run_backup
            show_summary
        else
            log "Backup cancelled by user"
            exit 0
        fi
    fi
    
    log "=== Backup Script Finished ==="
}

# Run main function
main "$@"
