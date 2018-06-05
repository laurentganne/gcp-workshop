# Setup

Go to the [Google Cloud Platform Console](https://console.cloud.google.com), sign up and create a new project.

On your host, download and install the [gcloud SDK](https://cloud.google.com/sdk/) following this [documentation](https://cloud.google.com/sdk/docs/quickstart-linux) (here for linux).

Once done, add additional dependencies that wil be used in the  [Kubernetes Engine section](kubernetes-engine.md) :
```
gcloud components install kubectl
```

Another alternative, that will be used in the  [Cloud Machine Learning section](cloud-ml-engine.md), is to use [Google Cloud Shell](https://cloud.google.com/shell/docs/), a shell environment with all required dependencies already installed for managing resources hosted on Google Cloud Platform.

References:
  * [Google Cloud Platform documentation](https://cloud.google.com/docs/)

Next: [Compute Engine](compute-engine.md)