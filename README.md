# Bucket_ReadR
This takes a list of bucket args and outputs a file with summary stats of the bucket.

Run the following command in a terminal where R is installed for help.

```
Rscript --vanilla Bucket_ReadR.R --help
```

```
Usage: Bucket_ReadR.R [options]

Bucket_ReadR v1.0.0

Options:
	-b CHARACTER, --buckets=CHARACTER
		A list of buckets, each separated by a comma (no spaces). Please provide the bucket names in a format that does not include the 's3://' prefix or the '/' suffix.

	-h, --help
		Show this help message and exit
```

This script will read into buckets that the user has access to. The format of the bucket is important for the script to handle the strings for example:

```
s3://test_bucket1/
s3://test_bucket2/
s3://test_bucket2/subfolder/
```

Will need to be in the following format for the script:

```
Rscript --vanilla Bucket_ReadR.R -b test_bucket1,test_bucket2,test_bucket2/subfolder
```
