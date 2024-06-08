# seArchitecture

## Prerequisites

* Terraform
* Azure CLI
* Azure Functions Core Tools
* Python 3.11 or lower
  * 3.12 is not supported on Azure Functions Core Tools (as of 2024/06/08)

## Create Azure Function Project

```sh
python -m venv .venv
source .venv/bin/activate
```

```sh
cd function_codes
func init {PROJECT_NAME} --python -m V2
cd {PROJECT_NAME}
```

## Install Dependencies

```sh
pip install -r requirements.txt
```

## Start Azure Function Locally

```sh
func azure functionapp fetch-app-settings {FUNCTIONS_APP_NAME}
func start # Ctrl + C to exit
```

## References

* <https://learn.microsoft.com/ja-jp/azure/azure-functions/create-first-function-cli-python>
