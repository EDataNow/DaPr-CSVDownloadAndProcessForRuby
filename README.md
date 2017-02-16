# DaPr-CSVDownloadAndProcessForRuby

**EDataNow** pushes csv reports hourly to S3.  This ruby script downloads all of the new CSV's from S3 and allows the end user to process each new csv file individually.

## Setup
- Ruby 2.3.0 or higher
- git clone git@github.com/EDataNow/DaPr-CSVDownloadAndProcessForRuby.git
- config.csv into the same directory as the DaPr-CSVDownloadAndProcessForRuby project folder

A config.csv file must be provided containing AWS credentials, region, and language preferences. In most cases this will be provided by us along with the AWS credentials.

<details>
 <summary> Creating the config.csv </summary>

> The headers for the config.csv are as follows:

> > User Name,Access Key Id,Secret Access Key,Region,Server,Language,Processor

> The order of these columns does not matter

> ####Required
> - User Name : This is the AWS username, usually an integer matching the Lessee ID on EDataNow
> - Access Key Id : This is used to authenticate your connection to our AWS buckets. If you do not have this, please contact your site administrator or EDN Liaison for the proper credentials.
> - Secret Access Key : As above
> - Region : As above (default is us-east-1)
> - Server : Determines where data is being pulled from. This will match the url used to access your data within our web app (eg. service.edatanow.com)
> - Language : You can see a list of ISO 639-1 language codes here: https://www.loc.gov/standards/iso639-2/php/code_list.php. English is en
> - Processor : We have provided an example ruby script which will print out the filenames and move them to the Processed folder, but if you wish to override this with a custom script, you may do so by including it's name here.  


> ####Example config.csv

> | User Name | Access Key Id | Secret Access Key | Region    | Server               | Language | Processor  |
> |-----------|---------------|-------------------|-----------|----------------------|----------|------------|
> | 3         | ABC123        | A1B2C3D4E5F6      | us-east-1 | service.edatanow.com | en       | example.rb |
</details>

## Resetting
- Delete anything from `./csv/{lessee-id}/{language}/Processed` and it will be redownloaded and reprocessed.
- Deleting all `./csv/` content will force the script to redownload everything.
