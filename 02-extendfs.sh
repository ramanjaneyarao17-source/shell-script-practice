#!/bin/bash

FS_DIR="$1"
EXTEND_SIZE="$2"

if [ -z "$FS_DIR" ] || [ -z "$EXTEND_SIZE" ]; then
    echo "Usage: $0 <mountpoint> <size_to_extend | e.g. +5G>"
    exit 1
fi

# 1. Show current utilization of the filesystem
echo "Current disk usage for $FS_DIR:"
df -h "$FS_DIR"

# 2. Find LV path from mountpoint
LV_PATH=$(df "$FS_DIR" | awk 'NR==2 {print $1}')
echo "Logical Volume path: $LV_PATH"

# 3. Find VG name
VG_NAME=$(lvs --noheadings -o vg_name "$LV_PATH" | xargs)
echo "Volume Group: $VG_NAME"

# 4. Check VG free space
VG_FREE=$(vgs "$VG_NAME" --noheadings -o vg_free | sed 's/[[:space:]]//g')
VG_FREE_MB=$(echo $VG_FREE | sed 's/\.[0-9]*//')
echo "Free space in $VG_NAME: $VG_FREE_MB"

# 5. Compare requested size with VG free space
REQ_MB=$(echo "$EXTEND_SIZE" | grep -Eo '[0-9]+' )
if [[ "$VG_FREE_MB" -ge "$REQ_MB" ]]; then
    echo "Enough VG free space. Extending Logical Volume..."
    lvextend -L "$EXTEND_SIZE" "$LV_PATH" -r
    echo "Filesystem extension completed!"
else
    echo "Not enough VG free space. Looking for new disks..."
    # Scan for new disks (assumes new disks are /dev/sdX without partitions/LVM)
    for d in $(lsblk -dn -o NAME | grep -vE 'loop|ram'); do
        DISK="/dev/$d"
        if ! pvs | grep -q "$DISK"; then
            echo "Found new disk: $DISK"
            pvcreate "$DISK"
            vgextend "$VG_NAME" "$DISK"
            echo "Disk $DISK added to VG $VG_NAME."
            break
        fi
    done
    # After adding, check VG free space again and extend LV
    VG_FREE=$(vgs "$VG_NAME" --noheadings -o vg_free | sed 's/[[:space:]]//g')
    VG_FREE_MB=$(echo $VG_FREE | sed 's/\.[0-9]*//')
    if [[ "$VG_FREE_MB" -ge "$REQ_MB" ]]; then
        echo "Free space now sufficient. Extending Logical Volume..."
        lvextend -L "$EXTEND_SIZE" "$LV_PATH" -r
        echo "Filesystem extension completed!"
    else
        echo "Failed to find or add sufficient disk space! Please check disks and retry."
        exit 2
    fi
fi

# 6. Final usage
echo "Final disk usage for $FS_DIR:"
df -h "$FS_DIR"
