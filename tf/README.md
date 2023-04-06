DataBricks Stack Set Up
=======================

Log in to Azure using the CLI:

``` shell
az login
```

Get the Subscription ID and Storage Account Name from `backend.tf`.  Or, if this is a new subscription, do the following to create a new service principal:

``` shell
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}"

Your appId, password, sp_name, and tenant are returned. Make a note of the appId and password.
```

Finally, it's possible to test these values work as expected by first logging in:

``` shell
az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET --tenant $TENANT_ID
```

If this is a new subscription, then you will need to create the resource group and storage account where Terraform will store its state files

``` shell
az group create --name $RESOURCE_GROUP_NAME --location $AZURE_REGION_LOCATION_NAME

az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME --location $AZURE_REGION_LOCATION_NAME --sku Standard_LRS
```

Create a Blob storage container for the state file for your stack.

``` shell
az storage container create --name $STACK_NAME \
    --auth-mode login \
    --account-name $STORAGE_ACCOUNT_NAME \
    --subscription $SUBSCRIPTION_ID
```

Point the Azure CLI to the correct subscription for your stack.

``` shell
az account set --subscription $SUBSCRIPTION_NAME
```

Set up Terraform. It's going to ask for:

* The name of container for you state file.
* A key, that is a file name, for your state file.

For the container name use the one you just created. for the state file name use your stack name followed by `.tf`.

``` shell
terraform init
```

Verify which variables from `variables.tf` you need to adjust.

Check that Terraform will create the resources you need.

``` shell
terraform plan
```

If everything looks good create the resources.

``` shell
terraform apply
```

Create your notebook in Databricks

``` shell
spark.conf.set("fs.azure.createRemoteFileSystemDuringInitialization", "true")
dbutils.fs.ls("abfss://risk@gfsqaedwdatabrickssa.dfs.core.windows.net/")
spark.conf.set("fs.azure.createRemoteFileSystemDuringInitialization", "false")
```

``` shell
%python
data = spark.read.csv("/databricks-datasets/samples/population-vs-price/data_geo.csv", header="true", inferSchema="true")
data.cache() # Cache data for faster reuse
data = data.dropna() # drop rows with missing values
```

``` shell
%python
data.take(10)
```

``` shell
%python
display(data)
```

``` shell
%python
data.createOrReplaceTempView("data_geo")
```

``` shell
%sql
select `State Code`, `2015 median sales price` from data_geo
```

