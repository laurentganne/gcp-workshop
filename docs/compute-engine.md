# Compute Engine

## Create a Compute Instance 

```
gcloud compute instances create myinstance \
    --image-family centos-7 \
    --image-project centos-cloud \
    --machine-type n1-standard-1 \
    --zone europe-west1-b \
    --preemptible
```

See [gcloud compute instances create](https://cloud.google.com/sdk/gcloud/reference/compute/instances/create).
Parameters used above :
  * [image](https://cloud.google.com/compute/docs/images): references public images provided by Compute Engine, or custom images you can create
  * [machine-type](https://cloud.google.com/compute/docs/machine-types): Type of machine to use.
  * [zone](https://cloud.google.com/compute/docs/regions-zones/): resources live in regions and zones. Check the [pricing](https://cloud.google.com/compute/pricing?hl=en) list to see differences between regions.


Other option of interest, attaching GPUs:
```
--accelerator type=nvidia-tesla-k80, count=2
```
See [documentation](https://cloud.google.com/compute/docs/gpus/add-gpus#create-new-gpu-instance) about creating an instance with GPUS, using a startup script to install required drivers.


## Manage ssh keys

User-defined keys can be define in the Compute instance metadata.
To define such keys, and assocate them to a compute instance, first create a file containing users and public keys values following this format: ```<user>:<key-value>```.
For example, with a public key ```./id_rsa.pub```, create a file containing two users ```user1``` and ```user2``` running :
```
echo  "user1:`cat id_rsa.pub`" > userkeys.txt
echo  "user2:`cat id_rsa.pub`" >> userkeys.txt
```
You can then define these user and keys for your Compute Instance running:
```
gcloud compute instances add-metadata myinstance --metadata-from-file ssh-keys=userkeys.txt
```
You can then ssh to your instance running:
```
ssh -i ./id_rsa user1@<your instance external ip address>
```


## Stop an instance

```
gcloud compute instances stop myinstance --async
````

## Start an instance

```
gcloud compute instances start myinstance
````

Check IP addresses have changed on restart (ephemeral IP addresses by default)

## Delete a compute instance

```
gcloud compute instances delete myinstance
````

Next: [Storage](storage.md)

