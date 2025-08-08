#!/bin/bash
# Debug script to check EFM package availability

echo "=== EFM Package Availability Debug Script ==="
echo ""

# Function to check package availability in a Docker image
check_packages_in_image() {
    local image="$1"
    local distro_name="$2"
    
    echo "--- Testing $distro_name ($image) ---"
    
    # Create a temporary container to check package availability
    docker run --rm "$image" bash -c "
        echo 'System Info:'
        cat /etc/os-release | grep -E '^(NAME|VERSION)='
        uname -m
        echo ''
        
        echo 'Installing prerequisites...'
        apt-get update -q
        apt-get install -y curl gnupg2 lsb-release ca-certificates apt-transport-https -q
        
        echo 'Adding EDB repository...'
        curl -1sSLf 'https://downloads.enterprisedb.com/a42f0873c732be6edafe2e22849eb0ff/enterprise/setup.deb.sh' | bash
        
        echo 'Updating package lists...'
        apt-get update -q
        
        echo 'Searching for EFM packages...'
        apt-cache search edb-efm || echo 'No EFM packages found'
        
        echo 'Available EFM versions:'
        apt-cache madison edb-efm* || echo 'No EFM packages available'
    " 2>&1
    echo ""
}

echo "Checking EFM package availability across different base images..."
echo ""

# Test different base images
images=(
    "debian:11|Debian 11"
    "debian:12|Debian 12" 
    "ubuntu:20.04|Ubuntu 20.04"
    "ubuntu:22.04|Ubuntu 22.04"
    "postgres:17|PostgreSQL 17 (Debian-based)"
)

for image_info in "${images[@]}"; do
    IFS='|' read -r image name <<< "$image_info"
    
    echo "Testing $name..."
    if docker image inspect "$image" >/dev/null 2>&1; then
        check_packages_in_image "$image" "$name"
    else
        echo "Image $image not available locally, pulling..."
        if docker pull "$image" >/dev/null 2>&1; then
            check_packages_in_image "$image" "$name"
        else
            echo "Failed to pull $image"
            echo ""
        fi
    fi
done

echo "=== Debug Complete ==="
echo ""
echo "Recommendations:"
echo "1. Use Debian 12 as the base image (best EFM 5.0 support)"  
echo "2. Ensure you're using the enterprise repository URL"
echo "3. Verify edb-efm50 package is available for your architecture"
echo "4. Check that ca-certificates and apt-transport-https are installed"
echo ""