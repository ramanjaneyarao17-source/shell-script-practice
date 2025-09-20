#!/bin/bash

FS_DIR="$1"
EXTEND_SIZE="$2"

if [ -z "$FS_DIR" ] || [ -z "$EXTEND_SIZE" ]; then
    echo "Usage: $0 <mountpoint> <size_to_extend | e.g. +5G>"
    echo "Example: $0 /mnt/data +10G"
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

# 4. Check VG free space in a format like 2.54g or 512m
VG_FREE=$(vgs "$VG_NAME" --noheadings -o vg_free | sed 's/[[:space:]]//g')
VG_FREE_NUM=${VG_FREE%?}  # Number part, e.g., 2.54
VG_FREE_UNIT=${VG_FREE: -1}  # Last char unit, e.g., g or m

# Convert VG free to MB for numeric comparison
case "$VG_FREE_UNIT" in
  M|m) VG_FREE_MB=${VG_FREE_NUM%.*} ;;
  G|g) VG_FREE_MB=$(echo "$VG_FREE_NUM * 1024 / 1" | bc) ;;
  T|t) VG_FREE_MB=$(echo "$VG_FREE_NUM * 1024 * 1024 / 1" | bc) ;;
  *) VG_FREE_MB=0 ;;
esac

echo "Free space in $VG_NAME: $VG_FREE (~${VG_FREE_MB}MB)"

# 5. Parse requested size to MB (strip leading +)
SIZE_STR="${EXTEND_SIZE#\+}"     # Remove leading +
UNIT="${SIZE_STR: -1}"           # Last char unit
SIZE_NUM="${SIZE_STR%?}"         # Numeric part

case "$UNIT" in
  G|g) REQ_MB=$(echo "$SIZE_NUM * 1024 / 1" | bc) ;;
  M|m) REQ_MB=$SIZE_NUM ;;
  K|k) REQ_MB=$(echo "$SIZE_NUM / 1024 / 1" | bc) ;;
  *) REQ_MB=$SIZE_NUM ;;
esac

echo "Requested extension size: $EXTEND_SIZE (~${REQ_MB}MB)"

# 6. Extend or add new disk as needed
if [[ "$VG_FREE_MB" -ge "$REQ_MB" ]]; then
    echo "Enough VG free space. Extending Logical Volume..."
    lvextend -L "$EXTEND_SIZE" "$LV_PATH" -r
    echo "Filesystem extension completed!"
else
    echo "Not enough VG free space. Looking for new disks..."
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

    # Re-check free space
    VG_FREE=$(vgs "$VG_NAME" --noheadings -o vg_free | sed 's/[[:space:]]//g')
    VG_FREE_NUM=${VG_FREE%?}
    VG_FREE_UNIT=${VG_FREE: -1}
    case "$VG_FREE_UNIT" in
      M|m) VG_FREE_MB=${VG_FREE_NUM%.*} ;;
      G|g) VG_FREE_MB=$(echo "$VG_FREE_NUM * 1024 / 1" | bc) ;;
      T|t) VG_FREE_MB=$(echo "$VG_FREE_NUM * 1024 * 1024 / 1" | bc) ;;
      *) VG_FREE_MB=0 ;;
    esac

    if [[ "$VG_FREE_MB" -ge "$REQ_MB" ]]; then
        echo "Free space now sufficient. Extending Logical Volume..."
        lvextend -L "$EXTEND_SIZE" "$LV_PATH" -r
        echo "Filesystem extension completed!"
    else
        echo "Failed to find or add sufficient disk space! Please check disks and retry."
        exit 2
    fi
fi

# 7. Final disk usage
echo "Final disk usage for $FS_DIR:"
df -h "$FS_DIR"
