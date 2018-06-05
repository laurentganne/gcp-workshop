# Storage

## Block storage

You can create [Persistent Disks](https://cloud.google.com/compute/docs/disks/), and attach up to 16 persistent disks to a compute instance.

Persistent disks can be of one of these types :

  * [standard](https://cloud.google.com/compute/docs/disks/#pdspecs) HDD or SSD persistent disk
    * up to 64 TB, redundancy in zone
    * can be either attached to one compute instance in read-write mode, or to n instances in read-only.
    * In any case the Compute instance must be on the same zone as the disk
  * [regional](https://cloud.google.com/compute/docs/disks/#repds) HDD or SSD persistent disk replicated in 2 zones (beta version)
    * up to 64 TB, multi-zone redundancy
    * must be attached in read-write mode
    * support force attach to another compute instance in case of zone failure

You can also attach up to 8 local SSD to one instance:
  * up to 3 TB
  * persists if you reboot or reset your instance, but not if you stop your instance

Example creating a standard persistent disk, and attaching it:
```
gcloud compute disks create mydisk1 --size 10GB --type pd-ssd
gcloud compute instances attach-disk myinstance --disk mydisk1 --mode rw
```
Then, login on the instance and get the list of attached disks :
```
sudo lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda      8:0    0  10G  0 disk
-sda1    8:1    0  10G  0 part /
sdb      8:16   0   1G  0 disk
```

Format the disk:
```
sudo mkfs.ext4 -m 0 -F -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
```

This disk can now be mounted and added to /etc/fstab to have it mounted at boot, or just mounted manually :
```
sudo mount -o discard,defaults /dev/sdb /mnt/
df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        10G  1.6G  8.5G  16% /
devtmpfs        1.8G     0  1.8G   0% /dev
tmpfs           1.8G     0  1.8G   0% /dev/shm
tmpfs           1.8G  9.5M  1.8G   1% /run
tmpfs           1.8G     0  1.8G   0% /sys/fs/cgroup
tmpfs           354M     0  354M   0% /run/user/0
tmpfs           354M     0  354M   0% /run/user/1001
/dev/sdb        976M  2.6M  958M   1% /mnt
 
sudo umount /mnt
```

References:

  * Add a persistent disk: https://cloud.google.com/compute/docs/disks/add-persistent-disk

## Cloud storage

When latency and throughput is less a priority than being able to share data easily between multiple instances or zones,
[Cloud Storage](https://cloud.google.com/storage/?hl=en) buckets can by used.

A Cloud Storage bucket has a storage class defining its availability and price :
  * [multi-regional](https://cloud.google.com/storage/docs/storage-classes#multi-regional): 99,95% availability SLA (monthly uptime percentage), geo-redundant
  * [regional](https://cloud.google.com/storage/docs/storage-classes#regional): 99.9% availability SLA, multi-zone redundancy
  * [nearline](https://cloud.google.com/storage/docs/storage-classes#nearline) (for backups): low cost per GBdata retrieval/operation cost
  * [coldline](https://cloud.google.com/storage/docs/storage-classes#coldline) (for disaster recovery): low cost per GB, data retrieval/operation cost

Examples:
Create a bucket
```
gsutil mb -l europe-west1 gs://bdsw-testbucket/
```
Copy a file in this bucket, under a new folder to create :
```
gsutil cp tmpfile gs://bdsw-testbucket/a-folder/
```
List contents :
```
gsutil ls -l gs://bdsw-testbucket/a-folder/
```

Delete the bucket:
```
gsutil rm -r gs://bdsw-testbucket/
```

References:
  * Mounting Cloud Storage buckets as file system using Cloud Storage FUSE: https://cloud.google.com/storage/docs/gcs-fuse
  * https://cloud.google.com/storage/docs/quickstart-gsutil

Next: [Kubernetes Engine](kubernetes-engine.md)
